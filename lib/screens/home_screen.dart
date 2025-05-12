import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medicos/screens/profile_screen.dart';
import 'package:medicos/screens/reminder_screen.dart';
import 'package:medicos/screens/symptom_checker_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:medicos/services/notification_service.dart';
import 'package:medicos/screens/settings_screen.dart';
import 'package:image_picker/image_picker.dart'; // Added for camera functionality

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  String _recognizedText = '';
  String _assistantResponse = '';
  late AnimationController _animationController;
  late Animation<double> _animation;
  final ImagePicker _picker = ImagePicker(); // Added for camera functionality
  Map<String, dynamic>? userProfileData; // Add this for profile data
  bool isLoadingProfile = true; // Add this for loading state
  String? avatarUrl; // Add this for avatar URL

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _fetchUserProfile(); // Add this to fetch profile data
  }

  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _listen() async {
    var status = await Permission.microphone.status;

    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }

    if (status.isGranted) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == "done" || val == "notListening") {
            setState(() => _isListening = false);
            if (_recognizedText.isNotEmpty) {
              _processCommand(_recognizedText.toLowerCase());
            }
          }
        },
        onError: (val) {
          setState(() => _isListening = false);
          _showError(val.errorMsg);
        },
      );

      if (available) {
        setState(() {
          _isListening = true;
          _recognizedText = '';
          _assistantResponse = '';
        });
        _speech.listen(
          onResult:
              (val) => setState(() {
                _recognizedText = val.recognizedWords;
              }),
        );
      } else {
        setState(() => _isListening = false);
        _showError('Speech recognition unavailable.');
      }
    } else {
      _showError(
        'Microphone permission denied. Please enable it from app settings.',
      );
    }
  }

  Future<void> _processCommand(String input) async {
    String response;

    if (input.contains("open reminder")) {
      response = "Opening your reminders.";
      await _flutterTts.speak(response);
      setState(() => _assistantResponse = response);
      await Future.delayed(Duration(milliseconds: 500));
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReminderScreen()),
      );
      _clearResponseAfterDelay();
    } else if (input.contains("open profile")) {
      response = "Sure! Taking you to your profile.";
      await _flutterTts.speak(response);
      setState(() => _assistantResponse = response);
      await Future.delayed(Duration(milliseconds: 500));
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen()),
      );
      _clearResponseAfterDelay();
    } else if (input.contains("return home") || input.contains("go home")) {
      response = "Heading back to the home screen.";
      await _flutterTts.speak(response);
      setState(() => _assistantResponse = response);
      await Future.delayed(Duration(milliseconds: 500));
      Navigator.popUntil(context, (route) => route.isFirst);
      _clearResponseAfterDelay();
    } else if (input.contains("open symptom checker")) {
      response = "Opening Symptom Checker.";
      await _flutterTts.speak(response);
      setState(() => _assistantResponse = response);
      await Future.delayed(Duration(milliseconds: 500));
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SymptomCheckerScreen()),
      );
      _clearResponseAfterDelay();
    } else if (input.contains("open camera")) {
      response = "Opening Camera.";
      await _flutterTts.speak(response);
      setState(() => _assistantResponse = response);
      await Future.delayed(Duration(milliseconds: 500));
      _openCamera();
      _clearResponseAfterDelay();
    } else if (input.contains("upload pdf")) {
      response = "Opening PDF uploader.";
      await _flutterTts.speak(response);
      setState(() => _assistantResponse = response);
      await Future.delayed(Duration(milliseconds: 500));
      _pickPDF();
      _clearResponseAfterDelay();
    } else {
      response =
          "I heard: '$input'. Let me know if you want to open reminders, profile, camera, or upload PDF.";
      setState(() => _assistantResponse = response);
      await _flutterTts.speak(response);
      _clearResponseAfterDelay();
    }

    setState(() {
      _recognizedText = '';
    });
  }

  void _clearResponseAfterDelay() async {
    await Future.delayed(Duration(seconds: 3));
    setState(() {
      _assistantResponse = '';
    });
  }

  void _showError(String error) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Error"),
            content: Text(error),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
    );
  }

  Future<void> _openCamera() async {
    try {
      // Show bottom sheet to choose between camera and gallery
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: Icon(
                    Icons.photo_camera,
                    color: Colors.green,
                    size: 28,
                  ),
                  title: Text('Take Photo', style: TextStyle(fontSize: 16)),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                Divider(),
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: Colors.green,
                    size: 28,
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: TextStyle(fontSize: 16),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      // Request appropriate permission
      if (source == ImageSource.camera) {
        var status = await Permission.camera.status;
        if (!status.isGranted) {
          status = await Permission.camera.request();
        }
        if (!status.isGranted) {
          _showError(
            'Camera permission denied. Please enable it from app settings.',
          );
          return;
        }
      } else if (source == ImageSource.gallery) {
        if (Platform.isAndroid) {
          var status = await Permission.photos.request();
          print('Photos permission status: $status');
          if (!status.isGranted) {
            _showError(
              'Photos permission denied. Please enable it from app settings.',
            );
            return;
          }
        }
      }

      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (photo != null) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );

        try {
          // Get current user
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) throw Exception("User not logged in");

          // Create a reference to Firebase Storage
          final storageRef = FirebaseStorage.instance.ref();
          final imageRef = storageRef.child(
            'camera_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg',
          );

          // Upload the file
          await imageRef.putFile(File(photo.path));

          // Get the download URL
          final downloadURL = await imageRef.getDownloadURL();

          // Save the image URL to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('camera_images')
              .add({
                'imageUrl': downloadURL,
                'timestamp': FieldValue.serverTimestamp(),
                'source': source == ImageSource.camera ? 'camera' : 'gallery',
              });

          // Close loading indicator
          Navigator.pop(context);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Photo uploaded successfully!"),
              backgroundColor: Colors.green,
            ),
          );

          // Show the captured/selected image
          showDialog(
            context: context,
            builder:
                (context) => Dialog(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.network(downloadURL, fit: BoxFit.cover),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Close'),
                      ),
                    ],
                  ),
                ),
          );
        } catch (e) {
          // Close loading indicator
          Navigator.pop(context);
          throw e;
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        String? filePath = result.files.single.path;
        String fileName = result.files.single.name;

        if (filePath != null) {
          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(child: CircularProgressIndicator()),
          );

          try {
            // Upload to Firebase Storage
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) {
              throw Exception('User not logged in');
            }

            // Create a reference to the location you want to upload to in Firebase Storage
            final storageRef = FirebaseStorage.instance.ref();
            final pdfRef = storageRef.child(
              'pdfs/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$fileName',
            );

            // Upload the file
            await pdfRef.putFile(File(filePath));

            // Get the download URL
            final downloadURL = await pdfRef.getDownloadURL();

            // Store the reference in Firestore
            await FirebaseFirestore.instance.collection('pdfs').add({
              'userId': user.uid,
              'fileName': fileName,
              'downloadURL': downloadURL,
              'uploadedAt': FieldValue.serverTimestamp(),
              'fileSize': result.files.single.size,
            });

            // Close loading dialog
            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("PDF uploaded successfully!"),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            // Close loading dialog
            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error uploading PDF: $e"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // User canceled the picker
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("PDF upload canceled"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error uploading PDF: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _setAlarm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReminderScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade800, Colors.green.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          "Medicos",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('/');
              },
              icon: Icon(Icons.logout, color: Colors.white),
              tooltip: "Logout",
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade50, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade800, Colors.green.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.green.shade800,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      user != null
                          ? "${user.email?.split('@')[0] ?? 'User'}"
                          : "Guest",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Medical Assistant",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              _buildMenuTile(
                icon: Icons.home,
                title: "Home",
                onTap: () => Navigator.pop(context),
              ),
              _buildMenuTile(
                icon: Icons.account_circle,
                title: "Profile",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                  );
                },
              ),
              _buildMenuTile(
                icon: Icons.medication,
                title: "Symptom Checker",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SymptomCheckerScreen(),
                    ),
                  );
                },
              ),
              _buildMenuTile(
                icon: Icons.calendar_today,
                title: "Reminders",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ReminderScreen()),
                  );
                },
              ),
              _buildMenuTile(
                icon: Icons.camera_alt,
                title: "Photo Upload",
                onTap: () {
                  Navigator.pop(context);
                  _openCamera();
                },
              ),
              Divider(color: Colors.green.shade200),
              _buildMenuTile(
                icon: Icons.settings,
                title: "Settings",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsScreen()),
                  );
                },
              ),
              _buildMenuTile(
                icon: Icons.picture_as_pdf,
                title: "Upload PDF",
                onTap: () {
                  Navigator.pop(context);
                  _pickPDF();
                },
              ),
              _buildMenuTile(
                icon: Icons.alarm,
                title: "Alarm",
                onTap: () {
                  Navigator.pop(context);
                  _setAlarm();
                },
              ),
            ],
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _animation,
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),

                    // Welcome Section
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 15 : 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: _updateAvatar,
                                child: Container(
                                  width: isSmallScreen ? 60 : 70,
                                  height: isSmallScreen ? 60 : 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child:
                                        avatarUrl != null
                                            ? Image.network(
                                              avatarUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return Container(
                                                  color: Colors.green.shade100,
                                                  child: Icon(
                                                    Icons.person,
                                                    size:
                                                        isSmallScreen ? 35 : 40,
                                                    color:
                                                        Colors.green.shade600,
                                                  ),
                                                );
                                              },
                                              loadingBuilder: (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Center(
                                                  child: CircularProgressIndicator(
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                                );
                                              },
                                            )
                                            : Container(
                                              color: Colors.green.shade100,
                                              child: Icon(
                                                Icons.person,
                                                size: isSmallScreen ? 35 : 40,
                                                color: Colors.green.shade600,
                                              ),
                                            ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade600,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: isSmallScreen ? 15 : 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user != null
                                      ? "Hello, ${userProfileData?['fullName']?.split(' ')[0] ?? user.email?.split('@')[0] ?? 'User'}!"
                                      : "Hello, Guest!",
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 18 : 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  "Your AI-powered medication assistant",
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 15,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 25),

                    // Assistant Response
                    if (_assistantResponse.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        margin: EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.green,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _assistantResponse,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Section Title
                    Text(
                      "Quick Access",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 15),

                    // Quick Access Cards - Modified as requested
                    GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: screenSize.width > 600 ? 3 : 2,
                      childAspectRatio: isSmallScreen ? 0.95 : 1.1,
                      crossAxisSpacing: isSmallScreen ? 10 : 15,
                      mainAxisSpacing: isSmallScreen ? 10 : 15,
                      children: [
                        _buildFeatureCard(
                          icon: Icons.medication,
                          title: "Symptom Checker",
                          color: Colors.orangeAccent,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SymptomCheckerScreen(),
                              ),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          icon: Icons.alarm,
                          title: "Alarm",
                          color: Colors.red,
                          onTap: () {
                            _setAlarm();
                          },
                        ),
                        _buildFeatureCard(
                          icon: Icons.picture_as_pdf,
                          title: "Upload PDF",
                          color: Colors.purple,
                          onTap: () {
                            _pickPDF();
                          },
                        ),
                        _buildFeatureCard(
                          icon: Icons.camera_alt,
                          title: "Photo Upload",
                          color: Colors.teal,
                          onTap: () {
                            _openCamera();
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: 25),

                    // Simplified Voice Assistant Section - Reduced size
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 10 : 15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade100, Colors.blue.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.blue.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.2),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.assistant,
                                color: Colors.blue.shade700,
                                size: isSmallScreen ? 20 : 22,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Voice Assistant",
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 15),
                          GestureDetector(
                            onTap: _isListening ? null : _listen,
                            child: Container(
                              width: 55, // Reduced from 70
                              height: 55, // Reduced from 70
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors:
                                      _isListening
                                          ? [
                                            Colors.red.shade400,
                                            Colors.red.shade700,
                                          ]
                                          : [
                                            Colors.blue.shade400,
                                            Colors.blue.shade700,
                                          ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        _isListening
                                            ? Colors.red.withOpacity(0.4)
                                            : Colors.blue.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isListening ? Icons.hearing : Icons.mic,
                                color: Colors.white,
                                size: 26, // Reduced from 32
                              ),
                            ),
                          ),
                          if (_recognizedText.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Text(
                                  "\"$_recognizedText\"",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.blue.shade800,
                                    fontSize: isSmallScreen ? 12 : 14,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: 80), // Space for FAB
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ReminderScreen()),
          );
        },
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade500, Colors.green.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.4),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.calendar_month_outlined,
                color: Colors.white,
                size: 28,
              ),
              Positioned(
                right: 18,
                bottom: 18,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.shade700, width: 2),
                  ),
                  child: Icon(
                    Icons.add,
                    color: Colors.green.shade700,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.green),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
      ),
      onTap: onTap,
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
    );
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.settings, color: Colors.green),
                SizedBox(width: 10),
                Text("Settings"),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.notifications_active,
                      color: Colors.green,
                    ),
                    title: Text("Notification Settings"),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Notification settings coming soon!"),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.color_lens, color: Colors.green),
                    title: Text("App Theme"),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Theme settings coming soon!")),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.language, color: Colors.green),
                    title: Text("Language"),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Language settings coming soon!"),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.info_outline, color: Colors.green),
                    title: Text("About App"),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("About page coming soon!")),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Close"),
                style: TextButton.styleFrom(foregroundColor: Colors.green),
              ),
            ],
          ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: isSmallScreen ? 26 : 30, color: color),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (docSnapshot.exists) {
          setState(() {
            userProfileData = docSnapshot.data();
            avatarUrl = userProfileData!['avatarUrl'];
            isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching profile: $e");
      setState(() {
        isLoadingProfile = false;
      });
    }
  }

  Future<void> _updateAvatar() async {
    try {
      // Show bottom sheet to choose between camera and gallery
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.photo_camera),
                  title: Text('Take Photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Choose from Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );

        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) throw Exception("User not logged in");

          // Upload to Firebase Storage
          final storageRef = FirebaseStorage.instance.ref();
          final avatarRef = storageRef.child(
            'avatars/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg',
          );

          await avatarRef.putFile(File(image.path));
          final downloadURL = await avatarRef.getDownloadURL();

          // Update Firestore with avatar URL
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
                'avatarUrl': downloadURL,
                'avatarUpdateDate': FieldValue.serverTimestamp(),
              });

          // Close loading indicator
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Profile picture updated successfully!"),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh profile data
          await _fetchUserProfile();
        } catch (e) {
          Navigator.pop(context);
          throw e;
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating profile picture: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
