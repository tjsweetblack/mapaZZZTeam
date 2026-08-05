import 'package:auth_bloc/main.dart';
import 'package:auth_bloc/features/auth/ui/screens/ui/phone.dart';
import 'package:auth_bloc/features/help/ui/screens/how_to_use_app_screen.dart';
import 'package:auth_bloc/features/map/ui/screens/main_screen.dart';
import 'package:auth_bloc/features/profile/ui/screens/profile.dart';
import 'package:auth_bloc/features/quiz/ui/screens/quiz_start.dart';
import 'package:auth_bloc/features/splash_screen/ui/screens/splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:auth_bloc/features/auth/logic/auth_cubit.dart';
import 'package:auth_bloc/screens/create_password/ui/create_password.dart';
import 'package:auth_bloc/screens/forget/ui/forget_screen.dart';
import 'package:auth_bloc/features/auth/ui/screens/ui/login_screen.dart';
import 'package:auth_bloc/features/onboarding/ui/screens/main_onboarding.dart';
import 'package:auth_bloc/screens/signup/ui/sign_up_sceen.dart';
import 'package:auth_bloc/core/routing/routes.dart';

class AppRouter {
  late AuthCubit authCubit;

  AppRouter() {
    authCubit = AuthCubit();
  }

  Route? generateRoute(RouteSettings settings) {
    if (settings.name == null) {
      return _handleInitialRoute();
    }

    switch (settings.name) {
      case Routes.forgetScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: authCubit,
            child: const ForgetScreen(),
          ),
        );

      case Routes.createPassword:
        final arguments = settings.arguments;
        if (arguments is List) {
          return MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: authCubit,
              child: CreatePassword(
                googleUser: arguments[0],
                credential: arguments[1],
              ),
            ),
          );
        }
        return null; // Handle incorrect arguments

      case Routes.signupScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: authCubit,
            child: const SignUpScreen(),
          ),
        );

      case Routes.loginScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: authCubit,
            child: const LoginScreen(),
          ),
        );

      case Routes.quizStart:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: authCubit,
            child: const QuizScreen(),
          ),
        );

      case Routes.howToUseApp:
        return MaterialPageRoute(builder: (_) => const HowToUseAppScreen());

      case Routes.splashScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: authCubit,
            child: const SplashScreen(),
          ),
        );

      case Routes.profileScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: authCubit,
            child: const ProfileScreen(),
          ),
        );

      case Routes.mainScreen:
        return MaterialPageRoute(builder: (_) => MapZzzPage());

      case Routes.PhoneAuthScreen:
        return MaterialPageRoute(builder: (_) => PhoneAuthScreen());

      case Routes.onboardingScreen: // Add onboarding route
        return MaterialPageRoute(builder: (_) => const mainOnboarding());

      default:
        return null;
    }
  }

  Route? _handleInitialRoute() {
    switch (initialRoute) {
      case Routes.loginScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: authCubit,
            child: const LoginScreen(),
          ),
        );
      case Routes.mainScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: authCubit,
            child: MapZzzPage(),
          ),
        );
      default:
        return null;
    }
  }
}
