import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData; // Stores user details
  bool isLoading = true; // Track loading state
  String errorMessage = ""; // Store error messages

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // ✅ Fetch user data from Firestore
  Future<void> _fetchUserProfile() async {
    try {
      User? user = _auth.currentUser;

      if (user == null) {
        setState(() {
          errorMessage = "User is not logged in.";
          isLoading = false;
        });
        print("❌ User not logged in.");
        return;
      }

      print("✅ Logged-in User UID: ${user.uid}");

      DocumentSnapshot<Map<String, dynamic>> snapshot =
      await _firestore.collection('users').doc(user.uid).get();

      if (snapshot.exists) {
        print("📄 Firestore Document Found: ${snapshot.data()}");
        setState(() {
          userData = snapshot.data();
          isLoading = false;
        });
      } else {
        print("❌ No user document found in Firestore.");
        setState(() {
          errorMessage = "Profile data not found.";
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching user data: $e");
      setState(() {
        errorMessage = "Failed to fetch profile. Please try again.";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // 🔄 Show loader while fetching data
          : userData != null
          ? SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade300,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
            SizedBox(height: 20),

            // ✅ Display user data from Firestore
            _buildProfileField("Full Name", userData!['fullName']),
            _buildProfileField("Email", userData!['email']),
            _buildProfileField("Date of Birth", userData!['dob']),
            _buildProfileField("Gender", userData!['gender']),
            _buildProfileField("Age", userData!['age']),
            _buildProfileField("Address", userData!['address']),
            _buildProfileField("Phone Number", userData!['phone']),
            _buildProfileField("Alternate Phone", userData!['altPhone']),
            _buildProfileField("Guardian Name", userData!['guardianName']),
            _buildProfileField("User ID", userData!['uid']),

            SizedBox(height: 20),
          ],
        ),
      )
          : Center(
        child: Text(
          errorMessage.isNotEmpty ? errorMessage : "No profile data found.",
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
      ),
    );
  }

  // ✅ Helper widget to display profile fields
  Widget _buildProfileField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 4),
          Text(value ?? "N/A", style: TextStyle(fontSize: 16, color: Colors.black54)),
          Divider(),
        ],
      ),
    );
  }
}
