import 'package:flutter/material.dart';
import '../models/word_level.dart'; // Importa a lista wordLevels
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sopa de Letras - Malária'), // Título mais específico
        backgroundColor: Colors.red,
        foregroundColor: Colors.white, // Texto do título branco
      ),
      body: ListView.builder(
        itemCount: wordLevels.length, // Usando a lista global de níveis
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(12),
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
    );
  }
}
