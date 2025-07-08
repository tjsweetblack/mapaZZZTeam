// lib/screens/game_screen.dart

import 'package:auth_bloc/screens/word_puzzle.dart/models/word_level.dart';
import 'package:auth_bloc/screens/word_puzzle.dart/screens/result_screen.dart';
import 'package:auth_bloc/screens/word_puzzle.dart/widgets/find_the_word_game.dart';
import 'package:flutter/material.dart';
// REMOVA ESTA LINHA SE VOCÊ NÃO ESTÁ USANDO UM PACOTE EXTERNO:
// import 'package:find_the_word/find_the_word.dart';
// ADICIONE A IMPORTAÇÃO PARA O SEU WIDGET FindTheWord

class GameScreen extends StatelessWidget {
  final WordLevel level;

  const GameScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final List<String> gameWords = level.words;

    print('Debugging GameScreen - Nível: ${level.title}, Palavras: $gameWords');

    int largestWordLength = 0;
    for (String word in gameWords) {
      if (word.length > largestWordLength) {
        largestWordLength = word.length;
      }
    }
    final int effectiveBoardSize = largestWordLength > 10 ? largestWordLength + 2 : 12;
    print('Debugging GameScreen - Board Size: $effectiveBoardSize');


    return Scaffold(
      appBar: AppBar(
        title: Text("Sopa de Letras - ${level.title}"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.width * 0.95,
          child: FindTheWord( // <--- AGORA ESTA CHAMADA SE REFERE À SUA PRÓPRIA CLASSE
            words: gameWords,
            boardSize: effectiveBoardSize,
            themeColor: Colors.green,
            // As cores foundTextColor e textColor são agora controladas dentro do seu FindTheWord
            // então não as passe aqui, a menos que você as adicione aos seus próprios parâmetros.

            onWordFound: (word) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                   content: Text(
                    "Você encontrou: $word!",
                     style: const TextStyle(color: Colors.white),
                  ),
                  
                ),
              );
            },
            onFinish: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ResultScreen(
                    level: level.title,
                    total: gameWords.length,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}