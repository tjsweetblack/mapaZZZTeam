import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auth_bloc/screens/main_screen.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'report_details.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // Import the generative AI package

// Add the API key.  Make sure to replace it with your actual API key.
const String _apiKey =
    'AIzaSyBAO_rST4zn3HeQNFHDCXaczAwLMQ0VROg'; //  <--- Replace with your actual API key

class CreateReportCameraScreen extends StatefulWidget {
  @override
  _CreateReportCameraScreenState createState() =>
      _CreateReportCameraScreenState();
}

class _CreateReportCameraScreenState extends State<CreateReportCameraScreen> {
  late CameraController _cameraController;
  late Future<void> _initializeCameraControllerFuture;
  List<CameraDescription> _cameras = [];
  bool _isAnalyzing = false; // Track image analysis state

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        // Handle the case where no cameras are available.
        print('No cameras available.');
        return;
      }
      _cameraController = CameraController(
        _cameras.first, // Get a specific camera from the list
        ResolutionPreset.high, // Set the resolution
      );
      _initializeCameraControllerFuture = _cameraController.initialize();
      await _initializeCameraControllerFuture; // Ensure initialization completes.

      if (!mounted) {
        return;
      }
      setState(() {});
    } catch (e) {
      print('Error initializing camera: $e');
      // Show error message to the user
      if (mounted) {
        //check mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize camera: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<bool> _isImageValidForReport(String imagePath) async {
    try {
      final generativeModel = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: _apiKey,
      );

      Uint8List imageBytes = await File(imagePath).readAsBytes();
      final content = [
        Content.multi([
          TextPart(
              "Analyze this image to detect potential mosquito breeding sites. Consider the presence of any of the following: \n"
              "- Stagnant water (puddles, pools, containers)\n"
              "- Vegetation capable of holding water (e.g., dense grass, bromeliads)\n"
              "- Discarded containers (tires, bottles, cans, flowerpots)\n"
              "- Accumulated trash or debris\n"
              "- Gutters or drainage systems\n"
              "- Any other area where water may collect and remain for more than 4 days.\n"
              "Respond with 'valid' if the image clearly shows one or more of these conditions, and 'invalid' if none are clearly present.  Focus on the presence of standing water and items/areas that can hold water. "),
          DataPart('image/jpeg', imageBytes),
        ]),
      ];

      final response = await generativeModel.generateContent(content);
      final aiResponse = response.text?.toLowerCase().trim();

      return aiResponse == 'valid';
    } catch (e) {
      print("Error analyzing image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao analisar a imagem.')),
        );
      }
      return false;
    }
  }

  void _showInvalidImageDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must interact with the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Foto Inválida'),
          content: const Text(
            'A foto não mostra um problema real de risco. Por favor, tire uma foto de um local com água parada, vegetação excessiva ou outros potenciais focos de mosquito.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar reportagem'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle:
            const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MapZzzPage(),
              ),
            ); // Navigate back to the previous screen (main screen)
          },
        ),
      ),
      body: FutureBuilder<void>(
        future: _initializeCameraControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
// Camera initialized, display the preview
            return Stack(
              children: [
                CameraPreview(_cameraController),
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 30.0),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Tire foto do risco .',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 30.0),
                    child: _isAnalyzing
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                _isAnalyzing = true;
                              });
                              try {
                                await _initializeCameraControllerFuture;
                                final image =
                                    await _cameraController.takePicture();
                                bool isImageValid =
                                    await _isImageValidForReport(image.path);
                                if (isImageValid) {
                                  if (mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CreateReportDetailsScreen(
                                                imagePath: image.path),
                                      ),
                                    );
                                  }
                                } else {
                                  if (mounted) {
                                    _showInvalidImageDialog();
                                  }
                                }
                              } catch (e) {
                                print('Error taking picture: $e');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Error taking picture: $e')),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isAnalyzing = false;
                                  });
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(30),
                              backgroundColor: Colors.white, // White button
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 40, color: Colors.red), // Red camera icon
                          ),
                  ),
                ),
              ],
            );
          } else if (snapshot.connectionState == ConnectionState.waiting) {
// Otherwise, display a loading indicator
            return const Center(child: CircularProgressIndicator());
          } else {
            return Center(
                child: Text('Camera Error: ${snapshot.error}')); //show error.
          }
        },
      ),
    );
  }
}

class CreateReportDetailsScreen extends StatefulWidget {
  final String imagePath;

  CreateReportDetailsScreen({required this.imagePath});

  @override
  _CreateReportDetailsScreenState createState() =>
      _CreateReportDetailsScreenState();
}

