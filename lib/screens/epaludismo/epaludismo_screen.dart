import 'package:flutter/material.dart';
import 'epaludismo_result_screen.dart'; // Assuming epaludismo_result_screen.dart is the file name

class EPaldudismoScreen extends StatefulWidget {
  const EPaldudismoScreen({super.key});

  @override
  State<EPaldudismoScreen> createState() => _EPaldudismoScreenState();
}

class _EPaldudismoScreenState extends State<EPaldudismoScreen> {
  final TextEditingController _symptomsController = TextEditingController();

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Back button
          Positioned(
            top: 50.0,
            left: 20.0,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),

                // Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.electric_meter, // Use a suitable icon from Flutter's library
                      size: 60,
                      color: Colors.red,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                const Text(
                  'É Paludismo?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 10),

                // Subtitle/Description
                const Text(
                  'Descreva seus sintomas detalhadamente para que nossa IA possa avaliar a probabilidade de malária.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 30),

                // Text Input Field
                Container(
                  height: 200, // Adjusted height to match the image
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextFormField(
                      controller: _symptomsController,
                      maxLines: null, // Allows the text to wrap indefinitely
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Descrição',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // Button
                ElevatedButton(
                  onPressed: () {
                    final String symptoms = _symptomsController.text;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              MalariaResultScreen(symptomsDescription: symptoms)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Text(
                    'Iniciar avaliação',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),

                // AI Powered Text
                const Text(
                  'AI Powered',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}