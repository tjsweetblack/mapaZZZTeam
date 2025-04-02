import 'package:auth_bloc/screens/report/report_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapWidget extends StatelessWidget {
  final LatLng belasLuanda =
      LatLng(-8.9036, 13.2489); // Current location: Belas, Luanda
  final bool interactive;

  MapWidget({this.interactive = true});

  final mapController = MapController();
  final double heatmapRadiusKm =
      0.3; // Radius of the heatmap circle in km - CHANGED TO 0.3

  Widget _greyScaleTileBuilder(
    BuildContext context,
    Widget tileWidget,
    TileImage tile,
  ) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.15, // Red contribution
        0.50, // Green contribution
        0.05, // Blue contribution
        0,
        0,
        0.15, // Red contribution
        0.50, // Green contribution
        0.05, // Blue contribution
        0,
        0,
        0.15, // Red contribution
        0.50, // Green contribution
        0.05, // Blue contribution
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
    return FlutterMap(
      key: UniqueKey(),
      mapController: mapController,
      options: MapOptions(
        initialCenter: belasLuanda,
        initialZoom: 13.0,
        interactionOptions: InteractionOptions(
          flags: interactive
              ? InteractiveFlag.all
              : InteractiveFlag.none, // Use flags for interactivity
          cursorKeyboardRotationOptions: const CursorKeyboardRotationOptions(),
          keyboardOptions: const KeyboardOptions(),
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
          tileBuilder: _greyScaleTileBuilder,
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('reports').snapshots(),
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
                    point: LatLng(
                      latitude, // Already cast to double? above
                      longitude, // Already cast to double? above
                    ),
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

            // Create Heatmap Circles based on clusters
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
                    final distance = const Distance().distance(
                        LatLng(lat1, lon1),
                        LatLng(lat2, lon2)); // Distance in meters
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

                  // Calculate the center point of the cluster
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

                  processedReports.addAll(
                      reportsInRadius); // Mark all reports in this cluster as processed
                }
              }
            }

            return Stack(
              children: [
                CircleLayer(circles: heatmapCircles), // Heatmap circles first
                MarkerLayer(markers: reportMarkers), // Report markers on top
              ],
            );
          },
        ),
      ],
    );
  }
}