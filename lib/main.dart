import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart' show SvgPicture;
import 'package:medicos/screens/home_screen.dart';
import 'package:medicos/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// ✅ Import local notifications, timezone
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:medicos/theme.dart';
import 'package:medicos/utils/language_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Create a global instance of the notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Define a global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for all platforms
  await Firebase.initializeApp();
  debugPrint("Firebase initialized successfully");

  // ✅ Initialize timezone data
  tz.initializeTimeZones();

  // ✅ Setup Android-specific initialization settings
  if (!kIsWeb) {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // ✅ Initialize local notifications plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (
        NotificationResponse notificationResponse,
      ) async {
        if (notificationResponse.payload != null) {
          print(
            "🔔 Notification tapped! Payload: ${notificationResponse.payload}",
          );
          navigatorKey.currentState?.pushNamed('/map');
        }
      },
    );

    // ✅ Request Exact Alarm Permission (Required for Android 12+)
    if (Platform.isAndroid) {
      await requestExactAlarmPermission();
    }
  }

  runApp(MyApp());
}

// ✅ Request Exact Alarm Permission for Android 12+
Future<void> requestExactAlarmPermission() async {
  final androidImplementation =
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

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
        sound: RawResourceAndroidNotificationSound(
          'alarm_sound',
        ), // ✅ Ensure 'alarm_sound.mp3' is in res/raw
        playSound: true,
        fullScreenIntent:
            true, // ✅ Ensure it rings even when the phone is locked
      ),
    ),
    androidScheduleMode:
        AndroidScheduleMode
            .exactAllowWhileIdle, // ✅ Allow while idle (important)
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

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    LanguageNotifier.instance.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    LanguageNotifier.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageNotifier.instance,
      builder: (context, locale, child) {
        return MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
          child: MaterialApp(
            title: 'Medicos',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
            locale: locale,
            supportedLocales: const [
              Locale('en'),
              Locale('es'),
              Locale('fr'),
              Locale('de'),
              Locale('hi'),
              Locale('ta'),
            ],
            localizationsDelegates: const [
              // Add localization delegates here (to be implemented)
            ],
            navigatorKey: navigatorKey,
            home: ArrivalScreen(),
          ),
        );
      },
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
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
            // Medical icon with animation
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.medical_services,
                size: 80,
                color: Color(0xFF00AA36),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "MEDICOS",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Your Smart Medication Reminder",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
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
