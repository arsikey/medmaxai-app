import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'config.dart';
import 'dispenser_page.dart';

class AssignedPatientPage extends StatefulWidget {

  final int userId;

  const AssignedPatientPage({
    super.key,
    required this.userId,
  });

  @override
  State<AssignedPatientPage> createState() =>
      _AssignedPatientPageState();
}

class _AssignedPatientPageState
    extends State<AssignedPatientPage> {

  List dispensers = [];
  List filteredDispensers = [];

  bool isLoading = true;

  final TextEditingController searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchDispensers();
  }

  // ==========================
  // FORMAT DATE
  // ==========================
  String formatDate(String? date) {

    if (date == null || date.isEmpty) {
      return "";
    }

    try {

      DateTime d =
      DateTime.parse(date).toLocal();

      return
          "${d.month}/${d.day}/${d.year}";

    } catch (e) {

      return date;
    }
  }

  // ==========================
  // FETCH DISPENSERS
  // ==========================
  Future<void> fetchDispensers() async {

    try {

      var url = Uri.parse(
        "${Config.baseUrl}/api/dispensers?user_id=${widget.userId}",
      );

      var response = await http.get(url);

      var data = jsonDecode(response.body);

      // RECENT FIRST
      data.sort((a, b) =>
          int.parse(
            b['id'].toString(),
          ).compareTo(
            int.parse(
              a['id'].toString(),
            ),
          ));

      setState(() {

        dispensers = data;

        filteredDispensers = data;

        isLoading = false;
      });

    } catch (e) {

      print("FETCH ERROR: $e");

      setState(() {
        isLoading = false;
      });
    }
  }

  // ==========================
  // SEARCH
  // ==========================
  void searchPatient(String value) {

    if (value.isEmpty) {

      setState(() {
        filteredDispensers =
            dispensers;
      });

      return;
    }

    final filtered =
    dispensers.where((d) {

      final patient =
      d['patient']
          .toString()
          .toLowerCase();

      final medicine =
      d['medicine']
          .toString()
          .toLowerCase();

      return patient.contains(
        value.toLowerCase(),
      ) ||
          medicine.contains(
            value.toLowerCase(),
          );

    }).toList();

    setState(() {
      filteredDispensers =
          filtered;
    });
  }

  // ==========================
  // DELETE DISPENSER
  // ==========================
  Future<void> deleteDispenser(
      int id,
      ) async {

    try {

      await http.delete(
        Uri.parse(
          "${Config.baseUrl}/api/dispensers/$id",
        ),
      );

      fetchDispensers();

    } catch (e) {

      print(
        "DELETE ERROR: $e",
      );
    }
  }

  // ==========================
  // DELETE DIALOG
  // ==========================
  void showDeleteDialog(int id) {

    showDialog(

      context: context,

      builder: (_) =>
          AlertDialog(

            title: const Text(
              "Delete Patient",
            ),

            content: const Text(
              "Are you sure you want to delete this assigned patient?",
            ),

            actions: [

              TextButton(

                onPressed: () {
                  Navigator.pop(
                    context,
                  );
                },

                child: const Text(
                  "Cancel",
                ),
              ),

              ElevatedButton(

                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  Colors.red,
                ),

                onPressed: () async {

                  Navigator.pop(
                    context,
                  );

                  await deleteDispenser(
                    id,
                  );
                },

                child: const Text(
                  "Delete",
                ),
              ),
            ],
          ),
    );
  }

  // ==========================
  // INFO TILE
  // ==========================
  Widget infoTile({

    required IconData icon,

    required String title,

    required String value,

  }) {

    return Row(
      children: [

        CircleAvatar(
          radius: 18,

          backgroundColor:
          Colors.blue.withOpacity(
            0.1,
          ),

          child: Icon(
            icon,
            size: 18,
            color: Colors.blue,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              Text(
                title,

                style: TextStyle(
                  color:
                  Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                value,

                style: const TextStyle(
                  fontWeight:
                  FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================
  // PATIENT CARD
  // ==========================
  Widget patientCard(var d) {

    return Container(

      margin:
      const EdgeInsets.only(
        bottom: 18,
      ),

      padding:
      const EdgeInsets.all(20),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:
        BorderRadius.circular(25),

        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(
              0.05,
            ),
            blurRadius: 10,
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          // TOP
          Row(
            children: [

              CircleAvatar(
                radius: 30,

                backgroundColor:
                Colors.blue.shade100,

                child: const Icon(
                  Icons.person,
                  color: Colors.blue,
                  size: 30,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    Text(
                      d['patient'] ?? '',

                      style:
                      const TextStyle(
                        fontSize: 20,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      "Medicine: ${d['medicine'] ?? ''}",

                      style: TextStyle(
                        color:
                        Colors.grey.shade700,

                        fontSize: 15,

                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              PopupMenuButton(

                itemBuilder:
                    (context) => [

                  PopupMenuItem(

                    child:
                    const Text(
                      "Delete",
                    ),

                    onTap: () {

                      Future.delayed(
                        Duration.zero,

                            () =>
                            showDeleteDialog(
                              d['id'],
                            ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // TIME
          infoTile(
            icon:
            Icons.access_time,

            title:
            "Time",

            value:
            d['time'] ?? '',
          ),

          const SizedBox(height: 12),

          // DATE
          infoTile(
            icon:
            Icons.calendar_month,

            title:
            "Date",

            value:
            formatDate(
              d['date'],
            ),
          ),

          const SizedBox(height: 12),

          // DISPENSER
          infoTile(
            icon:
            Icons.medication,

            title:
            "Dispenser",

            value:
            "Dispenser ${d['dispenser']}",
          ),

          const SizedBox(height: 12),

          // CYLINDER
          infoTile(
            icon:
            Icons.circle,

            title:
            "Cylinder",

            value:
            "Cylinder ${d['cylinder']}",
          ),

          const SizedBox(height: 12),

          // NURSE
          infoTile(
            icon:
            Icons.local_hospital,

            title:
            "Assigned Nurse",

            value:
            d['nurse'] ?? '',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
      const Color(0xFFF4F8FD),

      appBar: AppBar(

        backgroundColor:
        Colors.transparent,

        elevation: 0,

        iconTheme:
        const IconThemeData(
          color: Colors.black,
        ),

        title: const Text(
          "Assigned Patients",

          style: TextStyle(
            color: Colors.black,
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),

      floatingActionButton:
      FloatingActionButton.extended(

        backgroundColor:
        const Color.fromARGB(
          255,
          178,
          206,
          238,
        ),

        icon:
        const Icon(Icons.add),

        label:
        const Text(
          "Add Patient",
        ),

        onPressed: () async {

          final result =
          await Navigator.push(

            context,

            MaterialPageRoute(

              builder: (_) =>
                  DispenserPage(
                    userId:
                    widget.userId,
                  ),
            ),
          );

          if (result == true) {
            fetchDispensers();
          }
        },
      ),

      body: isLoading

          ? const Center(
        child:
        CircularProgressIndicator(),
      )

          : RefreshIndicator(

        onRefresh:
        fetchDispensers,

        child:
        SingleChildScrollView(

          physics:
          const AlwaysScrollableScrollPhysics(),

          padding:
          const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              // HEADER
              Container(

                width:
                double.infinity,

                padding:
                const EdgeInsets.all(
                  25,
                ),

                decoration:
                BoxDecoration(

                  gradient:
                  const LinearGradient(
                    colors: [
                      Color(
                        0xFF1565C0,
                      ),
                      Color(
                        0xFF42A5F5,
                      ),
                    ],
                  ),

                  borderRadius:
                  BorderRadius.circular(
                    30,
                  ),
                ),

                child: Row(
                  children: [

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                        children: [

                          Text(
                            "${filteredDispensers.length} Assigned Patients",

                            style:
                            const TextStyle(
                              color:
                              Colors.white,

                              fontSize:
                              28,

                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 10,
                          ),
                        ],
                      ),
                    ),

                    Container(

                      width: 70,
                      height: 70,

                      decoration:
                      BoxDecoration(

                        color:
                        Colors.white24,

                        borderRadius:
                        BorderRadius.circular(
                          20,
                        ),
                      ),

                      child: const Icon(
                        Icons.groups,
                        color:
                        Colors.white,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // SEARCH
              Container(

                decoration:
                BoxDecoration(

                  color:
                  Colors.white,

                  borderRadius:
                  BorderRadius.circular(
                    18,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color:
                      Colors.black
                          .withOpacity(
                        0.05,
                      ),

                      blurRadius:
                      10,
                    ),
                  ],
                ),

                child: TextField(

                  controller:
                  searchController,

                  onChanged:
                  searchPatient,

                  decoration:
                  InputDecoration(

                    hintText:
                    "Search patient or medicine",

                    prefixIcon:
                    const Icon(
                      Icons.search,
                    ),

                    border:
                    OutlineInputBorder(

                      borderRadius:
                      BorderRadius.circular(
                        18,
                      ),

                      borderSide:
                      BorderSide.none,
                    ),

                    filled: true,

                    fillColor:
                    Colors.transparent,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // TITLE
              const Text(
                "Assigned Schedule",

                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              // EMPTY
              filteredDispensers
                  .isEmpty

                  ? Container(

                width:
                double.infinity,

                padding:
                const EdgeInsets.all(
                  40,
                ),

                decoration:
                BoxDecoration(
                  color:
                  Colors.white,

                  borderRadius:
                  BorderRadius.circular(
                    25,
                  ),
                ),

                child: Column(
                  children: [

                    Icon(
                      Icons.people_alt,

                      size: 70,

                      color:
                      Colors.grey
                          .shade400,
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    const Text(
                      "No Assigned Patients",

                      style:
                      TextStyle(
                        fontSize:
                        18,

                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )

                  // LIST
                  : ListView.builder(

                shrinkWrap: true,

                physics:
                const NeverScrollableScrollPhysics(),

                itemCount:
                filteredDispensers
                    .length,

                itemBuilder:
                    (context, index) {

                  return patientCard(
                    filteredDispensers[
                    index],
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