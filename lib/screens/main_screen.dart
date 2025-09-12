import 'dart:async';
import 'package:auth_bloc/api/firebase_api.dart';
import 'package:auth_bloc/l10n/app_localizations.dart';
import 'package:auth_bloc/logic/cubit/auth_cubit.dart';
import 'package:auth_bloc/routing/routes.dart';
import 'package:auth_bloc/screens/google_map.dart';
import 'package:auth_bloc/screens/map_info/map_info.dart';
import 'package:auth_bloc/screens/menu.dart';
import 'package:auth_bloc/screens/rank_info/rank_info.dart';
import 'package:auth_bloc/screens/report/create_report.dart';
import 'package:auth_bloc/screens/report/report_details.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_inappwebview/src/in_app_webview/in_app_webview.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class MapZzzPage extends StatefulWidget {
  @override
  _MapZzzPageState createState() => _MapZzzPageState();
}

class _MapZzzPageState extends State<MapZzzPage> {
  final LatLng belasLuanda = LatLng(-8.9036, 13.2489);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GoogleMapController? _mapController;

  String _riskLevelText =
      'Calculando o nível de risco...'; // Initial loading text
  final FirebaseApi _firebaseApi = FirebaseApi();

  // Add a list to hold risk zones fetched from Firestore
  List<Map<String, dynamic>> _riskZones = [];

