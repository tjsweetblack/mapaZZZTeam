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
  int? _userVote; // Track user's vote
  bool _hasUserConfirmed = false;
  bool _isLoadingConfirmationStatus = true; // Track confirmation loading state
  bool _hasUserResolved = false; // Track if user has reported as resolved
  bool _isLoadingResolvedStatus = true; // Track resolved loading state.

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _checkIfUserConfirmed();
    _checkIfUserResolved();
  }

  Future<void> _fetchUserName() async {
    setState(() {
      _isLoadingUser = true;
      _userName = null;
    });
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.report['userId'])
          .get();
      if (userDoc.exists) {
        setState(() {
          _userName = userDoc.data()?['name'];
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

  Future<void> _checkIfUserConfirmed() async {
    setState(() {
      _isLoadingConfirmationStatus = true;
    });
    final authCubit = context.read<AuthCubit>();
    final userId = authCubit.currentUser?.uid;
    final reportId = widget.report['id'];

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

  Future<void> _checkIfUserResolved() async {
    setState(() {
      _isLoadingResolvedStatus = true;
    });
    final authCubit = context.read<AuthCubit>();
    final userId = authCubit.currentUser?.uid;
    final reportId = widget.report['id'];

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

  Widget _buildVoteButton(int voteValue, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _userVote = voteValue;
            });
            // Implement logic to store the vote in Firebase
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _userVote == voteValue ? Colors.red[100] : Colors.white,
            foregroundColor: Colors.black,
            side: BorderSide(color: Colors.red),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding:
                EdgeInsets.symmetric(vertical: 12), // Adjust vertical padding
          ),
          child: Column(
            children: [
              _buildRiskLevelIcons(voteValue),
              SizedBox(height: 4),
              if (voteValue == 1)
                Text('Baixo')
              else if (voteValue == 2)
                Text('Medio')
              else if (voteValue == 3)
                Text('alto'),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  Future<void> _confirmReport() async {
    if (_hasUserConfirmed) {
      await _showErrorDialog(
          'Já confirmado', 'Você já confirmou esta reportagem.');
      return;
    }

    setState(() {
      _isLoadingConfirmationStatus = true; // Start loading for confirmation
    }); // Show loading indicator
    double reportLatitudes = widget.report['latitude'];
    double reportLongitudes = widget.report['longitude'];
    print('Report Longitude: $reportLongitudes');
    print('Report Latitude: $reportLatitudes');
    print(
        'Report ID being used: ${widget.report['id']}'); // Print the report ID

    try {
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

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      double userLatitude = position.latitude;
      double userLongitude = position.longitude;
      print('User Longitude: $userLongitude');
      print('User Latitude: $userLatitude');

      double reportLatitude = widget.report['latitude'];
      double reportLongitude = widget.report['longitude'];

      double distanceInMeters = _calculateDistance(
          userLatitude, userLongitude, reportLatitude, reportLongitude);

      print('Distance to report: $distanceInMeters meters');

      if (distanceInMeters <= 5) {
        // User is within 5 meters, update NoConfirmation
        try {
          await FirebaseFirestore.instance
              .collection('reports')
              .doc(widget.report['id']) // Assuming 'id' is the document ID
              .update({'NoConfirmation': FieldValue.increment(1)});

          final authCubit = context.read<AuthCubit>();
          final userId = authCubit.currentUser?.uid;
          if (userId != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .update({
              'confirmations': FieldValue.arrayUnion([widget.report['id']])
            });
            setState(() {
              _hasUserConfirmed = true;
            });
          }

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
                .update({'points': currentPoints + 20});
          }

          await _showSuccessDialog('Reportagem confirmada com sucesso!');
        } on FirebaseException catch (e) {
          await _showErrorDialog('Erro ao confirmar no Firestore',
              'Ocorreu um erro ao atualizar o número de confirmações: ${e.message ?? e.code}');
        } catch (e) {
          await _showErrorDialog('Erro inesperado ao confirmar', e.toString());
        }
      } else {
        // User is too far, show error dialog
        await _showErrorDialog('Localização distante',
            'Nao se encontras no local da reportagem. Chegue mais proximo, 5 metros pelo menos de distancia.');
      }
    } catch (locationError) {
      print("Error getting location: $locationError");
      await _showErrorDialog(
          'Erro ao obter localização', locationError.toString());
    } catch (e) {
      print("General error during confirmation: $e");
      await _showErrorDialog('Erro geral ao confirmar', e.toString());
    } finally {
      setState(() => _isLoadingConfirmationStatus =
          false); // Stop loading after completion
    }
  }

  Future<void> _reportAsResolved() async {
    if (_hasUserResolved) {
      await _showErrorDialog('Já reportado como resolvido',
          'Você já reportou esta reportagem como resolvida.');
      return;
    }
    setState(() {
      _isLoadingResolvedStatus = true; // Start loading for resolved action
    });
    double reportLatitudes = widget.report['latitude'];
    double reportLongitudes = widget.report['longitude'];
    print('Report Longitude: $reportLongitudes');
    print('Report Latitude: $reportLatitudes');
    print('Report ID being used: ${widget.report['id']}');

    try {
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

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      double userLatitude = position.latitude;
      double userLongitude = position.longitude;
      print('User Longitude: $userLongitude');
      print('User Latitude: $userLatitude');

      double reportLatitude = widget.report['latitude'];
      double reportLongitude = widget.report['longitude'];

      double distanceInMeters = _calculateDistance(
          userLatitude, userLongitude, reportLatitude, reportLongitude);

      print('Distance to report for resolving: $distanceInMeters meters');

      if (distanceInMeters <= 5) {
        // User is within 5 meters, update NoResolved
        try {
          await FirebaseFirestore.instance
              .collection('reports')
              .doc(widget.report['id'])
              .update({'NoResolved': FieldValue.increment(1)});

          final authCubit = context.read<AuthCubit>();
          final userId = authCubit.currentUser?.uid;
          if (userId != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .update({
              'resolvedReports': FieldValue.arrayUnion([widget.report['id']])
            });
            setState(() {
              _hasUserResolved = true;
            });
          }

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

          await _showSuccessDialog(
              'Reportagem marcada como resolvida com sucesso!');
        } on FirebaseException catch (e) {
          await _showErrorDialog('Erro ao reportar como resolvido no Firestore',
              'Ocorreu um erro ao atualizar o número de confirmações de resolvidos: ${e.message ?? e.code}');
        } catch (e) {
          await _showErrorDialog(
              'Erro inesperado ao reportar como resolvido', e.toString());
        }
      } else {
        // User is too far, show error dialog
        await _showErrorDialog('Localização distante',
            'Nao se encontras no local da reportagem. Chegue mais proximo, 5 metros pelo menos de distancia para reportar como resolvido.');
      }
    } catch (locationError) {
      print("Error getting location: $locationError");
      await _showErrorDialog(
          'Erro ao obter localização', locationError.toString());
    } catch (e) {
      print("General error during reporting as resolved: $e");
      await _showErrorDialog(
          'Erro geral ao reportar como resolvido', e.toString());
    } finally {
      setState(() =>
          _isLoadingResolvedStatus = false); // Stop loading after completion
    }
  }

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
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SuccessScreen(
                            report: widget.report,
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

  _launchGoogleMaps() async {
    final latitude = widget.report['latitude'];
    final longitude = widget.report['longitude'];
    final url =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 43),
            Stack(
              children: [
                Hero(
                  tag: 'reportImage-${widget.report['imageUrl']}',
                  child: Image.network(
                    widget.report['imageUrl'],
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 250,
                        color: Colors.grey[300],
                        child: Center(child: Icon(Icons.image_not_supported)),
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
                    widget.report['title'],
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.report['location'],
                          softWrap: true,
                        ),
                      ),
                      Spacer(),
                    ],
                  ),
                  SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      final String googleMapsUrl =
                          'https://www.google.com/maps/place/${widget.report['latitude']},${widget.report['longitude']}';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              WebViewScreen(googleMapsUrl: googleMapsUrl),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    icon: Icon(Icons.map),
                    label: Text('Ver no mapa'),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Criado por: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: 13),
                      CircleAvatar(
                        radius: 10,
                        backgroundImage: NetworkImage(
                          'https://cdn4.iconfinder.com/data/icons/glyphs/24/icons_user-512.png',
                        ),
                      ),
                      SizedBox(width: 13),
                      _isLoadingUser
                          ? CircularProgressIndicator()
                          : Text(_userName ?? 'Loading...'),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Nível de risco: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      _buildRiskLevelIcons(widget.report['riskLevel'] as int),
                      SizedBox(width: 8),
                      Text(
                          _getRiskLevelText(widget.report['riskLevel'] as int)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.people, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        '${widget.report['NoConfirmation'] ?? 0}',
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
                      Text(
                        '${widget.report['NoResolved'] ?? 0}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Text('Número de confirmações de resolvidos',
                          style: TextStyle(color: Colors.green)),
                    ],
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _hasUserConfirmed ? null : _confirmReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _hasUserConfirmed ? Colors.red[100] : Colors.white,
                      foregroundColor: Colors.black,
                      side: BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        _isLoadingConfirmationStatus // Use loading state here
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.red),
                                ),
                              )
                            : Text(_hasUserConfirmed
                                ? 'Já Confirmado'
                                : 'Confirmar reportagem'),
                  ),
                  SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LocatorScreen(
                            reportLatitude: widget.report['latitude'],
                            reportLongitude: widget.report['longitude'],
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.explore),
                    label: Text('Abrir Localizador',
                        style: TextStyle(fontSize: 16)),
                  ),
                  SizedBox(height: 16),
                  Text('Descrição:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(widget.report['description'] ??
                      'No description provided.'),
                  SizedBox(height: 16),
                  Text('Solução criada por IA:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(widget.report['solutionAi'] ?? 'No solution provided.'),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hasUserResolved ? null : _reportAsResolved,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _hasUserResolved ? Colors.green[100] : Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoadingResolvedStatus // Use loading state here
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _hasUserResolved
                                  ? 'Reportado como Resolvido'
                                  : 'Reportar como resolvido',
                              style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
