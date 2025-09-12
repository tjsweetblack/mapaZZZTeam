import 'package:auth_bloc/screens/login/ui/login_screen.dart';
import 'package:auth_bloc/screens/signup/ui/create_password.dart';
import 'package:auth_bloc/screens/signup/ui/terms_of_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/cubit/auth_cubit.dart';
import '../../../routing/routes.dart';
import '../../../theming/styles.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailPhoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color.fromARGB(255, 255, 255, 255), // Match background color
      appBar: AppBar(
        //Added AppBar for back button
        backgroundColor:
            Colors.transparent, // Make AppBar background transparent
        elevation: 0, // Remove shadow
        iconTheme:
            const IconThemeData(color: Colors.black), // Set back button color
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) async {
          if (state is AuthLoading) {
            showLoadingDialog(context);
          } else if (state is AuthError) {
            Navigator.pop(context);
            showErrorDialog(context, state.message);
          } else if (state is UserSingupButNotVerified) {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => sucessScreen(
                  email: emailPhoneController.text.trim(), // Pass the email
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return _buildSignupEmailPage(context);
        },
      ),
    );
  }

  Widget _buildSignupEmailPage(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 32), // Add some top spacing
              Image.asset(
                'assets/images/logo1.png', // Replace with your actual logo path
                height: 144,
                color: const Color(0xFFE32626), // Match logo color
              ),
              const SizedBox(height: 16),
              Text(
                "Criar Sua Conta",
                style: TextStyles.font24Blue700Weight.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.black), // Match title style
              ),
              const SizedBox(height: 8),
              Text(
                "Crie uma conta para explorar noticias.",
                style: TextStyles.font14Grey400Weight.copyWith(
                    fontSize: 16,
                    color:
                        Colors.black.withOpacity(0.6)), // Match subtitle style
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: fullNameController,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      hintText: "Nome Completo",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      hintText: "Telefone",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: emailPhoneController,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      hintText: "Email ou telefone",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // For now, directly navigate to the next screen
                    final String fullName = fullNameController.text.trim();
                    final String phone = phoneController.text.trim();
                    final String emailOrPhone =
                        emailPhoneController.text.trim();

                    if (fullName.isEmpty ||
                        phone.isEmpty ||
                        emailOrPhone.isEmpty) {
                      // Show an error if fields are empty
                      showErrorDialog(
                          context, "Por favor, preencha todos os campos.");
                      return;
                    }

                    // Navigate to TermsAndServiceScreen, passing a callback for acceptance
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TermsAndServiceScreen(
                          onAccept: () {
                            // This code runs when 'Accept' is pressed in TermsAndServiceScreen
                            // Navigate from Terms screen to CreatePasswordScreen
                            Navigator.pushReplacement(
                              // Use pushReplacement if you don't want to go back to Terms
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreatePasswordScreen(
                                  emailOrPhone: emailOrPhone,
                                  fullName: fullName,
                                  phoneNumber: phone,
                                ),
                              ),
                            );
                          },
                          onDeny: () {
                            // Optional: Define what happens on Deny.
                            // Currently, it shows a dialog within TermsAndServiceScreen.
                            // You could pop back here if needed: Navigator.pop(context);
                            print("Terms Denied");
                          },
                        ),
                      ),
                    );
                    // In a real scenario, you might want to check if the email/phone exists
                    // or initiate the signup process up to the password stage.
                    // context.read<AuthCubit>().checkEmailOrPhone(emailPhoneController.text);
                  },
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(110.0),
                      ),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white),
                  child: const Text(
                    "Continuar",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              const SizedBox(height: 16),
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
          color: Color(0xFFE32626),
        ),
      ),
    );
  }

  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Error',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class sucessScreen extends StatelessWidget {
  final String email; // Add email parameter

  const sucessScreen({Key? key, required this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFBE2425),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFBE2425),
              Color(0xFFA6090A),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 400,
                  height: 400,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/sucess.png"),
                      fit: BoxFit.contain,
                    ),
                  ),
                  child: const Align(
                    alignment: Alignment(0.4, -0.8),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Conta criada com sucesso!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Verifique o seu email para continuar: $email",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Se você não encontrar o email, verifique sua pasta de spam ou lixo eletrônico.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 300,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 14),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                    ),
                    child: const Text(
                      'Entrar',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
