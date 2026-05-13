import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'api_connection.dart';

class PatientInfoPage extends StatefulWidget {
  final int userId;
  final String nurseName;

  const PatientInfoPage({
    super.key,
    required this.userId,
    required this.nurseName,
  });

  @override
  State<PatientInfoPage> createState() =>
      _PatientInfoPageState();
}

class _PatientInfoPageState
    extends State<PatientInfoPage> {

  List patients = [];
  List allPatients = [];

  bool isLoading = true;

  final TextEditingController searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPatients();
  }

  Future<void> assignPatient(int patientId) async {
    try {
      final response = await http.put(
        Uri.parse("${API.baseUrl}/api/patient-info/assign/$patientId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nurse_id": widget.userId,
          "nurse": widget.nurseName,
        }),
      );

      final data = jsonDecode(response.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? "Assign request completed")),
      );

      if (data['success'] == true) {
        fetchPatients();
      }
    } catch (e) {
      print("ASSIGN ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server error")),
      );
    }
  }

  Future<void> unassignPatient(int patientId) async {
    try {
      final response = await http.put(
        Uri.parse("${API.baseUrl}/api/patient-info/unassign/$patientId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nurse_id": widget.userId,
        }),
      );

      final data = jsonDecode(response.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? "Unassign request completed")),
      );

      if (data['success'] == true) {
        fetchPatients();
      }
    } catch (e) {
      print("UNASSIGN ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server error")),
      );
    }
  }
  // ==========================
  // FETCH PATIENTS
  // ==========================
  Future<void> fetchPatients() async {

    try {
      var url = Uri.parse(
        "${API.baseUrl}/api/patient-info",
      );

      var response = await http.get(url);
      var data = jsonDecode(response.body);

      // SORT ALPHABETICALLY BY NAME
      data.sort((a, b) {
        final nameA = (a['name'] ?? '').toString().toLowerCase();
        final nameB = (b['name'] ?? '').toString().toLowerCase();

        return nameA.compareTo(nameB);
      });

      setState(() {
        patients = data;
        allPatients = data;
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
        patients = allPatients;
      });

      return;
    }

    final filtered =
    allPatients.where((p) {

      final name =
      p['name']
          .toString()
          .toLowerCase();

      return name.contains(
        value.toLowerCase(),
      );

    }).toList();

    setState(() {
      patients = filtered;
    });
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

  // ==========================
  // SHOW DETAILS
  // ==========================
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
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 30),

                    detailTile(
                      icon: Icons.home,
                      title: "Address",
                      value: p['address'] ?? '',
                    ),

                    detailTile(
                      icon: Icons.person_outline,
                      title: "Sex",
                      value: p['sex'] ?? '',
                    ),

                    detailTile(
                      icon: Icons.cake,
                      title: "Birthday",
                      value: p['birthday'] ?? '',
                    ),

                    detailTile(
                      icon: Icons.medical_services,
                      title: "Condition",
                      value: p['condition_text'] ?? '',
                    ),

                    detailTile(
                      icon: Icons.local_hospital,
                      title: "Doctor",
                      value: p['doctor'] ?? '',
                    ),

                    detailTile(
                      icon: Icons.health_and_safety,
                      title: "Nurse",
                      value: p['nurse'] ?? 'Not Assigned',
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Maintenance Medicines",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    snapshot.connectionState == ConnectionState.waiting
                        ? const Center(
                            child: CircularProgressIndicator(),
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
                                                fontSize: 16,
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

  // ==========================
  // DETAIL TILE
  // ==========================
  Widget detailTile({
    required IconData icon,
    required String title,
    required String value,
  }) {

    return Container(

      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FD),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
            Colors.blue.withOpacity(0.15),
            child: Icon(
              icon,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================
  // PATIENT CARD
  // ==========================
  Widget patientCard(var p) {
    final int nurseId =
        int.tryParse((p['nurse_id'] ?? 0).toString()) ?? 0;

    final String assignedNurse =
        (p['nurse'] == null || p['nurse'].toString().isEmpty)
            ? "Not Assigned"
            : p['nurse'].toString();

    final bool isUnassigned = nurseId == 0;
    final bool assignedToMe = nurseId == widget.userId;
    final bool assignedToOther = !isUnassigned && !assignedToMe;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      p['condition_text'] ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 15,
                      ),
                    ),
                  ],
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

          Row(
            children: [
              Expanded(
                child: infoCard(
                  icon: Icons.local_hospital,
                  title: "Doctor",
                  value: p['doctor'] ?? '',
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: infoCard(
                  icon: Icons.health_and_safety,
                  title: "Nurse",
                  value: assignedNurse,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: assignedToMe
                    ? Colors.red.shade400
                    : assignedToOther
                        ? Colors.grey
                        : const Color(0xFF1565C0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: assignedToOther
                  ? null
                  : () {
                      if (assignedToMe) {
                        unassignPatient(p['id']);
                      } else {
                        assignPatient(p['id']);
                      }
                    },
              child: Text(
                assignedToMe
                    ? "UNASSIGN"
                    : assignedToOther
                        ? "ASSIGNED"
                        : "ASSIGN",
                style: const TextStyle(
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

  // ==========================
  // INFO CARD
  // ==========================
  Widget infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FD),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.blue,
          ),
          const SizedBox(height: 10),

          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),

          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
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
          "Patient Information",
          style: TextStyle(
            color: Colors.black,
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),

      body: isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: fetchPatients,
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
                          const Text(
                            "Patient Records",
                            style:
                            TextStyle(
                              color:
                              Colors.white70,
                              fontSize:
                              15,
                            ),
                          ),
                          const SizedBox(height: 8,),

                          Text(
                            "${patients.length} Patients",
                            style:
                            const TextStyle(
                              color:
                              Colors.white,
                              fontSize:
                              28,
                              fontWeight:
                              FontWeight
                                  .bold,
                            ),
                          ),
                          const SizedBox(height: 10,),
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
                        Icons.folder_shared,
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
                    "Search patient...",
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
                "Patient List",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),

              // EMPTY
              patients.isEmpty
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
                      color: Colors
                          .grey
                          .shade400,
                    ),
                    const SizedBox(height: 15,),

                    const Text(
                      "No Patient Records",
                      style:
                      TextStyle(
                        fontSize:
                        18,
                        fontWeight:
                        FontWeight
                            .bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
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
                patients.length,

                itemBuilder:
                    (context,
                    index) {

                  return patientCard(
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