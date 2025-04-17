import 'package:flutter/material.dart';
import 'package:medicos/screens/auth/login.dart';
import 'package:medicos/screens/auth/signup_screen.dart';
import 'package:medicos/screens/forgot_password_screen.dart';
import 'package:medicos/screens/home/home_screen.dart';
import 'package:medicos/screens/home_screen.dart';
import 'package:medicos/screens/login_screen.dart';
import 'package:medicos/screens/signup_screen.dart'; // Import Forgot Password Page

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case '/signup':
        return MaterialPageRoute(builder: (_) => SignupScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => HomeScreen());
      case '/forgot-password': // Added route for Forgot Password
        return MaterialPageRoute(builder: (_) => ForgotPasswordPage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Page not found!')),
          ),
        );
    }
  }
}
