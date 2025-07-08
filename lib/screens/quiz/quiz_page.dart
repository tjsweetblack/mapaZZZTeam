import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class MalariaQuizScreen extends StatefulWidget {
  @override
  _MalariaQuizScreenState createState() => _MalariaQuizScreenState();
}

class _MalariaQuizScreenState extends State<MalariaQuizScreen> {
  List<Map<String, dynamic>> malariaQuiz = [
    {
      "question": "Como a malária é transmitida ?",
      "options": [
        "Pelo ar",
        "Pessoa através do contato físico",
        "Pelo consumo de água contaminada",
        "Por mosquitos infectados",
        "Hereditário"
      ],
      "correctAnswer": "Por mosquitos infectados"
    },
    {
      "question": "O que causa a malária?",
      "options": ["Vírus", "Bactéria", "Parasita", "Fungo"],
      "correctAnswer": "Parasita"
    },
    {
      "question":
          "Qual gênero de mosquito é o principal transmissor da malária?",
      "options": ["Aedes", "Culex", "Anopheles", "Mansonia"],
      "correctAnswer": "Anopheles"
    },
    {
      "question":
          "Qual parasita é mais comumente associado à forma grave de malária?",
      "options": [
        "Plasmodium vivax",
        "Plasmodium falciparum",
        "Plasmodium ovale",
        "Plasmodium malariae"
      ],
      "correctAnswer": "Plasmodium falciparum"
    },
    {
      "question": "Qual é o principal sintoma inicial da malária?",
      "options": [
        "Tosse seca",
        "Febre",
        "Dor nas articulações",
        "Erupção cutânea"
      ],
      "correctAnswer": "Febre"
    },
    {
      "question":
          "Em que parte do corpo humano o parasita da malária se multiplica inicialmente?",
      "options": ["Pulmões", "Fígado", "Rins", "Coração"],
      "correctAnswer": "Fígado"
    },
    {
      "question": "Qual é uma medida eficaz para prevenir a malária?",
      "options": [
        "Beber água fervida",
        "Usar repelente de insetos",
        "Tomar antibióticos",
        "Evitar frutas tropicais"
      ],
      "correctAnswer": "Usar repelente de insetos"
    },
    {
      "question":
          "Qual medicamento é frequentemente usado no tratamento da malária?",
      "options": ["Penicilina", "Cloroquina", "Ibuprofeno", "Paracetamol"],
      "correctAnswer": "Cloroquina"
    },
    {
      "question": "Em que continente a malária é mais prevalente?",
      "options": ["Ásia", "Europa", "África", "Oceania"],
      "correctAnswer": "África"
    },
    {
      "question":
          "Qual é o nome do ciclo de vida do parasita da malária no mosquito?",
      "options": ["Esporogonia", "Gametogonia", "Merozoítos", "Trofozoítos"],
      "correctAnswer": "Esporogonia"
    },
    {
      "question":
          "Qual complicação grave pode ocorrer em casos de malária não tratada?",
      "options": [
        "Cegueira",
        "Malária cerebral",
        "Perda de audição",
        "Fratura óssea"
      ],
      "correctAnswer": "Malária cerebral"
    },
    {
      "question": "Qual é o vetor da malária?",
      "options": ["Mosca doméstica", "Mosquito Anopheles", "Barata", "Pulga"],
      "correctAnswer": "Mosquito Anopheles"
    },
    {
      "question":
          "Qual espécie de Plasmodium pode permanecer dormente no fígado?",
      "options": [
        "Plasmodium falciparum",
        "Plasmodium vivax",
        "Plasmodium malariae",
        "Plasmodium knowlesi"
      ],
      "correctAnswer": "Plasmodium vivax"
    },
    {
      "question": "Qual é o período típico de incubação da malária?",
      "options": ["1-2 dias", "7-30 dias", "2-3 meses", "6-12 meses"],
      "correctAnswer": "7-30 dias"
    },
    {
      "question": "Qual exame é mais usado para diagnosticar a malária?",
      "options": ["Raio-X", "Gota espessa", "Tomografia", "Ultrassom"],
      "correctAnswer": "Gota espessa"
    },
    {
      "question": "O que o mosquito Anopheles injeta ao picar uma pessoa?",
      "options": ["Vírus", "Esporozoítos", "Bactérias", "Toxinas"],
      "correctAnswer": "Esporozoítos"
    },
    {
      "question": "Qual é um sintoma comum da malária além da febre?",
      "options": [
        "Dor de cabeça",
        "Coceira na pele",
        "Visão dupla",
        "Perda de olfato"
      ],
      "correctAnswer": "Dor de cabeça"
    },
    {
      "question": "Qual é a principal fonte de infecção da malária?",
      "options": [
        "Água contaminada",
        "Picada de mosquito",
        "Alimentos crus",
        "Contato com sangue"
      ],
      "correctAnswer": "Picada de mosquito"
    },
    {
      "question":
          "Qual estação do ano favorece a proliferação do mosquito Anopheles?",
      "options": [
        "Inverno seco",
        "Verão chuvoso",
        "Outono frio",
        "Primavera seca"
      ],
      "correctAnswer": "Verão chuvoso"
    },
    {
      "question":
          "Qual é o nome da célula infectada pelo parasita na corrente sanguínea?",
      "options": ["Leucócito", "Hemácia", "Plaqueta", "Neurônio"],
      "correctAnswer": "Hemácia"
    },
    {
      "question": "Qual é uma consequência da malária grave em crianças?",
      "options": [
        "Anemia severa",
        "Crescimento acelerado",
        "Melhora da visão",
        "Aumento de peso"
      ],
      "correctAnswer": "Anemia severa"
    },
    {
      "question": "Qual é o objetivo da rede mosquiteira no combate à malária?",
      "options": [
        "Filtrar água",
        "Proteger contra picadas",
        "Aquecer o ambiente",
        "Capturar mosquitos"
      ],
      "correctAnswer": "Proteger contra picadas"
    },
  ];

