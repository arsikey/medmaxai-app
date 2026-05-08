import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'config.dart';

class PatientInfoPage extends StatefulWidget {
  final int userId;

  const PatientInfoPage({
    super.key,
    required this.userId,
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

  // ==========================
  // FETCH PATIENTS
  // ==========================
  Future<void> fetchPatients() async {

    try {

      var url = Uri.parse(
        "${Config.baseUrl}/api/patient-info?user_id=${widget.userId}",
      );

      var response = await http.get(url);

      var data = jsonDecode(response.body);

      // SORT RECENT FIRST
      data.sort((a, b) =>
          int.parse(b['id'].toString())
              .compareTo(
            int.parse(a['id'].toString()),
          ));

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

  // ==========================
  // DELETE
  // ==========================
  Future<void> deletePatient(int id) async {

    try {

      await http.delete(
        Uri.parse(
          "${Config.baseUrl}/api/patient-info/$id",
        ),
      );

      fetchPatients();

    } catch (e) {
      print("DELETE ERROR: $e");
    }
  }

  // ==========================
  // DELETE DIALOG
  // ==========================
  void showDeleteDialog(int id) {

    showDialog(
      context: context,
      builder: (_) => AlertDialog(

        title: const Text(
          "Delete Patient",
        ),

        content: const Text(
          "Are you sure you want to delete this patient?",
        ),

        actions: [

          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),

            onPressed: () async {

              Navigator.pop(context);

              await deletePatient(id);
            },

            child: const Text("Delete"),
          ),
        ],
      ),
    );
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
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Center(
                  child: Container(
                    width: 60,
                    height: 5,

                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Center(
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor:
                    Colors.blue.shade100,

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
                  title: "Gender",
                  value: p['gender'] ?? '',
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
                  value: p['nurse'] ?? '',
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
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
                      p['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight:
                        FontWeight.bold,
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

                  PopupMenuItem(
                    child: const Text("Delete"),
                    onTap: () {
                      Future.delayed(
                        Duration.zero,
                            () => showDeleteDialog(
                          p['id'],
                        ),
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
                  value: p['nurse'] ?? '',
                ),
              ),
            ],
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

      floatingActionButton:
      FloatingActionButton.extended(

        backgroundColor:
        const Color.fromARGB(255, 178, 206, 238),

        icon:
        const Icon(Icons.person_add),

        label:
        const Text("Add Patient"),

        onPressed: () async {

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AddPatientInfoPage(
                    userId:
                    widget.userId,
                  ),
            ),
          );

          fetchPatients();
        },
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

                          const SizedBox(
                            height: 8,
                          ),

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

                    const SizedBox(
                      height: 15,
                    ),

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

// =====================================
// ADD PATIENT PAGE
// =====================================

class AddPatientInfoPage extends StatefulWidget {

  final int userId;

  const AddPatientInfoPage({
    super.key,
    required this.userId,
  });

  @override
  State<AddPatientInfoPage> createState() =>
      _AddPatientInfoPageState();
}

class _AddPatientInfoPageState
    extends State<AddPatientInfoPage> {

  final name =
  TextEditingController();

  final address =
  TextEditingController();

  final gender =
  TextEditingController();

  final birthday =
  TextEditingController();

  final condition =
  TextEditingController();

  final doctor =
  TextEditingController();

  final nurse =
  TextEditingController();

  bool isLoading = false;

  Future<void> savePatient() async {

    if (name.text.isEmpty ||
        address.text.isEmpty ||
        gender.text.isEmpty ||
        birthday.text.isEmpty ||
        condition.text.isEmpty ||
        doctor.text.isEmpty ||
        nurse.text.isEmpty) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
          Text("Please fill all fields"),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      var url = Uri.parse(
        "${Config.baseUrl}/api/patient-info",
      );

      var response = await http.post(
        url,

        headers: {
          "Content-Type":
          "application/json",
        },

        body: jsonEncode({
          "name": name.text,
          "address": address.text,
          "gender": gender.text,
          "birthday": birthday.text,
          "condition_text":
          condition.text,
          "doctor": doctor.text,
          "nurse": nurse.text,
          "user_id":
          widget.userId,
        }),
      );

      var data =
      jsonDecode(response.body);

      if (data['success']) {

        Navigator.pop(
          context,
          true,
        );
      }

    } catch (e) {

      print("SAVE ERROR: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  Widget customField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {

    return Container(
      margin:
      const EdgeInsets.only(bottom: 18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),

      child: TextField(
        controller: controller,

        decoration: InputDecoration(
          hintText: hint,

          prefixIcon: Icon(
            icon,
            color: Colors.blue,
          ),

          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),

          filled: true,
          fillColor: Colors.transparent,
        ),
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
          "Add Patient",
          style: TextStyle(
            color: Colors.black,
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(

        padding:
        const EdgeInsets.all(20),

        child: Column(
          children: [

            customField(
              controller: name,
              hint: "Full Name",
              icon: Icons.person,
            ),

            customField(
              controller: address,
              hint: "Address",
              icon: Icons.home,
            ),

            customField(
              controller: gender,
              hint: "Gender",
              icon: Icons.people,
            ),

            customField(
              controller: birthday,
              hint: "Birthday",
              icon: Icons.cake,
            ),

            customField(
              controller: condition,
              hint: "Condition",
              icon:
              Icons.medical_services,
            ),

            customField(
              controller: doctor,
              hint: "Doctor",
              icon:
              Icons.local_hospital,
            ),

            customField(
              controller: nurse,
              hint: "Nurse",
              icon:
              Icons.health_and_safety,
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 58,

              child: ElevatedButton(

                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color.fromARGB(255, 180, 207, 237),

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      18,
                    ),
                  ),
                ),

                onPressed:
                isLoading
                    ? null
                    : savePatient,

                child: isLoading

                    ? const CircularProgressIndicator(
                  color:
                  Colors.white,
                )

                    : const Text(
                  "SAVE PATIENT",
                  style:
                  TextStyle(
                    fontSize:
                    16,
                    fontWeight:
                    FontWeight
                        .bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}