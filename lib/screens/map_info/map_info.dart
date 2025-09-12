import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class MapExplanationPage extends StatelessWidget {
  const MapExplanationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
        title: const Text('Explicação do Mapa',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Este mapa exibe informações sobre possíveis áreas de reprodução de mosquitos e sua localização. Aqui está um resumo do que os diferentes elementos significam:',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ícones e Marcadores:',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 8),
              // Visual representation of the report marker.
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Marcador de Denúncia (Visual):',
                      style: TextStyle(fontSize: 16, color: Colors.black87)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 40),
                child: Text(
                  '  -  Um pequeno círculo vermelho dentro de um círculo branco, indicando a localização exata de uma denúncia.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  // Blue circle for "Sua Localização"
                  const CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.blue,
                    child: SizedBox(), // empty child for solid color
                  ),
                  const SizedBox(width: 10),
                  const Text('Sua Localização:',
                      style: TextStyle(fontSize: 16, color: Colors.black87)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 40),
                child: Text(
                  '  -  Mostra sua localização atual no mapa.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Círculos de Mapa de Calor:',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                'Círculos no mapa representam áreas com uma maior concentração de possíveis áreas de reprodução relatadas. A cor e a opacidade dos círculos indicam o nível de risco:',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              _buildRiskCircleExplanation(
                color: Colors.red.withOpacity(0.3),
                description: 'Baixo Risco: Poucas denúncias na área.',
              ),
              _buildRiskCircleExplanation(
                color: Colors.red.withOpacity(0.6),
                description: 'Risco Médio: Número moderado de denúncias.',
              ),
              _buildRiskCircleExplanation(
                color: Colors.red.withOpacity(0.9),
                description:
                    'Alto Risco: Muitas denúncias, indicando uma área de reprodução potencial significativa.',
              ),
              const SizedBox(height: 20),
              const Text(
                'Notas Adicionais:',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                '  - O mapa é interativo. Você pode aumentar e diminuir o zoom para ver diferentes áreas.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              const Text(
                '  - Os marcadores de denúncia indicam denúncias individuais, enquanto os círculos indicam aglomerados de denúncias.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              const Text(
                '  -  A frase \'voçe esta aqui!\' indica sua localização no mapa.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildRiskCircleExplanation(
      {required Color color, required String description}) {
    return Row(
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: CircleAvatar(
            backgroundColor: color,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            description,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
