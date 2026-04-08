import 'package:flutter/material.dart';

class RankInfoScreen extends StatelessWidget {
  const RankInfoScreen({Key? key}) : super(key: key);

  // Define the rank information and points breakdown
  final Map<String, dynamic> rankDetails = const {
    'activities': {
      'Reportagens (Reports)': '10 pontos',
      'Confirmação (Confirmations)': '5 pontos',
      'Dar como resolvido (Marking as Resolved)': '15 pontos',
    },
    'ranks': {
      'Novinho (NV)': {
        'points': '0 - 69 pontos',
        'description': 'Junte seus primeiros pontos ao relatar casos.',
        'example': null,
        'image_path': 'assets/images/nv.png',
      },
      'Caçador de Mosquito (CM)': {
        'points': '70 - 149 pontos',
        'description': 'Você está ativamente combatendo mosquitos!',
        'example':
            'Requisitos: 70 pontos (ex.: 7 reportes ou combinação de ações).',
        'image_path': 'assets/images/cm.png',
      },
      'Fiscal Confiável (FC)': {
        'points': '150 - 300 pontos',
        'description':
            'Um contribuidor experiente e confiável para a comunidade.',
        'example':
            'Requisitos: 150 pontos (ex.: 10 reportes + 10 confirmações + 4 resoluções).',
        'image_path': 'assets/images/fc.png',
      },
      'Herói da Comunidade (HC)': {
        'points': '300+ pontos',
        'description':
            'Você é um líder na luta contra mosquitos, salvando vidas!',
        'example':
            'Requisitos: 300 pontos (ex.: 20 reportes + 20 confirmações + 10 resoluções).',
        'image_path': 'assets/images/hc.png',
      },
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Informações de Ranking',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black), // Back arrow color
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pontos por Atividade:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        rankDetails['activities'].entries.map<Widget>((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Níveis de Ranking:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics:
                    NeverScrollableScrollPhysics(), // Disable scrolling for the inner list
                itemCount: rankDetails['ranks'].length,
                itemBuilder: (context, index) {
                  final rankEntry =
                      rankDetails['ranks'].entries.elementAt(index);
                  final rankName = rankEntry.key;
                  final rankData = rankEntry.value;
                  final rankPoints = rankData['points'];
                  final rankDescription = rankData['description'];
                  final rankExample = rankData['example'];
                  final rankImagePath =
                      rankData['image_path']; // Get image path

                  return Card(
                    elevation: 2,
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$rankName:',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.red, // Highlight rank name
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pontos: $rankPoints',
                            style:
                                TextStyle(fontSize: 15, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rankDescription!,
                            style:
                                TextStyle(fontSize: 15, color: Colors.black54),
                          ),
                          if (rankExample != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              rankExample,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                  fontStyle: FontStyle.italic),
                            ),
                          ],
                          const SizedBox(height: 8),
                          // Display the image
                          Image.asset(
                            rankImagePath,
                            height: 100, // Adjust as needed
                            width: 100,
                          ),
                        ],
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
