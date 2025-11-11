import 'dart:async';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:auth_bloc/screens/report/report_details.dart';
import 'package:auth_bloc/utils/marker_utils.dart'; // Import the utility file
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart'; // Import Geolocator

class MapWidget2 extends StatefulWidget {
  final GoogleMapController? mapController;
  final LatLng? currentLocation = LatLng(-8.913499751058776, 13.18721354420165);
  final Function(String) onRiskLevelChanged;

  MapWidget2({
    Key? key,
    this.mapController,
    this.onRiskLevelChanged = _defaultRiskLevelChanged,
  }) : super(key: key);

  static void _defaultRiskLevelChanged(String riskLevel) {
    // Default implementation for onRiskLevelChanged
    print('Risk level changed: $riskLevel');
  }

  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget2> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  BitmapDescriptor? _reportMarkerIcon;

  bool _initialLoadDone = false;
  final double heatmapRadiusKm = 0.5; // Example radius, adjust as needed
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _mapController = widget.mapController;
    _createCustomMarker();
    _getUserCurrentLocation(); // Fetch user's current location
    _checkConnectivity(); // Check connectivity once on page load
  }

  // Check internet connectivity
  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (mounted) {
        setState(() {
          _isOffline = !isConnected;
        });
      }
    } on SocketException catch (_) {
      if (mounted) {
        setState(() {
          _isOffline = true;
        });
      }
    }
  }

  // Fetch user's current location
  Future<void> _getUserCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        setState(() {
          _currentLocation = widget.currentLocation ?? LatLng(-8.9036, 13.2489);
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied.');
          setState(() {
            _currentLocation =
                widget.currentLocation ?? LatLng(-8.9036, 13.2489);
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied.');
        setState(() {
          _currentLocation = widget.currentLocation ?? LatLng(-8.9036, 13.2489);
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      print('User location: $_currentLocation');
    } catch (e) {
      print('Error getting user location: $e');
      setState(() {
        _currentLocation = widget.currentLocation ?? LatLng(-8.9036, 13.2489);
      });
    }
  }

  void _createCustomMarker() async {
    _reportMarkerIcon = await getCustomMarkerIcon(); // Use the utility function
    if (mounted) {
      setState(() {});
    }
  }

  // Method to go to current location
  Future<void> _goToCurrentLocation() async {
    try {
      if (_currentLocation != null && _mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentLocation!,
              zoom: 16.0,
            ),
          ),
        );
      } else {
        // Get fresh location if current location is null
        await _getUserCurrentLocation();
        if (_currentLocation != null && _mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _currentLocation!,
                zoom: 16.0,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error going to current location: $e');
    }
  }

  void _saveNewZones(Set<Circle> circles) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    for (final circle in circles) {
      final Map<String, dynamic> zoneData = {
        'center': {
          'latitude': circle.center.latitude,
          'longitude': circle.center.longitude,
        },
        'radius': circle.radius,
        'opacity': circle.fillColor.opacity,
        'color': circle.fillColor.value.toRadixString(16), // Save color as hex
      };

      try {
        await firestore.collection('zones').add(zoneData);
        print('Zone saved: $zoneData');
      } catch (e) {
        print('Error saving zone: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Offline banner
        if (_isOffline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.orange.shade100,
            child: Row(
              children: [
                Icon(
                  Icons.wifi_off,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Você está offline',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Map widget
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reports')
                .where('status', isEqualTo: 'active')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                print("Google Maps: Error fetching reports: ${snapshot.error}");
              }
              List<Map<String, dynamic>> reports = [];
              try {
                reports = snapshot.data!.docs
                    .map((doc) => doc.data() as Map<String, dynamic>?)
                    .whereType<Map<String, dynamic>>()
                    .toList();
              } catch (e) {
                print('Error parsing reports: $e');
              }

              final Set<Marker> reportMarkers = {};
              final Set<Circle> heatmapCircles = {};
              final List<Map<String, dynamic>> processedReports = [];
              final double heatmapRadiusMeters = heatmapRadiusKm * 1000;
              String currentRiskLevelText = 'Está numa zona sem risco.';

              // Process reports and generate markers and circles
              for (final report in reports) {
                final latitude = report['latitude'] as double?;
                final longitude = report['longitude'] as double?;

                if (latitude != null && longitude != null) {
                  reportMarkers.add(
                    Marker(
                      markerId: MarkerId('report_${report.hashCode}'),
                      position: LatLng(latitude, longitude),
                      icon: _reportMarkerIcon ?? BitmapDescriptor.defaultMarker,
                      anchor: const Offset(0.5, 0.5),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ReportDetailPage(report: report),
                          ),
                        );
                      },
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
                      final distance = const latlong.Distance().distance(
                          latlong.LatLng(lat1, lon1),
                          latlong.LatLng(lat2, lon2));
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
                      Circle(
                        circleId: CircleId('circle_${report1.hashCode}'),
                        center: clusterCenter,
                        radius: heatmapRadiusMeters,
                        fillColor: Colors.red.withOpacity(opacity),
                        strokeColor: Colors.red.withOpacity(opacity),
                        strokeWidth: 1,
                      ),
                    );

                    processedReports.addAll(reportsInRadius);
                  }
                }
              }

              _saveNewZones(heatmapCircles);

              if (!_initialLoadDone && widget.currentLocation != null) {
                for (final circle in heatmapCircles) {
                  final distanceToCircleCenter =
                      const latlong.Distance().distance(
                    latlong.LatLng(widget.currentLocation!.latitude,
                        widget.currentLocation!.longitude),
                    latlong.LatLng(
                        circle.center.latitude, circle.center.longitude),
                  );
                  if (distanceToCircleCenter <= circle.radius) {
                    if (circle.fillColor.opacity == 0.3) {
                      currentRiskLevelText = 'Está numa zona de baixo risco.';
                      break;
                    } else if (circle.fillColor.opacity == 0.6) {
                      currentRiskLevelText = 'Está numa zona de médio risco.';
                      break;
                    } else if (circle.fillColor.opacity == 0.9) {
                      currentRiskLevelText = 'Está numa zona de alto risco.';
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

              return Stack(
                children: [
                  GoogleMap(
                    key: UniqueKey(),
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation ??
                          LatLng(-8.9036, 13.2489), // Use default if null
                      zoom: 15.0,
                    ),
                    mapType: MapType.normal,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false, // Disable default button
                    zoomControlsEnabled: false,
                    rotateGesturesEnabled: false,
                    padding: const EdgeInsets.only(
                      top: 100.0,
                      right: 16.0,
                      bottom: 100.0,
                      left: 16.0,
                    ),
                    markers: reportMarkers,
                    circles: heatmapCircles,
                    onMapCreated: (GoogleMapController controller) {
                      try {
                        _mapController = controller;
                        if (_currentLocation != null) {
                          _mapController?.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                  target: _currentLocation!, zoom: 12.0),
                            ),
                          );
                        }
                      } catch (e) {
                        print('Google Maps: Error in onMapCreated: $e');
                      }
                    },
                  ),
                  // Custom location button
                  Positioned(
                    top: 30,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(500),
                          onTap: _goToCurrentLocation,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(
                              Icons.my_location,
                              color: ui.Color.fromARGB(255, 255, 0, 0),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
