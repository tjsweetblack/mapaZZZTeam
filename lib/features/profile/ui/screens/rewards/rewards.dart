import 'package:auth_bloc/features/profile/ui/screens/rewards/logic.dart';
import 'package:auth_bloc/features/profile/ui/screens/rewards/widget/buildReward.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:auth_bloc/features/profile/ui/screens/rewards/reward_pending.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  List<Map<String, dynamic>> _cachedRewards = [];
  Map<String, dynamic>? _cachedUserData;
  bool _isOffline = false;
  late Future<bool> _connectivityFuture;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    _connectivityFuture = _checkConnectivity();
  }

  // Load cached data from SharedPreferences
  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load cached rewards
      final cachedRewardsData = prefs.getString('cached_rewards');
      if (cachedRewardsData != null) {
        final List<dynamic> rewardsList = json.decode(cachedRewardsData);
        setState(() {
          _cachedRewards = rewardsList.cast<Map<String, dynamic>>();
        });
      }

      // Load cached user data
      final cachedUserDataString = prefs.getString('cached_user_data');
      if (cachedUserDataString != null) {
        setState(() {
          _cachedUserData = json.decode(cachedUserDataString);
        });
      }
    } catch (e) {
      print('Error loading cached data: $e');
    }
  }

  // Save rewards to cache
  Future<void> _saveRewardsToCache(List<Map<String, dynamic>> rewards) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_rewards', json.encode(rewards));
    } catch (e) {
      print('Error saving rewards to cache: $e');
    }
  }

  // Save user data to cache
  Future<void> _saveUserDataToCache(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user_data', json.encode(userData));
    } catch (e) {
      print('Error saving user data to cache: $e');
    }
  }

  // Verify the Firebase service used by this page instead of relying on DNS
  // resolution for Google, which can be blocked even when Firestore is usable.
  Future<bool> _checkConnectivity() async {
    // Browsers block direct HTTP probes to this endpoint through CORS. The
    // Firestore stream below is the authoritative connection check on web.
    if (kIsWeb) return true;

    try {
      await http
          .head(Uri.parse('https://firestore.googleapis.com/'))
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _refreshConnectivity() async {
    final future = _checkConnectivity();
    setState(() {
      _connectivityFuture = future;
    });

    final hasConnection = await future;
    if (mounted) {
      setState(() {
        _isOffline = !hasConnection;
      });
    }
  }

  Widget _buildOfflineBanner() {
    if (!_isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: Colors.orange[100],
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: Colors.orange[700], size: 16),
          const SizedBox(width: 8),
          Text(
            'Modo offline - dados em cache',
            style: TextStyle(
              color: Colors.orange[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isOffline ? Icons.wifi_off : Icons.card_giftcard_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _isOffline
                ? 'Sem conexão com a internet'
                : 'Nenhum prêmio disponível',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isOffline
                ? 'Verifique sua conexão e tente novamente'
                : 'Volte mais tarde para novos prêmios',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCachedRewardsList(Map<String, dynamic> userData) {
    final int userPoints = userData['points'] as int? ?? 0;
    final List<dynamic> userRewardsDynamic = userData['rewards'] ?? [];
    List<Map<String, dynamic>> userRewards =
        userRewardsDynamic.whereType<Map<String, dynamic>>().toList();

    // Filter pending rewards
    final List<Map<String, dynamic>> pendingRewards =
        userRewards.where((item) => item['status'] == 'pending').toList();
    final int pendingCount = pendingRewards.length;

    return Column(
      children: [
        _buildOfflineBanner(),
        // Display number of pending rewards
        if (pendingCount > 0)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PendingRewardsPage()),
              );
            },
            child: Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                child: Text(
                  '$pendingCount prêmios pendentes',
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
          child: _cachedRewards.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _cachedRewards.length,
                  itemBuilder: (context, index) {
                    final data = _cachedRewards[index];
                    final int rewardPoints = data['points'] ?? 0;

                    bool canClaim = userPoints >= rewardPoints;
                    bool isPending = pendingRewards
                        .any((item) => item['rewardId'] == data['id']);

                    String buttonText;
                    Color buttonColor;
                    VoidCallback? onPressed;
                    Color? itemStrokeColor;

                    if (isPending) {
                      buttonText = 'Pendente';
                      buttonColor = Colors.orange;
                      onPressed = null;
                      itemStrokeColor = Colors.orange;
                    } else if (canClaim && !_isOffline) {
                      buttonText = 'Reivindicar';
                      buttonColor = Colors.red;
                      onPressed = () async {
                        final String? claimCode = await claimReward(
                            FirebaseAuth.instance.currentUser!.uid,
                            data['id'],
                            rewardPoints,
                            context);
                        if (claimCode != null && context.mounted) {
                          showClaimCodeDialog(context, claimCode);
                        }
                      };
                      itemStrokeColor = null;
                    } else {
                      buttonText =
                          _isOffline ? 'Offline' : 'Pontos Insuficientes';
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
                  },
                ),
        ),
      ],
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
        title: Row(
          children: [
            const Text('Prêmios', style: TextStyle(color: Colors.black)),
            if (_isOffline) ...[
              const SizedBox(width: 8),
              Icon(Icons.cloud_off, color: Colors.orange, size: 20),
              const SizedBox(width: 4),
              Text(
                'Offline',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          FutureBuilder<bool>(
            future: _connectivityFuture,
            builder: (context, connectivitySnapshot) {
              final isConnected = connectivitySnapshot.data ?? false;
              final userData = _isOffline ? _cachedUserData : null;
              final int displayPoints = userData?['points'] as int? ?? 0;

              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _refreshConnectivity,
                    ),
                    const Icon(Icons.star_outline, color: Colors.red),
                    const SizedBox(width: 4),
                    if (isConnected)
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError || !snapshot.hasData) {
                            return Text(
                              displayPoints.toString(),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            );
                          }

                          final dynamic rawUserData = snapshot.data?.data();
                          Map<String, dynamic>? userData;
                          if (rawUserData != null &&
                              rawUserData is Map<String, dynamic>) {
                            userData = rawUserData;
                            _saveUserDataToCache(userData); // Cache user data
                          }

                          final int userPoints =
                              userData?['points'] as int? ?? 0;

                          return Text(
                            userPoints.toString(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                            ),
                          );
                        },
                      )
                    else
                      Text(
                        displayPoints.toString(),
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
      body: FutureBuilder<bool>(
        future: _connectivityFuture,
        builder: (context, connectivitySnapshot) {
          if (connectivitySnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.red),
            );
          }

          final isConnected = connectivitySnapshot.data ?? false;

          // Update offline state after build completes
          if (_isOffline != !isConnected) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isOffline = !isConnected;
                });
              }
            });
          }

          if (!isConnected) {
            // Show cached data when offline
            if (_cachedUserData == null) {
              return _buildEmptyState();
            }
            return _buildCachedRewardsList(_cachedUserData!);
          }

          // Online - use StreamBuilder
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.hasError) {
                return Center(
                    child:
                        Text('Error loading user data: ${userSnapshot.error}'));
              }

              final dynamic rawUserData = userSnapshot.data?.data();
              Map<String, dynamic>? userData;
              if (rawUserData != null && rawUserData is Map<String, dynamic>) {
                userData = rawUserData;
                _saveUserDataToCache(userData); // Cache user data
              }

              final int userPoints = userData?['points'] as int? ?? 0;
              final List<dynamic> userRewardsDynamic =
                  userData?['rewards'] ?? [];
              List<Map<String, dynamic>> userRewards =
                  userRewardsDynamic.whereType<Map<String, dynamic>>().toList();

              // Filter pending rewards
              final List<Map<String, dynamic>> pendingRewards = userRewards
                  .where((item) => item['status'] == 'pending')
                  .toList();
              final int pendingCount = pendingRewards.length;

              return Column(
                children: [
                  // Display number of pending rewards
                  if (pendingCount > 0)
                    GestureDetector(
                      onTap: () {
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
                            '$pendingCount prêmios pendentes',
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
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (rewardsSnapshot.data == null ||
                            rewardsSnapshot.data!.docs.isEmpty) {
                          return _buildEmptyState();
                        }

                        // Cache rewards data
                        final rewardsToCache =
                            rewardsSnapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          data['id'] = doc.id; // Add document ID
                          return data;
                        }).toList();
                        _saveRewardsToCache(rewardsToCache);

                        return ListView(
                          children: rewardsSnapshot.data!.docs
                              .map((DocumentSnapshot document) {
                            Map<String, dynamic> data =
                                document.data() as Map<String, dynamic>;
                            final String rewardId = document.id;
                            final int rewardPoints = data['points'] ?? 0;

                            bool canClaim = userPoints >= rewardPoints;
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
                                    user.uid, rewardId, rewardPoints, context);
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
          );
        },
      ),
    );
  }
}
