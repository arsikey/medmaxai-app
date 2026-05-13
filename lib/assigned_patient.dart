import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'api_connection.dart';
import 'main.dart';

class AssignedPatientPage extends StatefulWidget {
  final int userId;
  final String nurseName;

  const AssignedPatientPage({
    super.key,
    required this.userId,
    required this.nurseName,
  });

  @override
  State<AssignedPatientPage> createState() => _AssignedPatientPageState();
}

class _AssignedPatientPageState extends State<AssignedPatientPage> {
  List patients = [];
  List filteredPatients = [];

  bool isLoading = true;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchAssignedPatients();
  }

  Future<void> fetchAssignedPatients() async {
    try {
      var url = Uri.parse(
        "${API.baseUrl}/api/my-assigned-patients?nurse_id=${widget.userId}",
      );

      var response = await http.get(url);
      var data = jsonDecode(response.body);

      data.sort((a, b) {
        final nameA = (a['name'] ?? '').toString().toLowerCase();
        final nameB = (b['name'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      });

      setState(() {
        patients = data;
        filteredPatients = data;
        isLoading = false;
      });
    } catch (e) {
      print("FETCH ERROR: $e");

      setState(() {
        isLoading = false;
      });
    }
  }

  void searchPatient(String value) {
    if (value.isEmpty) {
      setState(() {
        filteredPatients = patients;
      });
      return;
    }

    final filtered = patients.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final condition = (p['condition_text'] ?? '').toString().toLowerCase();
      final doctor = (p['doctor'] ?? '').toString().toLowerCase();

      return name.contains(value.toLowerCase()) ||
          condition.contains(value.toLowerCase()) ||
          doctor.contains(value.toLowerCase());
    }).toList();

    setState(() {
      filteredPatients = filtered;
    });
  }

  Widget infoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Icon(
            icon,
            size: 18,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<List> fetchPatientMedicines(int patientId) async {
    try {
      final response = await http.get(
        Uri.parse("${API.baseUrl}/api/patient-medicines/$patientId"),
      );

      return jsonDecode(response.body);
    } catch (e) {
      print("FETCH MEDICINES ERROR: $e");
      return [];
    }
  }

  Widget medicineList(int patientId) {
    return FutureBuilder<List>(
      future: fetchPatientMedicines(patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F8FD),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final medicines = snapshot.data ?? [];

        if (medicines.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F8FD),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              "No medicine listed",
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        return Column(
          children: List.generate(
            medicines.length,
            (index) {
              final med = medicines[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8FD),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.15),
                      child: Text(
                        "${index + 1}",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: Text(
                        med['medicine_name'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void showAddAlarmPanel(var patient) {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    String? selectedMedicine;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return FutureBuilder<List>(
              future: fetchPatientMedicines(patient['id']),
              builder: (context, snapshot) {
                final medicines = snapshot.data ?? [];

                if (selectedMedicine == null && medicines.isNotEmpty) {
                  selectedMedicine = medicines[0]['medicine_name'];
                }

                return Container(
                  padding: EdgeInsets.only(
                    left: 25,
                    right: 25,
                    top: 25,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 25,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 60,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        const Text(
                          "Add Alarm",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F8FD),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person,
                                color: Colors.blue,
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Patient Name",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      patient['name'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          "Medicine",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        snapshot.connectionState == ConnectionState.waiting
                            ? const Center(child: CircularProgressIndicator())
                            : medicines.isEmpty
                                ? Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4F8FD),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Text(
                                      "No medicine listed for this patient",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4F8FD),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedMedicine,
                                        isExpanded: true,
                                        items: medicines.map<DropdownMenuItem<String>>((med) {
                                          return DropdownMenuItem<String>(
                                            value: med['medicine_name'],
                                            child: Text(med['medicine_name']),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setModalState(() {
                                            selectedMedicine = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ),

                        const SizedBox(height: 18),

                        const Text(
                          "Date",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2035),
                            );

                            if (pickedDate != null) {
                              setModalState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F8FD),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  formatDate(selectedDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          "Time",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                              builder: (context, child) {
                                return MediaQuery(
                                  data: MediaQuery.of(context).copyWith(
                                    alwaysUse24HourFormat: true,
                                  ),
                                  child: child!,
                                );
                              },
                            );

                            if (pickedTime != null) {
                              setModalState(() {
                                selectedTime = pickedTime;
                              });
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F8FD),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  formatTime24(selectedTime),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: medicines.isEmpty
                                ? null
                                : () {
                                    saveAlarm(
                                      patientName: patient['name'] ?? '',
                                      medicine: selectedMedicine ?? '',
                                      date: selectedDate,
                                      time: selectedTime,
                                    );
                                  },
                            child: const Text(
                              "SAVE",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void showDetails(var p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return FutureBuilder<List>(
          future: fetchPatientMedicines(p['id']),
          builder: (context, snapshot) {
            final medicines = snapshot.data ?? [];

            return Container(
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 60,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Center(
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.blue.shade100,
                        child: const Icon(
                          Icons.person,
                          size: 45,
                          color: Colors.blue,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: Text(
                        p['name'] ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    infoTile(
                      icon: Icons.local_hospital,
                      title: "Doctor",
                      value: p['doctor'] ?? '',
                    ),

                    const SizedBox(height: 12),

                    infoTile(
                      icon: Icons.health_and_safety,
                      title: "Assigned Nurse",
                      value: p['nurse'] ?? widget.nurseName,
                    ),

                    const SizedBox(height: 12),

                    infoTile(
                      icon: Icons.medical_services,
                      title: "Condition",
                      value: p['condition_text'] ?? '',
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Maintenance Medicines",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    snapshot.connectionState == ConnectionState.waiting
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F8FD),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : medicines.isEmpty
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F8FD),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "No medicine listed",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : Column(
                                children: List.generate(
                                  medicines.length,
                                  (index) {
                                    final med = medicines[index];

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF4F8FD),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor:
                                                Colors.blue.withOpacity(0.15),
                                            child: Text(
                                              "${index + 1}",
                                              style: const TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 15),

                                          Expanded(
                                            child: Text(
                                              med['medicine_name'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return "$year-$month-$day";
  }

  String formatTime24(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return "$hour:$minute";
  }

  Future<void> saveAlarm({
    required String patientName,
    required String medicine,
    required DateTime date,
    required TimeOfDay time,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${API.baseUrl}/api/patients"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": patientName,
          "medicine": medicine,
          "date": formatDate(date),
          "time": formatTime24(time),
          "user_id": widget.userId,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        final int alarmId = data['alarm_id'];

        final scheduledDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        await scheduleNotification(
          id: alarmId,
          title: "Medication Time",
          body: "$patientName - $medicine",
          scheduledDate: scheduledDateTime,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Alarm added successfully")),
        );
        Navigator.pop(context);
        
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to add alarm")),
        );
      }
    } catch (e) {
      print("SAVE ALARM ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server error")),
      );
    }
  }

  Widget patientCard(var p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
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
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue.shade100,
                child: const Icon(
                  Icons.person,
                  color: Colors.blue,
                  size: 30,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Text(
                  p['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text("View"),
                    onTap: () {
                      Future.delayed(
                        Duration.zero,
                        () => showDetails(p),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          infoTile(
            icon: Icons.local_hospital,
            title: "Doctor",
            value: p['doctor'] ?? '',
          ),

          const SizedBox(height: 12),

          infoTile(
            icon: Icons.health_and_safety,
            title: "Assigned Nurse",
            value: p['nurse'] ?? widget.nurseName,
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                showAddAlarmPanel(p);
              },
              icon: const Icon(
                Icons.alarm_add,
                color: Colors.white,
              ),
              label: const Text(
                "ADD ALARM",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FD),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: const Text(
          "Assigned Patients",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: fetchAssignedPatients,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "My Assigned Patients",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "${filteredPatients.length} Patients",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.nurseName,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.groups,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: searchPatient,
                        decoration: InputDecoration(
                          hintText: "Search patient, condition, or doctor...",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      "Patient List",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 18),

                    filteredPatients.isEmpty
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
                                  Icons.people_alt,
                                  size: 70,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 15),
                                const Text(
                                  "No Assigned Patients",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredPatients.length,
                            itemBuilder: (context, index) {
                              return patientCard(filteredPatients[index]);
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}