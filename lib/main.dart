import 'package:flutter/material.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:audioplayers/audioplayers.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_page.dart';
import 'login_page.dart';
import 'dart:convert';
import 'alarm_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
int? activeAlarmScreenId;

void openAlarmFromPayload(String? payload) {
  if (payload == null) return;

  final data = jsonDecode(payload);
  final int alarmId = int.parse(data['id'].toString());

  if (activeAlarmScreenId == alarmId) {
    return;
  }

  activeAlarmScreenId = alarmId;

  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => AlarmScreen(
        id: alarmId,
        title: data['title'],
        body: data['body'],
      ),
    ),
  );
}

class AuthCheckPage extends StatefulWidget {
  const AuthCheckPage({super.key});

  @override
  State<AuthCheckPage> createState() => _AuthCheckPageState();
}

class _AuthCheckPageState extends State<AuthCheckPage> {
  bool isChecking = true;
  bool isLoggedIn = false;

  int userId = 0;
  String first_name = "";
  String last_name = "";

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();

    final loggedIn = prefs.getBool('is_logged_in') ?? false;

    setState(() {
      isLoggedIn = loggedIn;
      userId = prefs.getInt('user_id') ?? 0;
      first_name = prefs.getString('first_name') ?? "";
      last_name = prefs.getString('last_name') ?? "";
      isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (isLoggedIn) {
      return DashboardPage(
        first_name: first_name,
        last_name: last_name,
        userId: userId,
      );
    }

    return const LoginPage();
  }
}

// notifications plugin
final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

final AudioPlayer player = AudioPlayer();
bool isAlarmSoundPlaying = false;

// alarm
Future<void> startAlarmSound() async {
  if (isAlarmSoundPlaying) return;

  isAlarmSoundPlaying = true;
  await player.setReleaseMode(ReleaseMode.loop);
  await player.play(AssetSource('alarm.mp3'));
}

// to stop the alarm
Future<void> stopAlarmSound() async {
  isAlarmSoundPlaying = false;
  await player.stop();
}

// main
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  tz.initializeTimeZones();

  // logo
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/logos');

  const InitializationSettings settings = InitializationSettings(
    android: androidSettings,
  );
  // notifications
  await notificationsPlugin.initialize(
    settings: settings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      openAlarmFromPayload(response.payload);
    },
  );

  await Permission.notification.request();

  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();

  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestExactAlarmsPermission();

  try {
    String? token = await FirebaseMessaging.instance.getToken();
    print("FCM TOKEN: $token");
  } catch (e) {
    print("FCM TOKEN ERROR: $e");
  }
  final launchDetails =
    await notificationsPlugin.getNotificationAppLaunchDetails();

  String? initialPayload;

  if (launchDetails?.didNotificationLaunchApp ?? false) {
    initialPayload = launchDetails!.notificationResponse?.payload;
  }

  runApp(MedMaxAI(initialPayload: initialPayload));
}

// app widget
class MedMaxAI extends StatefulWidget {
  final String? initialPayload;

  const MedMaxAI({
    super.key,
    this.initialPayload,
  });

  @override
  State<MedMaxAI> createState() => _MedMaxAIState();
}

class _MedMaxAIState extends State<MedMaxAI> {
  @override
  void initState() {
    super.initState();

    if (widget.initialPayload != null) {
      Future.delayed(const Duration(milliseconds: 800), () {
        openAlarmFromPayload(widget.initialPayload);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: const Color(0xFFF4F8FD),
      ),
      home: const AuthCheckPage(),
    );
  }
}

// instant notif
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'medmax_alarm_v6',
      'Medication Alarm',
      channelDescription: 'Medication Alarm Channel',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      sound: RawResourceAndroidNotificationSound('alarm'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      ongoing: false,
      autoCancel: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await notificationsPlugin.show(
      id: 999,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  // Sched notif
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final payload = jsonEncode({
      "id": id,
      "title": title,
      "body": body,
    });

    await notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      payload: payload,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'medmax_alarm_v6',
          'Medication Alarm',
          channelDescription: 'Medication Alarm Channel',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          sound: RawResourceAndroidNotificationSound('alarm'),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          ongoing: false,
          autoCancel: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    print("ALARM SCHEDULED");
  }

// Cancel one notif
Future<void> cancelNotification(int id) async {
  await notificationsPlugin.cancel(id: id);
}

// Cancel all notifs
Future<void> cancelAllNotifications() async {
  await notificationsPlugin.cancelAll();
}
