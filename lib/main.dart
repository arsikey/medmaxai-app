import 'package:flutter/material.dart';
import 'login_page.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:audioplayers/audioplayers.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// ==========================
// NOTIFICATION PLUGIN
// ==========================
final FlutterLocalNotificationsPlugin
notificationsPlugin =
FlutterLocalNotificationsPlugin();

// ==========================
// AUDIO PLAYER (ONLY FOR IN-APP)
// ==========================
final AudioPlayer player = AudioPlayer();

// ==========================
// START ALARM SOUND (ONLY WHEN APP OPEN)
// ==========================
Future<void> startAlarmSound() async {
  await player.setReleaseMode(ReleaseMode.loop);
  await player.play(AssetSource('alarm.mp3'));
}

// ==========================
// STOP ALARM SOUND
// ==========================
Future<void> stopAlarmSound() async {
  await player.stop();
}

// ==========================
// MAIN
// ==========================
Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  tz.initializeTimeZones();

  // ==========================
  // ANDROID INIT SETTINGS
  // ==========================
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/logos');

  const InitializationSettings settings =
      InitializationSettings(android: androidSettings);

  await notificationsPlugin.initialize(
    settings,
    onDidReceiveNotificationResponse:
        (NotificationResponse response) async {
      print("NOTIFICATION CLICKED");
    },
  );

  // ==========================
  // PERMISSIONS
  // ==========================
  await Permission.notification.request();

  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestExactAlarmsPermission();

  // ==========================
  // FIREBASE TOKEN
  // ==========================
  String? token =
      await FirebaseMessaging.instance.getToken();

  print("FCM TOKEN: $token");

  runApp(const MedMaxAI());
}

// ==========================
// APP
// ==========================
class MedMaxAI extends StatelessWidget {
  const MedMaxAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor:
            const Color(0xFFF4F8FD),
      ),
      home: const LoginPage(),
    );
  }
}

// ==========================
// INSTANT NOTIFICATION
// ==========================
Future<void> showNotification({
  required String title,
  required String body,
}) async {

  const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(

    // ✅ SAME CHANNEL
    'medmax_alarm_v4',
    'Medication Alarm',

    channelDescription:
        'Medication Alarm Channel',

    importance: Importance.max,
    priority: Priority.max,

    playSound: true,
    enableVibration: true,
    fullScreenIntent: true,

    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,

    sound:
        RawResourceAndroidNotificationSound('alarm'),

    audioAttributesUsage:
        AudioAttributesUsage.alarm,
  );

  const NotificationDetails details =
      NotificationDetails(android: androidDetails);

  await notificationsPlugin.show(
    999,
    title,
    body,
    details,
  );
}

// ==========================
// SCHEDULE NOTIFICATION
// ==========================
Future<void> scheduleNotification({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledDate,
}) async {

  await notificationsPlugin.zonedSchedule(

    id,
    title,
    body,

    tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    ),

    const NotificationDetails(
      android: AndroidNotificationDetails(

        // ✅ SAME CHANNEL
        'medmax_alarm_v4',
        'Medication Alarm',

        channelDescription:
            'Medication Alarm Channel',

        importance: Importance.max,
        priority: Priority.max,

        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,

        category:
            AndroidNotificationCategory.alarm,

        visibility:
            NotificationVisibility.public,

        sound:
            RawResourceAndroidNotificationSound(
          'alarm',
        ),

        audioAttributesUsage:
            AudioAttributesUsage.alarm,
      ),
    ),

    androidScheduleMode:
        AndroidScheduleMode.exactAllowWhileIdle,

    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation
            .absoluteTime,
  );

  print("ALARM SCHEDULED");
}

// ==========================
// CANCEL ONE
// ==========================
Future<void> cancelNotification(int id) async {
  await notificationsPlugin.cancel(id);
}

// ==========================
// CANCEL ALL
// ==========================
Future<void> cancelAllNotifications() async {
  await notificationsPlugin.cancelAll();
}