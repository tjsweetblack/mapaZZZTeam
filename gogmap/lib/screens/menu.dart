import 'package:auth_bloc/cubits/language_cubit.dart';
import 'package:auth_bloc/l10n/app_localizations.dart';
import 'package:auth_bloc/screens/about/about.dart';
import 'package:auth_bloc/screens/blog/blog_screen.dart';
import 'package:auth_bloc/screens/epaludismo/epaludismo_screen.dart';
import 'package:auth_bloc/screens/profile/profile.dart';
import 'package:auth_bloc/screens/profile/rewards/rewards.dart';
import 'package:auth_bloc/screens/quiz/quiz_page.dart';
import 'package:auth_bloc/screens/quiz/quiz_start.dart';
import 'package:auth_bloc/screens/word_puzzle.dart/screens/home_screen.dart';
import 'package:auth_bloc/screens/word_puzzle.dart/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auth_bloc/logic/cubit/auth_cubit.dart';
import 'package:auth_bloc/routing/routes.dart';

Widget buildAppDrawer(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  return SizedBox(
    width: screenWidth * 0.9, // Covers 70% of the screen
    child: Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
              top: 50.0,
              left: 20.0,
              bottom: 20.0,
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo/logo4.png',
                  height: 30,
                ),
                const SizedBox(width: 8),
                Text(
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
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                ListTile(
                  leading: const Icon(
                    Icons.person_outline,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Perfil',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.quiz_outlined, color: Colors.red),
                  title: const Text(
                    'Quiz',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.description_outlined, color: Colors.red),
                  title: const Text(
                    'Notícias',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BlogPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.thermostat_outlined, color: Colors.red),
                  title: const Text(
                    'É-Paludismo',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EPaldudismoScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.star_border, color: Colors.red),
                  title: const Text(
                    'Reivindicar prêmio',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RewardsPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.red),
                  title: const Text(
                    'Sobre',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AboutPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MapaZZZ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.red, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Rua 13 Av. Al, Talatona\nLuanda - Angola',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(context); // Close the drawer
                    await context.read<AuthCubit>().signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        Routes.loginScreen,
                        (route) => false,
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
