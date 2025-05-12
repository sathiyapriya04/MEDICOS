import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

// Add this new widget for scanning animation
class ScanningAnimation extends StatefulWidget {
  final Widget child;
  final bool isScanning;

  const ScanningAnimation({
    Key? key,
    required this.child,
    required this.isScanning,
  }) : super(key: key);

  @override
  _ScanningAnimationState createState() => _ScanningAnimationState();
}

class _ScanningAnimationState extends State<ScanningAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isScanning)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.green.withOpacity(0.3),
                      Colors.transparent,
                      Colors.green.withOpacity(0.3),
                    ],
                    stops: [0.0, _animation.value, 1.0],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Map<String, dynamic>? userData; // Stores user details
  bool isLoading = true; // Track loading state
  String errorMessage = ""; // Store error messages
  bool isEditing = false;
  String? profileImageUrl;

  // Text controllers for editable fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _altPhoneController = TextEditingController();
  final TextEditingController _guardianController = TextEditingController();

  // Add this new variable
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    // Dispose all controllers
    _nameController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _guardianController.dispose();
    super.dispose();
  }

  // ✅ Fetch user data from Firestore - Keeping original logic
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
          profileImageUrl = userData!['profileImageUrl'];
          print(
            "🖼️ Profile Image URL: $profileImageUrl",
          ); // Debug log for image URL
          isLoading = false;
        });
        _initControllers();
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

  // Initialize controllers with user data
  void _initControllers() {
    if (userData != null) {
      _nameController.text = userData!['fullName'] ?? '';
      _dobController.text = userData!['dob'] ?? '';
      _genderController.text = userData!['gender'] ?? '';
      _ageController.text = userData!['age'] ?? '';
      _addressController.text = userData!['address'] ?? '';
      _phoneController.text = userData!['phone'] ?? '';
      _altPhoneController.text = userData!['altPhone'] ?? '';
      _guardianController.text = userData!['guardianName'] ?? '';
    }
  }

  // Save updated profile
  Future<void> _saveProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      await _firestore.collection('users').doc(user.uid).update({
        'fullName': _nameController.text,
        'dob': _dobController.text,
        'gender': _genderController.text,
        'age': _ageController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'altPhone': _altPhoneController.text,
        'guardianName': _guardianController.text,
      });

      await _fetchUserProfile();
      setState(() {
        isEditing = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
    } catch (e) {
      print("Error updating profile: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Handle profile picture selection and upload
  Future<void> _selectProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    try {
      // Request storage permission first
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Storage permission is required to access photos'),
            ),
          );
          return;
        }
      }

      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.photo_camera, color: Colors.green),
                  title: Text('Take Photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: Colors.green),
                  title: Text('Choose from Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                SizedBox(height: 8),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      // Request specific permissions based on source
      if (source == ImageSource.gallery) {
        if (Platform.isAndroid) {
          final status = await Permission.photos.request();
          if (!status.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Gallery permission is required to select photos',
                ),
              ),
            );
            return;
          }
        }
      } else if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Camera permission is required to take photos'),
            ),
          );
          return;
        }
      }

      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          isLoading = true;
          isScanning = true;
        });

        try {
          User? user = _auth.currentUser;
          if (user == null) throw Exception("User not logged in");

          final storageRef = _storage.ref();
          final profileImageRef = storageRef.child(
            'profile_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg',
          );

          // Show uploading message
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Uploading photo...')));

          await profileImageRef.putFile(File(image.path));
          final downloadURL = await profileImageRef.getDownloadURL();

          await _firestore.collection('users').doc(user.uid).update({
            'profileImageUrl': downloadURL,
          });

          setState(() {
            profileImageUrl = downloadURL;
            isLoading = false;
            isScanning = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile picture updated successfully')),
          );
        } catch (e) {
          print("Error uploading image: $e");
          setState(() {
            isLoading = false;
            isScanning = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading profile picture: $e')),
          );
        }
      }
    } catch (e) {
      print("Error selecting image: $e");
      setState(() {
        isScanning = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Profile" : "Profile"),
        backgroundColor: Colors.green,
        actions: [
          if (!isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            )
          else
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.cancel),
                  onPressed: () {
                    setState(() {
                      isEditing = false;
                      _initControllers(); // Reset to original values
                    });
                  },
                ),
                IconButton(icon: Icon(Icons.save), onPressed: _saveProfile),
              ],
            ),
        ],
      ),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(),
              ) // 🔄 Show loader while fetching data
              : userData != null
              ? SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile picture section
                    Center(
                      child: GestureDetector(
                        onTap: isEditing ? _selectProfilePicture : null,
                        child: Stack(
                          children: [
                            ScanningAnimation(
                              isScanning: isScanning,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.green,
                                    width: 3.0,
                                  ),
                                ),
                                child:
                                    profileImageUrl != null &&
                                            profileImageUrl!.isNotEmpty
                                        ? ClipOval(
                                          child: Image.network(
                                            profileImageUrl!,
                                            fit: BoxFit.cover,
                                            width: 120,
                                            height: 120,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              print(
                                                "❌ Error loading profile image: $error",
                                              );
                                              return Icon(
                                                Icons.person,
                                                size: 80,
                                                color: Colors.white,
                                              );
                                            },
                                            loadingBuilder: (
                                              context,
                                              child,
                                              loadingProgress,
                                            ) {
                                              if (loadingProgress == null)
                                                return child;
                                              print(
                                                "🔄 Loading profile image: ${loadingProgress.cumulativeBytesLoaded} / ${loadingProgress.expectedTotalBytes}",
                                              );
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value:
                                                      loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null
                                                          ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              loadingProgress
                                                                  .expectedTotalBytes!
                                                          : null,
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                        : Icon(
                                          Icons.person,
                                          size: 80,
                                          color: Colors.white,
                                        ),
                              ),
                            ),
                            if (isEditing)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // User information
                    isEditing ? _buildEditableForm() : _buildProfileDetails(),
                  ],
                ),
              )
              : Center(
                child: Text(
                  errorMessage.isNotEmpty
                      ? errorMessage
                      : "No profile data found.",
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
    );
  }

  // Display profile details when not editing
  Widget _buildProfileDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard("Personal Information", [
          _buildProfileField("Full Name", userData!['fullName']),
          _buildProfileField("Email", userData!['email']),
          _buildProfileField("Date of Birth", userData!['dob']),
          _buildProfileField("Gender", userData!['gender']),
          _buildProfileField("Age", userData!['age']),
        ]),

        SizedBox(height: 16),

        _buildInfoCard("Contact Information", [
          _buildProfileField("Address", userData!['address']),
          _buildProfileField("Phone Number", userData!['phone']),
          _buildProfileField("Alternate Phone", userData!['altPhone']),
        ]),

        SizedBox(height: 16),

        _buildInfoCard("Other Information", [
          _buildProfileField("Guardian Name", userData!['guardianName']),
          _buildProfileField("User ID", userData!['uid']),
        ]),
      ],
    );
  }

  // Card container for profile sections
  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Divider(color: Colors.grey.shade300, thickness: 1),
            SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  // Individual profile field
  Widget _buildProfileField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(child: Text(value ?? "N/A", style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  // Editable form for profile editing
  Widget _buildEditableForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard("Personal Information", [
          _buildTextField("Full Name", _nameController),
          Text("Email: ${userData!['email']}", style: TextStyle(fontSize: 16)),
          _buildTextField("Date of Birth", _dobController),
          _buildTextField("Gender", _genderController),
          _buildTextField("Age", _ageController),
        ]),

        SizedBox(height: 16),

        _buildInfoCard("Contact Information", [
          _buildTextField("Address", _addressController),
          _buildTextField("Phone Number", _phoneController),
          _buildTextField("Alternate Phone", _altPhoneController),
        ]),

        SizedBox(height: 16),

        _buildInfoCard("Other Information", [
          _buildTextField("Guardian Name", _guardianController),
          Text("User ID: ${userData!['uid']}", style: TextStyle(fontSize: 16)),
        ]),
      ],
    );
  }

  // Text field for editable form
  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
