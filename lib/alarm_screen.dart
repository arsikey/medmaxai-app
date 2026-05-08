import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'main.dart';
import 'config.dart';

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

  //  UPDATE STATUS
  Future<void> updateStatus(String status) async {
    try {
      await http.put(
        Uri.parse("${Config.baseUrl}/api/patients/status/${widget.id}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"status": status}),
      );
    } catch (e) {
      print("STATUS ERROR: $e");
    }
  }

  //  DISPENSE TRIGGER
  Future<void> dispenseMedicine() async {
    try {
      var url = Uri.parse("${Config.baseUrl}/api/dispense");
      await http.post(url);
    } catch (e) {
      print("DISPENSE ERROR: $e");
    }
  }

  @override
  void initState() {
    super.initState();

    //  SOFT PULSE ANIMATION
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);

    startAlarmSound(); //  start sound
  }

  @override
  void dispose() {
    _controller.dispose();
    stopAlarmSound();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ScaleTransition(
            scale: _controller,
            child: Container(
              padding: EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 20,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // ICON
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(Icons.medication,
                        size: 40, color: Colors.blue),
                  ),

                  SizedBox(height: 20),

                  // TITLE
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: 10),

                  // BODY
                  Text(
                    widget.body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),

                  SizedBox(height: 25),

                  //  TAKE MEDICINE
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () async {
                        await updateStatus("Taken"); 
                        await stopAlarmSound();
                        await dispenseMedicine();
                        Navigator.pop(context);
                      },
                      child: Text(
                        "TAKE MEDICINE",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  SizedBox(height: 10),

                  // MISS / REMIND LATER
                  TextButton(
                    onPressed: () async {
                      await updateStatus("Missed"); 
                      await stopAlarmSound();
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Remind me later",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}