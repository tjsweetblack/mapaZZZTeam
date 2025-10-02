import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore
// For Authentication

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthCubit() : super(AuthInitial());

  User? get currentUser => _auth.currentUser;

  Future<void> createAccountAndLinkItWithGoogleAccount(
      String email,
      String password,
      GoogleSignInAccount googleUser,
      OAuthCredential credential) async {
    emit(AuthLoading());

    try {
      await _auth.createUserWithEmailAndPassword(
        email: googleUser.email,
        password: password,
      );
      await _auth.currentUser!.linkWithCredential(credential);
      await _auth.currentUser!.updateDisplayName(googleUser.displayName);
      await _auth.currentUser!.updatePhotoURL(googleUser.photoUrl);
      emit(UserSingupAndLinkedWithGoogle());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        emit(AuthError('Este e-mail já está associado a uma conta.'));
      } else {
        emit(AuthError('Ocorreu um erro ao criar sua conta.'));
      }
    } catch (e) {
      emit(
          AuthError('Ocorreu um erro inesperado. Por favor, tente novamente.'));
    }
  }

  Future<void> resetPassword(String email) async {
    emit(AuthLoading());
    try {
      await _auth.sendPasswordResetEmail(email: email);
      emit(ResetPasswordSent());
    } on FirebaseAuthException catch (_) {
      // Avoid revealing if an email is registered or not.
      emit(AuthError(
          'Não foi possível enviar o e-mail de redefinição de senha. Por favor, verifique o endereço de e-mail.'));
    } catch (e) {
      emit(
          AuthError('Ocorreu um erro inesperado. Por favor, tente novamente.'));
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    emit(AuthLoading());
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user!.emailVerified) {
        // Update Firestore lastLogin field
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({
          'lastLogin': FieldValue.serverTimestamp(),
        });

        emit(UserSignIn());
      } else {
        await _auth.signOut();
        emit(AuthError(
            'E-mail não verificado. Por favor, verifique seu e-mail.'));
        emit(UserNotVerified());
      }
    } on FirebaseAuthException catch (_) {
      // Handle specific Firebase auth errors with a user-friendly message for invalid credentials.
      // Common codes: 'user-not-found', 'wrong-password', 'invalid-email', 'invalid-credential'
      emit(AuthError(
          'Credenciais de login inválidas. Por favor, tente novamente.'));
    } catch (e) {
      emit(
          AuthError('Ocorreu um erro inesperado. Por favor, tente novamente.'));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        emit(AuthError('Falha ao entrar com o Google.'));
        return;
      }
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential authResult =
          await _auth.signInWithCredential(credential);
      if (authResult.additionalUserInfo!.isNewUser) {
        // Delete the user account if it is a new user to Create it automatically in Next Screen
        await _auth.currentUser!.delete();

        emit(IsNewUser(googleUser: googleUser, credential: credential));
      } else {
        emit(UserSignIn());
      }
    } on FirebaseAuthException catch (_) {
      // e.g., 'account-exists-with-different-credential'
      emit(AuthError(
          'Falha ao entrar com o Google. Uma conta já pode existir com um método de login diferente.'));
    } catch (e) {
      emit(AuthError(
          'Ocorreu um erro inesperado durante o login com o Google.'));
    }
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    await _auth.signOut();
    emit(UserSignedOut());
  }

  Future<void> signUpWithEmail(
      String name, String email, String password, String phoneNumber) async {
    emit(AuthLoading());
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _auth.currentUser!.updateDisplayName(name);
      try {
        await _auth.currentUser!.sendEmailVerification();
        print("Verification email sent successfully");
      } catch (e) {
        print("Error sending verification email: $e");
        // Handle error
      }

      User? user = userCredential.user;
      if (user != null) {
        // Create a new cart document
        DocumentReference cartDocRef = _firestore.collection('cart').doc();
        await cartDocRef.set({
          'items': [], // Initialize with an empty items array
          'userId': user.uid, // Add user ID to cart for reference
          'cartTotalPrice': 0.0, // Initialize cart total price
          'dateCreated': FieldValue.serverTimestamp(), // Add timestamp
        });

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': user.email,
          'phoneNumber': phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': 0,
          'role': 'user', // Default role
          'cart': cartDocRef.id,
          'favorites': [], // Initialize with an empty favorites array
          // Add cart ID to user document
        });
      }
      emit(UserSingupButNotVerified());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        emit(AuthError('A senha fornecida é muito fraca.'));
      } else if (e.code == 'email-already-in-use') {
        emit(AuthError('Já existe uma conta para esse e-mail.'));
      } else {
        emit(AuthError(
            'E-mail ou senha inválidos. Por favor, tente novamente.'));
      }
    } catch (e) {
      emit(
          AuthError('Ocorreu um erro inesperado. Por favor, tente novamente.'));
    }
  }

  // Initiates phone number sign-up
  Future<void> signUpWithPhoneNumber(String phoneNumber) async {
    try {
      emit(AuthLoading());

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          emit(UserSignIn());
        },
        verificationFailed: (FirebaseAuthException e) {
          if (e.code == 'invalid-phone-number') {
            emit(AuthError("O número de telefone fornecido não é válido."));
          } else {
            emit(AuthError(
                "Falha ao verificar o número de telefone. Por favor, tente novamente mais tarde."));
          }
        },
        codeSent: (String verificationId, int? resendToken) async {
          // Emit the PhoneVerificationSent state with the verificationId
          emit(PhoneVerificationSent(verificationId));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          emit(AuthError("Tempo de recuperação do código esgotado."));
        },
      );
    } catch (e) {
      emit(
          AuthError("Ocorreu um erro inesperado. Por favor, tente novamente."));
    }
  }

  // Verifies the OTP sent to the phone number
  Future<void> verifyPhoneOTP(String verificationId, String otp) async {
    try {
      emit(AuthLoading());

      // Create a PhoneAuthCredential with the verification ID and OTP
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      // Sign in using the credential
      await _auth.signInWithCredential(credential);
      emit(UserSignIn());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        emit(AuthError("O código OTP que você digitou é inválido."));
      } else {
        emit(
            AuthError("Falha ao verificar o OTP. Por favor, tente novamente."));
      }
    } catch (e) {
      emit(
          AuthError("Ocorreu um erro inesperado. Por favor, tente novamente."));
    }
  }
}
