import 'package:auth_bloc/screens/profile/rewards/logic.dart';
import 'package:auth_bloc/screens/profile/rewards/widget/buildReward.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart'; // Import cached_network_image
import 'package:auth_bloc/screens/profile/rewards/reward_pending.dart'; // Import the PendingRewardsPage

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

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
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError || !snapshot.hasData) {
                return const SizedBox(); // Return an empty widget if there's an error or no data
              }

              final dynamic rawUserData = snapshot.data?.data();
              Map<String, dynamic>? userData;
              if (rawUserData != null && rawUserData is Map<String, dynamic>) {
                userData = rawUserData;
              }

              final int userPoints = userData?['points'] as int? ?? 0;

              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_outline, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      userPoints.toString(),
                      style: const TextStyle(
                        color: Colors.black,
                        
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
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
                            final String? claimCode = await claimReward(
                                user.uid,
                                rewardId,
                                rewardPoints,
                                context); // Pass rewardPoints and context
                            if (claimCode != null && context.mounted) {
                              showClaimCodeDialog(context, claimCode);
                            }
                          };
                          itemStrokeColor = null;
                        } else {
                          buttonText = 'Pontos Insuficientes';
                          buttonColor = Colors.grey;
                          onPressed = null;
                          itemStrokeColor = null;
                        }

                        return buildRewardItem(
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
}
