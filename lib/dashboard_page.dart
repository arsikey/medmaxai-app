import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'main.dart';
import 'login_page.dart';
import 'assigned_patient.dart';
import 'patient_info_page.dart';
import 'alarm_screen.dart';
import 'dispenser_page.dart';
import 'config.dart';
import 'history_page.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  final int userId;

  const DashboardPage({
    super.key,
    required this.username,
    required this.userId,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

Set<String> notified = {};

class _DashboardPageState extends State<DashboardPage> {
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
    await showNotification(
  title: "Medication Time",
  body: "${p['name']} - ${p['medicine']}",
);

    await startAlarmSound();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlarmScreen(
          id: p['id'],
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

      String key = "${p['id']}";

      if (notified.contains(key)) continue;

      try {
        final parts = p['time'].split(' ');
        final hm = parts[0].split(':');

        int hour = int.parse(hm[0]);
        int minute = int.parse(hm[1]);

        if (parts[1] == "PM" && hour != 12) hour += 12;
        if (parts[1] == "AM" && hour == 12) hour = 0;

        if (now.hour == hour && now.minute == minute) {
          startAlarm(context, p);
          notified.add(key);
        }
      } catch (_) {}
    }
  }

  @override
  void initState() {
    super.initState();

    fetchDashboardData();

    timer = Timer.periodic(
      const Duration(seconds: 5),
      (t) {
        fetchDashboardData();
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
      var url = Uri.parse(
        "${Config.baseUrl}/api/patients?user_id=${widget.userId}",
      );

      var response = await http.get(url);

      var data = jsonDecode(response.body);

      final now = DateTime.now();

      List todayPatients = data.where((p) {
        DateTime d = DateTime.parse(p['date']).toLocal();

        bool sameDate =
            d.year == now.year &&
            d.month == now.month &&
            d.day == now.day;

        return sameDate;
      }).toList();

      // SORT RECENT FIRST
      todayPatients.sort((a, b) {
        return b['id'].compareTo(a['id']);
      });

      int taken = todayPatients
          .where((p) => p['status'] == "Taken")
          .length;

      int missed = todayPatients
          .where((p) => p['status'] == "Missed")
          .length;

      setState(() {
        patients = todayPatients;

        totalPatients = todayPatients.length;
        totalMedicines = todayPatients.length;

        takenToday = taken;
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
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),

            const SizedBox(height: 15),

            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
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
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
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
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [

          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.blue.shade100,
            child: const Icon(
              Icons.medication,
              color: Colors.blue,
            ),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: getStatusColor(
                p['status'] ?? "Pending",
              ).withOpacity(0.12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              p['status'] ?? "Pending",
              style: TextStyle(
                color: getStatusColor(
                  p['status'] ?? "Pending",
                ),
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
              padding: const EdgeInsets.only(
                top: 60,
                bottom: 30,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1565C0),
                    Color(0xFF42A5F5),
                  ],
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
                    widget.username,
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
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
                      ),
                    ),

                    menuTile(
                      title: "Patient Information",
                      icon: Icons.folder_shared,
                      color: Colors.green,
                      page: PatientInfoPage(
                        userId: widget.userId,
                      ),
                    ),

                    menuTile(
                      title: "Dispenser Setter",
                      icon: Icons.medication,
                      color: Colors.orange,
                      page: DispenserPage(
                        userId: widget.userId,
                      ),
                    ),

                    menuTile(
                      title: "History",
                      icon: Icons.history,
                      color: Colors.purple,
                      page: HistoryPage(
                        userId: widget.userId,
                      ),
                    ),

                    const Spacer(),

                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: ListTile(
                        leading: const Icon(
                          Icons.logout,
                          color: Colors.red,
                        ),
                        title: const Text(
                          "Logout",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
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
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color.fromRGBO(213, 223, 235, 1),
        icon: const Icon(Icons.add),
        label: const Text("Add Patient"),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DispenserPage(
                userId: widget.userId,
              ),
            ),
          );

          if (result == true) {
            fetchDashboardData();
          }
        },
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
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
                          colors: [
                            Color(0xFF1565C0),
                            Color(0xFF42A5F5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
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
                                  widget.username,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                const Text(
                                  "Monitor medications and schedules easily.",
                                  style: TextStyle(
                                    color: Colors.white70,
                                  ),
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
                        ),

                        statCard(
                          title: "Medicines",
                          value: "$totalMedicines",
                          icon: Icons.medication,
                          color: Colors.orange,
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
                        ),

                        statCard(
                          title: "Missed",
                          value: "$missedToday",
                          icon: Icons.cancel,
                          color: Colors.red,
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // TITLE
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
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
                              borderRadius:
                                  BorderRadius.circular(25),
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
                            physics:
                                const NeverScrollableScrollPhysics(),
                            itemCount: patients.length,
                            itemBuilder: (context, index) {
                              return scheduleCard(
                                patients[index],
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}