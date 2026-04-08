import 'dart:math';

import 'package:auth_bloc/helpers/build_divider.dart'; // Ensure this import is correct
import 'package:auth_bloc/screens/word_puzzle.dart/models/word_level.dart';
import 'package:auth_bloc/screens/word_puzzle.dart/screens/result_screen.dart';
import 'package:auth_bloc/screens/word_puzzle.dart/widgets/find_the_word_game.dart'; // Your FindTheWord widget
import 'package:flutter/material.dart';

class GameScreen extends StatelessWidget {
  final WordLevel level;

  const GameScreen({super.key, required this.level});

  // Using a local buildDivider for self-containment, or ensure the helper is correctly imported.
  Widget _buildThemedDivider() {
    return const Divider(
      color: Color.fromARGB(
          255, 200, 200, 200), // Lighter grey for better contrast
      height: 30, // More vertical space
      thickness: 1.5, // Slightly thicker
      indent: 30, // More indent
      endIndent: 30, // More end indent
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> gameWords = level.words;

    // print('Debugging GameScreen - Nível: ${level.title}, Palavras: $gameWords'); // Keep for debugging

    int largestWordLength = 0;
    for (String word in gameWords) {
      if (word.length > largestWordLength) {
        largestWordLength = word.length;
      }
    }
    // Ensures a minimum board size of 10x10, or larger if needed for words.
    final int effectiveBoardSize = max(10, largestWordLength + 2);
    // print('Debugging GameScreen - Board Size: $effectiveBoardSize'); // Keep for debugging

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        List<String> foundWords = [];
        return Scaffold(
          backgroundColor: const Color.fromARGB(
              255, 250, 250, 250), // Soft off-white background
          appBar: AppBar(
            title: Text(
              "Sopa de Letras - ${level.title}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color.fromARGB(
                    255, 139, 0, 0), // Dark red for app bar title
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent, // Transparent app bar
            elevation: 0, // No shadow
            iconTheme: const IconThemeData(
                color: Color.fromARGB(255, 139, 0, 0)), // Back button color
          ),
          body: Column(
            children: [
              // Title for the words to find
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    20.0, 15.0, 20.0, 10.0), // Adjusted padding
                child: Text(
                  "PALAVRAS PARA ACHAR:",
                  style: TextStyle(
                    fontSize: 20, // Slightly larger
                    fontWeight: FontWeight.w900, // Extra bold
                    color: Color.fromARGB(255, 178, 34, 34), // Firebrick red
                    shadows: [
                      Shadow(
                        blurRadius: 3.0,
                        color: Colors.black26,
                        offset: Offset(1.5, 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              // List of words to find
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
                decoration: BoxDecoration(
                  color: Colors.red
                      .shade50, // Very light red background for the word list
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade100),
                ),
                margin: const EdgeInsets.symmetric(
                    horizontal: 20.0), // Margin around the container
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // More columns for better spacing
                    childAspectRatio:
                        3 / 1.2, // Adjust aspect ratio for word fit
                    mainAxisSpacing: 5.0,
                    crossAxisSpacing: 5.0,
                  ),
                  itemCount: gameWords.length,
                  itemBuilder: (context, index) {
                    final word = gameWords[index];
                    final isFound = foundWords.contains(word);
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 8.0),
                        decoration: BoxDecoration(
                          color: isFound
                              ? Colors.red.shade200
                              : Colors.transparent, // Highlight found words
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          word.toUpperCase(), // Display words in uppercase
                          style: TextStyle(
                            fontSize: 15, // Slightly larger font for words
                            fontWeight:
                                isFound ? FontWeight.bold : FontWeight.normal,
                            color: isFound
                                ? Color.fromARGB(
                                    255, 139, 0, 0) // Dark red for found words
                                : Colors
                                    .black87, // Slightly softer black for unfound words
                            decoration: isFound
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: Color.fromARGB(
                                255, 139, 0, 0), // Red line-through
                            decorationThickness: 2,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildThemedDivider(), // Uses the custom themed divider
              // Word search puzzle
              Expanded(
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.95,
                    height: MediaQuery.of(context).size.width * 0.95,
                    decoration: BoxDecoration(
                      color:
                          Colors.white, // White background for the puzzle grid
                      borderRadius: BorderRadius.circular(
                          15), // Rounded corners for the puzzle
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          spreadRadius: 3,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      // Clip to prevent the puzzle from overflowing rounded corners
                      borderRadius: BorderRadius.circular(15),
                      child: FindTheWord(
                        words: gameWords,
                        boardSize: effectiveBoardSize,
                        onWordFound: (word) {
                          setState(() {
                            foundWords.add(word);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Você encontrou: ${word.toUpperCase()}!",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: Color.fromARGB(
                                  255, 178, 34, 34), // Themed snackbar
                              duration: const Duration(seconds: 1),
                            ),
                          );

                          if (foundWords.length == gameWords.length) {
                            // Delay navigation slightly to allow snackbar to be seen
                            Future.delayed(const Duration(seconds: 1), () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ResultScreen(
                                    level: level.title,
                                    total: gameWords.length,
                                    found: foundWords
                                        .length, // Pass found words count
                                  ),
                                ),
                              );
                            });
                          }
                        },
                        onFinish: () {
                          // This onFinish might trigger too early if all words are found via onWordFound.
                          // The check for all words found should ideally be within onWordFound.
                          // I've moved the navigation logic there for better control.
                          if (foundWords.length == gameWords.length) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ResultScreen(
                                  level: level.title,
                                  total: gameWords.length,
                                  found: foundWords.length,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
