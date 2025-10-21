import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MalariaResultScreen extends StatefulWidget {
  final String symptomsDescription;

  const MalariaResultScreen({super.key, required this.symptomsDescription});

  @override
  State<MalariaResultScreen> createState() => _MalariaResultScreenState();
}

class _MalariaResultScreenState extends State<MalariaResultScreen> {
  String probabilityResult = 'Analisando...';
  bool isLoading = true;
  String errorMessage = '';
  String explanation = '';
  Color _resultColor = Colors.grey; // Default color

  @override
  void initState() {
    super.initState();
    _getMalariaProbability();
  }

  // Function to determine the color based on probability
  void _setResultColor(double probability) {
    if (probability < 45) {
      _resultColor = Colors.green;
    } else if (probability < 75) {
      _resultColor = Colors.orange; // Yellow in the image is more of an orange
    } else {
      _resultColor = Colors.red;
    }
  }

  Future<void> _getMalariaProbability() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      probabilityResult = 'Analisando...';
      explanation = '';
      _resultColor = Colors.grey;
    });

    final apiUrl =
        'https://epaludismo-api.vercel.app/malaria-probability'; // Change to your server address if needed

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'symptomsDescription': widget.symptomsDescription}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final percentage = data['percentage'];
        final explanationText = data['explanation'] ?? '';

        setState(() {
          probabilityResult =
              percentage != null ? '${percentage.toInt()}%' : 'N/A';
          explanation = explanationText.isNotEmpty
              ? explanationText
              : 'A explicação para esta probabilidade não foi fornecida.';
          _setResultColor(percentage?.toDouble() ?? 0.0);
          isLoading = false;
        });
      } else {
        setState(() {
          probabilityResult = 'N/A';
          explanation =
              'Erro ao analisar, por favor contacte o Team info@ma-pa-zzz.tech';
          errorMessage =
              'Erro ao analisar, por favor contacte o Team info@ma-pa-zzz.tech';
          isLoading = false;
          _resultColor = Colors.grey;
        });
      }
    } catch (e) {
      setState(() {
        probabilityResult = 'N/A';
        explanation =
            'Erro ao analisar, por favor contacte o Team info@ma-pa-zzz.tech';
        errorMessage =
            'Erro ao analisar, por favor contacte o Team info@ma-pa-zzz.tech';
        isLoading = false;
        _resultColor = Colors.grey;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Resultado da avaliação',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_resultColor
                          .withOpacity(0.2)), // Lighter ring for background
                      backgroundColor: Colors.transparent,
                      strokeWidth: 10,
                      value: 1.0, // Full circle for background
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_resultColor),
                      backgroundColor: Colors.transparent,
                      strokeWidth: 10,
                      value: isLoading
                          ? 0.0 // No progress while loading
                          : (double.tryParse(
                                      probabilityResult.replaceAll('%', '')) ??
                                  0.0) /
                              100,
                    ),
                  ),
                  Text(
                    isLoading ? '...' : probabilityResult,
                    style: TextStyle(
                      fontSize: 48, // Larger font size for the percentage
                      fontWeight: FontWeight.bold,
                      color: _resultColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              isLoading
                  ? 'Essa é a probabilidade estimada de que você tenha malária, com base nos sintomas informados.'
                  : errorMessage.isNotEmpty
                      ? errorMessage
                      : 'Essa é a probabilidade estimada de que você tenha malária, com base nos sintomas informados.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            if (!isLoading && explanation.isNotEmpty && errorMessage.isEmpty)
              Text(
                explanation,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Aviso importante:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Este diagnóstico é realizado por IA e não substitui a consulta médica profissional. Procure atendimento médico para confirmação e tratamento adequado.',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                // Define the search query
                const String searchQuery = 'hospitals near me';
                // Use a standard Google search URL format, ensuring proper encoding
                final Uri googleMapsUri = Uri.https(
                  'maps.google.com',
                  '/',
                  {'q': searchQuery},
                );
                final Uri uriToLaunch =
                    googleMapsUri; // Choose which URI to try

                print('Attempting to launch URL: $uriToLaunch');

                try {
                  // Check if the URL can be launched
                  bool canLaunch = await canLaunchUrl(uriToLaunch);
                  print('canLaunchUrl result for $uriToLaunch: $canLaunch');

                  if (canLaunch) {
                    // Launch the URL externally (usually in the default browser)
                    bool launched = await launchUrl(
                      uriToLaunch,
                      mode: LaunchMode
                          .externalApplication, // Try to open outside the app
                    );

                    if (!launched) {
                      print('launchUrl returned false for $uriToLaunch');
                      if (mounted) {
                        // Check if widget is still mounted
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Não foi possível abrir a pesquisa de mapa no navegador.')), // Slightly more specific
                        );
                      }
                    } else {
                      print('Successfully launched URL: $uriToLaunch');
                    }
                  } else {
                    // canLaunchUrl returned false
                    print('System cannot handle URL: $uriToLaunch');
                    if (mounted) {
                      // Check if widget is still mounted
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Não foi possível encontrar uma aplicação para abrir a pesquisa de mapa.')), // More user-friendly message
                      );
                    }
                  }
                } catch (e) {
                  // Catch any exceptions during canLaunchUrl or launchUrl
                  print("Error launching URL ($uriToLaunch): $e");
                  if (mounted) {
                    // Check if widget is still mounted
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Ocorreu um erro ao tentar abrir a pesquisa de mapa: ${e.toString()}')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Ver hospitais próximos',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () async {
                final Uri phoneUri = Uri(scheme: 'tel', path: '111');
                if (await canLaunchUrl(phoneUri)) {
                  await launchUrl(phoneUri);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not launch phone.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                  side: BorderSide(color: Colors.red[700]!),
                ),
              ),
              child: Text(
                'Contacto de emergência',
                style: TextStyle(color: Colors.red[700], fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
