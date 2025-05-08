import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isLoading = false;
  String? _errorMessage;

  User? _user;
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = credential.user;

      if (_user != null) {
        // ✅ Ensure UID is stored in Firestore
        userModel = userModel.copyWith(uid: _user!.uid);
        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .set(userModel.toMap());
      }

      _isLoading = false;
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      if (e.code == 'email-already-in-use') {
        _errorMessage = "This email is already registered. Please log in.";
      } else if (e.code == 'weak-password') {
        _errorMessage =
            "Password is too weak. Please choose a stronger password.";
      }
      notifyListeners();
      return _errorMessage;
    } catch (e) {
      _isLoading = false;
      _errorMessage = "An unexpected error occurred: ${e.toString()}";
      notifyListeners();
      return _errorMessage;
    }
  }

  // ✅ Sign In with Email
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = credential.user;

      _isLoading = false;
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = e.message ?? "Sign-in failed. Try again.";
      notifyListeners();
      return _errorMessage;
    } catch (e) {
      _isLoading = false;
      _errorMessage = "An unexpected error occurred: ${e.toString()}";
      notifyListeners();
      return _errorMessage;
    }
  }

  // Google Sign In
  Future<String?> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Begin interactive sign in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return "Google sign in was cancelled";
      }

      try {
        // Obtain auth details from request
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Create credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in with Firebase
        final userCredential = await _auth.signInWithCredential(credential);
        _user = userCredential.user;

        if (_user != null) {
          // Store user data in Firestore
          await _firestore.collection('users').doc(_user!.uid).set({
            'email': _user!.email,
            'name': _user!.displayName,
            'photoUrl': _user!.photoURL,
            'lastLogin': FieldValue.serverTimestamp(),
            'signInMethod': 'google',
          }, SetOptions(merge: true));
        }

        _isLoading = false;
        notifyListeners();
        return null; // Success
      } catch (authError) {
        _isLoading = false;
        _errorMessage = "Authentication failed: ${authError.toString()}";
        notifyListeners();
        return _errorMessage;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Google sign in failed: ${e.toString()}";
      notifyListeners();
      return _errorMessage;
    }
  }

  // Facebook Sign In
  Future<String?> signInWithFacebook() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final LoginResult loginResult = await FacebookAuth.instance.login();
      if (loginResult.status != LoginStatus.success) {
        _isLoading = false;
        notifyListeners();
        return "Facebook sign in was cancelled";
      }

      final OAuthCredential credential = FacebookAuthProvider.credential(
        loginResult.accessToken!.token,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      _user = userCredential.user;

      if (_user != null) {
        // Store user data in Firestore
        await _firestore.collection('users').doc(_user!.uid).set({
          'email': _user!.email,
          'name': _user!.displayName,
          'photoUrl': _user!.photoURL,
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Facebook sign in failed: ${e.toString()}";
      notifyListeners();
      return _errorMessage;
    }
  }

  // Apple Sign In
  Future<String?> signInWithApple() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      _user = userCredential.user;

      if (_user != null) {
        // Store user data in Firestore
        await _firestore.collection('users').doc(_user!.uid).set({
          'email': _user!.email,
          'name':
              _user!.displayName ??
              '${appleCredential.givenName} ${appleCredential.familyName}',
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Apple sign in failed: ${e.toString()}";
      notifyListeners();
      return _errorMessage;
    }
  }

  // ✅ Sign Out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
        FacebookAuth.instance.logOut(),
      ]);

      _user = null;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Error signing out: ${e.toString()}";
      notifyListeners();
    }
  }
}
