import 'package:auth_bloc/helpers/extensions.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '/../../logic/cubit/auth_cubit.dart';
import '/../../theming/styles.dart';

class ForgetScreen extends StatefulWidget {
  const ForgetScreen({super.key});

  @override
  State<ForgetScreen> createState() => _ForgetScreenState();
}

class _ForgetScreenState extends State<ForgetScreen> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = screenWidth * 0.08; // Approximate 30.w
    final bottomPadding = screenHeight * 0.02; // Approximate 15.h
    final topPadding = screenHeight * 0.006; // Approximate 5.h
    final imageheight = screenHeight * 0.18; // Approximate 150.h
    final gap30 = screenHeight * 0.036; // Approximate 30.h
    final gap40 = screenHeight * 0.048; // Approximate 40.h
    final gap20 = screenHeight * 0.024; // Approximate 20.h

    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
              left: horizontalPadding,
              right: horizontalPadding,
              bottom: bottomPadding,
              top: topPadding),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Gap(gap30),
                      Image.asset(
                        'assets/images/forget.png',
                        height: imageheight,
                        fit: BoxFit.contain,
                      ),
                      Gap(gap40),
                      BlocConsumer<AuthCubit, AuthState>(
                        listenWhen: (previous, current) => previous != current,
                        listener: (context, state) async {
                          if (state is AuthLoading) {
                            print("loading");
                            showLoadingDialog(context); // Show loading dialog
                          } else if (state is AuthError) {
                            Navigator.pop(context); // Pop loading dialog
                            await showErrorDialog(
                                context, state.message); // Show error dialog
                          } else if (state is ResetPasswordSent) {
                            Navigator.pop(context); // Pop loading dialog
                            showSuccessDialog(
                              // Use the new Success Dialog
                              context,
                              'Reset Password Email Sent!',
                              'A password reset link has been sent to your email. Please check your inbox and follow the instructions to reset your password.',
                            );
                          }
                        },
                        buildWhen: (previous, current) {
                          return previous != current;
                        },
                        builder: (context, state) {
                          return const PasswordResetThemed(); // Use themed PasswordReset widget
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: gap20), // Approximate 20.h
                child: const Text(
                  "Need Help | FAQ | Terms Of use",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Colors.red, // Red loading indicator
        ),
      ),
    );
  }

  Future<void> showErrorDialog(BuildContext context, String message) async {
    await AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.rightSlide,
      title: 'Error',
      desc: message,
      titleTextStyle: const TextStyle(color: Colors.black), // Black title text
      descTextStyle:
          const TextStyle(color: Colors.black), // Black description text
      headerAnimationLoop: false,
      dialogBackgroundColor: Colors.grey[200], // Light grey dialog background
      buttonsTextStyle:
          const TextStyle(color: Colors.black), // Black button text
      btnOkColor: Colors.red,
    ).show();
  }

  void showSuccessDialog(BuildContext context, String title, String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success, // Change to DialogType.success
      animType: AnimType.rightSlide,
      title: title,
      desc: message,
      titleTextStyle: const TextStyle(color: Colors.black), // Black title text
      descTextStyle:
          const TextStyle(color: Colors.black), // Black description text
      headerAnimationLoop: false,
      dialogBackgroundColor: Colors.grey[200], // Light grey dialog background
      buttonsTextStyle:
          const TextStyle(color: Colors.black), // Black button text
      btnOkText: 'OK', // Set button text to "OK"
      btnOkOnPress: () {
        // Action when OK is pressed
        context.pop(); // Go back to login page
      },
      btnOkColor: Colors.green[700], // Optional: Style OK button color
    ).show();
  }

  @override
  void initState() {
    super.initState();
    BlocProvider.of<AuthCubit>(context);
  }
}

class PasswordResetThemed extends StatefulWidget {
  const PasswordResetThemed({super.key});

  @override
  State<PasswordResetThemed> createState() => _PasswordResetThemedState();
}

class _PasswordResetThemedState extends State<PasswordResetThemed> {
  final TextEditingController emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Add a form key for validation

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final gap30 = screenHeight * 0.036; // Approximate 30.h
    final buttonHeight = screenHeight * 0.06; // Approximate 50
    final borderRadius = screenWidth * 0.02; // Approximate 8.0
    final fontSize16 = screenWidth * 0.04; // Approximate 16

    return Form(
      key: _formKey, // Assign the form key to the Form widget
      child: Column(
        children: [
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style:
                const TextStyle(color: Colors.black), // Input text color black
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email_outlined,
                  color: Colors.grey), // Email icon
              hintText: "Insira o endereço de e-mail", // Placeholder text
              hintStyle: const TextStyle(color: Colors.grey),
              labelText: null, // Remove label text
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: const BorderSide(color: Colors.grey), // Grey border
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: const BorderSide(
                    color: Colors.black), // Black focused border
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide:
                    const BorderSide(color: Colors.red), // Red error border
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: const BorderSide(
                    color: Colors.redAccent), // Red accent focused error border
              ),
              fillColor: Colors.grey[100],
              filled: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira seu e-mail'; // Please enter your email
              }
              if (!value.contains('@')) {
                return 'Por favor, insira um e-mail válido'; // Please enter a valid email
              }
              return null;
            },
          ),
          Gap(gap30),
          SizedBox(
            width: double.infinity,
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  context.read<AuthCubit>().resetPassword(emailController.text);
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: fontSize16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(borderRadius)),
                backgroundColor: Colors.red, // Red button
                foregroundColor: Colors.white, // White button text
              ),
              child: const Text(
                "Enviar código de verificação",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold), // White button text
              ),
            ),
          ),
        ],
      ),
    );
  }
}
