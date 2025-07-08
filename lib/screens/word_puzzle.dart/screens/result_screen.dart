import 'package:flutter/material.dart';
import 'home_screen.dart';

class ResultScreen extends StatelessWidget {
  final String level;
  final int total;

  const ResultScreen({
    super.key,
    required this.level,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Resultado"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white, // Garante que o texto do título seja branco
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone e mensagens de sucesso
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              Text(
                'Você completou $level!',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center, // Centraliza o texto
              ),
              const SizedBox(height: 10), // Espaçamento entre os textos
              Text(
                'Palavras encontradas: $total',
                style: const TextStyle(fontSize: 18), // Ajuste de tamanho para legibilidade
              ),
              const SizedBox(height: 40),
              // Botão para voltar ao menu
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder( // Borda arredondada para o botão
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text(
                  'Voltar ao Menu',
                  style: TextStyle(color: Colors.white, fontSize: 18), // Aumenta o tamanho da fonte do botão
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}