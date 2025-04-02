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
      appBar: AppBar(
        title:
            const Text('EPaludismo ?', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Datalhe os sintomas do paciente e receba a probalidade de malaria',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Detalhes de sintomas',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextFormField(
                  controller: _symptomsController,
                  maxLines: null, // Allows for multiline input
                  expands:
                      true, // Makes the TextFormField expand to fill available space
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Digite os sintomas aqui...',
                  ),
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
              child: const Text(
                'Ver Resultados',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
