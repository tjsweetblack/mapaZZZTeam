import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // Import for Clipboard

class PendingRewardsPage extends StatefulWidget {
  const PendingRewardsPage({Key? key}) : super(key: key);

  @override
  _PendingRewardsPageState createState() => _PendingRewardsPageState();
}

class _PendingRewardsPageState extends State<PendingRewardsPage> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Prêmios Pendentes")),
        body: const Center(child: Text("User not logged in.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Prêmios Pendentes',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      // StreamBuilder to listen for real-time updates to the user's pending list
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) {
            return Center(
                child: Text('Error loading user data: ${userSnapshot.error}'));
          }

          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Explicitly check if user data is a Map before accessing keys
          final dynamic rawUserData = userSnapshot.data?.data();
          Map<String, dynamic>? userData;
          if (rawUserData != null && rawUserData is Map<String, dynamic>) {
            userData = rawUserData;
          }

          // Safely get the pending list, ensuring it's treated as a List of Maps
          final List<dynamic> pendingListDynamic = userData?['pending'] ?? [];
          final List<Map<String, dynamic>> pendingRewardsFromUser =
              pendingListDynamic
                  .whereType<
                      Map<String, dynamic>>() // Filter out any non-map entries
                  .toList();

          if (pendingRewardsFromUser.isEmpty) {
            return const Center(child: Text('Você não tem prêmios pendentes.'));
          }

          // Extract just the reward IDs to fetch reward details
          final List<String> pendingRewardIds = pendingRewardsFromUser
              .map((item) =>
                  item['rewardId'] as String?) // Map to rewardId (can be null)
              .where((id) => id != null) // Filter out null IDs
              .cast<String>() // Cast to non-nullable String
              .toList();

          // If there are pending IDs, fetch the reward details
          if (pendingRewardIds.isNotEmpty) {
            return FutureBuilder<List<DocumentSnapshot>>(
              future: _fetchPendingRewardDetails(pendingRewardIds),
              builder: (context, rewardsSnapshot) {
                if (rewardsSnapshot.hasError) {
                  return Center(
                      child: Text(
                          'Error loading pending reward details: ${rewardsSnapshot.error}'));
                }

                if (rewardsSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!rewardsSnapshot.hasData || rewardsSnapshot.data!.isEmpty) {
                  return const Center(
                      child: Text(
                          'Nenhum detalhe encontrado para prêmios pendentes.'));
                }

                final rewardDetailsDocs = rewardsSnapshot.data!;

                // Create a map for easy lookup of reward details by ID
                final Map<String, Map<String, dynamic>> rewardDetailsMap = {
                  for (var doc in rewardDetailsDocs)
                    doc.id: doc.data() as Map<String, dynamic>? ??
                        {} // Use empty map if data is null
                };

                // Now build the list using the pending items from the user document
                // and looking up details from the fetched reward documents
                return ListView.builder(
                  itemCount: pendingRewardsFromUser.length,
                  itemBuilder: (context, index) {
                    final pendingItem = pendingRewardsFromUser[index];
                    final String? rewardId = pendingItem['rewardId'] as String?;
                    final String? claimCode =
                        pendingItem['claimCode'] as String?;

                    // Ensure we have a valid rewardId and claimCode
                    if (rewardId == null || claimCode == null) {
                      print(
                          'Warning: Invalid pending item data (missing rewardId or claimCode): $pendingItem');
                      return const SizedBox.shrink(); // Skip invalid items
                    }

                    // Look up the reward details using the rewardId
                    final rewardDetail = rewardDetailsMap[rewardId];

                    // Ensure reward details were found
                    if (rewardDetail == null) {
                      print(
                          'Warning: Reward details not found for ID: $rewardId');
                      return const SizedBox
                          .shrink(); // Skip if details not found
                    }

                    final String title =
                        rewardDetail['title'] ?? 'Unknown Reward';
                    final String imageUrl = rewardDetail['imageUrl'] ?? '';

                    return _buildPendingRewardItem(
                      title: title,
                      imageUrl: imageUrl,
                      claimCode: claimCode, // Pass the claim code
                      onCopy: () {
                        Clipboard.setData(ClipboardData(text: claimCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Código copiado!')),
                        );
                      },
                    );
                  },
                );
              },
            );
          } else {
            // This case is already covered by the initial check, but good to have
            return const Center(child: Text('Você não tem prêmios pendentes.'));
          }
        },
      ),
    );
  }

  // Helper function to fetch details for pending rewards by their IDs
  Future<List<DocumentSnapshot>> _fetchPendingRewardDetails(
      List<String> rewardIds) async {
    if (rewardIds.isEmpty) {
      return [];
    }

    // Use Future.wait to fetch all documents concurrently
    List<Future<DocumentSnapshot>> futures = rewardIds
        .map((id) =>
            FirebaseFirestore.instance.collection('reward').doc(id).get())
        .toList();
    List<DocumentSnapshot> results = await Future.wait(futures);

    // Filter out documents that were not found (where doc.data() would be null)
    return results.where((doc) => doc.exists).toList();
  }

  Widget _buildPendingRewardItem({
    required String title,
    required String imageUrl,
    required String claimCode, // Added claimCode
    required VoidCallback onCopy, // Added onCopy callback for the button
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
            color: Colors.orange, width: 2.0), // Highlight pending items
      ),
      child: Column(
        // Use Column to stack image, text, and button vertically
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            // Row for image and text
            children: [
              Container(
                width: 60,
                height: 60,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.image_not_supported,
                              size: 40, color: Colors.grey);
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
                        size: 40, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                // Use Expanded to prevent overflow if title is long
                child: Column(
                  // Column for title and code
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Código: $claimCode', // Display the claim code
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontFamily:
                            'monospace', // Use a monospace font for codes
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Space between text/image row and button
          Align(
            // Align the button to the left
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              // Use ElevatedButton.icon for button with icon
              onPressed: onCopy, // Use the passed onCopy callback
              icon: const Icon(Icons.copy, size: 18), // Copy icon
              label: const Text('Copiar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey, // Choose a suitable color
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
