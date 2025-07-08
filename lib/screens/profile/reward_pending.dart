import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import for CachedNetworkImage

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

          final dynamic rawUserData = userSnapshot.data?.data();
          Map<String, dynamic>? userData;
          if (rawUserData != null && rawUserData is Map<String, dynamic>) {
            userData = rawUserData;
          }

          final List<dynamic> userRewardsDynamic = userData?['rewards'] ?? [];
          final List<Map<String, dynamic>> userRewards =
              userRewardsDynamic.whereType<Map<String, dynamic>>().toList();

          final List<Map<String, dynamic>> pendingRewards =
              userRewards.where((item) => item['status'] == 'pending').toList();

          if (pendingRewards.isEmpty) {
            return const Center(child: Text('Você não tem prêmios pendentes.'));
          }

          return ListView.builder(
            itemCount: pendingRewards.length,
            itemBuilder: (context, index) {
              final pendingItem = pendingRewards[index];
              final String? rewardId = pendingItem['rewardId'] as String?;
              final String? claimCode = pendingItem['claimCode'] as String?;

              if (rewardId == null || claimCode == null) {
                print(
                    'Warning: Invalid pending item data (missing rewardId or claimCode): $pendingItem');
                return const SizedBox.shrink();
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('reward')
                    .doc(rewardId)
                    .get(),
                builder: (context, rewardSnapshot) {
                  if (rewardSnapshot.hasError) {
                    return Center(
                        child: Text(
                            'Error loading reward details: ${rewardSnapshot.error}'));
                  }

                  if (rewardSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!rewardSnapshot.hasData || !rewardSnapshot.data!.exists) {
                    return const Center(
                        child: Text('Reward details not found.'));
                  }

                  final Map<String, dynamic> rewardDetails =
                      rewardSnapshot.data!.data() as Map<String, dynamic>;

                  final String title =
                      rewardDetails['title'] ?? 'Unknown Reward';
                  final String imageUrl = rewardDetails['imageUrl'] ?? '';

                  return _buildPendingRewardItem(
                    title: title,
                    imageUrl: imageUrl,
                    claimCode: claimCode,
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
        },
      ),
    );
  }

  Widget _buildPendingRewardItem({
    required String title,
    required String imageUrl,
    required String claimCode,
    required VoidCallback onCopy,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.orange, width: 2.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        // Changed from Image.network to CachedNetworkImage
                        imageUrl: imageUrl,
                        placeholder: (context, url) => const Center(
                          // Placeholder for loading
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          // Widget to show on error
                          Icons.image_not_supported,
                          size: 40,
                          color: Colors.grey,
                        ),
                        fit: BoxFit
                            .cover, // Ensures the image fits the container
                      )
                    : const Icon(Icons.card_giftcard,
                        size: 40, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
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
                      'Código: $claimCode',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copiar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
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
