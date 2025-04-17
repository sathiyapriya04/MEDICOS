import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

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

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medicos',
      theme: ThemeData(primarySwatch: Colors.green),
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

  @override
  void initState() {
    super.initState();
    _ensureUser();
  }

  void _ensureUser() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text("Medication Reminders")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var reminders = snapshot.data!.docs;
          return ListView.builder(
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              var reminder = reminders[index];

              // ✅ Fixing Timestamp conversion error
              DateTime reminderTime = (reminder["time"] as Timestamp).toDate();
              String formattedTime = DateFormat.jm().format(reminderTime);
              String formattedDate = DateFormat.yMd().format(reminderTime);

              return Card(
                child: ListTile(
                  title: Text(reminder["medicineName"] ?? "Unknown"),
                  subtitle: Text(
                      "Dosage: ${reminder["dosage"]} - Date: $formattedDate - Time: $formattedTime"),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteReminder(reminder.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddReminderDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void deleteReminder(String id) {
    final user = _auth.currentUser;
    _firestore.collection('users').doc(user!.uid).collection('reminders').doc(id).delete();
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
          builder: (context, setState) => AlertDialog(
            title: Text("Add Reminder"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (value) => medicineName = value,
                  decoration: InputDecoration(labelText: "Medicine Name"),
                ),
                TextField(
                  onChanged: (value) => dosage = value,
                  decoration: InputDecoration(labelText: "Dosage"),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  child: Text(selectedDate == null
                      ? "Pick Date"
                      : "Date: ${DateFormat.yMd().format(selectedDate!)}"),
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      setState(() => selectedDate = pickedDate);
                    }
                  },
                ),
                ElevatedButton(
                  child: Text(selectedTime == null
                      ? "Pick Time"
                      : "Time: ${selectedTime!.format(context)}"),
                  onPressed: () async {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      setState(() => selectedTime = pickedTime);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (medicineName.isNotEmpty && dosage.isNotEmpty && selectedDate != null && selectedTime != null) {
                    DateTime scheduledDateTime = DateTime(
                      selectedDate!.year,
                      selectedDate!.month,
                      selectedDate!.day,
                      selectedTime!.hour,
                      selectedTime!.minute,
                    );
                    addReminder(medicineName, dosage, scheduledDateTime);
                    Navigator.pop(context);
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

  void addReminder(String medicineName, String dosage, DateTime scheduledTime) {
    final user = _auth.currentUser;

    _firestore.collection('users').doc(user!.uid).collection('reminders').add({
      "medicineName": medicineName,
      "dosage": dosage,
      "time": Timestamp.fromDate(scheduledTime),  // ✅ Fix: Ensure correct timestamp storage
    }).then((docRef) {
      scheduleDailyNotification(docRef.id.hashCode, medicineName, dosage, scheduledTime);
    });
  }

  Future<void> scheduleDailyNotification(
      int id, String medicineName, String dosage, DateTime scheduledTime) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Medication Reminder',
      'Time to take $medicineName, Dosage: $dosage',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medicos_channel_id',
          'Medicos Reminders',
          channelDescription: 'Daily medication reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '',
    );
  }
}