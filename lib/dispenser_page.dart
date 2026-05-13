import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_connection.dart';

class DispenserPage extends StatefulWidget {
  final int userId;
  final String nurseName;

  const DispenserPage({
    super.key,
    required this.userId,
    required this.nurseName,
  });

  @override
  State<DispenserPage> createState() => _DispenserPageState();
}

class _DispenserPageState extends State<DispenserPage> {
  final TextEditingController dispenser = TextEditingController();
  final TextEditingController cylinder = TextEditingController();
  final TextEditingController medicine = TextEditingController();
  final TextEditingController noOfMedicine = TextEditingController();

  bool isSaving = false;

  Future<void> saveDispenser(BuildContext context) async {
    if (dispenser.text.isEmpty ||
        cylinder.text.isEmpty ||
        medicine.text.isEmpty ||
        noOfMedicine.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final response = await http.post(
        Uri.parse("${API.baseUrl}/api/dispensers"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "dispenser": dispenser.text.trim(),
          "cylinder": cylinder.text.trim(),
          "medicine": medicine.text.trim(),
          "no_of_medicine": noOfMedicine.text.trim(),
          "user_id": widget.userId,
          "nurse_name": widget.nurseName,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Dispenser saved successfully")),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Failed to save dispenser"),
          ),
        );
      }
    } catch (e) {
      print("SAVE ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server error")),
      );
    }

    setState(() {
      isSaving = false;
    });
  }

  @override
  void dispose() {
    dispenser.dispose();
    cylinder.dispose();
    medicine.dispose();
    noOfMedicine.dispose();
    super.dispose();
  }

  Widget input({
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF1565C0),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget smallInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Expanded(
      child: input(
        label: label,
        controller: controller,
        keyboardType: TextInputType.number,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FD),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Dispenser Setter",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              // HEADER CARD
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
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.medication,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),

                    const SizedBox(width: 18),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Medicine Setup",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "Set by: ${widget.nurseName}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // FORM CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Dispenser Details",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        smallInput(
                          label: "Dispenser No.",
                          controller: dispenser,
                          icon: Icons.local_hospital,
                        ),

                        const SizedBox(width: 12),

                        smallInput(
                          label: "Cylinder No.",
                          controller: cylinder,
                          icon: Icons.circle,
                        ),
                      ],
                    ),

                    input(
                      label: "Medicine",
                      controller: medicine,
                      keyboardType: TextInputType.text,
                      icon: Icons.medication_liquid,
                    ),

                    input(
                      label: "No. of Medicine",
                      controller: noOfMedicine,
                      keyboardType: TextInputType.number,
                      icon: Icons.inventory_2,
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 3,
                        ),
                        onPressed: isSaving ? null : () => saveDispenser(context),
                        child: isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "SAVE DISPENSER",
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
            ],
          ),
        ),
      ),
    );
  }
}