import 'package:auth_bloc/logic/cubit/auth_cubit.dart';
import 'package:auth_bloc/routing/routes.dart';
import 'package:auth_bloc/screens/menu.dart';
import 'package:auth_bloc/screens/report/create_report.dart';
import 'package:auth_bloc/screens/report/report_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator
import 'package:latlong2/latlong.dart';
import 'package:webview_flutter/webview_flutter.dart'; // Import webview_flutter

void main() {
  runApp(
    BlocProvider(
      create: (context) => AuthCubit(), // Provide your AuthCubit
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MapZzz App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MapZzzPage(),
    );
  }
}

class MapZzzPage extends StatefulWidget {
  @override
  _MapZzzPageState createState() => _MapZzzPageState();
}

class _MapZzzPageState extends State<MapZzzPage> {
  final LatLng belasLuanda = LatLng(-8.9036, 13.2489);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  MapController _mapController =
      MapController(); // Create a MapController instance

  void _recenterMapToUser() async {
    final Position position = await _getCurrentLocation();
    _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
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

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    final authCubit = context.watch<AuthCubit>();
    final userId = authCubit.currentUser?.uid; // Get the current user's ID

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
                Icon(Icons.location_on, color: Colors.red, size: 18),
                SizedBox(width: 4),
                Text(
                  'CM',
                  style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.star_border, color: Colors.grey, size: 18),
                SizedBox(width: 4),
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
          MapWidget(mapController: _mapController), // Pass the MapController
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Estas em zona de baixo risco .',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
                  onTap: () {
                    final String searchTerms =
                        'hospitals near Belas, Luanda Province, Angola';
                    final String googleMapsUrl =
                        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(searchTerms)}';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            HospitalWebViewScreen(googleMapsUrl: googleMapsUrl),
                      ),
                    );
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Phone call functionality not implemented in this version.')),
                    );
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
                      child: Icon(Icons.location_pin, color: Colors.red)),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  // Wrap with GestureDetector
                  onTap: () {
                    Navigator.pushReplacement(
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
  bool _isLoading = true; // To show a loading indicator

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    try {
      FirebaseFirestore.instance
          .collection('reports')
          .snapshots()
          .listen((snapshot) {
        List<Map<String, dynamic>> fetchedReports = [];
        for (final doc in snapshot.docs) {
          fetchedReports.add(doc.data() as Map<String, dynamic>);
        }
        setState(() {
          _reports = fetchedReports;
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
      return Center(child: Text('No reports found.'));
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

class HospitalWebViewScreen extends StatefulWidget {
  final String googleMapsUrl;

  const HospitalWebViewScreen({super.key, required this.googleMapsUrl});

  @override
  State<HospitalWebViewScreen> createState() => _HospitalWebViewScreenState();
}

class _HospitalWebViewScreenState extends State<HospitalWebViewScreen> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.googleMapsUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospitals Near You'),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}

class MapWidget extends StatefulWidget {
  final MapController mapController;

  const MapWidget({Key? key, required this.mapController}) : super(key: key);

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  LatLng? _currentLocation;
  bool _locationFetched = false;

  @override
  void initState() {
    super.initState();
    _getCurrentUserLocation();
  }

  Future<void> _getCurrentUserLocation() async {
    try {
      final Position position = await _getCurrentLocation();
      print(
          "Fetched Location: Latitude: ${position.latitude}, Longitude: ${position.longitude}"); // Log the fetched location
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _locationFetched = true;
      });
      widget.mapController.move(_currentLocation!, 15.0); // Initial zoom
    } catch (e) {
      print("Error getting location: $e");
      // Handle error appropriately, maybe show a default location
      setState(() {
        _currentLocation =
            LatLng(-8.9036, 13.2489); // Default to Belas if location fails
        _locationFetched = true;
      });
      widget.mapController.move(_currentLocation!, 13.0);
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

    return await Geolocator.getCurrentPosition();
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

  @override
  Widget build(BuildContext context) {
    return _locationFetched && _currentLocation != null
        ? FlutterMap(
            key: UniqueKey(),
            mapController: widget.mapController,
            options: MapOptions(
              initialCenter: _currentLocation!, // Use the fetched location
              initialZoom: 15.0, // Increased initial zoom
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all,
                cursorKeyboardRotationOptions:
                    const CursorKeyboardRotationOptions(),
                keyboardOptions: const KeyboardOptions(),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
                tileBuilder: _greyScaleTileBuilder,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point:
                        _currentLocation!, // Use the fetched location for the marker
                    width: 30,
                    height: 30,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reports')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final reports = snapshot.data!.docs
                      .map((doc) => doc.data() as Map<String, dynamic>)
                      .toList();
                  final reportMarkers = <Marker>[];
                  final heatmapCircles = <CircleMarker>[];
                  final processedReports = <Map<String, dynamic>>[];
                  final double heatmapRadiusMeters = heatmapRadiusKm * 1000;

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
                              decoration: BoxDecoration(
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
                    if (processedReports.contains(report1)) {
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
                        final centerLat = count > 0 ? sumLat / count : 0.0;
                        final centerLon = count > 0 ? sumLon / count : 0.0;

                        heatmapCircles.add(
                          CircleMarker(
                            point: LatLng(centerLat, centerLon),
                            radius: heatmapRadiusMeters,
                            useRadiusInMeter: true,
                            color: Colors.red.withOpacity(opacity),
                          ),
                        );

                        processedReports.addAll(reportsInRadius);
                      }
                    }
                  }

                  return Stack(
                    children: [
                      CircleLayer(circles: heatmapCircles),
                      MarkerLayer(markers: reportMarkers),
                    ],
                  );
                },
              ),
            ],
          )
        : Center(
            child:
                CircularProgressIndicator()); // Show loading while fetching location
  }
}
