import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'api_connection.dart';

class TakenPage extends StatefulWidget {
  final int userId;
  final String nurseName;

  const TakenPage({
    super.key,
    required this.userId,
    required this.nurseName,
  });

  @override
  State<TakenPage> createState() => _TakenPageState();
}

class _TakenPageState extends State<TakenPage> {
  List taken = [];
  List filteredTaken = [];

  bool isLoading = true;
  String sortOption = "Latest";

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTaken();
  }

  Future<void> fetchTaken() async {
    try {
      final response = await http.get(
        Uri.parse("${API.baseUrl}/api/taken?user_id=${widget.userId}"),
      );

      final data = jsonDecode(response.body);

      setState(() {
        taken = data;
        filteredTaken = data;
        isLoading = false;
      });

      sortTaken();
    } catch (e) {
      print("FETCH TAKEN ERROR: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void searchTaken(String value) {
    final keyword = value.toLowerCase();

    final result = taken.where((t) {
      final name = (t['name'] ?? '').toString().toLowerCase();
      final medicine = (t['medicine'] ?? '').toString().toLowerCase();

      return name.contains(keyword) || medicine.contains(keyword);
    }).toList();

    setState(() {
      filteredTaken = result;
    });

    sortTaken();
  }

  DateTime getDateTimeValue(var t) {
    final dateText = formatDate(t['date']);
    final timeText = (t['time'] ?? '00:00').toString();

    try {
      return DateTime.parse("$dateText $timeText");
    } catch (e) {
      return DateTime(2000);
    }
  }

  void sortTaken() {
    setState(() {
      filteredTaken.sort((a, b) {
        final dateA = getDateTimeValue(a);
        final dateB = getDateTimeValue(b);

        if (sortOption == "Latest") {
          return dateB.compareTo(dateA);
        } else {
          return dateA.compareTo(dateB);
        }
      });
    });
  }

  String formatDate(dynamic value) {
    if (value == null) return "";

    final text = value.toString();

    // Example from MySQL: 2026-05-12T16:00:00.000Z
    if (text.contains("T")) {
      return text.split("T").first;
    }

    // Example: 2026-05-13
    if (text.length >= 10) {
      return text.substring(0, 10);
    }

    return text;
  }

  String formatTime(dynamic value) {
    if (value == null) return "";

    final text = value.toString();

    // If time is 16:46:00, show only 16:46
    if (text.length >= 5) {
      return text.substring(0, 5);
    }

    return text;
  }

  Widget takenCard(var t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.green.withOpacity(0.15),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 32,
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Medicine: ${t['medicine'] ?? ''}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Time Taken: ${formatTime(t['time'])}",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "Nurse: ${widget.nurseName}",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "Date: ${formatDate(t['date'])}",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget searchAndFilter() {
    return Column(
      children: [
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
            onChanged: searchTaken,
            decoration: InputDecoration(
              hintText: "Search patient or medicine...",
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

        const SizedBox(height: 15),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: sortOption,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: "Latest",
                  child: Text("Latest Time Taken"),
                ),
                DropdownMenuItem(
                  value: "Earliest",
                  child: Text("Earliest Time Taken"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  sortOption = value!;
                });
                sortTaken();
              },
            ),
          ),
        ),
      ],
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
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Taken Records",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchTaken,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
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
                                  "Dispensed / Taken",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "${filteredTaken.length} taken records",
                                  style: const TextStyle(
                                    color: Colors.white70,
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
                              Icons.check_circle,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    searchAndFilter(),

                    const SizedBox(height: 25),

                    filteredTaken.isEmpty
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
                                  Icons.check_circle_outline,
                                  size: 70,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 15),
                                const Text(
                                  "No Taken Records",
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
                            itemCount: filteredTaken.length,
                            itemBuilder: (context, index) {
                              return takenCard(filteredTaken[index]);
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}