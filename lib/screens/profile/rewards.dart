import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:auth_bloc/screens/profile/reward_pending.dart'; // Import the PendingRewardsPage

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  String _generateClaimCode(String rewardId, String userId) {
    final random = Random();
    final randomString =
        String.fromCharCodes(List.generate(6, (_) => random.nextInt(33) + 89));
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final base =
        '${rewardId.substring(0, min(4, rewardId.length))}${userId.substring(0, min(4, userId.length))}${timestamp.substring(timestamp.length - min(4, timestamp.length))}$randomString';
    return base.substring(0, min(12, base.length)).toUpperCase();
  }

  Future<String?> _claimReward(String userId, String rewardId, int rewardPoints,
      BuildContext context) async {
    // Add BuildContext
    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(userId);
      final userDoc = await userDocRef.get();
      final dynamic rawUserData = userDoc.data();

      Map<String, dynamic>? userData;
      if (rawUserData != null && rawUserData is Map<String, dynamic>) {
        userData = rawUserData;
      }

      if (userData != null) {
        // Changed from 'pending' to 'rewards'
        final List<dynamic> userRewardsDynamic = userData['rewards'] ?? [];
        List<Map<String, dynamic>> userRewards =
            userRewardsDynamic.whereType<Map<String, dynamic>>().toList();

        // Check for existing pending reward
        bool isAlreadyPending = userRewards.any((item) =>
            item['rewardId'] == rewardId && item['status'] == 'pending');

        if (!isAlreadyPending) {
          final String claimCode = _generateClaimCode(rewardId, userId);
          // Added status field
          final newRewardItem = {
            'rewardId': rewardId,
            'claimCode': claimCode,
            'timestamp': Timestamp.now(),
            'status':
                'pending', // Initial status is pending // <--- ADDED STATUS FIELD
          };

          userRewards.add(newRewardItem);

          // Deduct points
          final int currentUserPoints = userData['points'] ?? 0;
          if (currentUserPoints >= rewardPoints) {
            await userDocRef.update({
              'rewards': userRewards, // Changed from 'pending' to 'rewards'
              'points': currentUserPoints - rewardPoints,
            });
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Insufficient points to claim this reward.'),
                ),
              );
            }
            return null;
          }

          print(
              'Reward $rewardId added to rewards list for user $userId with code $claimCode and status pending');
          return claimCode;
        } else {
          print('Reward $rewardId is already pending for user $userId');
          return null;
        }
      } else {
        print('Error claiming reward: User data is null or not a Map.');
        return null;
      }
    } catch (e) {
      print('Error claiming reward: $e');
      return null;
    }
  }

  void _showClaimCodeDialog(BuildContext context, String claimCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Código de Reivindicação',
              textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Este é o código que vais usar para reivindicar este prêmio:',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 12.0),
              Center(
                child: Text(
                  claimCode,
                  style: const TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
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
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
          icon: const Icon(Icons.chevron_left, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Prêmios', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) {
            return Center(
                child: Text('Error loading user data: ${userSnapshot.error}'));
          }

          final dynamic rawUserData = userSnapshot.data?.data();
          Map<String, dynamic>? userData;
          if (rawUserData != null && rawUserData is Map<String, dynamic>) {
            userData = rawUserData;
          }

          final int userPoints = userData?['points'] as int? ?? 0;

          // Changed from 'pending' to 'rewards'
          final List<dynamic> userRewardsDynamic = userData?['rewards'] ?? [];
          List<Map<String, dynamic>> userRewards =
              userRewardsDynamic.whereType<Map<String, dynamic>>().toList();

          // Filter pending rewards
          final List<Map<String, dynamic>> pendingRewards =
              userRewards.where((item) => item['status'] == 'pending').toList();
          final int pendingCount = pendingRewards.length;

          return Column(
            children: [
              // Display number of pending rewards
              if (pendingCount > 0)
                GestureDetector(
                  // Wrap with GestureDetector
                  onTap: () {
                    // Navigate to Pending Rewards Page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const PendingRewardsPage()), // Use const here
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.red, // Background color for pending count
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Center(
                      child: Text(
                        '$pendingCount prêmios pendentes', // Label with count
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
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
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (rewardsSnapshot.data == null ||
                        rewardsSnapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No rewards found.'));
                    }

                    return ListView(
                      children: rewardsSnapshot.data!.docs
                          .map((DocumentSnapshot document) {
                        Map<String, dynamic> data =
                            document.data() as Map<String, dynamic>;
                        final String rewardId = document.id;
                        final int rewardPoints = data['points'] ?? 0;

                        bool canClaim = userPoints >= rewardPoints;
                        // Check if this reward is in the user's pending rewards
                        bool isPending = pendingRewards
                            .any((item) => item['rewardId'] == rewardId);

                        String buttonText;
                        Color buttonColor;
                        VoidCallback? onPressed;
                        Color? itemStrokeColor;

                        if (isPending) {
                          buttonText = 'Pendente';
                          buttonColor = Colors.orange;
                          onPressed = null;
                          itemStrokeColor = Colors.orange;
                        } else if (canClaim) {
                          buttonText = 'Reivindicar';
                          buttonColor = Colors.red;
                          onPressed = () async {
                            final String? claimCode = await _claimReward(
                                user.uid,
                                rewardId,
                                rewardPoints,
                                context); // Pass rewardPoints and context
                            if (claimCode != null && context.mounted) {
                              _showClaimCodeDialog(context, claimCode);
                            }
                          };
                          itemStrokeColor = null;
                        } else {
                          buttonText = 'Pontos Insuficientes';
                          buttonColor = Colors.grey;
                          onPressed = null;
                          itemStrokeColor = null;
                        }

                        return _buildRewardItem(
                          image: data['imageUrl'] ?? '',
                          title: data['title'] ?? '',
                          points: rewardPoints,
                          buttonText: buttonText,
                          buttonColor: buttonColor,
                          onPressed: onPressed,
                          strokeColor: itemStrokeColor,
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
    required VoidCallback? onPressed,
    Color? strokeColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: strokeColor ?? Colors.grey.shade300,
          width: strokeColor != null ? 2.0 : 1.0,
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
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.image_not_supported,
                              size: 50, color: Colors.grey);
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
                        size: 50, color: Colors.grey),
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
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
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
