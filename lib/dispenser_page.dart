import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'main.dart';

//  GLOBAL SELECTED VALUES
int selectedHour = 1;
int selectedMinute = 0;
String selectedPeriod = "AM";

int selectedYear = DateTime.now().year;
int selectedMonth = DateTime.now().month;
int selectedDay = DateTime.now().day;

class DispenserPage extends StatefulWidget {
  final int userId;

  const DispenserPage({super.key, required this.userId});

  @override
  _DispenserPageState createState() => _DispenserPageState();
}

class _DispenserPageState extends State<DispenserPage> {
  final TextEditingController dispenser = TextEditingController();
  final TextEditingController cylinder = TextEditingController();
  final TextEditingController medicine = TextEditingController();
  final TextEditingController patient = TextEditingController();
  final TextEditingController nurse = TextEditingController();
  final TextEditingController minuteController = TextEditingController();

  //  SAVE FUNCTION (FIXED + CLEAN)
  Future<void> saveDispenser(BuildContext context) async {
    if (patient.text.isEmpty || medicine.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    try {
      // FORMAT TIME
      String timeValue =
          "$selectedHour:${selectedMinute.toString().padLeft(2, '0')} $selectedPeriod";

      //  LOCAL DATE (NO TIMEZONE ISSUE)
      String dateValue =
          "${selectedYear.toString().padLeft(4, '0')}-${selectedMonth.toString().padLeft(2, '0')}-${selectedDay.toString().padLeft(2, '0')}";

      //  SAVE TO PATIENTS (FOR DASHBOARD + ASSIGNED)
      await http.post(
        Uri.parse("${Config.baseUrl}/api/patients"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": patient.text,
          "medicine": medicine.text,
          "time": timeValue,
          "date": dateValue,
          "user_id": widget.userId,
        }),
      );

      // SAVE TO DISPENSERS 
      await http.post(
        Uri.parse("${Config.baseUrl}/api/dispensers"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "dispenser": dispenser.text,
          "cylinder": cylinder.text,
          "medicine": medicine.text,
          "time": timeValue,
          "date": dateValue,
          "patient": patient.text,
          "nurse": nurse.text,
          "user_id": widget.userId,
        }),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saved Successfully")),
      );

      // ==========================
// CONVERT TO 24 HOUR
// ==========================
int hour = selectedHour;

if (selectedPeriod == "PM" &&
    hour != 12) {
  hour += 12;
}

if (selectedPeriod == "AM" &&
    hour == 12) {
  hour = 0;
}

// ==========================
// CREATE DATE TIME
// ==========================
DateTime alarmDateTime =
    DateTime(
  selectedYear,
  selectedMonth,
  selectedDay,
  hour,
  selectedMinute,
);

// ==========================
// SCHEDULE NOTIFICATION
// ==========================
await scheduleNotification(

  id: DateTime.now()
      .millisecondsSinceEpoch ~/ 1000,

  title: "Medication Reminder",

  body:
      "${patient.text} needs ${medicine.text}",

  scheduledDate:
      alarmDateTime,
);

      Navigator.pop(context, true); //  refresh dashboard

    } catch (e) {
      print("SAVE ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dispenser Setter"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [

              Icon(Icons.medication, size: 80, color: Colors.blue),
              const SizedBox(height: 20),

              input("What Dispenser?", dispenser),
              input("What Cylinder?", cylinder),
              input("What Medicine?", medicine),

              //  TIME
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedHour,
                      decoration: const InputDecoration(labelText: "Hour"),
                      items: List.generate(12, (i) {
                        int hour = i + 1;
                        return DropdownMenuItem(
                          value: hour,
                          child: Text("$hour"),
                        );
                      }),
                      onChanged: (val) =>
                          setState(() => selectedHour = val!),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: TextField(
                      controller: minuteController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Minute",
                        border: const UnderlineInputBorder(),
                        suffixIcon: PopupMenuButton<int>(
                          icon: const Icon(Icons.arrow_drop_down),
                          onSelected: (value) {
                            setState(() {
                              selectedMinute = value;
                              minuteController.text =
                                  value.toString().padLeft(2, '0');
                            });
                          },
                          itemBuilder: (context) {
                            return List.generate(60, (i) {
                              return PopupMenuItem(
                                value: i,
                                child: Text(
                                    i.toString().padLeft(2, '0')),
                              );
                            });
                          },
                        ),
                      ),
                      onChanged: (value) {
                        int? val = int.tryParse(value);
                        if (val != null && val >= 0 && val <= 59) {
                          selectedMinute = val;
                        }
                      },
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedPeriod,
                      decoration:
                          const InputDecoration(labelText: "AM/PM"),
                      items: ["AM", "PM"]
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedPeriod = val!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              //  DATE
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedYear,
                      decoration: const InputDecoration(labelText: "Year"),
                      items: List.generate(5, (i) {
                        int year = DateTime.now().year + i;
                        return DropdownMenuItem(
                          value: year,
                          child: Text("$year"),
                        );
                      }),
                      onChanged: (val) =>
                          setState(() => selectedYear = val!),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedMonth,
                      decoration: const InputDecoration(labelText: "Month"),
                      items: List.generate(12, (i) {
                        int month = i + 1;
                        return DropdownMenuItem(
                          value: month,
                          child: Text(
                              month.toString().padLeft(2, '0')),
                        );
                      }),
                      onChanged: (val) =>
                          setState(() => selectedMonth = val!),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedDay,
                      decoration: const InputDecoration(labelText: "Day"),
                      items: List.generate(31, (i) {
                        int day = i + 1;
                        return DropdownMenuItem(
                          value: day,
                          child: Text(
                              day.toString().padLeft(2, '0')),
                        );
                      }),
                      onChanged: (val) =>
                          setState(() => selectedDay = val!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              input("Who's Patient?", patient),
              input("Who's Nurse?", nurse),

              const SizedBox(height: 20),

              //  SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => saveDispenser(context),
                  child: const Text("Save",
                      style: TextStyle(fontSize: 18)),
                ),
              ),

              const SizedBox(height: 20),

              //  OPTIONAL FEATURE
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Scan Face"),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Face Scan Coming Soon")),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //  INPUT UI
  Widget input(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}