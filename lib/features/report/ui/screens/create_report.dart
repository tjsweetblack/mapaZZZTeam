import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:auth_bloc/features/map/ui/screens/main_screen.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auth_bloc/features/report/ui/screens/report_details.dart';

const _kPhotoAnalysisConsentKey = 'report_photo_ai_consent_accepted_v1';

enum LoadingStage {
  uploadingImage,
  analyzingRisk,
  generatingSolution,
  addingPoints,
  success,
}

class CreateReportCameraScreen extends StatefulWidget {
  @override
  _CreateReportCameraScreenState createState() =>
      _CreateReportCameraScreenState();
}

class _CreateReportCameraScreenState extends State<CreateReportCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  Future<void>? _initializeCameraControllerFuture;
  List<CameraDescription> _cameras = [];
  bool _isAnalyzing = false; // Track image analysis state

  @override
  void initState() {
    super.initState();
    _ensurePhotoAnalysisConsent();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Use .value.isInitialized to check if the controller is initialized.
    if (_cameraController?.value.isInitialized != true) {
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cameraController?.dispose();
      _cameraController = null;
      _initializeCameraControllerFuture = null;
    } else if (state == AppLifecycleState.resumed) {
      _setupCamera();
    }
  }

  // Ensures the user has explicitly acknowledged, at least once, that report
  // photos are sent to third-party AI services (Google Gemini) for automated
  // analysis before the camera is engaged. This is the in-app consent/notice
  // step required alongside the OS-level camera permission prompt.
  Future<void> _ensurePhotoAnalysisConsent() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final alreadyAccepted = prefs.getBool(_kPhotoAnalysisConsentKey) ?? false;
    if (alreadyAccepted) {
      _setupCamera();
      return;
    }
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Análise da foto por IA'),
        content: const SingleChildScrollView(
          child: Text(
            'A foto que vai tirar é enviada de forma segura (HTTPS) a serviços de '
            'inteligência artificial de terceiros (Google Gemini) para verificar e '
            'classificar automaticamente o risco de foco de mosquitos.\n\n'
            'A foto e a localização ficam associadas ao seu reporte. Só continue se '
            'concordar com este processamento.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Concordo e continuar'),
          ),
        ],
      ),
    );
    if (accepted == true) {
      await prefs.setBool(_kPhotoAnalysisConsentKey, true);
      if (mounted) _setupCamera();
    } else if (mounted) {
      Navigator.of(context).pop();
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

      // Dispose existing controller if any
      await _cameraController?.dispose();

      _cameraController = CameraController(
        _cameras.first, // Get a specific camera from the list
        ResolutionPreset.high, // Set the resolution
      );
      _initializeCameraControllerFuture = _cameraController!.initialize();
      await _initializeCameraControllerFuture!; // Ensure initialization completes.

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
    _cameraController?.dispose();
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
    } catch (e) {
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
          if (snapshot.connectionState == ConnectionState.done &&
              _cameraController != null &&
              _cameraController!.value.isInitialized) {
            // Camera initialized, display the preview
            return Stack(
              children: [
                CameraPreview(_cameraController!),
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
                                //_isAnalyzing = true;
                              });
                              _showAnalyzingDialog(); // Show dialog
                              try {
                                await _initializeCameraControllerFuture;
                                if (_cameraController == null) {
                                  throw Exception('Camera not initialized');
                                }
                                final image =
                                    await _cameraController!.takePicture();
                                bool isImageValid =
                                    await _isImageValidForReport(image.path);

                                Navigator.of(context).pop(); // Dismiss dialog
                                //show result dialog

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
          } else {
            // Show nothing while camera is loading or if there's an error
            return Container(
              color: Colors.black,
              child: const SizedBox.expand(),
            );
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
  bool _isUploading = false;
  String _shippingAddress = ''; // To store the fetched address
  bool _isCreatingReport = false; // To track report creation process
  final GlobalKey<_CreateReportLoadingDialogState> _loadingDialogKey =
      GlobalKey<_CreateReportLoadingDialogState>();

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

//   Future<String?> _getCurrentLocationName(
//       double latitude, double longitude) async {
//     try {
//       final response = await http.get(Uri.parse(
//           'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$latitude&lon=$longitude&addressdetails=1'));
//       if (response.statusCode == 200) {
//         final decodedResponse = jsonDecode(response.body);
//         print("Nominatim API decodedResponse: $decodedResponse");
//         if (decodedResponse != null &&
//             decodedResponse['display_name'] != null) {
//           // <-- Check for display_name
//           setState(() {
//             // Ensure mounted before calling setState
//             _shippingAddress = decodedResponse[
//                 'display_name']; // <-- Use display_name directly
//             print(
//                 "Shipping address set to: $_shippingAddress"); // Log shipping address
//           });
//           return _shippingAddress;
//         } else {
//           print(
//               "Nominatim API: No address details found in response (inside IF condition)");
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                   content: Text(
//                       'Nenhum endereço encontrado para a localização selecionada.')),
//             );
//           }
//           setState(() {
//             _shippingAddress = '';
//           });
//           return null;
//         }
//       } else {
// // Handle API error (e.g., show an error message)
//         print(
//             "Nominatim API request failed with status: ${response.statusCode}");
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Falha ao obter o endereço.')));
//         }

//         setState(() {
//           _shippingAddress = '';
//         });
//         return null;
//       }
//     } catch (e) {
// // Handle any exceptions (e.g., network issues)
//       print("Error fetching address: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Falha ao obter o endereço.')));
//       }
//       setState(() {
//         _shippingAddress = '';
//       });
//       return null;
//     }
//   }

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

  void _showCreatingReportDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _CreateReportLoadingDialog(key: _loadingDialogKey);
      },
    );
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

    // Show the loading dialog
    _showCreatingReportDialog();

    try {
      // Stage 1: Upload image
      _updateLoadingStage(context, LoadingStage.uploadingImage);
      String? imageUrl = await _uploadImageToCloudinary(widget.imagePath);

      if (imageUrl != null) {
        Position position = await _getCurrentPosition();
        String? userId = FirebaseAuth.instance.currentUser?.uid;

        if (userId != null) {
          // Stage 2: Analyze risk level
          _updateLoadingStage(context, LoadingStage.analyzingRisk);
          int riskLevel = await _analyzeRiskLevel(imageUrl, title, description);

          // Stage 3: Generate AI solution
          _updateLoadingStage(context, LoadingStage.generatingSolution);
          final aiSolution = await _generateSolution(title, description);

          // Stage 4: Adding points
          _updateLoadingStage(context, LoadingStage.addingPoints);

          // Create the report and get the DocumentReference
          DocumentReference reportRef =
              await FirebaseFirestore.instance.collection('reports').add({
            'NoConfirmation': 0,
            'description': description,
            'imageUrl': imageUrl,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'riskLevel': riskLevel,
            'solutionAi': aiSolution,
            'status': 'active',
            'title': title,
            'userId': userId,
          });

          String reportId = reportRef.id;
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

          // Stage 5: Success
          _updateLoadingStage(context, LoadingStage.success);

          // Wait a moment to show success state
          await Future.delayed(const Duration(seconds: 1));

          setState(() {
            _isCreatingReport = false;
          });

          // Fetch the newly created report data
          DocumentSnapshot<Map<String, dynamic>> newReportSnapshot =
              await reportRef.get() as DocumentSnapshot<Map<String, dynamic>>;

          Map<String, dynamic>? reportDataWithId = newReportSnapshot.data();
          if (reportDataWithId != null) {
            reportDataWithId['id'] = newReportSnapshot.id;
          }

          // Close the loading dialog
          Navigator.of(context).pop();

          // Navigate to success screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CreateReportSuccessScreen(report: reportDataWithId),
            ),
          );
        } else {
          setState(() {
            _isCreatingReport = false;
          });
          Navigator.of(context).pop(); // Close loading dialog
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
        Navigator.of(context).pop(); // Close loading dialog
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
      Navigator.of(context).pop(); // Close loading dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ocorreu um erro ao criar a reportagem: $e')),
        );
      }
    }
  }

  void _updateLoadingStage(BuildContext context, LoadingStage stage) {
    // Update the dialog state using the GlobalKey
    _loadingDialogKey.currentState?.updateStage(stage);
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
                child: const Text('Completar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Beautiful Loading Dialog Widget
class _CreateReportLoadingDialog extends StatefulWidget {
  const _CreateReportLoadingDialog({Key? key}) : super(key: key);

  @override
  _CreateReportLoadingDialogState createState() =>
      _CreateReportLoadingDialogState();
}

class _CreateReportLoadingDialogState extends State<_CreateReportLoadingDialog>
    with SingleTickerProviderStateMixin {
  LoadingStage _currentStage = LoadingStage.uploadingImage;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void updateStage(LoadingStage stage) {
    if (mounted) {
      setState(() {
        _currentStage = stage;
      });
    }
  }

  String _getStageTitle() {
    switch (_currentStage) {
      case LoadingStage.uploadingImage:
        return 'Enviando imagem...';
      case LoadingStage.analyzingRisk:
        return 'Analisando nível de risco...';
      case LoadingStage.generatingSolution:
        return 'Gerando solução por IA...';
      case LoadingStage.addingPoints:
        return 'Adicionando 30 pontos...';
      case LoadingStage.success:
        return 'Reportagem criada!';
    }
  }

  String _getStageDescription() {
    switch (_currentStage) {
      case LoadingStage.uploadingImage:
        return 'Preparando sua evidência fotográfica';
      case LoadingStage.analyzingRisk:
        return 'IA avaliando a gravidade do risco';
      case LoadingStage.generatingSolution:
        return 'Criando recomendações personalizadas';
      case LoadingStage.addingPoints:
        return 'Recompensando sua contribuição';
      case LoadingStage.success:
        return 'Tudo pronto! Parabéns pela contribuição';
    }
  }

  IconData _getStageIcon() {
    switch (_currentStage) {
      case LoadingStage.uploadingImage:
        return Icons.cloud_upload_outlined;
      case LoadingStage.analyzingRisk:
        return Icons.analytics_outlined;
      case LoadingStage.generatingSolution:
        return Icons.lightbulb_outline;
      case LoadingStage.addingPoints:
        return Icons.stars_outlined;
      case LoadingStage.success:
        return Icons.check_circle_outline;
    }
  }

  Color _getStageColor() {
    switch (_currentStage) {
      case LoadingStage.uploadingImage:
        return Colors.blue;
      case LoadingStage.analyzingRisk:
        return Colors.orange;
      case LoadingStage.generatingSolution:
        return Colors.purple;
      case LoadingStage.addingPoints:
        return Colors.amber;
      case LoadingStage.success:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              _getStageColor().withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Icon
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getStageColor().withOpacity(0.8),
                      _getStageColor(),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getStageColor().withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _getStageIcon(),
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Stage Title
            Text(
              _getStageTitle(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _getStageColor(),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Stage Description
            Text(
              _getStageDescription(),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Progress Indicator or Success Check
            if (_currentStage != LoadingStage.success)
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_getStageColor()),
                  strokeWidth: 3,
                ),
              )
            else
              Icon(
                Icons.check_circle,
                size: 40,
                color: _getStageColor(),
              ),
            const SizedBox(height: 20),

            // Progress Steps
            _buildProgressSteps(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSteps() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildProgressDot(LoadingStage.uploadingImage),
        _buildProgressLine(LoadingStage.uploadingImage),
        _buildProgressDot(LoadingStage.analyzingRisk),
        _buildProgressLine(LoadingStage.analyzingRisk),
        _buildProgressDot(LoadingStage.generatingSolution),
        _buildProgressLine(LoadingStage.generatingSolution),
        _buildProgressDot(LoadingStage.addingPoints),
        _buildProgressLine(LoadingStage.addingPoints),
        _buildProgressDot(LoadingStage.success),
      ],
    );
  }

  Widget _buildProgressDot(LoadingStage stage) {
    bool isActive = _currentStage.index >= stage.index;
    bool isCurrent = _currentStage == stage;

    return Container(
      width: isCurrent ? 12 : 8,
      height: isCurrent ? 12 : 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? _getStageColor() : Colors.grey.shade300,
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: _getStageColor().withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
    );
  }

  Widget _buildProgressLine(LoadingStage stage) {
    bool isActive = _currentStage.index > stage.index;

    return Container(
      width: 20,
      height: 2,
      color: isActive ? _getStageColor() : Colors.grey.shade300,
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