  int _currentQuestionIndex = 0;
  int _correctAnswersCount = 0; // Track correct answers, not points yet
  String? _selectedAnswer;
  bool _answerChecked = false;
  List<Map<String, dynamic>> _shuffledQuestions = [];
  Timer? _timer;
  int _start = 15 * 60; // 15 minutes in seconds

  @override
  void initState() {
    super.initState();
    _shuffleQuestionsList();
    _startTimer();
  }

  void _startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
            _submitQuiz(); // Automatically submit when time is up
          });
        } else {
          if (mounted) {
            // Check if widget is still mounted before updating state
            setState(() {
              _start--;
            });
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int minutes = (seconds / 60).floor();
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _shuffleQuestionsList() {
    final random = Random();
    _shuffledQuestions = List.from(malariaQuiz);
    if (_shuffledQuestions.length > 10) {
      _shuffledQuestions = _shuffledQuestions.sublist(
          0, 10); // Limit to 10 questions as per the image
    }
    _shuffledQuestions.shuffle(random);
  }

  Future<void> _showAnswerDialog(bool isCorrect, String? correctAnswer) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isCorrect ? 'Correto!' : 'Errado!'), // Updated text
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                // Modified text based on correctness
                Text(
                  isCorrect
                      ? 'Boa! Você ganhou 2 pontos!' // Added points message here
                      : 'A resposta correta era: $correctAnswer', // Updated text
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Próxima'), // Updated text
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _nextQuestion(); // Automatically go to next question
              },
            ),
          ],
        );
      },
    );
  }

  void _checkAnswer(String selectedOption) {
    if (!_answerChecked) {
      final bool isCorrect = selectedOption ==
          _shuffledQuestions[_currentQuestionIndex]['correctAnswer'];

      setState(() {
        _selectedAnswer = selectedOption;
        _answerChecked = true;
        if (isCorrect) {
          _correctAnswersCount++; // Increment correct answers count
        }
      });

      // Add a short delay so the user can see the result
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          // Show the answer dialog after the delay
          _showAnswerDialog(isCorrect,
              _shuffledQuestions[_currentQuestionIndex]['correctAnswer']);
        }
      });
    }
  }

  void _nextQuestion() {
    // This is called after the answer dialog is dismissed
    setState(() {
      _selectedAnswer = null;
      _answerChecked = false;
      _currentQuestionIndex++;
      if (_currentQuestionIndex >= _shuffledQuestions.length) {
        _submitQuiz(); // Submit if it was the last question
      }
    });
  }

  // Removed _previousQuestion function as the button is removed

  void _submitQuiz() {
    _timer?.cancel(); // Cancel the timer
    // Calculate total points earned (2 points per correct answer)
    final int totalPointsEarned = _correctAnswersCount * 2;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          correctAnswersCount:
              _correctAnswersCount, // Pass correct answers count
          totalQuestions: _shuffledQuestions.length,
          totalPointsEarned: totalPointsEarned, // Pass total points earned
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_shuffledQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Quiz Malaria')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentQuestion = _shuffledQuestions[_currentQuestionIndex];
    final options = currentQuestion['options'] as List<String>;

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Malaria'),
        // automaticallyImplyLeading: false, // Removed to show back button
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(child: Text(_formatTime(_start))),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Progress Indicator
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_shuffledQuestions.length, (index) {
                  final questionNumber = index + 1;
                  final isCurrent = index == _currentQuestionIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          isCurrent ? Colors.red : Colors.grey[300],
                      foregroundColor:
                          isCurrent ? Colors.white : Colors.grey[600],
                      child: Text('$questionNumber',
                          style: TextStyle(fontSize: 12)),
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: 24.0),
            Text(
              currentQuestion['question'] as String,
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Column(
              children: options.asMap().entries.map((entry) {
                final int index = entry.key;
                final String option = entry.value;
                final letter = String.fromCharCode(65 + index); // A, B, C...
                final isSelected = _selectedAnswer == option;
                final isCorrect = _answerChecked &&
                    option == currentQuestion['correctAnswer'];
                final isIncorrect = _answerChecked &&
                    isSelected &&
                    option != currentQuestion['correctAnswer'];

                // Determine background and text color based on state
                Color backgroundColor = Colors.white;
                Color textColor = Colors.black;
                Color borderColor = Colors.grey[300]!;

                if (_answerChecked) {
                  if (isCorrect) {
                    backgroundColor = Colors.green[100]!;
                    textColor = Colors.green[900]!; // Darker text for contrast
                    borderColor = Colors.green[300]!;
                  } else if (isIncorrect) {
                    backgroundColor = Colors.red[100]!;
                    textColor = Colors.red[900]!; // Darker text for contrast
                    borderColor = Colors.red[300]!;
                  } else if (option == currentQuestion['correctAnswer']) {
                    // Highlight the correct answer even if not selected
                    backgroundColor = Colors.green[50]!;
                    textColor = Colors.green[700]!;
                    borderColor = Colors.green[200]!;
                  }
                } else if (isSelected) {
                  backgroundColor = Colors.blue[100]!;
                  textColor = Colors.blue[900]!;
                  borderColor = Colors.blue[300]!;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: backgroundColor,
                      foregroundColor: textColor,
                      padding: EdgeInsets.all(16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        side: BorderSide(
                            color: borderColor), // Use dynamic border color
                      ),
                    ),
                    onPressed:
                        _answerChecked // Disable button if answer is already checked
                            ? null
                            : () {
                                _checkAnswer(option);
                              },
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _answerChecked
                              ? (isCorrect
                                  ? Colors.green
                                  : Colors
                                      .red) // Green for correct, Red for incorrect
                              : (isSelected
                                  ? Colors.blue
                                  : Colors.grey[
                                      300]), // Blue if selected, Grey otherwise
                          foregroundColor:
                              Colors.white, // White text on colored circle
                          radius: 12,
                          child: Text(letter,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        SizedBox(width: 12.0),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(fontSize: 16.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            // Removed the Row containing Previous, Submit, and Next buttons
          ],
        ),
      ),
      // Removed the bottom navigation buttons
    );
  }
}

class QuizResultScreen extends StatefulWidget {
  // Changed to StatefulWidget to use initState
  final int correctAnswersCount; // Number of correct answers
  final int totalQuestions;
  final int totalPointsEarned; // Total points earned (correctAnswersCount * 2)

  QuizResultScreen({
    required this.correctAnswersCount,
    required this.totalQuestions,
    required this.totalPointsEarned, // Receive total points
  });

  @override
  _QuizResultScreenState createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  @override
  void initState() {
    super.initState();
    // Add points to user document when the result screen is initialized
    _updateUserPoints(widget.totalPointsEarned);
  }

  Future<void> _updateUserPoints(int pointsToAdd) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in. Cannot update points.');
      return;
    }

    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Use a transaction to ensure atomic read and write
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userDocRef);

        if (!userDoc.exists) {
          print('User document does not exist.');
          // Optionally create the user document if it doesn't exist,
          // but typically user documents are created during registration.
          // For now, we'll just log and return.
          return;
        }

        // Explicitly check if user data is a Map before accessing keys
        final dynamic rawUserData = userDoc.data();
        Map<String, dynamic>? userData;
        if (rawUserData != null && rawUserData is Map<String, dynamic>) {
          userData = rawUserData;
        } else {
          print('User data is not a Map or is null.');
          return; // Exit if data is not in expected format
        }

        final int currentPoints =
            userData['points'] as int? ?? 0; // Safely access points
        final int newTotalPoints = currentPoints + pointsToAdd;

        // Update the points field in the user document within the transaction
        transaction.update(userDocRef, {'points': newTotalPoints});

        print(
            'User ${user.uid} points updated: $currentPoints + $pointsToAdd = $newTotalPoints');
      }).catchError((error) {
        print('Transaction failed: $error');
        // Handle transaction errors (e.g., show a message to the user)
      });
    } catch (e) {
      print('Error updating user points: $e');
      // Handle other potential errors (e.g., show a message)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resultado do Quiz'),
        automaticallyImplyLeading:
            false, // Keep no back button on result screen
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Você acertou:',
              style: TextStyle(fontSize: 24.0),
            ),
            Text(
              '${widget.correctAnswersCount} / ${widget.totalQuestions}', // Show correct answers count
              style: TextStyle(fontSize: 36.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.0),
            Text(
              'Pontos Ganhos:',
              style: TextStyle(fontSize: 24.0),
            ),
            Text(
              '${widget.totalPointsEarned} pontos', // Display total points earned
              style: TextStyle(
                  fontSize: 36.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.green), // Highlight points
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MalariaQuizScreen()),
                );
              },
              child: Text('Refazer o Quiz'),
            ),
            SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: () {
                // Use pop until the quiz screen is no longer in the navigation stack
                // This prevents stacking multiple quiz result screens
                // Navigator.popUntil(context, (route) => route.settings.name != '/quiz'); // Assuming '/quiz' is the route name for MalariaQuizScreen
                // If you don't use named routes, you might need a different approach
                // e.g., Navigator.pop(context); if the screen before the quiz is the target
                // Or pop twice if the quiz was pushed on top of another screen
                Navigator.pop(context); // Simple pop to go back one screen
              },
              child: Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }
}