class _CreateReportDetailsScreenState extends State<CreateReportDetailsScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _imageUrl;
  bool _isUploading = false;
  String _shippingAddress = ''; // To store the fetched address
  bool _isCreatingReport = false; // To track report creation process

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<String?> _uploadImageToCloudinary(String imagePath) async {
    setState(() {
      _isUploading = true;
    });
    try {
      List<int> imageBytes = await File(imagePath).readAsBytes();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://burger-image-api.vercel.app/upload'),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imagePath.split('/').last,
        ),
      );
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(responseBody);
        setState(() {
          _isUploading = false;
        });
        return decodedResponse['imageUrl'];
      } else {
        print('Backend upload error: ${response.statusCode} - ${responseBody}');
        setState(() {
          _isUploading = false;
        });
        throw Exception('Backend upload failed');
      }
    } catch (e) {
      print('Upload exception: $e');
      setState(() {
        _isUploading = false;
      });
      rethrow;
    }
  }

  Future<String?> _getCurrentLocationName(
      double latitude, double longitude) async {
    try {
      final response = await http.get(Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$latitude&lon=$longitude&addressdetails=1'));
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        print("Nominatim API decodedResponse: $decodedResponse");
        if (decodedResponse != null &&
            decodedResponse['display_name'] != null) {
// <-- Check for display_name
          setState(() {
            _shippingAddress = decodedResponse[
                'display_name']; // <-- Use display_name directly
            print(
                "Shipping address set to: $_shippingAddress"); // Log shipping address
          });
          return _shippingAddress;
        } else {
          print(
              "Nominatim API: No address details found in response (inside IF condition)");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('No address found for selected location.')),
            );
          }
          setState(() {
            _shippingAddress = '';
          });
          return null;
        }
      } else {
// Handle API error (e.g., show an error message)
        print(
            "Nominatim API request failed with status: ${response.statusCode}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to get address.')),
          );
        }

        setState(() {
          _shippingAddress = '';
        });
        return null;
      }
    } catch (e) {
// Handle any exceptions (e.g., network issues)
      print("Error fetching address: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get address.')),
        );
      }
      setState(() {
        _shippingAddress = '';
      });
      return null;
    }
  }

  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;
// Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition();
  }

  //this is the function that calls the LLM
  Future<int> _analyzeRiskLevel(
      String imageUrl, String title, String description) async {
    try {
      final generativeModel = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: _apiKey,
      );

      // Prepare the image data for the AI.
      Uint8List imageBytes = await File(widget.imagePath).readAsBytes();
      final content = [
        Content.multi([
          TextPart(
              "Analyze the image and report to assess the risk level of mosquito breeding, taking into account the following title: '$title' and description: '$description'. Rate the risk level on a scale of 1 to 3, where 1 is low risk, 2 is medium risk, and 3 is high risk.  Respond with only a single number (1, 2, or 3) indicating the risk level."),
          DataPart('image/jpeg', imageBytes),
        ]),
      ];

      // Generate content using the AI model.
      final response = await generativeModel.generateContent(content);
      final aiResponse = response.text?.trim();

      // Parse the response to an integer
      int? riskLevel = int.tryParse(aiResponse ?? '');
      if (riskLevel != null && riskLevel >= 1 && riskLevel <= 3) {
        return riskLevel;
      } else {
        // Handle the error case where the AI doesn't return a valid number
        print("AI returned invalid risk level: $aiResponse");
        return 1; // Default to low risk
      }
    } catch (e) {
      // Handle any exceptions (e.g., network issues, AI failure)
      print("Error analyzing risk level: $e");
      return 1; // Default to low risk in case of error
    }
  }

  Future<void> _createReport() async {
    if (_isCreatingReport || _isUploading) {
      return; // Prevent multiple submissions during upload/creation
    }
    String title = _titleController.text.trim();
    String description = _descriptionController.text.trim();
    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, preencha o título e a descrição.')),
      );
      return;
    }
    setState(() {
      _isCreatingReport = true;
    });
    try {
      String? imageUrl = await _uploadImageToCloudinary(widget.imagePath);
      if (imageUrl != null) {
        Position position = await _getCurrentPosition();
        String? locationName = await _getCurrentLocationName(
            position.latitude, position.longitude);
        String? userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          // Analyze the risk level using AI
          int riskLevel = await _analyzeRiskLevel(
              imageUrl, title, description); // Get risk level from AI

          // Initialize the generative AI model
          final generativeModel = GenerativeModel(
            model: 'gemini-1.5-flash-latest',
            apiKey: _apiKey,
          );

          // Prepare the image data for the AI.
          Uint8List imageBytes = await File(widget.imagePath).readAsBytes();
          final content = [
            Content.multi([
              TextPart(
                  "Analyze this report to provide a solution to prevent malaria, respond in portuguese. Title: $title, Description: $description.  Also analyze the image and what to fix in the image to avoid malaria"),
              // The image is sent as a DataPart.
              DataPart('image/jpeg', imageBytes),
            ]),
          ];

          // Generate content using the AI model.
          final response = await generativeModel.generateContent(content);
          final aiSolution = response.text ??
              "Não foi possível gerar uma solução."; // Provide a default value

          // Create the report and get the DocumentReference
          DocumentReference reportRef =
              await FirebaseFirestore.instance.collection('reports').add({
            'NoConfirmation': 0,
            'description': description,
            'imageUrl': imageUrl,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'location': locationName ?? 'Localização desconhecida',
            'riskLevel':
                riskLevel, // Store the AI-generated risk level here.  1, 2, or 3
            'solutionAi': aiSolution, // Store the AI-generated solution here.
            'status': 'active',
            'title': title,
            'userId': userId,
          });

          // Get the ID from the DocumentReference
          String reportId = reportRef.id;

          // Update the document with the 'id' field
          await reportRef.update({'id': reportId});

// Update user points
          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
          if (userSnapshot.exists && userSnapshot.data() != null) {
            int currentPoints =
                (userSnapshot.data() as Map<String, dynamic>)['points'] ?? 0;
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .update({'points': currentPoints + 30});
          }
          setState(() {
            _isCreatingReport = false;
          });

// Fetch the newly created report data
          DocumentSnapshot<Map<String, dynamic>> newReportSnapshot =
              await reportRef.get() as DocumentSnapshot<Map<String, dynamic>>;

          // Add the document ID to the report data
          Map<String, dynamic>? reportDataWithId = newReportSnapshot.data();
          if (reportDataWithId != null) {
            reportDataWithId['id'] = newReportSnapshot.id;
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CreateReportSuccessScreen(
                  report: reportDataWithId), // Pass report data with ID
            ),
          );
        } else {
          setState(() {
            _isCreatingReport = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erro ao obter o ID do usuário.')),
            );
          }
        }
      } else {
        setState(() {
          _isCreatingReport = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao fazer o upload da imagem.')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isCreatingReport = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ocorreu um erro ao criar a reportagem: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('MapZzz'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle:
            const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CreateReportCameraScreen(),
              ),
            );
          },
        ),
      ),
      body: Padding(
        // Remove the Center Widget
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Change to .stretch
          children: [
            const Text(
              'Detalhe o risco e as potencias\ncausas do risco',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center, //Center the text
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Titulo',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 10.0, horizontal: 15.0), //Add padding
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Detalhes',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText:
                    'Contrary to popular belief , Lorem Ipsum\nis not simply random text . It has roots in\na piece of classical Latin literature from\n45 BC , making it over 2000 years old .\nRichard McClintock , a Latin professor at\nHampden - Sydney College in Virginia ,\nlooked up one of the more obscure Latin\nwords , consectetur , from a Lorem Ipsum\npassage , and going through the cites of\nthe word in',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 10.0, horizontal: 15.0), //Add padding
              ),
            ),
            const SizedBox(height: 20), //Add space before the button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isCreatingReport || _isUploading ? null : _createReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
                child: (_isCreatingReport || _isUploading)
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text('Completar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateReportSuccessScreen extends StatelessWidget {
  final Map<String, dynamic>? report; // Receive the report data

  CreateReportSuccessScreen({this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('MapZzz'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle:
            const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      body: Padding(
        //changed to padding
        padding: EdgeInsets.only(top: 50),
        child: Column(
          //changed to column
          //mainAxisAlignment: MainAxisAlignment.center, // Removed mainAxisAlignment
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.red,
              size: 120,
            ),
            const SizedBox(height: 20),
            const Text(
              'Concluido .',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Reportagem criada com sucesso .",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold), // Made message bold
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Ganhaste',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.star_border, color: Colors.red, size: 20),
                SizedBox(width: 4),
                Text(
                  '30 pontos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 300, // Increased width of the button.
              height: 50, // increased height
              child: ElevatedButton(
                onPressed: () {
                  if (report != null && report!.containsKey('id')) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportDetailPage(report: report!),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Erro ao carregar detalhes da reportagem.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  textStyle:
                      const TextStyle(fontSize: 18), // Increased font size
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
                child: const Text('Ver reportagem'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 300, // Increased width of the button.
              height: 50, // increased height
              child: ElevatedButton(
                onPressed: () {
// Navigate back to the main map screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapZzzPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  textStyle:
                      const TextStyle(fontSize: 18), // Increased font size
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
                child: const Text('voltar ao inicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
