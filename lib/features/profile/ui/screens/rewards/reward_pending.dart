import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PendingRewardsPage extends StatefulWidget {
  const PendingRewardsPage({Key? key}) : super(key: key);

  @override
  _PendingRewardsPageState createState() => _PendingRewardsPageState();
}

class _PendingRewardsPageState extends State<PendingRewardsPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? _cachedUserData;
  bool _isOffline = false;
  late Future<bool> _connectivityFuture;

  @override
  void initState() {
    super.initState();
    _loadCachedUserData();
    _connectivityFuture = _checkConnectivity();
  }

  // Load cached user data
  Future<void> _loadCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUserDataString = prefs.getString('cached_user_data');
      if (cachedUserDataString != null) {
        setState(() {
          _cachedUserData = json.decode(cachedUserDataString);
        });
      }
    } catch (e) {
      print('Error loading cached user data: $e');
    }
  }

  // Check the Firebase service used by this page. A DNS lookup to Google can
  // fail on valid networks and incorrectly put the page into offline mode.
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
                : 'Nenhum prêmio pendente',
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
                : 'Seus prêmios reivindicados aparecerão aqui',
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
        title: Row(
          children: [
            const Text(
              'Prêmios Pendentes',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            if (_isOffline) ...[
              const SizedBox(width: 8),
              Icon(Icons.cloud_off, color: Colors.orange, size: 20),
            ],
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshConnectivity,
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

          // Update offline status after build completes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _isOffline != !isConnected) {
              setState(() {
                _isOffline = !isConnected;
              });
            }
          });

          if (!isConnected) {
            // Show cached data when offline
            if (_cachedUserData == null) {
              return _buildEmptyState();
            }

            final List<dynamic> userRewardsDynamic =
                _cachedUserData?['rewards'] ?? [];
            List<Map<String, dynamic>> userRewards =
                userRewardsDynamic.whereType<Map<String, dynamic>>().toList();

            final List<Map<String, dynamic>> pendingRewards = userRewards
                .where((item) => item['status'] == 'pending')
                .toList();

            return Column(
              children: [
                _buildOfflineBanner(),
                Expanded(
                  child: pendingRewards.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: pendingRewards.length,
                          itemBuilder: (context, index) {
                            final reward = pendingRewards[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16.0),
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                border:
                                    Border.all(color: Colors.orange, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0, vertical: 4.0),
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                        child: const Text(
                                          'PENDENTE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${reward['points'] ?? 0} pontos',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.0,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12.0),
                                  Text(
                                    reward['title'] ?? 'Prêmio',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  if (reward['claimCode'] != null)
                                    Container(
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                      ),
                                      child: Row(
                                        children: [
                                          const Text(
                                            'Código: ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Expanded(
                                            child: Text(
                                              reward['claimCode'],
                                              style: const TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 16.0,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'Offline - não é possível copiar',
                                            style: TextStyle(
                                              color: Colors.orange[700],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          }

          // Online mode - use StreamBuilder
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user!.uid)
                .snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.hasError) {
                return Center(
                    child:
                        Text('Error loading user data: ${userSnapshot.error}'));
              }

              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final dynamic rawUserData = userSnapshot.data?.data();
              Map<String, dynamic>? userData;
              if (rawUserData != null && rawUserData is Map<String, dynamic>) {
                userData = rawUserData;
              }

              final List<dynamic> userRewardsDynamic =
                  userData?['rewards'] ?? [];
              final List<Map<String, dynamic>> userRewards =
                  userRewardsDynamic.whereType<Map<String, dynamic>>().toList();

              final List<Map<String, dynamic>> pendingRewards = userRewards
                  .where((item) => item['status'] == 'pending')
                  .toList();

              if (pendingRewards.isEmpty) {
                return _buildEmptyState();
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

                      if (!rewardSnapshot.hasData ||
                          !rewardSnapshot.data!.exists) {
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
