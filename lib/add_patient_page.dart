import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';


int selectedHour = 1;
int selectedMinute = 0;
String selectedPeriod = "AM";
int selectedYear = DateTime.now().year;
int selectedMonth = DateTime.now().month;
int selectedDay = DateTime.now().day;
final TextEditingController timeController = TextEditingController();

class AddPatientPage extends StatefulWidget {
  final String username;
  final int userId;

  const AddPatientPage({super.key, 
    required this.username,
    required this.userId,
  });

  @override
  _AddPatientPageState createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final TextEditingController name = TextEditingController();
  final TextEditingController medicine = TextEditingController();
  final TextEditingController time = TextEditingController();
  final TextEditingController date = TextEditingController();
  final TextEditingController minuteController = TextEditingController();


  Future<void> addPatient() async {
    try {
      print("USER ID: ${widget.userId}"); 

      var url = Uri.parse("${Config.baseUrl}/api/patients");

      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name.text,
          "medicine": medicine.text,
          "time": "$selectedHour:${selectedMinute.toString().padLeft(2, '0')} $selectedPeriod",
"date": "$selectedYear-${selectedMonth.toString().padLeft(2, '0')}-${selectedDay.toString().padLeft(2, '0')}",
          "user_id": widget.userId, 
        }),
      );

      var data = jsonDecode(response.body);

      if (data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Patient added successfully")),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add patient")),
        );
      }
    } catch (e) {
      print("ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Server error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Patient"),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: name,
              decoration: InputDecoration(labelText: "Patient Name"),
            ),
            SizedBox(height: 15),

            TextField(
              controller: medicine,
              decoration: InputDecoration(labelText: "Medicine"),
            ),
            SizedBox(height: 15),

SizedBox(height: 10),
            Row(
  children: [
    // HOUR
    Expanded(
      child: DropdownButtonFormField<int>(
        initialValue: selectedHour,
        decoration: InputDecoration(labelText: "Hour"),
        items: List.generate(12, (index) {
          int hour = index + 1;
          return DropdownMenuItem(
            value: hour,
            child: Text(hour.toString()),
          );
        }),
        onChanged: (value) {
          setState(() {
            selectedHour = value!;
          });
        },
      ),
    ),

    SizedBox(width: 10),

    // MINUTE
    Expanded(
  child: TextField(
    controller: minuteController,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(
      labelText: "Minute",
      border: UnderlineInputBorder(),
      suffixIcon: PopupMenuButton<int>(
        icon: Icon(Icons.arrow_drop_down),
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
              child: Text(i.toString().padLeft(2, '0')),
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

    SizedBox(width: 10),

    // AM/PM
    Expanded(
      child: DropdownButtonFormField<String>(
        initialValue: selectedPeriod,
        decoration: InputDecoration(labelText: "AM/PM"),
        items: ["AM", "PM"].map((p) {
          return DropdownMenuItem(
            value: p,
            child: Text(p),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedPeriod = value!;
          });
        },
      ),
    ),
  ],
),
            SizedBox(height: 15),

           Row(
  children: [
    // YEAR
    Expanded(
      child: DropdownButtonFormField<int>(
        initialValue: selectedYear,
        decoration: InputDecoration(labelText: "Year"),
        items: List.generate(10, (index) {
          int year = DateTime.now().year + index;
          return DropdownMenuItem(
            value: year,
            child: Text(year.toString()),
          );
        }),
        onChanged: (value) {
          setState(() {
            selectedYear = value!;
          });
        },
      ),
    ),

    SizedBox(width: 10),

    // MONTH
    Expanded(
      child: DropdownButtonFormField<int>(
        initialValue: selectedMonth,
        decoration: InputDecoration(labelText: "Month"),
        items: List.generate(12, (index) {
          int month = index + 1;
          return DropdownMenuItem(
            value: month,
            child: Text(month.toString().padLeft(2, '0')),
          );
        }),
        onChanged: (value) {
          setState(() {
            selectedMonth = value!;
          });
        },
      ),
    ),

    SizedBox(width: 10),

    // DAY
    Expanded(
      child: DropdownButtonFormField<int>(
        initialValue: selectedDay,
        decoration: InputDecoration(labelText: "Day"),
        items: List.generate(31, (index) {
          int day = index + 1;
          return DropdownMenuItem(
            value: day,
            child: Text(day.toString().padLeft(2, '0')),
          );
        }),
        onChanged: (value) {
          setState(() {
            selectedDay = value!;
          });
        },
      ),
    ),
  ],
),  
            SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: addPatient,
                child: Text("Save", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}