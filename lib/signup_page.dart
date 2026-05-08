import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'config.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {

  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() =>
      _SignUpPageState();
}

class _SignUpPageState
    extends State<SignUpPage> {

  final TextEditingController username =
      TextEditingController();

  final TextEditingController email =
      TextEditingController();

  final TextEditingController password =
      TextEditingController();

  final TextEditingController confirmPassword =
      TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirm = true;

  bool isLoading = false;

  // ==========================
  // SIGNUP
  // ==========================
  Future<void> signup() async {

    if (username.text.isEmpty ||
        email.text.isEmpty ||
        password.text.isEmpty ||
        confirmPassword.text.isEmpty) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
          Text("Please fill all fields"),
        ),
      );

      return;
    }

    if (password.text.length < 6) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
          Text(
            "Password must be at least 6 characters",
          ),
        ),
      );

      return;
    }

    if (password.text !=
        confirmPassword.text) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
          Text("Passwords do not match"),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      var url = Uri.parse(
        "${Config.baseUrl}/api/signup",
      );

      var response = await http.post(

        url,

        headers: {
          "Content-Type":
          "application/json",
        },

        body: jsonEncode({

          "username":
          username.text,

          "email":
          email.text,

          "password":
          password.text,
        }),
      );

      var data =
      jsonDecode(response.body);

      if (data['success']) {

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content:
            Text("Signup Successful"),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
            const LoginPage(),
          ),
        );

      } else {

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content:
            Text("Signup Failed"),
          ),
        );
      }

    } catch (e) {

      print("SIGNUP ERROR: $e");

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
          Text("Server Error"),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  // ==========================
  // CUSTOM FIELD
  // ==========================
  Widget customField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? toggle,
  }) {

    return Container(
      margin:
      const EdgeInsets.only(bottom: 18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(20),

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
        obscureText: obscure,

        decoration: InputDecoration(

          hintText: hint,

          prefixIcon: Icon(
            icon,
            color: Colors.blue,
          ),

          suffixIcon: isPassword

              ? IconButton(
            onPressed: toggle,

            icon: Icon(
              obscure
                  ? Icons.visibility_off
                  : Icons.visibility,

              color: Colors.grey,
            ),
          )

              : null,

          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(20),
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

      body: SafeArea(

        child: SingleChildScrollView(

          padding:
          const EdgeInsets.all(25),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              const SizedBox(height: 20),

              // ==========================
              // ICON
              // ==========================
              Center(
                child: Container(
                  width: 110,
                  height: 110,

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                    BorderRadius.circular(
                      30,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color:
                        Colors.black.withOpacity(
                          0.08,
                        ),

                        blurRadius: 15,
                      ),
                    ],
                  ),

                  child: const Icon(
                    Icons.person_add,
                    size: 55,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),

              const SizedBox(height: 35),

              // TITLE
              const Text(
                "Create Account",

                style: TextStyle(
                  fontSize: 32,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),
              // USERNAME
              customField(
                controller: username,
                hint: "Username",
                icon: Icons.person,
              ),

              // EMAIL
              customField(
                controller: email,
                hint: "Email",
                icon: Icons.email,
              ),

              // PASSWORD
              customField(
                controller: password,
                hint: "Password",
                icon: Icons.lock,

                isPassword: true,

                obscure: obscurePassword,

                toggle: () {

                  setState(() {
                    obscurePassword =
                    !obscurePassword;
                  });
                },
              ),

              // CONFIRM PASSWORD
              customField(
                controller:
                confirmPassword,

                hint:
                "Confirm Password",

                icon:
                Icons.lock_outline,

                isPassword: true,

                obscure:
                obscureConfirm,

                toggle: () {

                  setState(() {
                    obscureConfirm =
                    !obscureConfirm;
                  });
                },
              ),

              const SizedBox(height: 15),

              // PASSWORD HINT
              Container(
                padding:
                const EdgeInsets.all(
                  15,
                ),

                decoration: BoxDecoration(
                  color:
                  Colors.blue.withOpacity(
                    0.08,
                  ),

                  borderRadius:
                  BorderRadius.circular(
                    18,
                  ),
                ),
              ),
              // SIGNUP BUTTON
              SizedBox(
                width: double.infinity,
                height: 58,

                child: ElevatedButton(

                  style:
                  ElevatedButton.styleFrom(

                    backgroundColor:
                    const Color(
                      0xFF1565C0,
                    ),

                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
                    ),
                  ),

                  onPressed:
                  isLoading
                      ? null
                      : signup,

                  child: isLoading

                      ? const CircularProgressIndicator(
                    color:
                    Colors.white,
                  )

                      : const Text(
                    "CREATE ACCOUNT",

                    style: TextStyle(
                      color:
                      Colors.white,

                      fontSize: 16,

                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // LOGIN
              Center(
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,

                  children: [

                    Text(
                      "Already have an account? ",
                      style: TextStyle(
                        color:
                        Colors.grey.shade700,
                      ),
                    ),

                    GestureDetector(

                      onTap: () {

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const LoginPage(),
                          ),
                        );
                      },

                      child: const Text(
                        "Login",

                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}