  @override
  void initState() {
    super.initState();
    _firebaseApi.initNotifications(); // Call initNotifications here

    // Fetch risk zones and calculate initial risk level after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRiskZonesAndCalculateInitialRisk();
    });
  }

  Future<void> _fetchRiskZonesAndCalculateInitialRisk() async {
    try {
      // Fetch risk zones first
      _riskZones = await _fetchRiskZones();
      print("Fetched ${_riskZones.length} risk zones for initial calculation.");

      // Then get current location and calculate initial risk level
      await _calculateInitialRiskLevel();
    } catch (e) {
      print("Error during initial risk calculation setup: $e");
      // Set a default risk text if fetching or location fails
      if (mounted) {
        _showRiskDialog(
            'Indeterminado',
            'Não foi possível determinar o nível de risco.',
            Icons.help_outline,
            Colors.grey);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRiskZones() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .collection('zones')
              .doc('87XfsZASiHtEwk1GEdO6')
              .get();

      if (documentSnapshot.exists) {
        final data = documentSnapshot.data();
        if (data != null &&
            data.containsKey('zones') &&
            data['zones'] is List) {
          final zones = data['zones'] as List;
          print('Fetched zones data:');
          print(zones);
          return (data['zones'] as List).cast<Map<String, dynamic>>();
        } else {
          print(
              "Error: 'zones' field not found or is not a list in the document.");
          return [];
        }
      } else {
        print(
            "Error: Document '87XfsZASiHtEwk1GEdO6' does not exist in the 'zones' collection.");
        return [];
      }
    } catch (e) {
      print("Error fetching risk zones: $e");
      return [];
    }
  }

  Future<void> _calculateInitialRiskLevel() async {
    print("Calculating initial risk level...");
    try {
      Position position = await _getCurrentLocation();
      int highestRiskLevel = 0; // Initialize risk level to 0 (no risk)

      for (var zone in _riskZones) {
        if (zone.containsKey('latitude') &&
            zone.containsKey('longitude') &&
            zone.containsKey('riskLevel')) {
          final double? zoneLat = zone['latitude'] as double?;
          final double? zoneLon = zone['longitude'] as double?;
          final int? zoneRiskLevel = zone['riskLevel'] as int?;

          if (zoneLat != null && zoneLon != null && zoneRiskLevel != null) {
            double distance = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              zoneLat,
              zoneLon,
            );

            // Check if the user is within 300 meters of this zone
            if (distance <= 300) {
              print(
                  "Initial check: User within 300m of zone with risk level: $zoneRiskLevel");
              // Update highestRiskLevel if the current zone's level is higher
              if (zoneRiskLevel > highestRiskLevel) {
                highestRiskLevel = zoneRiskLevel;
              }
            }
          } else {
            print("Warning: Invalid zone data in _riskZones list.");
          }
        } else {
          print("Warning: Zone data in _riskZones list missing expected keys.");
        }
      }

      // Now highestRiskLevel holds the maximum risk level if within any zone, or 0 if not.
      String initialRiskText;
      switch (highestRiskLevel) {
        case 1:
          initialRiskText = 'Você está numa zona de baixo risco.';
          break;
        case 2:
          initialRiskText = 'Você está numa zona de médio risco.';
          break;
        case 3:
          initialRiskText = 'Você está numa zona de alto risco.';
          break;
        default: // riskLevel is 0
          initialRiskText = 'Você está numa zona sem risco.';
          break;
      }

      if (mounted) {
        // Instead of setting text, show the dialog
        IconData dialogIcon;
        Color dialogColor;
        String dialogTitle;

        switch (highestRiskLevel) {
          case 1:
            dialogTitle = 'Risco Baixo';
            dialogIcon = Icons.shield_outlined;
            dialogColor = Colors.green;
            break;
          case 2:
            dialogTitle = 'Risco Médio';
            dialogIcon = Icons.warning_amber_rounded;
            dialogColor = Colors.orange;
            break;
          case 3:
            dialogTitle = 'Risco Alto';
            dialogIcon = Icons.gpp_bad_rounded;
            dialogColor = Colors.red;
            break;
          default: // riskLevel is 0
            dialogTitle = 'Sem Risco';
            dialogIcon = Icons.check_circle_outline;
            dialogColor = Colors.blue;
            break;
        }
        _showRiskDialog(dialogTitle, initialRiskText, dialogIcon, dialogColor);
      }
      print("Initial risk level text set to: $initialRiskText");
    } catch (e) {
      print("Error calculating initial risk level: $e");
      if (mounted) {
        _showRiskDialog('Erro', 'Erro ao determinar o nível de risco.',
            Icons.error_outline, Colors.black);
      }
    }
  }

  void _updateRiskLevelText(String newText) {
    // This function is now primarily for updates from the MapWidget
    // if it calculates risk level differently or needs to push updates.
    // The initial text is set by _calculateInitialRiskLevel.
    // You might decide if you still need this or if MapWidget should rely
    // on a stream/future provided from here to get risk levels.
    // For now, let's keep it to allow MapWidget to potentially update the text.
    if (mounted) {
      // This function is no longer used to update the UI directly.
      // If you need to show the dialog again on updates, you can call _showRiskDialog here.
    }
  }

  // void _recenterMapToUser() async {
  //   try {
  //     final Position position = await _getCurrentLocation();
  //     _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
  //   } catch (e) {
  //     print("Error recentering map: $e");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //           content: Text(
  //               'Não foi possível obter a localização atual para recentralizar.')),
  //     );
  //   }
  // }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Os serviços de localização estão desativados.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('As permissões de localização foram negadas.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'As permissões de localização foram negadas permanentemente, não podemos solicitar permissões.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy
            .high // Request high accuracy for better proximity checks
        );
  }

  // Function to determine abbreviated rank based on points
  String _getAbbreviatedRank(int points) {
    if (points >= 300) {
      return 'HC';
    } else if (points >= 150) {
      return 'FC';
    } else if (points >= 70) {
      return 'CM';
    } else {
      return 'NV'; // 0 to 69 points
    }
  }

  void _showRiskDialog(
      String title, String message, IconData icon, Color color) {
    showDialog(
      context: context,
      barrierDismissible: true, // User can tap outside to dismiss
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 5,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // To make the dialog compact
              children: <Widget>[
                Icon(icon, color: color, size: 60),
                SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK, Entendi',
                      style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authCubit = context.watch<AuthCubit>();
    final userId = authCubit.currentUser?.uid;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Row(
          children: [
            Text(
              "MapaZZZ",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RankInfoScreen()),
                );
              },
              child: Row(
                children: [
                  Row(
                    children: [
                      Icon(Icons.military_tech, color: Colors.red, size: 18),
                      SizedBox(width: 4),
                      // StreamBuilder for user points and rank
                      StreamBuilder<DocumentSnapshot>(
                        stream: userId != null
                            ? FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .snapshots() // Use snapshots for real-time updates
                            : null,
                        builder: (context, snapshot) {
                          // Default abbreviated rank text
                          String abbreviatedRank = 'NV';
                          int currentPoints = 0;

                          if (snapshot.hasData && snapshot.data!.exists) {
                            final userData =
                                snapshot.data!.data() as Map<String, dynamic>?;
                            currentPoints = userData?['points'] as int? ?? 0;
                            // Determine the abbreviated rank based on points
                            abbreviatedRank =
                                _getAbbreviatedRank(currentPoints);

                            // --- Optional: Add rank update logic here if needed based on stream ---
                            // Note: This could potentially cause frequent writes if points update often.
                            // The previous FutureBuilder logic in ProfileScreen might be sufficient
                            // for saving the rank once on profile load.
                            // If you need real-time rank updates *in the database* from anywhere points change,
                            // you might need a Cloud Function or trigger.
                            // For just displaying the rank in the UI based on the latest points,
                            // calculating it here is fine.
                            // --- End optional rank update logic ---
                          }
                          // Display the abbreviated rank
                          return Text(
                            abbreviatedRank,
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.star_border, color: Colors.grey, size: 18),
                  SizedBox(width: 4),
                  // StreamBuilder for user points (this one only displays points)
                  StreamBuilder<DocumentSnapshot>(
                    stream: userId != null
                        ? FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .snapshots()
                        : null,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final userData =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        final points = userData?['points'] as int? ?? 0;
                        return Text(
                          '$points',
                          style: TextStyle(color: Colors.black, fontSize: 16),
                        );
                      } else {
                        return Text(
                          '0', // Default value if no data or user is not logged in
                          style: TextStyle(color: Colors.black, fontSize: 16),
                        );
                      }
                    },
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.info, color: Colors.red, size: 18),
                ],
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      drawer: buildAppDrawer(context),
      body: Stack(
        children: [
          MapWidget2(),
          // The Positioned widget for the risk level text has been removed.
          Positioned(
            bottom: 200,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () async {
                    // Define the search query
                    const String searchQuery = 'hospitals near me';
                    // Use a standard Google search URL format, ensuring proper encoding
                    final Uri googleMapsUri = Uri.https(
                      'maps.google.com',
                      '/',
                      {'q': searchQuery},
                    );
                    final Uri uriToLaunch =
                        googleMapsUri; // Choose which URI to try

                    print('Attempting to launch URL: $uriToLaunch');

                    try {
                      // Check if the URL can be launched
                      bool canLaunch = await canLaunchUrl(uriToLaunch);
                      print('canLaunchUrl result for $uriToLaunch: $canLaunch');

                      if (canLaunch) {
                        // Launch the URL externally (usually in the default browser)
                        bool launched = await launchUrl(
                          uriToLaunch,
                          mode: LaunchMode
                              .externalApplication, // Try to open outside the app
                        );

                        if (!launched) {
                          print('launchUrl returned false for $uriToLaunch');
                          if (mounted) {
                            // Check if widget is still mounted
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Não foi possível abrir a pesquisa de mapa no navegador.')), // Slightly more specific
                            );
                          }
                        } else {
                          print('Successfully launched URL: $uriToLaunch');
                        }
                      } else {
                        // canLaunchUrl returned false
                        print('System cannot handle URL: $uriToLaunch');
                        if (mounted) {
                          // Check if widget is still mounted
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Não foi possível encontrar uma aplicação para abrir a pesquisa de mapa.')), // More user-friendly message
                          );
                        }
                      }
                    } catch (e) {
                      // Catch any exceptions during canLaunchUrl or launchUrl
                      print("Error launching URL ($uriToLaunch): $e");
                      if (mounted) {
                        // Check if widget is still mounted
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Ocorreu um erro ao tentar abrir a pesquisa de mapa: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.local_hospital, color: Colors.red),
                  ),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final Uri phoneUri = Uri(scheme: 'tel', path: '111');
                    if (await canLaunchUrl(phoneUri)) {
                      await launchUrl(phoneUri);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Não foi possível iniciar a chamada.')),
                      );
                    }
                  },
                  child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.call, color: Colors.red)),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    Navigator.push(
                      // Changed to push to allow back navigation
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapExplanationPage(),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.info_outline, color: Colors.red),
                  ),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  // Wrap with GestureDetector
                  onTap: () {
                    Navigator.pushReplacement(
                      // Changed to push to allow back navigation
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateReportCameraScreen(),
                      ),
                    );
                  },
                  child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.camera_alt, color: Colors.red)),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16, // Distance from the bottom of the screen
            left: 16, // Distance from the left side of the screen
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapExplanationPage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8.0), // Add padding for tap area
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3), // Slight background
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 28, // Adjusted size slightly
                ),
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.2,
            minChildSize: 0.2,
            maxChildSize: 0.9,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "reportagens",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Expanded(
                      child: ReportList(scrollController: scrollController),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ReportList extends StatefulWidget {
  final ScrollController scrollController;

  ReportList({required this.scrollController});

  @override
  _ReportListState createState() => _ReportListState();
}

class _ReportListState extends State<ReportList> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading =
      true; // To show a loading indicator, changed to true initially
  static List<Map<String, dynamic>> _cachedReports =
      []; // Static cache variable

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    if (_cachedReports.isNotEmpty) {
      // If data is in the cache, use it immediately
      setState(() {
        _reports = _cachedReports;
        _isLoading = false; //set to false here
      });
      return; // Exit the function to avoid unnecessary Firestore call
    }

    try {
      FirebaseFirestore.instance
          .collection('reports')
          .where('status',
              isEqualTo:
                  'active') // Filter reports where status is equal to 'active'
          .snapshots()
          .listen((snapshot) {
        List<Map<String, dynamic>> fetchedReports = [];
        for (final doc in snapshot.docs) {
          fetchedReports.add(doc.data() as Map<String, dynamic>);
        }
        setState(() {
          _reports = fetchedReports;
          _cachedReports = fetchedReports; // Store fetched reports in cache
          _isLoading = false;
        });
      });
    } catch (e) {
      print("Error fetching reports: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildRiskLevelIcons(int riskLevel) {
    Icon levelIcon =
        Icon(Icons.signal_cellular_alt_1_bar_sharp, color: Colors.red);
    if (riskLevel == 1) {
      levelIcon =
          Icon(Icons.signal_cellular_alt_1_bar_sharp, color: Colors.red);
    } else if (riskLevel == 2) {
      levelIcon =
          Icon(Icons.signal_cellular_alt_2_bar_sharp, color: Colors.red);
    } else if (riskLevel == 3) {
      levelIcon = Icon(Icons.signal_cellular_alt_sharp, color: Colors.red);
    } else if (riskLevel == 4) {
      levelIcon = Icon(Icons.signal_cellular_alt, color: Colors.red);
    }

    return levelIcon;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_reports.isEmpty) {
      return const Center(
          child: Text(
              'Nenhuma reportagem ativa encontrada.')); //show no active reports
    }

    return ListView.builder(
      controller: widget.scrollController,
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportDetailPage(report: report),
                ),
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: SizedBox(
                    // Use SizedBox to give CachedNetworkImage explicit dimensions
                    width: 50.0,
                    height: 50.0,
                    child: CachedNetworkImage(
                      // Changed to CachedNetworkImage
                      imageUrl: report['imageUrl'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        // Placeholder for loading
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        // Widget to show on error
                        Icons.error_outline,
                        size:
                            50, // Match the size of the SizedBox for consistent layout
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report['title'],
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report['location'],
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: _buildRiskLevelIcons(report['riskLevel'] as int),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
