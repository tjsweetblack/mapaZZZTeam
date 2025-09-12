import 'package:auth_bloc/screens/quiz/questions.dart';
import 'package:auth_bloc/screens/quiz/result_quiz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class MalariaQuizScreen extends StatefulWidget {
  final String language;
  const MalariaQuizScreen({super.key, required this.language});

  @override
  _MalariaQuizScreenState createState() => _MalariaQuizScreenState();
}

class _MalariaQuizScreenState extends State<MalariaQuizScreen> {
  List<Map<String, dynamic>> malariaQuiz = [];

  int _currentQuestionIndex = 0;
  int _correctAnswersCount = 0;
  String? _selectedAnswer;
  bool _answerChecked = false;
  List<Map<String, dynamic>> _shuffledQuestions = [];
  Timer? _timer;
  int _start = 15 * 60; // 15 minutes in seconds

  @override
  void initState() {
    super.initState();
    _loadQuestionsByLanguage();
    _startTimer();
  }

  void _loadQuestionsByLanguage() {
    if (widget.language == 'en') {
      malariaQuiz = englishQuestions();
    } else if (widget.language == 'ja') {
      malariaQuiz = japaneseQuestions();
    } else {
      malariaQuiz = allQuestions();
    }
    _shuffleQuestionsList();
  }

  void _startTimer() {
    const oneSec = Duration(seconds: 1);
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
    List<Map<String, dynamic>> tempQuestions = List.from(malariaQuiz);
    tempQuestions.shuffle(random); // Shuffle all questions
    _shuffledQuestions = tempQuestions.sublist(
        0, min(10, tempQuestions.length)); // Take up to 10 questions
  }

  void _checkAnswer(String selectedOption) {
    if (!_answerChecked) {
      final bool isCorrect = selectedOption ==
          _shuffledQuestions[_currentQuestionIndex]['correctAnswer'];

      setState(() {
        _selectedAnswer = selectedOption;
        _answerChecked = true;
        if (isCorrect) {
          _correctAnswersCount++;
        }
      });

      // Add a short delay to show the feedback, then move to the next question
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _nextQuestion();
        }
      });
    }
  }

  void _nextQuestion() {
    setState(() {
      _selectedAnswer = null;
      _answerChecked = false;
      _currentQuestionIndex++;
      if (_currentQuestionIndex >= _shuffledQuestions.length) {
        _submitQuiz(); // Submit if it was the last question
      }
    });
  }

  void _submitQuiz() {
    _timer?.cancel(); // Cancel the timer
    final int totalPointsEarned = _correctAnswersCount * 2;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          correctAnswersCount: _correctAnswersCount,
          totalQuestions: _shuffledQuestions.length,
          totalPointsEarned: totalPointsEarned,
          languageCode:
              widget.language, // Passing the language to the next screen
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_shuffledQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz Malaria')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentQuestion = _shuffledQuestions[_currentQuestionIndex];
    final options = currentQuestion['options'] as List<String>;

    // Calculate progress for the linear indicator
    double progress = (_currentQuestionIndex + 1) / _shuffledQuestions.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize:
              MainAxisSize.min, // Make row only as big as its children
          children: const [
            Icon(Icons.auto_awesome,
                color: Colors.red), // Placeholder for spark icon
            SizedBox(width: 8),
            Text(
              'MapaZZZ Quiz',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: const [
          // Empty actions to push title to center if needed by other widgets
          SizedBox(width: 50), // To balance the leading icon
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Timer display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 5),
                Text(
                  _formatTime(_start),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800]),
                ),
              ],
            ),
            const SizedBox(height: 20.0),

            // Question Card
            Container(
              padding: const EdgeInsets.all(25.0),
              decoration: BoxDecoration(
                color: Colors.red[700],
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 7,
                    offset: const Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: Text(
                currentQuestion['question'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20.0),

            // Progress Bar and Question Count
            Stack(
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red[700]!),
                  minHeight: 30,
                  borderRadius: BorderRadius.circular(5),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        '${_currentQuestionIndex + 1}/${_shuffledQuestions.length}',
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30.0),

            // Answer Options
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final String option = options[index];
                  final String letter =
                      String.fromCharCode(65 + index); // A, B, C...
                  final bool isSelected = _selectedAnswer == option;
                  final bool isCorrectAnswer =
                      option == currentQuestion['correctAnswer'];

                  // Determine colors and icon based on answer state
                  Color backgroundColor = Colors.white;
                  Color borderColor = Colors.grey[300]!;
                  Color textColor = Colors.black87;
                  IconData? suffixIcon;
                  Color iconColor = Colors.transparent;

                  if (_answerChecked) {
                    if (isCorrectAnswer) {
                      backgroundColor = Colors.green[50]!;
                      borderColor = Colors.green[300]!;
                      textColor = Colors.green[800]!;
                      suffixIcon = Icons.check_circle;
                      iconColor = Colors.green;
                    } else if (isSelected && !isCorrectAnswer) {
                      backgroundColor = Colors.red[50]!;
                      borderColor = Colors.red[300]!;
                      textColor = Colors.red[800]!;
                      suffixIcon = Icons.cancel;
                      iconColor = Colors.red;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: backgroundColor,
                        padding: const EdgeInsets.all(16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          side: BorderSide(color: borderColor, width: 1.5),
                        ),
                        elevation: 0, // No shadow for options
                        shadowColor: Colors.transparent,
                      ),
                      onPressed: _answerChecked
                          ? null // Disable button if answer is already checked
                          : () {
                              _checkAnswer(option);
                            },
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors
                                .grey[200], // Gray background for letter circle
                            radius: 18,
                            child: Text(
                              letter,
                              style: TextStyle(
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 15.0),
                          Expanded(
                            child: Text(
                              option,
                              style:
                                  TextStyle(fontSize: 16.0, color: textColor),
                            ),
                          ),
                          if (_answerChecked && suffixIcon != null)
                            Icon(suffixIcon, color: iconColor, size: 24),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
