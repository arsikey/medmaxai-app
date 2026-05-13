import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';
import 'login_page.dart';
import 'assigned_patient.dart';
import 'patient_info_page.dart';
import 'alarm_screen.dart';
import 'dispenser_page.dart';
import 'api_connection.dart';
import 'history_page.dart';
import 'medicines_list.dart';
import 'taken.dart';

class DashboardPage extends StatefulWidget {
  final String first_name;
  final String last_name;
  final int userId;

  const DashboardPage({
    super.key,
    required this.first_name,
    required this.last_name,
    required this.userId,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

Set<String> notified = {};

class _DashboardPageState extends State<DashboardPage> {
  String get full_name => "${widget.first_name} ${widget.last_name}";

  List patients = [];

  int totalPatients = 0;
  int totalMedicines = 0;
  int takenToday = 0;
  int missedToday = 0;

  bool isLoading = true;

  Timer? timer;

  // STATUS COLOR
  Color getStatusColor(String status) {
    switch (status) {
      case "Taken":
        return Colors.green;
      case "Missed":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  // ALARM
  void startAlarm(BuildContext context, var p) async {
    final int alarmId = p['id'];

    if (activeAlarmScreenId == alarmId) {
      return;
    }

    activeAlarmScreenId = alarmId;

    await cancelNotification(alarmId);

    await startAlarmSound();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlarmScreen(
          id: alarmId,
          title: "Medication Time",
          body: "${p['name']} - ${p['medicine']}",
        ),
      ),
    );
  }

  // CHECK SCHEDULE
  void checkSchedule() {
    final now = TimeOfDay.now();

    for (var p in patients) {
      if (p['time'] == null) continue;

      if ((p['status'] ?? '') != "Pending") continue;

      String key = "${p['id']}";
      if (notified.contains(key)) continue;

      try {
        final timeString = p['time'].toString();
        final hm = timeString.split(':');

        int hour = int.parse(hm[0]);
        int minute = int.parse(hm[1]);

        if (now.hour == hour && now.minute == minute) {
          notified.add(key);
          startAlarm(context, p);
        }
      } catch (e) {
        print("TIME PARSE ERROR: $e");
      }
    }
  }

  @override
  void initState() {
    super.initState();

    fetchDashboardData();

    timer = Timer.periodic(
      const Duration(seconds: 5),
      (t) async {
        await fetchDashboardData();
        checkSchedule();
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // FETCH DASHBOARD
  Future<void> fetchDashboardData() async {
    try {
      final scheduleUrl = Uri.parse(
        "${API.baseUrl}/api/patients?user_id=${widget.userId}",
      );

      final assignedUrl = Uri.parse(
        "${API.baseUrl}/api/my-assigned-patients?nurse_id=${widget.userId}",
      );

      final takenUrl = Uri.parse(
        "${API.baseUrl}/api/taken?user_id=${widget.userId}",
      );

      final scheduleResponse = await http.get(scheduleUrl);
      final assignedResponse = await http.get(assignedUrl);
      final takenResponse = await http.get(takenUrl);

      final scheduleData = jsonDecode(scheduleResponse.body);
      final assignedData = jsonDecode(assignedResponse.body);
      final takenData = jsonDecode(takenResponse.body);

      final now = DateTime.now();

      List todayPatients = scheduleData.where((p) {
        DateTime d = DateTime.parse(p['date']).toLocal();

        bool sameDate =
            d.year == now.year && d.month == now.month && d.day == now.day;

        return sameDate;
      }).toList();

      todayPatients.sort((a, b) {
        return b['id'].compareTo(a['id']);
      });

      int missed = todayPatients.where((p) => p['status'] == "Missed").length;

      setState(() {
        patients = todayPatients;

        totalPatients = assignedData.length;
        totalMedicines = 0;

        takenToday = takenData.length;
        missedToday = missed;

        isLoading = false;
      });
    } catch (e) {
      print("ERROR: $e");

      setState(() {
        isLoading = false;
      });
    }
  }

  // STAT CARD
  Widget statCard({
    required String title,
    String? value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          height: 155, // SAME SIZE FOR ALL CARDS
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color),
              ),

              const SizedBox(height: 18),

              // RESERVE SPACE EVEN IF NO NUMBER
              SizedBox(
                height: 32,
                child: value != null
                    ? Text(
                        value,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : const SizedBox(),
              ),

              const Spacer(),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  ),

                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // MENU TILE
  Widget menuTile({
    required String title,
    required IconData icon,
    required Widget page,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );

          if (result == true) {
            fetchDashboardData();
          }
        },
      ),
    );
  }

  // SCHEDULE CARD
  Widget scheduleCard(var p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.blue.shade100,
            child: const Icon(Icons.medication, color: Colors.blue),
          ),
          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Medicine: ${p['medicine'] ?? ''}",
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      p['time'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: getStatusColor(p['status'] ?? "Pending").withOpacity(0.12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              p['status'] ?? "Pending",
              style: TextStyle(
                color: getStatusColor(p['status'] ?? "Pending"),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FD),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.health_and_safety,
                      size: 45,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "MedMax AI",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    full_name,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    menuTile(
                      title: "Assigned Patients",
                      icon: Icons.assignment_ind,
                      color: Colors.blue,
                      page: AssignedPatientPage(
                        userId: widget.userId,
                        nurseName: full_name,
                      ),
                    ),
                    menuTile(
                      title: "Patient Information",
                      icon: Icons.folder_shared,
                      color: Colors.green,
                      page: PatientInfoPage(
                        userId: widget.userId,
                        nurseName: full_name,
                      ),
                    ),
                    menuTile(
                      title: "Dispenser Setter",
                      icon: Icons.medication,
                      color: Colors.orange,
                      page: DispenserPage(
                        userId: widget.userId,
                        nurseName: full_name,
                      ),
                    ),
                    menuTile(
                      title: "History",
                      icon: Icons.history,
                      color: Colors.purple,
                      page: HistoryPage(userId: widget.userId),
                    ),
                    const Spacer(),
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text(
                          "Logout",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Dashboard",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // WELCOME CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Welcome",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  full_name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                const Text(
                                  "Monitor medications and schedules easily.",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),

                          const CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.white24,
                            child: Icon(
                              Icons.health_and_safety,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // STATS
                    Row(
                      children: [
                        statCard(
                          title: "Patients",
                          value: "$totalPatients",
                          icon: Icons.people,
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AssignedPatientPage(
                                  userId: widget.userId,
                                  nurseName: full_name,
                                ),
                              ),
                            );
                          },
                        ),

                        statCard(
                          title: "Medicines",
                          value: null,
                          icon: Icons.medication,
                          color: Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MedicinesListPage(
                                  userId: widget.userId,
                                  nurseName: full_name,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        statCard(
                          title: "Taken",
                          value: "$takenToday",
                          icon: Icons.check_circle,
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TakenPage(
                                  userId: widget.userId,
                                  nurseName: full_name,
                                ),
                              ),
                            );
                          },
                        ),

                        statCard(
                          title: "Missed Alarms",
                          value: "$missedToday",
                          icon: Icons.cancel,
                          color: Colors.red,
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // TITLE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Today's Schedule",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        TextButton(
                          onPressed: fetchDashboardData,
                          child: const Text("Refresh"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // EMPTY
                    patients.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 70,
                                  color: Colors.grey.shade400,
                                ),

                                const SizedBox(height: 15),

                                const Text(
                                  "No Schedule Today",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 5),
                              ],
                            ),
                          )
                        // LIST
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: patients.length,
                            itemBuilder: (context, index) {
                              return scheduleCard(patients[index]);
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
