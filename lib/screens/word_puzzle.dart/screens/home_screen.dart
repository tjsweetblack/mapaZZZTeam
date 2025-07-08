import 'package:flutter/material.dart';
import '../models/word_level.dart'; // Importa a lista wordLevels
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: const Text('Sopa de Letras - Malária'), // Título mais específico
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        foregroundColor: const Color.fromARGB(255, 0, 0, 0), // Texto do título branco
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Escolhe o teu nível',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: wordLevels.length, // Usando a lista global de níveis
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    color: Colors.red.shade50,
                    elevation: 4, // Adiciona uma pequena sombra ao card
                    shape: RoundedRectangleBorder(
                      // Borda arredondada para o card
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: Text(
                        wordLevels[index].title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.red,
                        ), // Estilo do texto do título
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.red),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            // Passando o objeto WordLevel completo para GameScreen
                            builder: (_) => GameScreen(level: wordLevels[index]),
                          ),
                        );
                      },
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
