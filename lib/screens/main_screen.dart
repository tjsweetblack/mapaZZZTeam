import 'package:auth_bloc/logic/cubit/auth_cubit.dart';
import 'package:auth_bloc/routing/routes.dart';
import 'package:auth_bloc/screens/map/main_map.dart';
import 'package:auth_bloc/screens/menu.dart';
import 'package:auth_bloc/screens/report/create_report.dart';
import 'package:auth_bloc/screens/report/report_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart'; // Import the url_launcher package

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
          MapWidget(interactive: true), // Set interactive to true
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
                  onTap: () async {
                    final String googleMapsUrl =
                        'https://www.google.com/maps/search/?api=1&query=nearest+hospital&origin=${belasLuanda.latitude},${belasLuanda.longitude}';
                    final Uri googleMapsUri = Uri.parse(googleMapsUrl);
                    if (await canLaunchUrl(googleMapsUri)) {
                      await launchUrl(googleMapsUri);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Could not launch Google Maps.')),
                      );
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
                  onTap: () {},
                  child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.location_pin, color: Colors.red)),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  // Wrap with GestureDetector
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SimpleCreateReportCameraScreen(),
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
          Positioned(
            top: 200,
            left: MediaQuery.of(context).size.width / 2 - 15,
            child: Icon(Icons.location_on, color: Colors.white, size: 30),
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
      // Optionally show an error message to the user
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
