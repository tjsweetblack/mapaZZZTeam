import 'package:auth_bloc/screens/quiz/quiz_start.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Dummy imports for screens to make the code runnable
// In your actual project, ensure these paths are correct

// Dummy implementations to satisfy imports, replace with your actual ones if not present
class MapZzzPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Main Screen')),
      body: Center(child: Text('Welcome to MapZzz!')),
    );
  }
}

class QuizResultScreen extends StatefulWidget {
  final int correctAnswersCount;
  final int totalQuestions;
  final int totalPointsEarned;
  final String languageCode;

  const QuizResultScreen({
    super.key,
    required this.correctAnswersCount,
    required this.totalQuestions,
    required this.totalPointsEarned,
    required this.languageCode,
  });

  @override
  _QuizResultScreenState createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  // A map to hold all the translations with a placeholder for points.
  static final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'points_earned_text': 'You earned {points} points',
      'retake_quiz_button': 'Retake quiz',
      // 'back_to_start_button': 'Back to start', // This is no longer used
    },
    'pt': {
      'points_earned_text': 'ganhaste {points} pontos',
      'retake_quiz_button': 'Refazer quiz',
      // 'back_to_start_button': 'Voltar ao início', // This is no longer used
    },
    'ja': {
      'points_earned_text': '{points} ポイントを獲得しました',
      'retake_quiz_button': 'クイズをやり直す',
      // 'back_to_start_button': '最初に戻る', // This is no longer used
    },
  };

  @override
  void initState() {
    super.initState();
    _updateUserPoints(widget.totalPointsEarned);
  }

  // Function to send quiz count data to the API
  Future<void> _sendQuizCountToAPI() async {
    try {
      // Use the correct API URL
      final url = Uri.parse('https://contagemapi-sable.vercel.app/historico');

      // Get current date in YYYY-MM-DD format
      final currentDate = DateTime.now();
      final formattedDate =
          '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';

      // Map language codes to the format expected by the API
      String apiLanguageCode;
      switch (widget.languageCode) {
        case 'ja':
          apiLanguageCode = 'jp';
          break;
        case 'pt':
          apiLanguageCode = 'pt';
          break;
        case 'en':
        default:
          apiLanguageCode = 'en';
          break;
      }

      final requestBody = {
        'lingua': apiLanguageCode,
        'data': formattedDate,
        'rank': widget.correctAnswersCount.toString(),
      };

      print('Sending quiz count to API: $requestBody');

      final body = jsonEncode(requestBody);

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Quiz count successfully sent to API');
      } else {
        print('Failed to send quiz count. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        // Don't throw error to avoid breaking the user experience
      }
    } catch (e) {
      print('Error sending quiz count to API: $e');
      // Don't rethrow the error to avoid breaking the user experience
    }
  }

  // Modified to handle the point interpolation dynamically.
  String _getTranslatedString(String key) {
    final language =
        _localizedStrings[widget.languageCode] ?? _localizedStrings['en']!;
    final String baseString = language[key] ?? key;
    return baseString.replaceFirst(
        '{points}', widget.totalPointsEarned.toString());
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

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userDocRef);

        if (!userDoc.exists) {
          print('User document does not exist.');
          return;
        }

        final dynamic rawUserData = userDoc.data();
        Map<String, dynamic>? userData;
        if (rawUserData != null && rawUserData is Map<String, dynamic>) {
          userData = rawUserData;
        } else {
          print('User data is not a Map or is null.');
          return;
        }

        final int currentPoints = userData['points'] as int? ?? 0;
        final int newTotalPoints = currentPoints + pointsToAdd;

        transaction.update(userDocRef, {'points': newTotalPoints});

        print(
            'User ${user.uid} points updated: $currentPoints + $pointsToAdd = $newTotalPoints');
      }).catchError((error) {
        print('Transaction failed: $error');
      });
    } catch (e) {
      print('Error updating user points: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final translatedStrings = _getTranslatedString;

    return Scaffold(
      backgroundColor: Colors.red[700], // Full screen red background
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Placeholder for the success image
                  const Text(
                    '🎉',
                    style: TextStyle(fontSize: 100),
                  ),
                  const SizedBox(height: 30.0),

                  // Score display
                  Text(
                    '${widget.correctAnswersCount}/${widget.totalQuestions}',
                    style: const TextStyle(
                      fontSize: 48.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // White text
                    ),
                  ),
                  const SizedBox(height: 10.0),

                  // Points earned text (now localized)
                  Text(
                    translatedStrings('points_earned_text'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white
                          .withOpacity(0.8), // Slightly transparent white
                    ),
                  ),
                  const SizedBox(height: 60.0),

                  // "Refazer quiz" Button (now localized)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Send quiz count to API before navigating
                        await _sendQuizCountToAPI();

                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QuizScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // White background
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10.0), // Rounded corners
                        ),
                        elevation: 0, // No shadow for this button
                      ),
                      child: Text(
                        translatedStrings('retake_quiz_button'),
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
