import 'package:auth_bloc/api/firebase_api.dart';
import 'package:auth_bloc/logic/cubit/auth_cubit.dart';
import 'package:auth_bloc/routing/routes.dart';
import 'package:auth_bloc/screens/menu.dart';
import 'package:auth_bloc/screens/rank_info/rank_info.dart';
import 'package:auth_bloc/screens/report/create_report.dart';
import 'package:auth_bloc/screens/report/report_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart'; // Import webview_flutter

class MapZzzPage extends StatefulWidget {
  @override
  _MapZzzPageState createState() => _MapZzzPageState();
}

class _MapZzzPageState extends State<MapZzzPage> {
  final LatLng belasLuanda = LatLng(-8.9036, 13.2489);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  MapController _mapController = MapController();
  String _riskLevelText =
      'A calcular o nível de risco...'; // Initial loading text
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
        setState(() {
          _riskLevelText = 'Não foi possível determinar o nível de risco.';
        });
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
          initialRiskText = 'Estas em uma zona de baixo risco.';
          break;
        case 2:
          initialRiskText = 'Estas em uma zona de médio risco.';
          break;
        case 3:
          initialRiskText = 'Estas em uma zona de alto risco.';
          break;
        default: // riskLevel is 0
          initialRiskText = 'Estas em zona sem risco.';
          break;
      }

      if (mounted) {
        setState(() {
          _riskLevelText = initialRiskText;
        });
      }
      print("Initial risk level text set to: $_riskLevelText");
    } catch (e) {
      print("Error calculating initial risk level: $e");
      if (mounted) {
        setState(() {
          _riskLevelText = 'Erro ao determinar o nível de risco.';
        });
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
      setState(() {
        _riskLevelText = newText;
      });
    }
  }

  void _recenterMapToUser() async {
    try {
      final Position position = await _getCurrentLocation();
      _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
    } catch (e) {
      print("Error recentering map: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not get current location to recenter.')),
      );
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
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
              'MapaZZZ',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Row(
              children: [
                // Make the Rank and CM/Abbreviation clickable
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
              ],
            ),
          ],
        ),
        elevation: 0,
      ),
      drawer: buildAppDrawer(context),
      body: Stack(
        children: [
          MapWidget(
            mapController: _mapController,
            onRiskLevelChanged:
                _updateRiskLevelText, // Keep this to allow MapWidget to potentially update
          ),
          Positioned(
            top: 16,
            left: 32, // Adjust this value for desired margin
            right: 32, // Adjust this value to be the same as left for centering
            child: Center(
              // Wrap the Container with a Center widget
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _riskLevelText, // Display the state variable
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () async {
                    // Made onTap async
                    // Use a proper URL for Google Maps search
                    final String searchTerms =
                        'hospitals near me'; // Example search terms
                    // Construct a standard Google Maps web search URL
                    // Using the standard format for web-based Google Maps search
                    // Note: Using maps.google.com/search?q=... is another common format
                    final Uri googleMapsUri = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(searchTerms)}');

                    print(
                        'Opening Google Maps search in external browser: $googleMapsUri');

                    // Use url_launcher to open the URL in the external application (default browser)
                    if (await canLaunchUrl(googleMapsUri)) {
                      launchUrl(googleMapsUri,
                              mode: LaunchMode.externalApplication)
                          .catchError((e) {
                        print("Error launching Google Maps: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Could not open hospitals search in map.')),
                        );
                      });
                    } else {
                      print("Could not launch URL: $googleMapsUri");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Could not launch hospitals search URL.')),
                      );
                    }

                    // Commented out the WebView navigation
                    //  Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) =>
                    //         HospitalWebViewScreen(googleMapsUrl: googleMapsWebUrl),
                    //   ),
                    // );
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
                            content: Text('Could not launch phone.')),
                      );
                    }
                  },
                  child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.call, color: Colors.red)),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: _recenterMapToUser, // Call the recenter function
                  child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.my_location, color: Colors.red)),
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
                      'Reportagems',
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
      return Center(
          child: Text('No active reports found.')); //show no active reports
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
                  child: Image.network(
                    report['imageUrl'],
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return SizedBox(
                        width: 50,
                        height: 50,
                        child: Icon(Icons.error_outline),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report['title'],
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
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

// Import the package

class HospitalWebViewScreen extends StatefulWidget {
  final String googleMapsUrl;

  const HospitalWebViewScreen({Key? key, required this.googleMapsUrl})
      : super(key: key);

  @override
  _HospitalWebViewScreenState createState() => _HospitalWebViewScreenState();
}

class _HospitalWebViewScreenState extends State<HospitalWebViewScreen> {
  late InAppWebViewController _webViewController;
  double _progress = 0; // To track loading progress

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospitais Próximos'), // Title for the WebView screen
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black), // Back arrow color
        // You might want to add navigation controls here later (e.g., forward/back buttons)
      ),
      body: Stack(
        // Use Stack to layer the WebView and the progress bar
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
                url: WebUri(widget.googleMapsUrl)), // Load the provided URL
            // Use InAppWebViewSettings instead of InAppWebViewGroupOptions and InAppWebViewOptions
            initialSettings: InAppWebViewSettings(
              javaScriptCanOpenWindowsAutomatically: true,
              javaScriptEnabled: true,
              // useHybridComposition is removed in newer versions
              // useHybridComposition: true, // Recommended for better performance (Removed)

              // Android specific settings (if needed, check latest docs for parameter names)
              // android: AndroidInAppWebViewOptions( // This structure is also likely changed
              //   useHybridComposition: true, // Removed
              // ),

              // iOS specific settings (if needed, check latest docs for parameter names)
              allowsInlineMediaPlayback:
                  true, // This might be a cross-platform setting now
              // ios: IOSInAppWebViewOptions( // This structure is also likely changed
              //   allowsInlineMediaPlayback: true, // Handled above
              // ),

              // You can add other settings here as needed, e.g.:
              // supportZoom: true,
              // builtInZoomControls: true,
              // displayZoomControls: false,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onProgressChanged: (controller, progress) {
              // Update the loading progress
              if (mounted) {
                setState(() {
                  _progress = progress / 100;
                });
              }
            },
            onLoadError: (controller, url, code, message) {
              print("Error loading $url: $code, $message");
              // Optionally show an error message to the user
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to load page: $message')),
              );
            },
            onLoadHttpError: (controller, url, statusCode, description) {
              print("HTTP Error loading $url: $statusCode, $description");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('HTTP Error loading page: $statusCode')),
              );
            },
            // Add other callbacks as needed (e.g., onLoadStart, onLoadStop)
          ),
          // Show a linear progress indicator while loading
          if (_progress < 1.0)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.red), // Use your app's theme color
            ),
        ],
      ),
    );
  }
}

