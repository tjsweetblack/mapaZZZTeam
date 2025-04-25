import 'package:auth_bloc/screens/profile/reward_pending.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:flutter/services.dart'; // Import for Clipboard
import 'dart:math'; // Import for Random

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key}); // Added const constructor

  // Function to generate a simple unique code
  String _generateClaimCode(String rewardId, String userId) {
    // A simple approach: combine parts of IDs and a random string
    // For a production app, consider a more robust server-side generation
    final random = Random();
    final randomString = String.fromCharCodes(List.generate(
        6, (_) => random.nextInt(33) + 89)); // Generate 6 random chars
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    // Combine parts and take a substring for a fixed length (e.g., 12 chars)
    // This is NOT guaranteed to be globally unique or cryptographically secure
    final base = '${rewardId.substring(0, min(4, rewardId.length))}'
        '${userId.substring(0, min(4, userId.length))}'
        '${timestamp.substring(timestamp.length - min(4, timestamp.length))}'
        '$randomString';

    return base
        .substring(0, min(12, base.length))
        .toUpperCase(); // Use uppercase
  }

  // Function to handle claiming a reward
  Future<String?> _claimReward(String userId, String rewardId) async {
    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(userId);
      final userDoc = await userDocRef.get();
      final dynamic rawUserData = userDoc.data(); // Get raw data

      Map<String, dynamic>? userData;
      // Explicitly check if data is a Map before using it
      if (rawUserData != null && rawUserData is Map<String, dynamic>) {
        userData = rawUserData;
      }

      if (userData != null) {
        // Access 'pending' field safely now that userData is confirmed as Map<String, dynamic>
        // Ensure 'pending' is treated as List<dynamic> to handle potential null or non-list data
        final List<dynamic> pendingListDynamic = userData['pending'] ?? [];
        List<Map<String, dynamic>> pendingRewards = pendingListDynamic
            .whereType<Map<String, dynamic>>() // Filter out non-map items
            .toList();

        // Check if the reward ID is already in the pending list (check within the maps)
        bool isAlreadyPending =
            pendingRewards.any((item) => item['rewardId'] == rewardId);

        if (!isAlreadyPending) {
          // Generate the claim code
          final String claimCode = _generateClaimCode(rewardId, userId);

          // Create the new pending item map
          final newPendingItem = {
            'rewardId': rewardId,
            'claimCode': claimCode,
            'timestamp': Timestamp.now(), // <--- CORRECTED: Use Timestamp.now()
          };

          // Add the new item to the pending list
          pendingRewards.add(newPendingItem);

          // Update the user document with the new list
          await userDocRef.update({
            'pending': pendingRewards,
          });

          print(
              'Reward $rewardId added to pending list for user $userId with code $claimCode');
          return claimCode; // Return the generated code
        } else {
          print('Reward $rewardId is already in pending list for user $userId');
          // Optionally retrieve the existing code if needed, but for now, just indicate it's pending
          // You could return null or a specific value to indicate it was already pending
          return null; // Indicate it was already pending
        }
      } else {
        print('Error claiming reward: User data is null or not a Map.');
        return null; // Indicate failure
      }
    } catch (e) {
      print('Error claiming reward: $e');
      return null; // Indicate failure
    }
  }

  // Function to show the claim code pop-up
  void _showClaimCodeDialog(BuildContext context, String claimCode) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap a button to close
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Código de Reivindicação',
              textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Make column fit content
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Este é o código que vais usar para reivindicar este prêmio:',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 12.0),
              Center(
                // Center the code text
                child: Text(
                  claimCode,
                  style: const TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.red, // Highlight the code
                  ),
                ),
              ),
              const SizedBox(height: 12.0),
              const Text(
                'O código também pode ser encontrado na seção "Prêmios Pendentes".',
                style: TextStyle(
                    fontSize: 14.0,
                    fontStyle: FontStyle.italic,
                    color: Colors.black54),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Copiar'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: claimCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Código copiado para a área de transferência!')),
                );
                // No need to close the dialog here, user can copy multiple times
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser; // Get current user

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Prêmios")),
        body: const Center(child: Text("User not logged in.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon:
              const Icon(Icons.chevron_left, color: Colors.black), // Black icon
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Prêmios',
            style: TextStyle(color: Colors.black)), // Black title
        centerTitle: true,
        backgroundColor: Colors.white, // White AppBar background
        elevation: 0, // Remove shadow
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // Stream for user data
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) {
            return Center(
                child: Text('Error loading user data: ${userSnapshot.error}'));
          }
          // You can still show a loading indicator specifically for the user data fetch if needed
          // if (userSnapshot.connectionState == ConnectionState.waiting) {
          //   return const Center(child: CircularProgressIndicator());
          // }

          // Explicitly check if user data is a Map before accessing keys
          final dynamic rawUserData = userSnapshot.data?.data();
          Map<String, dynamic>? userData;
          // Corrected variable name check here
          if (rawUserData != null && rawUserData is Map<String, dynamic>) {
            userData = rawUserData;
          }

          // Now access 'points' and 'pending' using the potentially null userData Map
          // These lines should now be safe because userData is either a valid Map or null
          final int userPoints = userData?['points'] as int? ?? 0;

          // Safely get the pending list, ensuring it's treated as a List of Maps
          final List<dynamic> pendingListDynamic = userData?['pending'] ?? [];
          final List<Map<String, dynamic>> pendingRewardsMaps =
              pendingListDynamic
                  .whereType<
                      Map<String, dynamic>>() // Filter out any non-map entries
                  .toList();

          // Extract just the reward IDs for checking if a reward is pending
          final List<String> pendingRewardIds = pendingRewardsMaps
              .map((item) =>
                  item['rewardId'] as String?) // Map to rewardId (can be null)
              .where((id) => id != null) // Filter out null IDs
              .cast<String>() // Cast to non-nullable String
              .toList();

          // Build the main content based on user data and rewards data
          return Column(
            children: [
              // Pending Rewards Banner
              if (pendingRewardIds
                  .isNotEmpty) // Show only if there are pending rewards
                GestureDetector(
                  onTap: () {
                    // Navigate to Pending Rewards Page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PendingRewardsPage()),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Center(
                      child: Text(
                        '${pendingRewardIds.length} prêmios pendentes',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ),
                ),

              // Rewards List (using the existing StreamBuilder)
              Expanded(
                // Use Expanded to make the ListView take available space
                child: StreamBuilder<QuerySnapshot>(
                  // Stream for rewards data
                  stream: FirebaseFirestore.instance
                      .collection('reward')
                      .snapshots(),
                  builder: (context, rewardsSnapshot) {
                    if (rewardsSnapshot.hasError) {
                      return Center(
                          child: Text(
                              'Error loading rewards: ${rewardsSnapshot.error}'));
                    }

                    if (rewardsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child:
                              CircularProgressIndicator()); // Show loading for rewards
                    }

                    if (rewardsSnapshot.data == null ||
                        rewardsSnapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No rewards found.'));
                    }

                    return ListView(
                      children: rewardsSnapshot.data!.docs
                          .map((DocumentSnapshot document) {
                        Map<String, dynamic> data = document.data() as Map<
                            String,
                            dynamic>; // Cast is okay here as it's reward data doc.data()
                        final String rewardId =
                            document.id; // Get the document ID
                        final int rewardPoints = data['points'] ??
                            0; // Access points from reward data

                        // Determine button state
                        bool canClaim = userPoints >= rewardPoints;
                        bool isPending = pendingRewardsMaps.any((item) =>
                            item['rewardId'] ==
                            rewardId); // Check if rewardId is in any pending map

                        String buttonText;
                        Color buttonColor;
                        VoidCallback? onPressed;
                        Color?
                            itemStrokeColor; // Use for highlighting pending items

                        if (isPending) {
                          buttonText = 'Pendente';
                          buttonColor =
                              Colors.orange; // Or another color for pending
                          onPressed = null; // Disable button
                          itemStrokeColor =
                              Colors.orange; // Highlight pending item
                        } else if (canClaim) {
                          buttonText = 'Reivindicar';
                          buttonColor = Colors.red;
                          onPressed = () async {
                            // Make onPressed async
                            final String? claimCode =
                                await _claimReward(user.uid, rewardId);
                            if (claimCode != null && context.mounted) {
                              // Check if claim was successful and widget is mounted
                              _showClaimCodeDialog(context, claimCode);
                            }
                          };
                          itemStrokeColor = null; // No special stroke
                        } else {
                          buttonText = 'Pontos Insuficientes';
                          buttonColor =
                              Colors.grey; // Grey out if not enough points
                          onPressed = null; // Disable button
                          itemStrokeColor = null; // No special stroke
                        }

                        return _buildRewardItem(
                          image: data['imageUrl'] ?? '',
                          title: data['title'] ?? '',
                          points: rewardPoints,
                          buttonText: buttonText,
                          buttonColor: buttonColor,
                          onPressed:
                              onPressed, // Pass the determined onPressed callback
                          strokeColor: itemStrokeColor, // Pass the stroke color
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRewardItem({
    required String image,
    required String title,
    required int points,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback? onPressed, // Added onPressed callback
    Color? strokeColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: strokeColor ?? Colors.grey.shade300,
          width: strokeColor != null
              ? 2.0
              : 1.0, // Thicker stroke for highlighted items
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                height: 80.0,
                child: image.isNotEmpty
                    ? Image.network(
                        image,
                        // Optional: Add error handling for network image
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.image_not_supported,
                              size: 50, color: Colors.grey); // Show error icon
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      )
                    : const Icon(Icons.card_giftcard,
                        size: 50,
                        color: Colors
                            .grey), // Show gift icon if image URL is empty
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Nome:',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            Text(title, style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 8.0),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.star,
                  color: Colors.red,
                  size: 20.0,
                ),
                const SizedBox(width: 4.0),
                Text('pontos necessario: $points pontos',
                    style: const TextStyle(color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 16.0),
            Align(
              alignment: Alignment.bottomLeft,
              child: ElevatedButton(
                onPressed: onPressed, // Use the passed onPressed callback
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white, // Text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
