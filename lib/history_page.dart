import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';

class HistoryPage extends StatefulWidget {
  final int userId;

  const HistoryPage({super.key, required this.userId});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List history = [];
  bool isLoading = true;
  String selectedStatus = "All";

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  //  FETCH DATA
  Future<void> fetchHistory() async {
    try {
      var url = Uri.parse(
          "${Config.baseUrl}/api/patients?user_id=${widget.userId}");

      var res = await http.get(url);
      var data = jsonDecode(res.body);

      // FILTER ONLY HISTORY
      var filtered = data.where((p) {
        return p['status'] == "Taken" || p['status'] == "Missed";
      }).toList();

      //  SORT LATEST FIRST (FIXED TIMEZONE)
      filtered.sort((a, b) {
        DateTime da =
            DateTime.parse(a['date']).toLocal(); // 🔥 FIX
        DateTime db =
            DateTime.parse(b['date']).toLocal(); // 🔥 FIX
        return db.compareTo(da);
      });

      setState(() {
        history = filtered;
        isLoading = false;
      });

    } catch (e) {
      print("HISTORY ERROR: $e");
      setState(() => isLoading = false);
    }
  }

  // 🔥 FORMAT DATE (NO INTL + LOCAL SAFE)
  String formatDate(String? date) {
    if (date == null || date.isEmpty) return "";

    try {
      DateTime d = DateTime.parse(date).toLocal(); // 🔥 FIX
      return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    } catch (_) {
      return date;
    }
  }

  //  FILTER STATUS
  List getFilteredHistory() {
    if (selectedStatus == "All") return history;

    return history.where((p) {
      return p['status'] == selectedStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    var displayList = getFilteredHistory();

    return Scaffold(
      appBar: AppBar(title: const Text("History")),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [

                //  STATUS FILTER
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: DropdownButtonFormField<String>(
                    value: selectedStatus,
                    items: ["All", "Taken", "Missed"]
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedStatus = val!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "Filter Status",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                //  LIST
                Expanded(
                  child: displayList.isEmpty
                      ? const Center(child: Text("No history yet"))
                      : ListView.builder(
                          itemCount: displayList.length,
                          itemBuilder: (context, index) {
                            var p = displayList[index];

                            return Card(
                              child: ListTile(
                                title: Text(p['name'] ?? ''),
                                subtitle: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(p['medicine'] ?? ''),
                                    Text("🕒 ${p['time']}"),
                                    Text("📅 ${formatDate(p['date'])}"),
                                  ],
                                ),

                                //  STATUS COLOR
                                trailing: Text(
                                  p['status'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: p['status'] == "Taken"
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}