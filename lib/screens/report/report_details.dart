import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReportDetailPage extends StatefulWidget {
  final Map<String, dynamic> report;

  ReportDetailPage({required this.report});

  @override
  _ReportDetailPageState createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  String? _userName;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
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
          _userName = userDoc
              .data()?['name']; // Assuming 'name' is the field for user's name
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
                  tag:
                      'reportImage-${widget.report['imageUrl']}', // Unique tag for hero animation
                  child: Image.network(
                    widget.report['imageUrl'],
                    width: double.infinity,
                    height: 250, // Adjust height as needed
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
                    radius: 18, // Adjust radius as needed
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      iconSize: 20, // Adjust icon size if needed
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
                      Text(widget.report['location']),
                      Spacer(),
                      TextButton(
                        onPressed: () {
                          // Implement "Ver no mapa" functionality
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: Text('Ver no mapa'),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Criado por: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
                  // SizedBox(height: 8),
                  // Text('45 confirmações', style: TextStyle(fontWeight: FontWeight.bold)), // Confirmation count not in provided fields
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Implement "Confirmar reportagem" functionality
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Confirmar reportagem'),
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
                      onPressed: () {
                        // Implement "Reportar como resolvido" functionality
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Reportar como resolvido',
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
