// lib/widgets/find_the_word_game.dart

import 'package:flutter/material.dart';
import 'dart:math';

class FindTheWord extends StatefulWidget {
  final List<String> words;
  final int boardSize;
  final Function(String word) onWordFound;
  final Function() onFinish;

  const FindTheWord({
    super.key,
    required this.words,
    required this.boardSize,
    required this.onWordFound,
    required this.onFinish,
  });

  @override
  State<FindTheWord> createState() => _FindTheWordState();
}

class _FindTheWordState extends State<FindTheWord> {
  late List<List<String>> _board;
  late List<String> _remainingWords;
  Set<Offset> _selectedLetters = {};
  Set<Offset> _foundLettersCoordinates = {}; // <-- NOVO: Armazena as coordenadas das letras encontradas
  String _currentWordSelection = '';

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    _remainingWords = List.from(widget.words.map((word) => word.toUpperCase()));
    _board = List.generate(widget.boardSize, (_) => List.filled(widget.boardSize, ''));
    _fillBoardWithWords();
    _fillRemainingWithRandomLetters();
  }

  void _fillBoardWithWords() {
    final Random random = Random();
    for (String word in _remainingWords) {
      bool placed = false;
      int attempts = 0;
      while (!placed && attempts < 100) {
        int row = random.nextInt(widget.boardSize);
        int col = random.nextInt(widget.boardSize);
        int direction = random.nextInt(2); // Apenas direções 0 (horizontal) e 1 (vertical)

        if (_canPlaceWord(word, row, col, direction)) {
          _placeWord(word, row, col, direction);
          placed = true;
        }
        attempts++;
      }
      if (!placed) {
        print('AVISO: Não foi possível posicionar a palavra: $word');
      }
    }
  }

  bool _canPlaceWord(String word, int startRow, int startCol, int direction) {
    for (int i = 0; i < word.length; i++) {
      int r = startRow;
      int c = startCol;

      switch (direction) {
        case 0: c += i; break; // Horizontal
        case 1: r += i; break; // Vertical
        case 2: r += i; c += i; break; // Diagonal (\)
        case 3: r += i; c -= i; break; // Diagonal (/)
      }

      if (r < 0 || r >= widget.boardSize || c < 0 || c >= widget.boardSize) {
        return false;
      }
      if (_board[r][c] != '' && _board[r][c] != word[i]) {
        return false;
      }
    }
    return true;
  }

  void _placeWord(String word, int startRow, int startCol, int direction) {
    for (int i = 0; i < word.length; i++) {
      int r = startRow;
      int c = startCol;

      switch (direction) {
        case 0: c += i; break;
        case 1: r += i; break;
        case 2: r += i; c += i; break;
        case 3: r += i; c -= i; break;
      }
      _board[r][c] = word[i];
    }
  }

  void _fillRemainingWithRandomLetters() {
    final Random random = Random();
    const String alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for (int r = 0; r < widget.boardSize; r++) {
      for (int c = 0; c < widget.boardSize; c++) {
        if (_board[r][c] == '') {
          _board[r][c] = alphabet[random.nextInt(alphabet.length)];
        }
      }
    }
  }

  void _onPanStart(DragStartDetails details, BoxConstraints constraints) {
    setState(() {
      _selectedLetters.clear();
      _currentWordSelection = '';
    });
    _addLetterToSelection(details.localPosition, constraints);
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    _addLetterToSelection(details.localPosition, constraints);
  }

  void _onPanEnd(DragEndDetails details, BoxConstraints constraints) {
    _checkWord();
  }

  void _addLetterToSelection(Offset localPosition, BoxConstraints constraints) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final double cellSize = size.width / widget.boardSize;

    int col = (localPosition.dx / cellSize).floor();
    int row = (localPosition.dy / cellSize).floor();

    if (row >= 0 && row < widget.boardSize && col >= 0 && col < widget.boardSize) {
      Offset currentCell = Offset(col.toDouble(), row.toDouble());
      if (!_selectedLetters.contains(currentCell)) { // REMOVEMOS: !_foundLettersCoordinates.contains(currentCell)
        setState(() {
          _selectedLetters.add(currentCell);
          _currentWordSelection += _board[row][col];
        });
      }
    }
  }

  void _checkWord() {
    String foundWord = _currentWordSelection.toUpperCase();
    if (_remainingWords.contains(foundWord)) {
      setState(() {
        _remainingWords.remove(foundWord);
        // Adiciona as letras da palavra encontrada ao conjunto de letras encontradas
        _foundLettersCoordinates.addAll(_selectedLetters);
        _selectedLetters.clear(); // Limpa a seleção atual
      });
      widget.onWordFound(foundWord); // Ainda notifica o GameScreen
      if (_remainingWords.isEmpty) {
        widget.onFinish();
      }
    } else {
      // Palavra incorreta ou não encontrada
      setState(() {
        _selectedLetters.clear(); // Limpa a seleção
      });
    }
    _currentWordSelection = '';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cellSize = constraints.maxWidth / widget.boardSize;
        return GestureDetector(
          onPanStart: (details) => _onPanStart(details, constraints),
          onPanUpdate: (details) => _onPanUpdate(details, constraints),
          onPanEnd: (details) => _onPanEnd(details, constraints),
          child: Container(
            color: const Color.fromARGB(255, 255, 219, 219),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.boardSize,
              ),
              itemCount: widget.boardSize * widget.boardSize,
              itemBuilder: (context, index) {
                int row = index ~/ widget.boardSize;
                int col = index % widget.boardSize;
                String char = _board[row][col];
                Offset currentCellCoord = Offset(col.toDouble(), row.toDouble());

                bool isSelected = _selectedLetters.contains(currentCellCoord);
                bool isFound = _foundLettersCoordinates.contains(currentCellCoord); // <-- NOVO: Verifica se a letra faz parte de uma palavra encontrada

                Color textColor;
                Color backgroundColor;

                if (isSelected) {
                  // Cor da letra e fundo quando a letra está sendo selecionada (arrastada)
                  textColor = Colors.white;
                  backgroundColor = Colors.red; // Seleção atual é vermelha
                } else if (isFound) {
                  // Cor da letra e fundo quando a palavra já foi encontrada
                  textColor = Colors.white; // Letra branca
                  backgroundColor = Colors.green; // Palavra encontrada fica verde
                } else {
                  // Cor padrão das letras não selecionadas/encontradas
                  textColor = Colors.black87;
                  backgroundColor = Colors.transparent; // Fundo transparente
                }


                return Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border.all(color: Colors.grey.shade300, width: 0.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    char,
                    style: TextStyle(
                      fontSize: cellSize * 0.5,
                      fontWeight: FontWeight.bold,
                      color: textColor, // Usa a cor da letra definida acima
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}