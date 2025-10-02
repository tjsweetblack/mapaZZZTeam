 import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

String generateClaimCode(String rewardId, String userId) {
    final random = Random();
    final randomString =
        String.fromCharCodes(List.generate(6, (_) => random.nextInt(33) + 89));
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final base =
        '${rewardId.substring(0, min(4, rewardId.length))}${userId.substring(0, min(4, userId.length))}${timestamp.substring(timestamp.length - min(4, timestamp.length))}$randomString';
    return base.substring(0, min(4, base.length)).toUpperCase();
  }

  Future<String?> claimReward(String userId, String rewardId, int rewardPoints,
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
          final String claimCode = generateClaimCode(rewardId, userId);
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

  void showClaimCodeDialog(BuildContext context, String claimCode) {
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