// Make sure ReportDetailPage is defined or imported elsewhere
// import 'path/to/report_detail_page.dart'; // Example import

// Import the report details page.  Make sure this import is correct.
// import 'report_details.dart';  //<-- Correct the import if needed.

class MapWidget extends StatefulWidget {
  final MapController mapController;
  final Function(String) onRiskLevelChanged;

  const MapWidget(
      {Key? key, required this.mapController, required this.onRiskLevelChanged})
      : super(key: key);

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  LatLng? _currentLocation;
  bool _locationFetched = false;
  bool _initialLoadDone = false;
  List<CircleMarker> _currentHeatmapCircles = [];
  String _riskLevelText = 'Estas em zona sem risco .';

  @override
  void initState() {
    super.initState();
    _getCurrentUserLocation();
  }

  Future<void> _getCurrentUserLocation() async {
    try {
      final Position position = await _getCurrentLocation();
      print(
          "Fetched Location: Latitude: ${position.latitude}, Longitude: ${position.longitude}");
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _locationFetched = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_currentLocation != null) {
          widget.mapController.move(_currentLocation!, 15.0);
        }
      });
      print('this is it No error:');
    } catch (e) {
      print('this is it error:');
      print("Error getting location: $e");
      setState(() {
        _currentLocation = LatLng(-8.913499751058776, 13.18721354420165);
        _locationFetched = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_currentLocation != null) {
          widget.mapController.move(_currentLocation!, 13.0);
        }
      });
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  final double heatmapRadiusKm = 0.3;

  Widget _greyScaleTileBuilder(
    BuildContext context,
    Widget tileWidget,
    TileImage tile,
  ) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.15,
        0.50,
        0.05,
        0,
        0,
        0.15,
        0.50,
        0.05,
        0,
        0,
        0.15,
        0.50,
        0.05,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: tileWidget,
    );
  }

  Future<void> _saveNewZones(List<CircleMarker> circles) async {
    final riskCircles = circles.where((circle) {
      final opacity = circle.color.opacity;
      return opacity >= 0.2 && opacity <= 0.9;
    }).toList();

    if (riskCircles.isEmpty) {
      print("No risk level circles to process for saving.");
      return;
    }

    try {
      final zonesDocRef = FirebaseFirestore.instance
          .collection('zones')
          .doc('87XfsZASiHtEwk1GEdO6');

      final docSnapshot = await zonesDocRef.get();

      List<Map<String, dynamic>> existingZones = [];
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data['zones'] is List) {
          existingZones = (data['zones'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .toList();
        }
      }

      List<Map<String, dynamic>> updatedZonesList = List.from(existingZones);
      bool changesMade = false;

      final Set<String> processedCoords = {};

      for (final circle in riskCircles) {
        final double currentLat = circle.point.latitude;
        final double currentLon = circle.point.longitude;

        final String coordKey = '${currentLat}_${currentLon}';

        if (processedCoords.contains(coordKey)) {
          continue;
        }
        processedCoords.add(coordKey);

        int? currentRiskLevel;
        final double opacity = circle.color.opacity;

        if (opacity >= 0.8) {
          currentRiskLevel = 3;
        } else if (opacity >= 0.5) {
          currentRiskLevel = 2;
        } else if (opacity >= 0.2) {
          currentRiskLevel = 1;
        }

        if (currentRiskLevel == null) {
          print(
              "Warning: Circle with unexpected opacity (${opacity}) processed.");
          continue;
        }

        bool foundExistingMatch = false;
        for (int i = 0; i < updatedZonesList.length; i++) {
          final existingZone = updatedZonesList[i];
          final existingLat = existingZone['latitude'] as double?;
          final existingLon = existingZone['longitude'] as double?;
          final existingRiskLevel = existingZone['riskLevel'];

          if (existingLat != null &&
              existingLon != null &&
              existingLat == currentLat &&
              existingLon == currentLon) {
            foundExistingMatch = true;

            if (existingRiskLevel == null) {
              updatedZonesList[i]['riskLevel'] = currentRiskLevel;
              changesMade = true;
              print(
                  'Updated existing zone: $currentLat, $currentLon with risk level $currentRiskLevel');
            }
            break;
          }
        }

        if (!foundExistingMatch) {
          final newZoneEntry = {
            'latitude': currentLat,
            'longitude': currentLon,
            'riskLevel': currentRiskLevel,
          };
          updatedZonesList.add(newZoneEntry);
          changesMade = true;
          print(
              'Added new zone: $currentLat, $currentLon with risk level $currentRiskLevel');
        }
      }

      if (changesMade) {
        print('Saving updated zones list to Firestore...');
        await zonesDocRef.set({'zones': updatedZonesList});
        print('Zones list saved successfully.');
      } else {
        print('No new zones added or existing zones updated with risk level.');
      }
    } catch (e) {
      print("Error saving or updating zones in Firestore: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return _locationFetched && _currentLocation != null
        ? FlutterMap(
            key: UniqueKey(),
            mapController: widget.mapController,
            options: MapOptions(
              initialCenter: _currentLocation!,
              initialZoom: 40.0,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                cursorKeyboardRotationOptions:
                    const CursorKeyboardRotationOptions(),
                keyboardOptions: const KeyboardOptions(),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
                tileBuilder: _greyScaleTileBuilder,
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reports')
                    .where('status', isEqualTo: 'active')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Stack(
                      children: [
                        CircleLayer(circles: _currentHeatmapCircles),
                        MarkerLayer(markers: []),
                        const Center(child: CircularProgressIndicator()),
                      ],
                    );
                  }

                  if (snapshot.hasError) {
                    print("Error fetching reports: ${snapshot.error}");
                    return const Center(child: Text('Error loading reports'));
                  }

                  final reports = snapshot.data!.docs
                      .map((doc) => doc.data() as Map<String, dynamic>)
                      .toList();
                  final reportMarkers = <Marker>[];
                  final heatmapCircles = <CircleMarker>[];
                  final processedReports = <Map<String, dynamic>>[];
                  final double heatmapRadiusMeters = heatmapRadiusKm * 1000;
                  String currentRiskLevelText = 'Estas em zona sem risco .';

                  for (final report in reports) {
                    final latitude = report['latitude'] as double?;
                    final longitude = report['longitude'] as double?;

                    if (latitude != null && longitude != null) {
                      reportMarkers.add(
                        Marker(
                          point: LatLng(latitude, longitude),
                          width: 20,
                          height: 20,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ReportDetailPage(report: report),
                                ),
                              );
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  }

                  for (final report1 in reports) {
                    if (processedReports.any((pReport) =>
                        pReport['latitude'] == report1['latitude'] &&
                        pReport['longitude'] == report1['longitude'])) {
                      continue;
                    }

                    final lat1 = report1['latitude'] as double?;
                    final lon1 = report1['longitude'] as double?;

                    if (lat1 != null && lon1 != null) {
                      List<Map<String, dynamic>> reportsInRadius = [];
                      for (final report2 in reports) {
                        final lat2 = report2['latitude'] as double?;
                        final lon2 = report2['longitude'] as double?;

                        if (lat2 != null && lon2 != null) {
                          final distance = const Distance()
                              .distance(LatLng(lat1, lon1), LatLng(lat2, lon2));
                          if (distance <= heatmapRadiusMeters) {
                            reportsInRadius.add(report2);
                          }
                        }
                      }

                      if (reportsInRadius.length >= 3) {
                        double opacity = 0.0;
                        if (reportsInRadius.length >= 3 &&
                            reportsInRadius.length < 6) {
                          opacity = 0.3;
                        } else if (reportsInRadius.length >= 6 &&
                            reportsInRadius.length < 9) {
                          opacity = 0.6;
                        } else if (reportsInRadius.length >= 9) {
                          opacity = 0.9;
                        }

                        double sumLat = 0;
                        double sumLon = 0;
                        int count = 0;
                        for (final r in reportsInRadius) {
                          final rLat = r['latitude'] as double?;
                          final rLon = r['longitude'] as double?;

                          if (rLat != null && rLon != null) {
                            sumLat += rLat;
                            sumLon += rLon;
                            count++;
                          }
                        }
                        final centerLat = count > 0 ? sumLat / count : lat1;
                        final centerLon = count > 0 ? sumLon / count : lon1;

                        final clusterCenter = LatLng(centerLat, centerLon);

                        heatmapCircles.add(
                          CircleMarker(
                            point: clusterCenter,
                            radius: heatmapRadiusMeters,
                            useRadiusInMeter: true,
                            color: Colors.red.withOpacity(opacity),
                          ),
                        );

                        processedReports.addAll(reportsInRadius);
                      }
                    }
                  }

                  _saveNewZones(heatmapCircles);

                  if (!_initialLoadDone && _currentLocation != null) {
                    for (final circle in heatmapCircles) {
                      final distanceToCircleCenter = const Distance().distance(
                        _currentLocation!,
                        circle.point,
                      );
                      if (distanceToCircleCenter <= circle.radius) {
                        if (circle.color.opacity == 0.3) {
                          currentRiskLevelText =
                              'Estas em zona de baixo risco .';
                          break;
                        } else if (circle.color.opacity == 0.6) {
                          currentRiskLevelText =
                              'Estas em zona de medio risco .';
                          break;
                        } else if (circle.color.opacity == 0.9) {
                          currentRiskLevelText =
                              'Estas em zona de alto risco .';
                          break;
                        }
                      }
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      widget.onRiskLevelChanged(currentRiskLevelText);
                      setState(() {
                        _initialLoadDone = true;
                      });
                    });
                  }

                  _currentHeatmapCircles = heatmapCircles;

                  return Stack(
                    children: [
                      CircleLayer(circles: heatmapCircles),
                      MarkerLayer(markers: reportMarkers),
                      MarkerLayer(
                        markers: [
                          if (_currentLocation != null)
                            Marker(
                              width: 120.0,
                              height: 60.0,
                              point: _currentLocation!,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // Location pin
                                  const Icon(
                                    Icons.location_pin,
                                    color: Colors.blue,
                                    size: 40.0,
                                  ),
                                  // Image bubble replaced with a Container
                                  Positioned(
                                    top: -30, // Adjusted to bring it closer
                                    left: -30,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            spreadRadius: 2,
                                            blurRadius: 5,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0, vertical: 4.0),
                                      child: const Text(
                                        "voçe esta aqui!",
                                        style: TextStyle(
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors
                                              .red, // Set text color to red
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          )
        : const Center(child: CircularProgressIndicator());
  }
}
