import 'package:flutter/material.dart';
import '../models/word_level.dart'; // Importa a lista wordLevels
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 240, 240), // Very light red/pink background
      appBar: AppBar(
        title: const Text(
          'Sopa de Letras - Malária',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Color.fromARGB(255, 139, 0, 0), // Dark red for title
          ),
        ),
        centerTitle: true, // Center the title
        backgroundColor: Colors.transparent, // Transparent app bar
        elevation: 0, // No shadow for app bar
        foregroundColor: const Color.fromARGB(255, 139, 0, 0),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0), // More horizontal padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Game Logo/Title Image (Optional but recommended for a game feel) ---
              // Make sure you have 'assets/malaria_logo.png' in your project
              Image.asset(
                'assets/images/logo/logo.png', // Replace with your game logo image path
                height: 150,
              ),
              const SizedBox(height: 30),

              const Text(
                'Escolhe o teu nível',
                style: TextStyle(
                  fontSize: 28, // Larger font size
                  fontWeight: FontWeight.w900, // Extra bold
                  color: Color.fromARGB(255, 178, 34, 34), // Firebrick red for main text
                  shadows: [
                    Shadow(
                      blurRadius: 4.0,
                      color: Colors.black26,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: wordLevels.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 10.0), // Increased vertical margin
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade100, // Lighter red for gradient start
                          Colors.red.shade300, // Darker red for gradient end
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15), // More rounded corners
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.shade200.withOpacity(0.6), // Red shadow
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent, // Make Material widget transparent
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15), // Match inkwell border radius
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GameScreen(level: wordLevels[index]),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0), // More padding inside list tile
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                wordLevels[index].title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20, // Slightly larger font
                                  color: Color.fromARGB(255, 139, 0, 0), // Dark red for level titles
                                ),
                              ),
                              Icon(Icons.play_circle_fill, color: Color.fromARGB(255, 139, 0, 0), size: 30), // Play icon in dark red
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}