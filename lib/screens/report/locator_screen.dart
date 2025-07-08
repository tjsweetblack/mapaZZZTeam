import 'dart:async'; // For StreamSubscription
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart'; // Import flutter_compass
import 'package:vector_math/vector_math.dart' show degrees, radians;

class LocatorScreen extends StatefulWidget {
  final double reportLatitude;
  final double reportLongitude;

  LocatorScreen({required this.reportLatitude, required this.reportLongitude});

  @override
  _LocatorScreenState createState() => _LocatorScreenState();
}

class _LocatorScreenState extends State<LocatorScreen> {
  Position? _currentPosition;
  double _distanceToReport = 0.0;
  double _bearingToReport = 0.0; // Bearing from current location to target
  double? _deviceHeading; // Device's current magnetic heading (from compass)
  double _arrowRotationAngle = 0.0; // Final angle for the arrow

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
    _startCompassUpdates();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _compassSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startLocationUpdates() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      _showPermissionDeniedDialog('Serviços de localização desabilitados.');
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        _showPermissionDeniedDialog('Permissão de localização negada.');
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      _showPermissionDeniedDialog('Permissão de localização negada permanentemente.');
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0, // Get updates as frequently as possible
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _distanceToReport = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            widget.reportLatitude,
            widget.reportLongitude,
          );
          _bearingToReport = _calculateBearing(
            position.latitude,
            position.longitude,
            widget.reportLatitude,
            widget.reportLongitude,
          );
          _updateArrowRotation(); // Recalculate arrow angle when position changes
        });
      }
    });
  }

  void _startCompassUpdates() {
    if (FlutterCompass.events != null) {
      _compassSubscription = FlutterCompass.events!.listen((CompassEvent event) {
        if (mounted && event.heading != null) {
          setState(() {
            // Magnetic North heading. Need to adjust for true north if desired
            // (requires knowing magnetic declination for current location).
            _deviceHeading = event.heading!;
            _updateArrowRotation(); // Recalculate arrow angle when heading changes
          });
        }
      });
    }
  }

  void _updateArrowRotation() {
    if (_deviceHeading != null) {
      // Calculate the difference between the device's heading and the target bearing.
      // We want the arrow to point towards the target relative to the device's current orientation.
      double relativeBearing = _bearingToReport - _deviceHeading!;

      // Normalize the angle to be between -180 and 180 degrees
      if (relativeBearing > 180) {
        relativeBearing -= 360;
      } else if (relativeBearing < -180) {
        relativeBearing += 360;
      }
      _arrowRotationAngle = radians(relativeBearing);
    }
  }

  // Haversine formula for initial bearing (0-360 degrees, true north)
  double _calculateBearing(double currentLat, double currentLon,
      double targetLat, double targetLon) {
    double startLat = radians(currentLat);
    double startLong = radians(currentLon);
    double endLat = radians(targetLat);
    double endLong = radians(targetLon);

    double dLong = endLong - startLong;

    double y = math.sin(dLong) * math.cos(endLat);
    double x = math.cos(startLat) * math.sin(endLat) -
               math.sin(startLat) * math.cos(endLat) * math.cos(dLong);

    // Convert to degrees and normalize to 0-360
    double bearing = (degrees(math.atan2(y, x)) + 360) % 360;
    return bearing;
  }

  void _showPermissionDeniedDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Permissão Necessária"),
          content: Text(message + "\nPor favor, habilite as permissões de localização e bússola nas configurações do seu dispositivo."),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                // Optionally, navigate back or offer to open app settings
                // Geolocator.openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasLocationData = _currentPosition != null;
    bool hasCompassData = _deviceHeading != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Localizador da Reportagem'),
        backgroundColor: Colors.red.shade700, // Themed app bar
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.red.shade50, Colors.red.shade100], // Soft red gradient background
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Distance display
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'Distância para o Ponto:',
                        style: TextStyle(fontSize: 20, color: Colors.grey.shade700),
                      ),
                      SizedBox(height: 10),
                      Text(
                        hasLocationData
                            ? '${_distanceToReport.toStringAsFixed(0)} metros' // Show as integer for meters
                            : 'Calculando...',
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 40),

              // Arrow indicator
              if (hasLocationData && hasCompassData)
                Column(
                  children: [
                    Text(
                      'Apontando para a direção da reportagem',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Transform.rotate(
                      angle: _arrowRotationAngle,
                      child: Icon(
                        Icons.navigation, // A more appropriate arrow icon
                        size: 150,
                        color: Colors.red.shade700, // Themed arrow color
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    CircularProgressIndicator(color: Colors.red.shade700),
                    SizedBox(height: 20),
                    Text(
                      'Aguardando dados de localização e/ou bússola...',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}