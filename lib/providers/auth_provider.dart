import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  User? get user => _user;

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // ✅ Sign Up with Email (Fixed Parameter Passing)
  Future<String?> signUpWithEmail({
    required String email,
    required String password,
    required UserModel userModel,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = credential.user;

      if (_user != null) {
        // ✅ Ensure UID is stored in Firestore
        userModel = userModel.copyWith(uid: _user!.uid);
        await _firestore.collection('users').doc(_user!.uid).set(userModel.toMap());
      }

      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return "This email is already registered. Please log in.";
      } else if (e.code == 'weak-password') {
        return "Password is too weak. Please choose a stronger password.";
      }
      return e.message ?? "Signup failed. Try again.";
    } catch (e) {
      return "An unexpected error occurred: ${e.toString()}";
    }
  }

  // ✅ Sign In with Email
  Future<String?> signInWithEmail({required String email, required String password}) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = credential.user;
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Sign-in failed. Try again.";
    } catch (e) {
      return "An unexpected error occurred: ${e.toString()}";
    }
  }

  // ✅ Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }
}
