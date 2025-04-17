import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart' show SvgPicture;
import 'package:medicos/screens/home_screen.dart';
import 'package:medicos/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

// ✅ Import local notifications, timezone
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';

// Create a global instance of the notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Define a global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ✅ Initialize timezone data
  tz.initializeTimeZones();

  // ✅ Setup Android-specific initialization settings
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  // ✅ Initialize local notifications plugin
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) async {
      if (notificationResponse.payload != null) {
        print("🔔 Notification tapped! Payload: ${notificationResponse.payload}");
        navigatorKey.currentState?.pushNamed('/map');
      }
    },
  );

  // ✅ Request Exact Alarm Permission (Required for Android 12+)
  if (Platform.isAndroid) {
    await requestExactAlarmPermission();
  }

  runApp(MyApp());
}

// ✅ Request Exact Alarm Permission for Android 12+
Future<void> requestExactAlarmPermission() async {
  final androidImplementation =
  flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  if (androidImplementation != null) {
    bool? granted = await androidImplementation.requestExactAlarmsPermission();
    debugPrint("Exact Alarm Permission Granted: $granted");
  }
}

// ✅ UPDATED: Function to schedule an alarm notification with sound
Future<void> scheduleAlarmNotification(int hour, int minute) async {
  final tz.TZDateTime scheduledTime = _nextInstanceOfTime(hour, minute);

  print("📅 Scheduling alarm for: $scheduledTime");

  await flutterLocalNotificationsPlugin.zonedSchedule(
    1, // Unique notification ID for the alarm
    "⏰ Alarm!",
    "Time to take your medicine 💊",
    scheduledTime,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'medicos_alarm_channel',
        'Alarm Notifications',
        channelDescription: 'Alarm notification for reminders',
        importance: Importance.high,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('alarm_sound'), // ✅ Ensure 'alarm_sound.mp3' is in res/raw
        playSound: true,
        fullScreenIntent: true, // ✅ Ensure it rings even when the phone is locked
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // ✅ Allow while idle (important)
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

// Function to get the next instance of the scheduled time
tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime scheduledTime = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );

  if (scheduledTime.isBefore(now)) {
    scheduledTime = scheduledTime.add(Duration(days: 1));
  }
  return scheduledTime;
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'MEDICOS',
        theme: ThemeData(primarySwatch: Colors.green),
        initialRoute: '/',
        routes: {
          '/': (context) => ArrivalScreen(),
          '/auth': (context) => AuthWrapper(),
          '/map': (context) => HomeScreen(),
        },
      ),
    );
  }
}

class ArrivalScreen extends StatefulWidget {
  @override
  _ArrivalScreenState createState() => _ArrivalScreenState();
}

class _ArrivalScreenState extends State<ArrivalScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/auth');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF00AA36),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/hybrid_car.svg',
              height: 150,
              width: 150,
            ),
            SizedBox(height: 10),
            Text(
              "MEDICOS!!",
              style: TextStyle(
                  fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        return auth.user != null ? HomeScreen() : LoginScreen();
      },
    );
  }
}
