import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Generates a custom marker icon.
Future<BitmapDescriptor> getCustomMarkerIcon() async {
  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);
  final Paint paint1 = Paint()..color = Colors.white;
  final Paint paint2 = Paint()..color = Colors.red.withOpacity(0.8);
  const double size = 40;
  const double outerRadius = size / 2;
  const double innerRadius = size / 4;

  canvas.drawCircle(
      const Offset(outerRadius, outerRadius), outerRadius, paint1);
  canvas.drawCircle(
      const Offset(outerRadius, outerRadius), innerRadius, paint2);

  final img =
      await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
}
