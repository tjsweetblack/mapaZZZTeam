import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine the safe area at the bottom of the screen to avoid the home indicator on iOS
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Directionality(
      // Add Directionality widget
      textDirection: TextDirection.ltr, // Set text direction (usually ltr)
      child: Scaffold(
        backgroundColor: const Color(0xFFF44336), // A slightly more saturated red
        body: Stack(
          children: [
            // Centered Logo
            Center(
              child: Image.asset('assets/images/logo/logo3.png', height: 90,),
            ),
            
            // "Mapazzz" Text at the bottom
            Positioned(
              bottom: 40 + bottomPadding, // Adjusting for the safe area and adding some margin
              left: 0,
              right: 0,
              child: const Text(
                'Mapazzz',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
