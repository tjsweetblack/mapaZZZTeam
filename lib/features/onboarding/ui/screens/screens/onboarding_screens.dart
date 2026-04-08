// onboarding_pages.dart
import 'package:flutter/material.dart';

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final double? imageHeight;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
    this.imageHeight = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image.asset(imagePath, height: imageHeight),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.black, // Corrected title text color to black
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12,
                color:
                    Colors.black, // Corrected description text color to black
                fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage1 extends StatelessWidget {
  const OnboardingPage1({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingPage(
      title: "Juntos contra a malária: previna, alerte, combata!",
      description: "Juntos contra a malária: previna, alerte, combata!",
      imagePath: 'assets/images/on1.png', // Replace with your image asset path
      imageHeight: 400.0, // Example: Keeping default height of 200
    );
  }
}

class OnboardingPage2 extends StatelessWidget {
  const OnboardingPage2({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingPage(
      title:
          "A cada minuto, vidas são afetadas pela malária. Faça a diferença!",
      description:
          "A cada minuto, vidas são afetadas pela malária. Faça a diferença!",
      imagePath: 'assets/images/on2.png', // Replace with your image asset path
      imageHeight: 350.0, // Example: Keeping default height of 200
    );
  }
}

class OnboardingPage3 extends StatelessWidget {
  const OnboardingPage3({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingPage(
      title: "Malária sob controle: prevenção em ação!",
      description: "Malária sob controle: prevenção em ação!",
      imagePath: 'assets/images/on3.png', // Replace with your image asset path
      imageHeight: 400.0, // Example: Keeping default height of 200
    );
  }
}
