import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _altPhoneController = TextEditingController();
  final TextEditingController _guardianController = TextEditingController();

  String _selectedGender = "Select Gender";
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _signUp(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    UserModel userModel = UserModel(
      uid: "", // Will be assigned after Firebase signup
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      dob: _dobController.text.trim(),
      gender: _selectedGender,
      age: _ageController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      altPhone: _altPhoneController.text.trim(),
      guardianName: _guardianController.text.trim(),
    );

    String? errorMessage = await authProvider.signUpWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      userModel: userModel,
    );

    if (errorMessage == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }

    setState(() => _isLoading = false);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: Icon(icon),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "$label cannot be empty";
        if (label == "Email" && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return "Enter a valid email";
        }
        if (label == "Password" && value.length < 6) {
          return "Password must be at least 6 characters";
        }
        if (label == "Confirm Password" && value != _passwordController.text) {
          return "Passwords do not match";
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: 20),
                  SvgPicture.asset('assets/images/medicos_icon.svg', height: 150, width: 150),
                  SizedBox(height: 30),
                  Text('Create Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  _buildTextField(controller: _fullNameController, label: "Full Name", icon: Icons.person),
                  SizedBox(height: 20),
                  _buildTextField(controller: _emailController, label: "Email", icon: Icons.email),
                  SizedBox(height: 20),
                  _buildTextField(controller: _passwordController, label: "Password", icon: Icons.lock, isPassword: true),
                  SizedBox(height: 20),
                  _buildTextField(controller: _confirmPasswordController, label: "Confirm Password", icon: Icons.lock, isPassword: true),
                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    items: ["Select Gender", "Male", "Female", "Other"].map((gender) {
                      return DropdownMenuItem(value: gender, child: Text(gender));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedGender = value!),
                    decoration: InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
                  ),
                  SizedBox(height: 20),
                  _buildTextField(controller: _dobController, label: "Date of Birth (DD/MM/YYYY)", icon: Icons.calendar_today),
                  SizedBox(height: 20),
                  _buildTextField(controller: _ageController, label: "Age", icon: Icons.cake),
                  SizedBox(height: 20),
                  _buildTextField(controller: _addressController, label: "Address", icon: Icons.location_on),
                  SizedBox(height: 20),
                  _buildTextField(controller: _phoneController, label: "Phone Number", icon: Icons.phone),
                  SizedBox(height: 20),
                  _buildTextField(controller: _altPhoneController, label: "Alternative Phone Number", icon: Icons.phone),
                  SizedBox(height: 20),
                  _buildTextField(controller: _guardianController, label: "Guardian Name", icon: Icons.supervisor_account),
                  SizedBox(height: 20),
                  _isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: () => _signUp(context),
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                    child: Text("Sign Up", style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                    },
                    child: Text("Already have an account? Login", style: TextStyle(fontSize: 16, color: Colors.blue)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
