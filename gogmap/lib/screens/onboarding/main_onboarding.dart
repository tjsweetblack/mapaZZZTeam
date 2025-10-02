// onboarding_screen.dart (Create a new file named this, or place it in a relevant folder)
import 'package:auth_bloc/screens/onboarding/screens/onboarding_screens.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auth_bloc/routing/routes.dart';


// mainOnboarding widget
class mainOnboarding extends StatefulWidget {
  const mainOnboarding({super.key});

  @override
  State<mainOnboarding> createState() => _mainOnboardingState();
}

class _mainOnboardingState extends State<mainOnboarding> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  void _navigateToMainApp() {
    _setOnboardingComplete();
    Navigator.of(context)
        .pushReplacementNamed(Routes.loginScreen); // Navigate to main app
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80, // Adjust height for better spacing
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/logo/logo4.png',
              height: 40, // Adjust logo height
            ),
            const SizedBox(width: 8),
            const Text(
              'Mapazzz',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: const <Widget>[
              OnboardingPage1(),
              OnboardingPage2(),
              OnboardingPage3(),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
                bottom: 90.0), // Increased bottom padding to accommodate button
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildPageIndicator(),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_currentPage < 2) // Show "Next" button on pages 1 and 2
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: SizedBox(
                        width: 50, // Fixed width for the rounded square button
                        height: 50, // Fixed height for the rounded square button
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero, // Remove default padding
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded, // Use a forward arrow icon
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_currentPage == 2) // Show "Entrar" button on the last page
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: ElevatedButton(
                      onPressed: _navigateToMainApp,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(110.0),
                          ),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Entrar", style: TextStyle(color: Colors.white)),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      height: 8.0,
      width: 25.0, // Wider for the active indicator
      decoration: BoxDecoration(
        color: isActive ? Colors.red : Colors.grey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4.0), // Rounded corners for squares
        shape: BoxShape.rectangle, // Use the rectangle shape for squares
      ),
    );
  }

  List<Widget> _buildPageIndicator() {
    List<Widget> indicators = [];
    for (int i = 0; i < 3; i++) {
      indicators.add(
        _indicator(i == _currentPage),
      );
    }
    return indicators;
  }
}