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
    'AIzaSyDAymoAdQKM79yNb7P0ki5KbRKZIOaDbWY'; //  <--- Replace with your actual API key

class CreateReportCameraScreen extends StatefulWidget {
  @override
  _CreateReportCameraScreenState createState() =>
      _CreateReportCameraScreenState();
}

class _CreateReportCameraScreenState extends State<CreateReportCameraScreen>
    with WidgetsBindingObserver {
  late CameraController _cameraController;
  late Future<void> _initializeCameraControllerFuture;
  List<CameraDescription> _cameras = [];
  bool _isAnalyzing = false; // Track image analysis state

  @override
  void initState() {
    super.initState();
    _setupCamera();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Use .value.isInitialized to check if the controller is initialized.
    if (!_cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _setupCamera();
    }
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
          SnackBar(content: Text('Falha ao inicializar a câmera: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<bool> _isImageValidForReport(String imagePath) async {
    try {
      final apiUrl = 'https://image-validation-api.vercel.app/analyze-image';
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final result = data['result']?.toLowerCase()?.trim();
        return result == 'valid';
      } else {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Erro'),
              content: const Text(
                  'Erro ao analisar a imagem. Por favor, tente novamente ou contate o MapaZZZ.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          );
        }
        return false;
      }
    } catch (e, stack) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erro'),
            content: const Text(
                'Erro ao analisar a imagem. Por favor, tente novamente ou contate o MapaZZZ.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
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

  Future<void> _showAnalyzingDialog() async {
    await showDialog(
      context: context,
      barrierDismissible:
          false, // User cannot dismiss the dialog while analyzing
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Analisando Imagem'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Aguarde enquanto a IA analisa a foto...'),
            ],
          ),
        );
      },
    );
  }

  void _showResultDialog(bool isImageValid) {
    String title = isImageValid ? 'Imagem Aceita' : 'Imagem Não Aceita';
    String content = isImageValid
        ? 'A imagem foi aceita. Prossiga para os detalhes da reportagem.'
        : 'A imagem não mostra um problema real de risco. Por favor, tente novamente.';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                if (isImageValid) {
                  //  No need to check mounted here, because the Navigator.pushReplacement will handle the navigation.
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapZzzPage(),
                    ),
                  );
                }
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withOpacity(0.8), // Ensure this is not null
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Tire foto do risco .',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Ensure this is not null
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
                              _showAnalyzingDialog(); // Show dialog
                              try {
                                await _initializeCameraControllerFuture;
                                final image =
                                    await _cameraController.takePicture();
                                bool isImageValid =
                                    await _isImageValidForReport(image.path);

                                Navigator.of(context).pop(); // Dismiss dialog
                                _showResultDialog(
                                    isImageValid); //show result dialog

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
                                Navigator.of(context)
                                    .pop(); // Dismiss dialog on error
                                print('Error taking picture: $e');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Erro ao tirar a foto: $e')),
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
            // Ensure mounted before calling setState
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
                  content: Text(
                      'Nenhum endereço encontrado para a localização selecionada.')),
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
              const SnackBar(content: Text('Falha ao obter o endereço.')));
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
            const SnackBar(content: Text('Falha ao obter o endereço.')));
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
      return Future.error('Os serviços de localização estão desativados.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('As permissões de localização foram negadas');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'As permissões de localização foram negadas permanentemente, não podemos solicitar permissões.');
    }
    return await Geolocator.getCurrentPosition();
  }

  //this is the function that calls the LLM
  Future<int> _analyzeRiskLevel(
      String imageUrl, String title, String description) async {
    try {
      final apiUrl = 'https://risk-level-api.vercel.app/analyze-risk';
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files
          .add(await http.MultipartFile.fromPath('image', widget.imagePath));
      request.fields['title'] = title;
      request.fields['description'] = description;

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        int? riskLevel = data['riskLevel'];
        if (riskLevel != null && riskLevel >= 1 && riskLevel <= 3) {
          return riskLevel;
        } else {
          if (mounted) {
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Erro'),
                content: const Text(
                    'Erro ao analisar o nível de risco. Por favor, tente novamente ou contate o MapaZZZ.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            );
          }
          return 1;
        }
      } else {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Erro'),
              content: const Text(
                  'Erro ao analisar o nível de risco. Por favor, tente novamente ou contate o MapaZZZ.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          );
        }
        return 1;
      }
    } catch (e) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erro'),
            content: const Text(
                'Erro ao analisar o nível de risco. Por favor, tente novamente ou contate o MapaZZZ.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      }
      return 1;
    }
  }

  Future<String> _generateSolution(String title, String description) async {
    final apiUrl =
        'https://solution-by-ai.vercel.app/api/generate-solution'; // Use your deployed endpoint
    try {
      // Read image as base64
      final bytes = await File(widget.imagePath).readAsBytes();
      final imageBase64 = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'description': description,
          'imageBase64': imageBase64,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['solution'] ?? "Não foi possível gerar uma solução.";
      } else {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Erro'),
              content: const Text(
                  'Erro ao gerar solução. Por favor, tente novamente ou contate o MapaZZZ.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          );
        }
        return "Não foi possível gerar uma solução.";
      }
    } catch (e) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erro'),
            content: const Text(
                'Erro ao gerar solução. Por favor, tente novamente ou contate o MapaZZZ.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      }
      return "Não foi possível gerar uma solução.";
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

          final aiSolution = await _generateSolution(
              title, description); // Provide a default value

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
                .update({'points': currentPoints + 10});
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
              'Detalhe o risco e as potenciais\ncausas do risco',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center, //Center the text
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Título',
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
                hintText: 'Um breve detalhe sobre a sua reportagem',
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
      // Remove Scaffold's direct background color, as the body will handle the gradient
      appBar: AppBar(
        backgroundColor: const Color(
            0xFFBE2425), // Darker red for AppBar to blend with gradient top
        elevation: 0, // Removed shadow
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white), // Close icon
          onPressed: () {
            // Navigate back or close the screen
            Navigator.pop(context);
          },
        ),
        title: const Text(''), // Removed title
      ),
      body: Container(
        // Wrap the content in a Container for the gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFBE2425), // Dark Red (top)
              Color(0xFFA6090A), // Even Darker Red (bottom)
            ],
          ),
        ),
        child: Center(
          // Centered the entire content
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20.0), // Added horizontal padding
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Centered content vertically
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Image container to match the illustration
                Container(
                  width: 400, // Adjust size as needed
                  height: 400, // Adjust size as needed
                  // Using a placeholder image for the illustration.
                  // In a real app, you would load your asset image here.
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                          "assets/images/sucess.png"), // Placeholder for the illustration
                      fit: BoxFit.contain,
                    ),
                  ),
                  child: const Align(
                    alignment: Alignment(
                        0.4, -0.8), // Adjust position of the checkmark
                    child: Icon(
                      Icons
                          .check_circle, // Filled checkmark for the illustration
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '+30 pontos', // Changed to +30 pontos
                  style: TextStyle(
                    fontSize: 32, // Increased font size
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Changed text color to white
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Reportagem criada com sucesso!\nForam adicionados 30 pontos à sua carteira.", // Updated message
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal, // Adjusted font weight
                    color: Colors.white, // Changed text color to white
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 300,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (report != null && report!.containsKey('id')) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ReportDetailPage(report: report!),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Erro ao carregar detalhes da reportagem.')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.white, // Changed button background to white
                      foregroundColor: Colors.red, // Changed text color to red
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 14),
                      textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight
                              .bold), // Increased font size and made bold
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                    ),
                    child: const Text('Ver reportagem',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                        )),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 300,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapZzzPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.transparent, // Transparent background
                      foregroundColor: Colors.white, // White text
                      side: const BorderSide(
                          color: Colors.white, width: 2), // White border
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 14),
                      textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight
                              .bold), // Increased font size and made bold
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      elevation: 0, // No shadow for this button
                    ),
                    child: const Text('Voltar ao início',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
