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

  // Page controller for form steps
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;

  // Define green theme colors
  final Color primaryGreen = Color(0xFF009639);  // Darker green similar to WhatsApp
  final Color secondaryGreen = Color(0xFF00AF45);
  final Color lightGreen = Color(0xFFE8F5E9);  // Light green background
  final Color darkGreen = Color(0xFF006E2B);  // Dark green for app bar

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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: primaryGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryGreen),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryGreen, width: 2),
          ),
          prefixIcon: Icon(icon, color: primaryGreen),
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          filled: true,
          fillColor: Colors.white,
        ),
        cursorColor: primaryGreen,
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
          if (label == "Phone Number" && value.length < 10) {
            return "Enter a valid phone number";
          }
          return null;
        },
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: lightGreen,
      appBar: AppBar(
        backgroundColor: darkGreen,
        elevation: 0,
        title: Text("Sign Up", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenSize.width * 0.05,
            vertical: 16,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // App Logo
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.medical_services_rounded,
                    size: 50,
                    color: primaryGreen,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Create your account',
                  style: TextStyle(
                    fontSize: isTablet ? 28 : 22,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                Text(
                  'Please fill out the form below',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey[700],
                  ),
                ),

                // Progress indicator
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _totalPages,
                          (index) => Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        width: screenSize.width * 0.25 / _totalPages,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage >= index ? primaryGreen : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),

                // Form Pages
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    margin: EdgeInsets.symmetric(vertical: 8),
                    padding: EdgeInsets.all(16),
                    child: PageView(
                      controller: _pageController,
                      physics: NeverScrollableScrollPhysics(),
                      onPageChanged: (page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                      children: [
                        // Page 1: Basic Information
                        ListView(
                          // Using ListView instead of SingleChildScrollView to maintain text field positions
                          physics: ClampingScrollPhysics(), // Prevents over-scrolling bounces
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                "Account Information",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryGreen,
                                ),
                              ),
                            ),
                            _buildTextField(
                              controller: _fullNameController,
                              label: "Full Name",
                              icon: Icons.person,
                            ),
                            _buildTextField(
                              controller: _emailController,
                              label: "Email",
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            _buildTextField(
                              controller: _passwordController,
                              label: "Password",
                              icon: Icons.lock,
                              isPassword: true,
                            ),
                            _buildTextField(
                              controller: _confirmPasswordController,
                              label: "Confirm Password",
                              icon: Icons.lock,
                              isPassword: true,
                            ),
                          ],
                        ),

                        // Page 2: Personal Details
                        ListView(
                          // Using ListView instead of SingleChildScrollView
                          physics: ClampingScrollPhysics(), // Prevents over-scrolling bounces
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                "Personal Details",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryGreen,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: DropdownButtonFormField<String>(
                                value: _selectedGender,
                                items: ["Select Gender", "Male", "Female", "Other"].map((gender) {
                                  return DropdownMenuItem(value: gender, child: Text(gender));
                                }).toList(),
                                onChanged: (value) => setState(() => _selectedGender = value!),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: primaryGreen),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.green.shade200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: primaryGreen, width: 2),
                                  ),
                                  prefixIcon: Icon(Icons.person_outline, color: primaryGreen),
                                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                validator: (value) {
                                  if (value == "Select Gender") return "Please select a gender";
                                  return null;
                                },
                              ),
                            ),
                            _buildTextField(
                              controller: _dobController,
                              label: "Date of Birth (DD/MM/YYYY)",
                              icon: Icons.calendar_today,
                            ),
                            _buildTextField(
                              controller: _ageController,
                              label: "Age",
                              icon: Icons.cake,
                              keyboardType: TextInputType.number,
                            ),
                            _buildTextField(
                              controller: _addressController,
                              label: "Address",
                              icon: Icons.location_on,
                            ),
                          ],
                        ),

                        // Page 3: Contact Information
                        ListView(
                          // Using ListView instead of SingleChildScrollView
                          physics: ClampingScrollPhysics(), // Prevents over-scrolling bounces
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                "Contact Information",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryGreen,
                                ),
                              ),
                            ),
                            _buildTextField(
                              controller: _phoneController,
                              label: "Phone Number",
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                            ),
                            _buildTextField(
                              controller: _altPhoneController,
                              label: "Alternative Phone Number",
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                            ),
                            _buildTextField(
                              controller: _guardianController,
                              label: "Guardian Name",
                              icon: Icons.supervisor_account,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Navigation and Submit Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      _currentPage > 0
                          ? TextButton.icon(
                        onPressed: _previousPage,
                        icon: Icon(Icons.arrow_back, color: primaryGreen),
                        label: Text("Back", style: TextStyle(color: primaryGreen)),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: primaryGreen),
                          ),
                        ),
                      )
                          : SizedBox(width: 100),

                      // Next or Submit button
                      _isLoading
                          ? CircularProgressIndicator(color: primaryGreen)
                          : _currentPage < _totalPages - 1
                          ? ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Next"),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 16),
                          ],
                        ),
                      )
                          : ElevatedButton(
                        onPressed: () => _signUp(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text("Sign Up", style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),

                // Login link
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                        "Already have an account? Login",
                        style: TextStyle(fontSize: 14, color: primaryGreen, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      resizeToAvoidBottomInset: false, // This prevents the screen from resizing when keyboard appears
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}