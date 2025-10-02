import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneNumberController = TextEditingController();
  String? _verificationId;

  Future<void> _sendOTP() async {
    String phoneNumber = _phoneNumberController.text.trim();
    if (phoneNumber.isNotEmpty) {
      try {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Auto-verification complete (usually on Android)
            await FirebaseAuth.instance.signInWithCredential(credential);
            // Navigate to your home screen or next step
          },
          verificationFailed: (FirebaseAuthException e) {
            // Handle verification failure (e.g., invalid phone number)
            print('Verification failed: ${e.message}');
            // Show an error message to the user
          },
          codeSent: (String verificationId, int? resendToken) async {
            // Code has been sent to the phone number
            setState(() {
              _verificationId = verificationId;
            });
            // Navigate to the OTP verification screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    OTPScreen(verificationId: verificationId),
              ),
            );
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            // Auto-retrieval of code timed out
            setState(() {
              _verificationId = verificationId;
            });
            // Optionally show a message to the user
          },
        );
      } catch (e) {
        print('Error sending OTP: $e');
        // Handle other errors
      }
    } else {
      // Show an error message if the phone number is empty
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phone Number Verification')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _phoneNumberController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixText: '+',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendOTP,
              child: const Text('Send OTP'),
            ),
          ],
        ),
      ),
    );
  }
}

class OTPScreen extends StatefulWidget {
  final String verificationId;

  const OTPScreen({super.key, required this.verificationId});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController _otpController = TextEditingController();

  Future<void> _verifyOTP() async {
    String smsCode = _otpController.text.trim();
    if (smsCode.isNotEmpty) {
      try {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: widget.verificationId,
          smsCode: smsCode,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
        // Navigate to your home screen or next step upon successful login
        print('Phone authentication successful!');
        // You can use Navigator.pushReplacement to go to the next screen
      } catch (e) {
        print('Error verifying OTP: $e');
        // Handle invalid OTP or other errors
        // Show an error message to the user
      }
    } else {
      // Show an error message if the OTP is empty
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OTP Verification')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter OTP',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyOTP,
              child: const Text('Verify OTP'),
            ),
          ],
        ),
      ),
    );
  }
}