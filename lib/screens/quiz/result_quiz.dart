import 'package:auth_bloc/screens/quiz/quiz_start.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Dummy imports for screens to make the code runnable
// In your actual project, ensure these paths are correct
import 'package:auth_bloc/screens/main_screen.dart'; // Assuming this is MapZzzPage's location
import 'package:auth_bloc/screens/quiz/quiz_page.dart'; // Assuming this is MalariaQuizScreen's location

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

class MalariaQuizScreen extends StatelessWidget {
  const MalariaQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quiz Screen')),
      body: Center(child: Text('Malaria Quiz')),
    );
  }
}

class QuizResultScreen extends StatefulWidget {
  final int correctAnswersCount;
  final int totalQuestions;
  final int totalPointsEarned;

  const QuizResultScreen({
    super.key,
    required this.correctAnswersCount,
    required this.totalQuestions,
    required this.totalPointsEarned,
  });

  @override
  _QuizResultScreenState createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  @override
  void initState() {
    super.initState();
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
    return Scaffold(
      backgroundColor: Colors.red[700], // Full screen red background
      body: Stack(
        children: [
          // Close button at top left
          Positioned(
            top: 50.0,
            left: 20.0,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () {
                Navigator.of(context).popUntil(
                    (route) => route.isFirst); // Go back to main screen
              },
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Image/Illustration at the top
                  Image.asset(
                    'assets/images/sucess.png', // Replace with your actual asset path
                    // If you don't have this asset, use a placeholder:
                    // Image.network('https://placehold.co/300x200/FF0000/FFFFFF?text=Quiz+Result'),
                    height: 200, // Adjust height as needed
                    fit: BoxFit.contain,
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

                  // Points earned text
                  Text(
                    'ganhanaste ${widget.totalPointsEarned} pontos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white
                          .withOpacity(0.8), // Slightly transparent white
                    ),
                  ),
                  const SizedBox(height: 60.0),

                  // "Refazer quiz" Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const QuizScreen()),
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
                        'Refazer quiz',
                        style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15.0),

                  // "Voltar ao inicio" text button
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: Text(
                      'Voltar ao inicio',
                      style: TextStyle(
                        color: Colors.white
                            .withOpacity(0.8), // Slightly transparent white
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
