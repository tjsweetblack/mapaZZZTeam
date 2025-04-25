import 'package:auth_bloc/logic/cubit/auth_cubit.dart';
import 'package:auth_bloc/screens/main_screen.dart';
import 'package:auth_bloc/screens/report/locator_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ReportDetailPage extends StatefulWidget {
  final Map<String, dynamic> report;

  ReportDetailPage({required this.report});

  @override
  _ReportDetailPageState createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  String? _userName;
  bool _isLoadingUser = true;
  // Removed _userVote as it wasn't fully implemented and seems out of scope for this request
  bool _hasUserConfirmed = false;
  bool _isLoadingConfirmationStatus = true; // Track confirmation loading state
  bool _hasUserResolved = false; // Track if user has reported as resolved
  bool _isLoadingResolvedStatus = true; // Track resolved loading state.

  // Stream for the specific report document to get real-time updates
  late final Stream<DocumentSnapshot> _reportStream;

  @override
  void initState() {
    super.initState();
    // Initialize the stream to listen to changes on the specific report document
    _reportStream = FirebaseFirestore.instance
        .collection('reports')
        .doc(widget.report[
            'id']) // Listen to the specific report document using its ID
        .snapshots(); // Get a stream of snapshots (real-time updates)

    // Fetch initial data that doesn't change frequently or is user-specific
    _fetchUserName();
    _checkIfUserConfirmed(); // Check if the current user has already confirmed this report
    _checkIfUserResolved(); // Check if the current user has already marked this report as resolved
  }

  // Fetches the name of the user who created the report
  Future<void> _fetchUserName() async {
    setState(() {
      _isLoadingUser = true;
      _userName = null;
    });
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.report['userId']) // Use the userId from the report data
          .get();
      if (userDoc.exists) {
        setState(() {
          _userName = userDoc.data()?['name']; // Get the user's name
          _isLoadingUser = false;
        });
      } else {
        setState(() {
          _userName = 'Unknown User';
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      print("Error fetching user name: $e");
      setState(() {
        _userName = 'Error Loading User';
        _isLoadingUser = false;
      });
    }
  }

  // Checks if the current authenticated user has already confirmed this report
  Future<void> _checkIfUserConfirmed() async {
    setState(() {
      _isLoadingConfirmationStatus = true;
    });
    final authCubit = context.read<AuthCubit>();
    final userId = authCubit.currentUser?.uid; // Get the current user's ID
    final reportId = widget.report['id']; // Get the ID of the current report

    if (userId != null && reportId != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && userData.containsKey('confirmations')) {
            final confirmations = userData['confirmations'] as List<dynamic>?;
            // Check if the reportId is in the user's list of confirmed reports
            if (confirmations != null && confirmations.contains(reportId)) {
              setState(() {
                _hasUserConfirmed = true;
              });
            }
          }
        }
      } catch (e) {
        print("Error checking confirmation status: $e");
      } finally {
        setState(() {
          _isLoadingConfirmationStatus = false;
        });
      }
    } else {
      setState(() {
        _isLoadingConfirmationStatus = false;
      });
    }
  }

  // Checks if the current authenticated user has already marked this report as resolved
  Future<void> _checkIfUserResolved() async {
    setState(() {
      _isLoadingResolvedStatus = true;
    });
    final authCubit = context.read<AuthCubit>();
    final userId = authCubit.currentUser?.uid; // Get the current user's ID
    final reportId = widget.report['id']; // Get the ID of the current report

    if (userId != null && reportId != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && userData.containsKey('resolvedReports')) {
            final resolvedReports =
                userData['resolvedReports'] as List<dynamic>?;
            // Check if the reportId is in the user's list of resolved reports
            if (resolvedReports != null && resolvedReports.contains(reportId)) {
              setState(() {
                _hasUserResolved = true;
              });
            }
          }
        }
      } catch (e) {
        print("Error checking resolved status: $e");
      } finally {
        setState(() {
          _isLoadingResolvedStatus = false;
        });
      }
    } else {
      setState(() {
        _isLoadingResolvedStatus = false;
      });
    }
  }

  // Returns the text representation of the risk level
  String _getRiskLevelText(int riskLevel) {
    switch (riskLevel) {
      case 1:
        return 'Baixo';
      case 2:
        return 'Médio';
      case 3:
        return 'Alto';
      case 4:
        return 'Muito Alto';
      default:
        return 'Desconhecido';
    }
  }

  // Builds the icon representation of the risk level
  Widget _buildRiskLevelIcons(int riskLevel) {
    Icon levelIcon =
        Icon(Icons.signal_cellular_alt_1_bar_sharp, color: Colors.red);
    if (riskLevel == 1) {
      levelIcon =
          Icon(Icons.signal_cellular_alt_1_bar_sharp, color: Colors.red);
    } else if (riskLevel == 2) {
      levelIcon =
          Icon(Icons.signal_cellular_alt_2_bar_sharp, color: Colors.red);
    } else if (riskLevel == 3) {
      levelIcon = Icon(Icons.signal_cellular_alt_sharp, color: Colors.red);
    } else if (riskLevel == 4) {
      levelIcon = Icon(Icons.signal_cellular_alt, color: Colors.red);
    }
    return levelIcon;
  }

  // Removed _buildVoteButton as it's not directly related to the request for counts

  // Calculates the distance between two geographic points
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Handles the logic for confirming a report
  Future<void> _confirmReport() async {
    // Prevent confirmation if the user has already confirmed
    if (_hasUserConfirmed) {
      await _showErrorDialog(
          'Já confirmado', 'Você já confirmou esta reportagem.');
      return;
    }

    setState(() {
      _isLoadingConfirmationStatus =
          true; // Show loading indicator for confirmation
    });

    try {
      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          await _showErrorDialog('Permissão de localização negada',
              'Por favor, habilite a permissão de localização para confirmar a reportagem.');
          setState(() =>
              _isLoadingConfirmationStatus = false); // Stop loading on error
          return;
        }
      }
      // Handle permanently denied permission
      if (permission == LocationPermission.deniedForever) {
        await _showErrorDialog(
            'Permissão de localização permanentemente negada',
            'A permissão de localização foi permanentemente negada. Por favor, vá para as configurações do seu dispositivo para habilitá-la.');
        setState(() =>
            _isLoadingConfirmationStatus = false); // Stop loading on error
        return;
      }

      // Get the user's current location
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      double userLatitude = position.latitude;
      double userLongitude = position.longitude;

      // Get the report's location
      double reportLatitude = widget.report['latitude'];
      double reportLongitude = widget.report['longitude'];

      // Calculate the distance between the user and the report location
      double distanceInMeters = _calculateDistance(
          userLatitude, userLongitude, reportLatitude, reportLongitude);

      print('Distance to report: $distanceInMeters meters');

      // Check if the user is within the allowed distance (5 meters)
      if (distanceInMeters <= 5) {
        // User is within 5 meters, proceed with updating Firestore
        final reportDocRef = FirebaseFirestore.instance
            .collection('reports')
            .doc(widget.report['id']); // Reference to the report document

        final authCubit = context.read<AuthCubit>();
        final userId = authCubit.currentUser?.uid; // Get the current user's ID

        if (userId != null) {
          final userDocRef = FirebaseFirestore.instance
              .collection('users')
              .doc(userId); // Reference to the user document

          try {
            // Use a Firestore transaction to perform atomic updates
            await FirebaseFirestore.instance
                .runTransaction((transaction) async {
              // Get the current report document snapshot within the transaction
              DocumentSnapshot reportSnapshot =
                  await transaction.get(reportDocRef);

              if (!reportSnapshot.exists) {
                throw Exception("Report does not exist!");
              }

              // Get the current user document snapshot within the transaction
              DocumentSnapshot userSnapshot = await transaction.get(userDocRef);

              if (!userSnapshot.exists) {
                throw Exception("User does not exist!");
              }

              // Double-check if user has already confirmed within the transaction
              final userData = userSnapshot.data() as Map<String, dynamic>?;
              final confirmations =
                  userData?['confirmations'] as List<dynamic>? ?? [];
              if (confirmations.contains(widget.report['id'])) {
                // If already confirmed, throw an exception to roll back the transaction
                throw Exception("User has already confirmed this report.");
              }

              // Update the report's NoConfirmation count by incrementing
              int currentConfirmations = (reportSnapshot.data()
                      as Map<String, dynamic>)?['NoConfirmation'] ??
                  0;
              transaction.update(
                  reportDocRef, {'NoConfirmation': currentConfirmations + 1});

              // Add the report ID to the user's list of confirmed reports using arrayUnion
              transaction.update(userDocRef, {
                'confirmations': FieldValue.arrayUnion([widget.report['id']])
              });

              // Update user points by adding 20
              int currentPoints = userData?['points'] ?? 0;
              transaction.update(userDocRef, {'points': currentPoints + 20});
            });

            // If the transaction completes successfully
            setState(() {
              _hasUserConfirmed =
                  true; // Update local state to disable the button
            });

            await _showSuccessDialog('Reportagem confirmada com sucesso!');
          } on FirebaseException catch (e) {
            // Handle Firestore specific errors during the transaction
            await _showErrorDialog('Erro ao confirmar no Firestore',
                'Ocorreu um erro ao atualizar o número de confirmações: ${e.message ?? e.code}');
          } catch (e) {
            // Catch other exceptions, including the one thrown for already confirmed
            if (e.toString().contains("User has already confirmed")) {
              await _showErrorDialog(
                  'Já confirmado', 'Você já confirmou esta reportagem.');
            } else if (e.toString().contains("Report does not exist")) {
              await _showErrorDialog('Reportagem não encontrada',
                  'A reportagem que você tentou confirmar não existe mais.');
            } else {
              print("Error during confirmation transaction: $e");
              await _showErrorDialog(
                  'Erro inesperado ao confirmar', e.toString());
            }
          }
        } else {
          // Handle case where user is not logged in (should be protected by auth flow)
          await _showErrorDialog('Erro', 'Usuário não autenticado.');
        }
      } else {
        // User is too far from the report location
        await _showErrorDialog('Localização distante',
            'Nao se encontras no local da reportagem. Chegue mais proximo, 5 metros pelo menos de distancia.');
      }
    } catch (locationError) {
      // Handle errors related to getting the user's location
      print("Error getting location: $locationError");
      await _showErrorDialog(
          'Erro ao obter localização', locationError.toString());
    } catch (e) {
      // Handle any other general errors
      print("General error during confirmation: $e");
      await _showErrorDialog('Erro geral ao confirmar', e.toString());
    } finally {
      setState(() => _isLoadingConfirmationStatus =
          false); // Hide loading indicator after completion (success or error)
    }
  }

  // Handles the logic for reporting a report as resolved
  Future<void> _reportAsResolved() async {
    // Prevent marking as resolved if the user has already done so
    if (_hasUserResolved) {
      await _showErrorDialog('Já reportado como resolvido',
          'Você já reportou esta reportagem como resolvida.');
      return;
    }
    setState(() {
      _isLoadingResolvedStatus =
          true; // Show loading indicator for resolved action
    });

    try {
      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          await _showErrorDialog('Permissão de localização negada',
              'Por favor, habilite a permissão de localização para reportar como resolvido.');
          setState(
              () => _isLoadingResolvedStatus = false); // Stop loading on error
          return;
        }
      }
      // Handle permanently denied permission
      if (permission == LocationPermission.deniedForever) {
        await _showErrorDialog(
            'Permissão de localização permanentemente negada',
            'A permissão de localização foi permanentemente negada. Por favor, vá para as configurações do seu dispositivo para habilitá-la.');
        setState(
            () => _isLoadingResolvedStatus = false); // Stop loading on error
        return;
      }

      // Get the user's current location
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      double userLatitude = position.latitude;
      double userLongitude = position.longitude;

      // Get the report's location
      double reportLatitude = widget.report['latitude'];
      double reportLongitude = widget.report['longitude'];

      // Calculate the distance between the user and the report location
      double distanceInMeters = _calculateDistance(
          userLatitude, userLongitude, reportLatitude, reportLongitude);

      print('Distance to report for resolving: $distanceInMeters meters');

      // Check if the user is within the allowed distance (5 meters)
      if (distanceInMeters <= 5) {
        // User is within 5 meters, proceed with updating Firestore
        final reportDocRef = FirebaseFirestore.instance
            .collection('reports')
            .doc(widget.report['id']); // Reference to the report document

        final authCubit = context.read<AuthCubit>();
        final userId = authCubit.currentUser?.uid; // Get the current user's ID

        if (userId != null) {
          final userDocRef = FirebaseFirestore.instance
              .collection('users')
              .doc(userId); // Reference to the user document

          try {
            // Use a Firestore transaction to perform atomic updates
            await FirebaseFirestore.instance
                .runTransaction((transaction) async {
              // Get the current report document snapshot within the transaction
              DocumentSnapshot reportSnapshot =
                  await transaction.get(reportDocRef);

              if (!reportSnapshot.exists) {
                throw Exception("Report does not exist!");
              }

              // Get the current user document snapshot within the transaction
              DocumentSnapshot userSnapshot = await transaction.get(userDocRef);

              if (!userSnapshot.exists) {
                throw Exception("User does not exist!");
              }

              // Double-check if user has already reported as resolved within the transaction
              final userData = userSnapshot.data() as Map<String, dynamic>?;
              final resolvedReports =
                  userData?['resolvedReports'] as List<dynamic>? ?? [];
              if (resolvedReports.contains(widget.report['id'])) {
                // If already reported as resolved, throw an exception
                throw Exception(
                    "User has already reported this report as resolved.");
              }

              // Update the report's NoResolved count by incrementing
              int currentResolved = (reportSnapshot.data()
                      as Map<String, dynamic>)?['NoResolved'] ??
                  0;
              transaction
                  .update(reportDocRef, {'NoResolved': currentResolved + 1});

              // Add the report ID to the user's list of resolved reports using arrayUnion
              transaction.update(userDocRef, {
                'resolvedReports': FieldValue.arrayUnion([widget.report['id']])
              });

              // Update user points by adding 10
              int currentPoints = userData?['points'] ?? 0;
              transaction.update(userDocRef, {'points': currentPoints + 10});
            });

            // If the transaction completes successfully
            setState(() {
              _hasUserResolved =
                  true; // Update local state to disable the button
            });

            await _showSuccessDialog(
                'Reportagem marcada como resolvida com sucesso!');
          } on FirebaseException catch (e) {
            // Handle Firestore specific errors during the transaction
            await _showErrorDialog(
                'Erro ao reportar como resolvido no Firestore',
                'Ocorreu um erro ao atualizar o número de confirmações de resolvidos: ${e.message ?? e.code}');
          } catch (e) {
            // Catch other exceptions, including the one thrown for already resolved
            if (e.toString().contains("User has already reported")) {
              await _showErrorDialog('Já reportado como resolvido',
                  'Você já reportou esta reportagem como resolvida.');
            } else if (e.toString().contains("Report does not exist")) {
              await _showErrorDialog('Reportagem não encontrada',
                  'A reportagem que você tentou marcar como resolvida não existe mais.');
            } else {
              print("Error during resolved transaction: $e");
              await _showErrorDialog(
                  'Erro inesperado ao reportar como resolvido', e.toString());
            }
          }
        } else {
          // Handle case where user is not logged in
          await _showErrorDialog('Erro', 'Usuário não autenticado.');
        }
      } else {
        // User is too far from the report location
        await _showErrorDialog('Localização distante',
            'Nao se encontras no local da reportagem. Chegue mais proximo, 5 metros pelo menos de distancia para reportar como resolvido.');
      }
    } catch (locationError) {
      // Handle errors related to getting the user's location
      print("Error getting location: $locationError");
      await _showErrorDialog(
          'Erro ao obter localização', locationError.toString());
    } catch (e) {
      // Handle any other general errors
      print("General error during reporting as resolved: $e");
      await _showErrorDialog(
          'Erro geral ao reportar como resolvido', e.toString());
    } finally {
      setState(() => _isLoadingResolvedStatus =
          false); // Hide loading indicator after completion
    }
  }

  // Shows an error dialog
  Future<void> _showErrorDialog(String title, String message) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  // Shows a success dialog and navigates to the SuccessScreen
  Future<void> _showSuccessDialog(String message) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sucesso'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                // Close the dialog first
                Navigator.of(context).pop();
                // Then navigate to the SuccessScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SuccessScreen(
                            report:
                                widget.report, // Pass the original report map
                            message: message,
                          )),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Launches Google Maps to show the report location
  _launchGoogleMaps() async {
    final latitude = widget.report['latitude'];
    final longitude = widget.report['longitude'];
    // Construct a standard Google Maps URL for viewing a point
    final url =
        'https://maps.google.com/?q=$latitude,$longitude'; // Standard format for viewing a point
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Handle error if Google Maps cannot be launched
      print('Could not launch $url');
      await _showErrorDialog(
          'Erro ao abrir o mapa', 'Não foi possível abrir o Google Maps.');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use StreamBuilder to listen for real-time updates to the report document
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _reportStream, // The stream providing report document updates
        builder: (context, snapshot) {
          // --- Handle different connection states ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading indicator while waiting for the initial data
            return Center(child: CircularProgressIndicator());
          }

          // Handle errors during data fetching
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Handle case where the document doesn't exist or has no data
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Reportagem não encontrada.'));
          }

          // --- Data is available, extract and display ---
          // Get the latest data from the stream snapshot
          final latestReportData =
              snapshot.data!.data() as Map<String, dynamic>?;

          // Handle case where data is null (shouldn't happen if exists is true, but for safety)
          if (latestReportData == null) {
            return Center(child: Text('Dados da reportagem inválidos.'));
          }

          // Extract the dynamic fields that update in real-time
          final currentNoConfirmation = latestReportData['NoConfirmation'] ?? 0;
          final currentNoResolved = latestReportData['NoResolved'] ?? 0;
          // Assuming risk level is static, but using latest data if it could change
          final currentRiskLevel = latestReportData['riskLevel'] as int? ?? 1;

          // Build the UI using the latest data
          return SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: 43),
                Stack(
                  children: [
                    Hero(
                      // Ensure imageUrl is not null, provide fallback
                      tag: 'reportImage-${widget.report['imageUrl']}',
                      child: Image.network(
                        widget.report['imageUrl'] ??
                            'https://via.placeholder.com/150',
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 250,
                            color: Colors.grey[300],
                            child:
                                Center(child: Icon(Icons.image_not_supported)),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 18,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          iconSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.report['title'] ?? 'No Title', // Use fallback
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.red),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.report['location'] ??
                                  'No Location', // Use fallback
                              softWrap: true,
                            ),
                          ),
                          Spacer(),
                        ],
                      ),
                      SizedBox(height: 8),
                      // Button to view location on map (using WebView)
                      TextButton.icon(
                        onPressed: () {
                          // Use the coordinates from the original widget.report map
                          // as they are static report creation data.
                          final double? latitude = widget.report['latitude'];
                          final double? longitude = widget.report['longitude'];

                          if (latitude != null && longitude != null) {
                            // Construct a standard Google Maps URL for a marker
                            final String googleMapsUrl =
                                'https://maps.google.com/?q=$latitude,$longitude';
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    WebViewScreen(googleMapsUrl: googleMapsUrl),
                              ),
                            );
                          } else {
                            _showErrorDialog('Erro',
                                'Coordenadas da reportagem não disponíveis.');
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        icon: Icon(Icons.map),
                        label: Text('Ver no mapa'),
                      ),
                      // Optional: Button to launch native Google Maps app
                      // TextButton.icon(
                      //   onPressed: _launchGoogleMaps,
                      //   style: TextButton.styleFrom(
                      //     foregroundColor: Colors.red,
                      //   ),
                      //   icon: Icon(Icons.map),
                      //   label: Text('Abrir no Google Maps App'), // Different label
                      // ),

                      SizedBox(height: 16),
                      Row(
                        children: [
                          Text('Criado por: ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 13),
                          CircleAvatar(
                            radius: 10,
                            backgroundImage: NetworkImage(
                              'https://cdn4.iconfinder.com/data/icons/glyphs/24/icons_user-512.png', // Consider a default user avatar or load from user profile if available
                            ),
                          ),
                          SizedBox(width: 13),
                          _isLoadingUser
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ))
                              : Text(_userName ?? 'Loading...'),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Nível de risco: ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          // Use the latest risk level from the stream if it could change, otherwise use the initial one
                          // Assuming risk level is static after report creation, using widget.report['riskLevel'] is fine,
                          // but using currentRiskLevel from the stream is safer if it *might* change.
                          _buildRiskLevelIcons(currentRiskLevel),
                          SizedBox(width: 8),
                          Text(_getRiskLevelText(currentRiskLevel)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.people, color: Colors.grey),
                          SizedBox(width: 4),
                          // Display the real-time confirmation count from the stream
                          Text(
                            '$currentNoConfirmation',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 8),
                          Text('Número de confirmações',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.people, color: Colors.green),
                          SizedBox(width: 4),
                          // Display the real-time resolved count from the stream
                          Text(
                            '$currentNoResolved',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 8),
                          Text('Número de confirmações de resolvidos',
                              style: TextStyle(color: Colors.green)),
                        ],
                      ),
                      SizedBox(height: 16),
                      // Confirmation Button
                      ElevatedButton(
                        // Button is disabled if the user has already confirmed (_hasUserConfirmed)
                        onPressed: _hasUserConfirmed ? null : _confirmReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasUserConfirmed
                              ? Colors.red[100]
                              : Colors.white,
                          foregroundColor: Colors.black,
                          side: BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child:
                            // Show loading indicator while confirmation is in progress
                            _isLoadingConfirmationStatus
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.red),
                                    ),
                                  )
                                : Text(_hasUserConfirmed
                                    ? 'Já Confirmado' // Button text changes if confirmed
                                    : 'Confirmar reportagem'),
                      ),
                      SizedBox(height: 8),
                      // Locator Button
                      TextButton.icon(
                        onPressed: () {
                          // Use the coordinates from the original widget.report map
                          final double? latitude = widget.report['latitude'];
                          final double? longitude = widget.report['longitude'];

                          if (latitude != null && longitude != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LocatorScreen(
                                  reportLatitude: latitude,
                                  reportLongitude: longitude,
                                ),
                              ),
                            );
                          } else {
                            _showErrorDialog('Erro',
                                'Coordenadas da reportagem não disponíveis.');
                          }
                        },
                        icon: Icon(Icons.explore),
                        label: Text('Abrir Localizador',
                            style: TextStyle(fontSize: 16)),
                      ),
                      SizedBox(height: 16),
                      Text('Descrição:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      // Use description from latest data, fall back to initial or default
                      Text(latestReportData['description'] ??
                          widget.report['description'] ??
                          'No description provided.'),
                      SizedBox(height: 16),
                      Text('Solução criada por IA:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      // Use solution from latest data, fall back to initial or default
                      Text(latestReportData['solutionAi'] ??
                          widget.report['solutionAi'] ??
                          'No solution provided.'),
                      SizedBox(height: 24),
                      // Report as Resolved Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          // Button is disabled if the user has already reported as resolved (_hasUserResolved)
                          onPressed:
                              _hasUserResolved ? null : _reportAsResolved,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasUserResolved
                                ? Colors.green[100]
                                : Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child:
                              // Show loading indicator while resolved action is in progress
                              _isLoadingResolvedStatus
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Text(
                                      _hasUserResolved
                                          ? 'Reportado como Resolvido' // Button text changes if resolved
                                          : 'Reportar como resolvido',
                                      style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SuccessScreen extends StatelessWidget {
  final Map<String, dynamic>? report; // Receive the report data
  final String message;

  SuccessScreen({this.report, required this.message});

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
              message,
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
                  '20 pontos',
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

class WebViewScreen extends StatefulWidget {
  final String googleMapsUrl;

  const WebViewScreen({super.key, required this.googleMapsUrl});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.googleMapsUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('localizacao da reportagem'),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
