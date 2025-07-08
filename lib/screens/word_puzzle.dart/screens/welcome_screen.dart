// lib/screens/welcome_screen.dart

//import 'dart:nativewrappers/_internal/vm/lib/ffi_patch.dart';

//import 'package:myapp/screens/home_screen.dart'; // Importa sua tela de níveis atual
//import 'package:myapp/screens/home_screen.dart  '

import 'package:auth_bloc/screens/word_puzzle.dart/screens/home_screen.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fundo branco
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Imagem ou Ícone (Opcional)
              // Você pode adicionar uma imagem relacionada à malária ou um ícone grande
              // Exemplo: Image.asset('assets/mosquito_icon.png', height: 100),
              Image.asset('mosquito.jpg', height: 100),
              //Icon(Icons.health_and_safety, size: 100, color: Colors.red.shade700),
              //onst SizedBox(height: 30),

              // Título do Jogo
              Text(
                'Bem-vindo(a) a Sopa de Letras:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
              ),
              Text(
                'Sem Malaria!', // Ou o nome que você escolher!
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade900,
                ),
              ),
              const SizedBox(height: 20),

              // Mensagem Introdutória Amigável
              const Text(
                'Prepare-se para um desafio divertido e educativo! Neste jogo de sopa de letras, você vai explorar palavras importantes relacionadas à malária, aprendendo enquanto joga.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'A malária é uma doença séria, mas com informação e prevenção, podemos combatê-la. Sua missão é encontrar todas as palavras escondidas!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 40),

              // Botão para Iniciar o Jogo
              ElevatedButton(
                onPressed: () {
                  // Redireciona para a tela de níveis (sua HomeScren atual)
                  Navigator.pushReplacement( // Usa pushReplacement para que não dê para voltar para a WelcomeScreen
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Cor de fundo do botão
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Começar o Desafio!',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white, // Cor do texto do botão
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}