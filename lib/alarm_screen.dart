import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'main.dart';
import 'api_connection.dart';
import 'face_verify.dart';

class AlarmScreen extends StatefulWidget {
  final int id;
  final String title;
  final String body;

  const AlarmScreen({
    super.key,
    required this.id,
    required this.title,
    required this.body,
  });

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Future<void> updateStatus(String status) async {
    try {
      await http.put(
        Uri.parse("${API.baseUrl}/api/patients/status/${widget.id}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"status": status}),
      );
    } catch (e) {
      print("STATUS ERROR: $e");
    }
  }

  Future<void> closeAlarm(String status) async {
    await updateStatus(status);

    await cancelNotification(widget.id);
    await cancelNotification(999);

    await stopAlarmSound();

    activeAlarmScreenId = null;

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();

    startAlarmSound();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 0.85,
      upperBound: 1.15,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    stopAlarmSound();

    if (activeAlarmScreenId == widget.id) {
      activeAlarmScreenId = null;
    }

    super.dispose();
  }

  String currentTime() {
    final now = TimeOfDay.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0D47A1), // dark blue
                Color(0xFF1565C0), // main blue
                Color(0xFF42A5F5), // light blue
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  Text(
                    currentTime(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 3,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    widget.body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const Spacer(),

                  ScaleTransition(
                    scale: _controller,
                    child: Container(
                      width: 135,
                      height: 135,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.alarm,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1565C0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FaceVerifyPage(
                              returnResult: true,
                            ),
                          ),
                        );

                        if (result != null && result['authorized'] == true) {
                          await closeAlarm("Taken");
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Face verification failed. Medicine not taken."),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.medication),
                      label: const Text(
                        "Take Medicine",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () async {
                        await closeAlarm("Missed");
                      },
                      icon: const Icon(Icons.snooze),
                      label: const Text(
                        "Remind Me Later",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}