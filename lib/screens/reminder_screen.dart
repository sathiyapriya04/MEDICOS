import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../services/whatsapp_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  tz.initializeTimeZones();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medicos',
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: Color(0xFF43A047),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.green,
          accentColor: Color(0xFF66BB6A),
          backgroundColor: Colors.white,
        ),
        cardTheme: CardTheme(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        appBarTheme: AppBarTheme(elevation: 0, centerTitle: true),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
      home: ReminderScreen(),
    );
  }
}

class ReminderScreen extends StatefulWidget {
  @override
  _ReminderScreenState createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final WhatsAppService _whatsappService = WhatsAppService();
  bool _showNotifications = false;
  List<String> _notifications = [];
  String? _userPhoneNumber;

  @override
  void initState() {
    super.initState();
    _ensureUser();
    _initializeNotifications();
    _setupNotificationActions();
    _fetchUserPhoneNumber();
  }

  Future<void> _fetchUserPhoneNumber() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _userPhoneNumber = doc['phone'] as String?;
          });
        }
      }
    } catch (e) {
      print('Error fetching user phone number: $e');
    }
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
  }

  Future<void> _setupNotificationActions() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final String? actionId = response.actionId;
        final String? payload = response.payload;

        if (payload != null && payload.startsWith('reminder_')) {
          final String reminderId = payload.substring(9);

          // Handle snooze actions
          if (actionId?.startsWith('snooze_') == true) {
            final durationStr = actionId!.split('_')[1];
            final duration = int.tryParse(durationStr);
            if (duration != null) {
              await _handleSnooze(reminderId, duration);
            }
          } else if (actionId == 'mark_taken') {
            await _handleMarkAsTaken(reminderId);
          } else if (actionId == 'dismiss') {
            await _handleDismiss(reminderId);
          } else if (actionId == 'take_now') {
            await _handleTakeNow(reminderId);
          } else if (actionId == 'take_later') {
            await _handleTakeLater(reminderId);
          } else if (actionId == 'skip') {
            await _handleSkip(reminderId);
          }
        }
      },
    );
  }

  Future<void> _handleSnooze(String reminderId, int durationMinutes) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get reminder details from Firestore
      final doc =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('reminders')
              .doc(reminderId)
              .get();

      if (doc.exists) {
        final medicineName = doc['medicineName'] as String;
        final dosage = doc['dosage'] as String;
        final isRecurring = doc['isRecurring'] as bool? ?? false;

        // Snooze the alarm
        await _notificationService.snoozeAlarm(
          reminderId.hashCode,
          'Medication Reminder',
          'Time to take $medicineName, Dosage: $dosage',
          'reminder_$reminderId',
          durationMinutes,
        );

        // Add notification about snooze
        setState(() {
          _notifications.add(
            "Reminder for $medicineName snoozed for $durationMinutes minutes",
          );
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Reminder snoozed for $durationMinutes minutes"),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error snoozing reminder: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleMarkAsTaken(String reminderId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Get reminder details from Firestore
    final doc =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .doc(reminderId)
            .get();

    if (doc.exists) {
      final medicineName = doc['medicineName'] as String;

      // Cancel the alarm
      await _notificationService.cancelAlarm(reminderId.hashCode);

      // Add notification about marking as taken
      setState(() {
        _notifications.add("Marked $medicineName as taken");
      });
    }
  }

  Future<void> _handleDismiss(String reminderId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Get reminder details from Firestore
    final doc =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .doc(reminderId)
            .get();

    if (doc.exists) {
      final medicineName = doc['medicineName'] as String;

      // Cancel the alarm
      await _notificationService.cancelAlarm(reminderId.hashCode);

      // Add notification about dismissal
      setState(() {
        _notifications.add("Reminder for $medicineName dismissed");
      });
    }
  }

  Future<void> _handleTakeNow(String reminderId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get reminder details from Firestore
      final doc =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('reminders')
              .doc(reminderId)
              .get();

      if (doc.exists) {
        final medicineName = doc['medicineName'] as String;
        final dosage = doc['dosage'] as String;
        final isRecurring = doc['isRecurring'] as bool? ?? false;

        // Cancel the alarm
        await _notificationService.cancelAlarm(reminderId.hashCode);

        // Add notification about taking now
        setState(() {
          _notifications.add("Marked $medicineName as taken now");
        });

        // If recurring, schedule the next occurrence
        if (isRecurring) {
          final nextTime = DateTime.now().add(const Duration(days: 1));
          await _notificationService.scheduleAlarm(
            id: reminderId.hashCode,
            title: 'Medication Reminder',
            body: 'Time to take $medicineName, Dosage: $dosage',
            scheduledTime: nextTime,
            payload: 'reminder_$reminderId',
            isRecurring: true,
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error handling reminder: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleTakeLater(String reminderId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Get reminder details from Firestore
    final doc =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .doc(reminderId)
            .get();

    if (doc.exists) {
      final medicineName = doc['medicineName'] as String;
      final dosage = doc['dosage'] as String;
      final isRecurring = doc['isRecurring'] as bool? ?? false;

      // Show time picker dialog
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.green,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        // Calculate the scheduled time
        final now = DateTime.now();
        final scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // Cancel the current alarm
        await _notificationService.cancelAlarm(reminderId.hashCode);

        // Schedule the new alarm
        await _notificationService.scheduleAlarm(
          id: reminderId.hashCode,
          title: 'Medication Reminder',
          body: 'Time to take $medicineName, Dosage: $dosage',
          scheduledTime: scheduledTime,
          payload: 'reminder_$reminderId',
          isRecurring: isRecurring,
        );

        // Add notification about rescheduling
        setState(() {
          _notifications.add(
            "Reminder for $medicineName rescheduled to ${pickedTime.format(context)}",
          );
        });
      }
    }
  }

  Future<void> _handleSkip(String reminderId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Get reminder details from Firestore
    final doc =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .doc(reminderId)
            .get();

    if (doc.exists) {
      final medicineName = doc['medicineName'] as String;
      final isRecurring = doc['isRecurring'] as bool? ?? false;

      if (isRecurring) {
        // For recurring reminders, just cancel the current alarm
        await _notificationService.cancelAlarm(reminderId.hashCode);

        // Add notification about skipping
        setState(() {
          _notifications.add("Skipped today's reminder for $medicineName");
        });
      } else {
        // For one-time reminders, delete the reminder
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .doc(reminderId)
            .delete();

        // Cancel the alarm
        await _notificationService.cancelAlarm(reminderId.hashCode);

        // Add notification about deletion
        setState(() {
          _notifications.add("Reminder for $medicineName deleted");
        });
      }
    }
  }

  void _ensureUser() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
      setState(() {});
    }
  }

  void _toggleNotifications() {
    setState(() {
      _showNotifications = !_showNotifications;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              SizedBox(height: 20),
              Text(
                "Loading Medicos...",
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medical_services, size: 28),
            SizedBox(width: 8),
            Text(
              "Medicos",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: _toggleNotifications,
              ),
              if (_notifications.isNotEmpty)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${_notifications.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text(
                  "Your Medication Reminders",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      _firestore
                          .collection('users')
                          .doc(user.uid)
                          .collection('reminders')
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.green,
                          ),
                        ),
                      );
                    }

                    var reminders = snapshot.data!.docs;

                    if (reminders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.medication_outlined,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "No reminders yet",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Add your first medication reminder",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton.icon(
                              icon: Icon(Icons.add),
                              label: Text("Add Medication"),
                              onPressed: () => showAddReminderDialog(context),
                            ),
                          ],
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ListView.builder(
                        // Added padding at the bottom to prevent FAB overflow
                        padding: EdgeInsets.only(bottom: 80),
                        itemCount: reminders.length,
                        itemBuilder: (context, index) {
                          var reminder = reminders[index];

                          // Fixing Timestamp conversion error: Check type of 'time' field
                          DateTime reminderTime;
                          var timeField = reminder["time"];
                          if (timeField is Timestamp) {
                            reminderTime =
                                timeField.toDate(); // Timestamp to DateTime
                          } else if (timeField is String) {
                            // Parse string to DateTime
                            try {
                              reminderTime = DateTime.parse(timeField);
                            } catch (e) {
                              reminderTime =
                                  DateTime.now(); // Fallback to current time if the format is invalid
                              print("Error parsing date string: $e");
                            }
                          } else {
                            reminderTime =
                                DateTime.now(); // Fallback to current time if the type is unexpected
                          }

                          String formattedTime = DateFormat.jm().format(
                            reminderTime,
                          );
                          String formattedDate = DateFormat.yMd().format(
                            reminderTime,
                          );

                          // Check if reminder is today
                          bool isToday =
                              DateTime.now().day == reminderTime.day &&
                              DateTime.now().month == reminderTime.month &&
                              DateTime.now().year == reminderTime.year;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color:
                                      isToday
                                          ? Colors.green.shade300
                                          : Colors.transparent,
                                  width: isToday ? 1.5 : 0,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Medicine name and date row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Medicine name with more space
                                        Expanded(
                                          child: Text(
                                            reminder["medicineName"] ??
                                                "Unknown",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade800,
                                            ),
                                            overflow:
                                                TextOverflow
                                                    .visible, // Allow text to be fully visible
                                            softWrap:
                                                true, // Allow wrapping if needed
                                          ),
                                        ),
                                        // Date pill
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isToday
                                                    ? Colors.green.shade50
                                                    : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color:
                                                  isToday
                                                      ? Colors.green.shade200
                                                      : Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Text(
                                            isToday ? "Today" : formattedDate,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w300,
                                              color:
                                                  isToday
                                                      ? Colors.green.shade700
                                                      : Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    // Time and dosage info
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Left side with time
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size: 16,
                                              color: Colors.grey.shade600,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              formattedTime,
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Right side with dosage
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.medical_information,
                                              size: 16,
                                              color: Colors.grey.shade600,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              reminder["dosage"],
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Action buttons
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              iconSize: 20,
                                              padding: EdgeInsets.all(4),
                                              constraints: BoxConstraints(),
                                              icon: Icon(
                                                Icons.edit,
                                                color: Colors.green,
                                              ),
                                              onPressed:
                                                  () => editReminder(
                                                    context,
                                                    reminder,
                                                  ),
                                            ),
                                            IconButton(
                                              iconSize: 20,
                                              padding: EdgeInsets.all(4),
                                              constraints: BoxConstraints(),
                                              icon: Icon(
                                                Icons.delete_outline,
                                                color: Colors.red.shade400,
                                              ),
                                              onPressed:
                                                  () => deleteReminder(
                                                    reminder.id,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Notification panel
          if (_showNotifications)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 250,
                margin: EdgeInsets.only(top: 10, right: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Notifications",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _notifications.clear();
                                _showNotifications = false;
                              });
                            },
                            child: Text(
                              "Clear all",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1),
                    if (_notifications.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            "No notifications",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      ),
                    ...List.generate(
                      _notifications.length,
                      (index) => Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.shade100,
                              child: Icon(
                                Icons.medication_outlined,
                                color: Colors.green,
                              ),
                            ),
                            title: Text(
                              _notifications[index],
                              style: TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              "Just now",
                              style: TextStyle(fontSize: 12),
                            ),
                            dense: true,
                          ),
                          if (index < _notifications.length - 1)
                            Divider(height: 1, indent: 70),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddReminderDialog(context),
        icon: Icon(Icons.add),
        label: Text("Add Reminder"),
        backgroundColor: Colors.green,
        elevation: 4,
      ),
    );
  }

  void editReminder(BuildContext context, DocumentSnapshot reminder) {
    // Extract current values for editing
    String medicineName = reminder["medicineName"] ?? "";
    String dosage = reminder["dosage"] ?? "";

    // Get time from reminder
    DateTime reminderTime;
    var timeField = reminder["time"];
    if (timeField is Timestamp) {
      reminderTime = timeField.toDate();
    } else if (timeField is String) {
      try {
        reminderTime = DateTime.parse(timeField);
      } catch (e) {
        reminderTime = DateTime.now();
      }
    } else {
      reminderTime = DateTime.now();
    }

    DateTime? selectedDate = reminderTime;
    TimeOfDay selectedTime = TimeOfDay(
      hour: reminderTime.hour,
      minute: reminderTime.minute,
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: Center(
                  child: Text(
                    "Edit Medication Reminder",
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                content: SingleChildScrollView(
                  child: Container(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: TextEditingController(text: medicineName),
                          onChanged: (value) => medicineName = value,
                          decoration: InputDecoration(
                            labelText: "Medicine Name",
                            prefixIcon: Icon(
                              Icons.medication,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: TextEditingController(text: dosage),
                          onChanged: (value) => dosage = value,
                          decoration: InputDecoration(
                            labelText: "Dosage",
                            prefixIcon: Icon(
                              Icons.medical_information,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate!,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Colors.green,
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedDate != null) {
                              setState(() => selectedDate = pickedDate);
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: Colors.green),
                                SizedBox(width: 8),
                                Text(
                                  "Date: ${DateFormat.yMd().format(selectedDate!)}",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Colors.green,
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedTime != null) {
                              setState(() => selectedTime = pickedTime);
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, color: Colors.green),
                                SizedBox(width: 8),
                                Text(
                                  "Time: ${selectedTime.format(context)}",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      if (medicineName.isNotEmpty && dosage.isNotEmpty) {
                        DateTime scheduledDateTime = DateTime(
                          selectedDate!.year,
                          selectedDate!.month,
                          selectedDate!.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                        updateReminder(
                          reminder.id,
                          medicineName,
                          dosage,
                          scheduledDateTime,
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: Text("Update"),
                  ),
                ],
              ),
        );
      },
    );
  }

  void updateReminder(
    String id,
    String medicineName,
    String dosage,
    DateTime scheduledTime,
  ) {
    final user = _auth.currentUser;

    _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('reminders')
        .doc(id)
        .update({
          "medicineName": medicineName,
          "dosage": dosage,
          "time": Timestamp.fromDate(scheduledTime),
        })
        .then((_) {
          // Reschedule the alarm with the new time
          _notificationService.scheduleAlarm(
            id: id.hashCode,
            title: 'Medication Reminder',
            body: 'Time to take $medicineName, Dosage: $dosage',
            scheduledTime: scheduledTime,
            payload: 'reminder_$id',
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Reminder updated successfully"),
              backgroundColor: Colors.green.shade700,
            ),
          );
        });
  }

  void deleteReminder(String id) {
    final user = _auth.currentUser;
    if (user == null) return;

    // Cancel the alarm first
    _notificationService.cancelAlarm(id.hashCode);

    // Then delete from Firestore
    _firestore
        .collection('users')
        .doc(user.uid)
        .collection('reminders')
        .doc(id)
        .delete()
        .then((_) {
          setState(() {
            _notifications.add("Reminder deleted successfully");
          });
        });
  }

  void showAddReminderDialog(BuildContext context) {
    String medicineName = "";
    String dosage = "";
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: Center(
                  child: Text(
                    "Add Medication Reminder",
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                content: SingleChildScrollView(
                  child: Container(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          onChanged: (value) => medicineName = value,
                          decoration: InputDecoration(
                            labelText: "Medicine Name",
                            prefixIcon: Icon(
                              Icons.medication,
                              color: Colors.green,
                            ),
                            hintText: "Enter medicine name",
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          onChanged: (value) => dosage = value,
                          decoration: InputDecoration(
                            labelText: "Dosage",
                            prefixIcon: Icon(
                              Icons.medical_information,
                              color: Colors.green,
                            ),
                            hintText: "E.g. 1 pill, 5ml, etc.",
                          ),
                        ),
                        SizedBox(height: 20),
                        InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Colors.green,
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedDate != null) {
                              setState(() => selectedDate = pickedDate);
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: Colors.green),
                                SizedBox(width: 8),
                                Text(
                                  selectedDate == null
                                      ? "Select Date"
                                      : "Date: ${DateFormat.yMd().format(selectedDate!)}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        selectedDate == null
                                            ? Colors.grey.shade600
                                            : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Colors.green,
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedTime != null) {
                              setState(() => selectedTime = pickedTime);
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, color: Colors.green),
                                SizedBox(width: 8),
                                Text(
                                  selectedTime == null
                                      ? "Select Time"
                                      : "Time: ${selectedTime!.format(context)}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        selectedTime == null
                                            ? Colors.grey.shade600
                                            : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      if (medicineName.isNotEmpty &&
                          dosage.isNotEmpty &&
                          selectedDate != null &&
                          selectedTime != null) {
                        DateTime scheduledDateTime = DateTime(
                          selectedDate!.year,
                          selectedDate!.month,
                          selectedDate!.day,
                          selectedTime!.hour,
                          selectedTime!.minute,
                        );
                        addReminder(medicineName, dosage, scheduledDateTime);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Reminder added successfully"),
                            backgroundColor: Colors.green.shade700,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Please fill in all fields"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Text("Save"),
                  ),
                ],
              ),
        );
      },
    );
  }

  Future<void> addReminder(
    String medicineName,
    String dosage,
    DateTime scheduledTime,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Add reminder to Firestore
      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('reminders')
          .add({
            "medicineName": medicineName,
            "dosage": dosage,
            "time": Timestamp.fromDate(scheduledTime),
            "isRecurring": false,
            "createdAt": FieldValue.serverTimestamp(),
          });

      // Add a notification
      setState(() {
        _notifications.add(
          "New reminder set: $medicineName at ${DateFormat.jm().format(scheduledTime)}",
        );
      });

      // Schedule the alarm
      await _notificationService.scheduleAlarm(
        id: docRef.id.hashCode,
        title: 'Medication Reminder',
        body: 'Time to take $medicineName, Dosage: $dosage',
        scheduledTime: scheduledTime,
        payload: 'reminder_${docRef.id}',
      );

      // Send WhatsApp notification if phone number is available
      if (_userPhoneNumber != null) {
        try {
          final message =
              '🔔 Medication Reminder\n\n'
              'Medicine: $medicineName\n'
              'Dosage: $dosage\n'
              'Time: ${DateFormat('hh:mm a').format(scheduledTime)}\n\n'
              'Please take your medication as prescribed.';

          await _whatsappService.sendWhatsAppMessage(
            _userPhoneNumber!,
            message,
          );

          // Show success message for WhatsApp
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("WhatsApp notification sent successfully"),
              backgroundColor: Colors.green.shade700,
            ),
          );
        } on WhatsAppServiceException catch (e) {
          // Show error message for WhatsApp failure
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_whatsappService.formatErrorMessage(e)),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );

          // Log the error for debugging
          print('WhatsApp notification failed: ${e.toString()}');
        }
      }

      // Show success message for reminder creation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Reminder added successfully"),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      // Show error message for reminder creation failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error adding reminder: $e"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }
}
