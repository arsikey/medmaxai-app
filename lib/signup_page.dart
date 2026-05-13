import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'api_connection.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {

  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() =>
      _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {

  final TextEditingController first_name = TextEditingController();
  final TextEditingController last_name = TextEditingController();
  final TextEditingController username = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirm_pass = TextEditingController();
  final TextEditingController otp = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool isLoading = false;

  
  Timer? otp_timer;
  int otp_seconds = 0;
  bool send_otp = true;

  // signup func
  Future<void> signup() async {
    
  if (first_name.text.isEmpty ||
      last_name.text.isEmpty ||
      username.text.isEmpty ||
      email.text.isEmpty ||
      otp.text.isEmpty ||
      password.text.isEmpty ||
      confirm_pass.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please fill all fields"),
      ),
    );
    return;
  }

    // email validation func
    final email_value = email.text.trim();

    final email_valid = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$',).hasMatch(email_value);

    if (!email_valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid email address"),
        ),
      );
      return;
    }

    // password validation func
    final password_value = password.text;
    final upper_case = RegExp(r'[A-Z]').hasMatch(password_value);
    final lower_case = RegExp(r'[a-z]').hasMatch(password_value);
    final number = RegExp(r'[0-9]').hasMatch(password_value);
    final symbol = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/\\[\]~`]').hasMatch(password_value);

    if (password_value.length < 6 ||
        !upper_case ||
        !lower_case ||
        !number ||
        !symbol) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Password must be at least 6 characters and include uppercase, lowercase, number, and symbol.",
          ),
        ),
      );
      return;
    }

    if (password.text !=
        confirm_pass.text) {

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
      var url = Uri.parse(API.signup);
      var response = await http.post(
        url,
        headers: {
          "Content-Type":
          "application/json",
        },
        body: jsonEncode({
          "first_name": first_name.text.trim(),
          "last_name": last_name.text.trim(),
          "username": username.text.trim(),
          "email": email.text.trim(),
          "password": password.text,
          "otp": otp.text.trim(),
        }),
      );

      var data = jsonDecode(response.body);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Signup Failed"),
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

  // send OTP func
  Future<void> sendOtp() async {
    if (email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your email first"),
        ),
      );
      return;
    }

    final email_value = email.text.trim();

    final email_valid = RegExp(
      r'^[\w\.-]+@[\w\.-]+\.\w{2,}$',
    ).hasMatch(email_value);

    if (!email_valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid email address"),
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(API.sendOtp),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email_value,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        setState(() {
          send_otp = false;
          otp_seconds = 300;
        });

        otp_timer?.cancel();

        otp_timer = Timer.periodic(
          const Duration(seconds: 1),
          (timer) {
            if (otp_seconds == 0) {
              timer.cancel();
              setState(() {
                send_otp = true;
              });
            } else {
              setState(() {
                otp_seconds--;
              });
            }
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "OTP sent successfully"),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Failed to send OTP"),
          ),
        );
      }

    } catch (e) {
      print("SEND OTP ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Server Error"),
        ),
      );
    }
  }

  String formatOtpTime() {
    final minutes = otp_seconds ~/ 60;
    final seconds = otp_seconds % 60;

    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    first_name.dispose();
    last_name.dispose();
    username.dispose();
    email.dispose();
    password.dispose();
    confirm_pass.dispose();
    otp.dispose();
    otp_timer?.cancel();
    super.dispose();
  }

  // custom field
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

              // icon
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

              // title
              const Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: customField(
                      controller: first_name,
                      hint: "First Name",
                      icon: Icons.badge,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: customField(
                      controller: last_name,
                      hint: "Last Name",
                      icon: Icons.badge_outlined,
                    ),
                  ),
                ],
              ),

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
              // OTP
              customField(
                controller: otp,
                hint: "Enter OTP",
                icon: Icons.verified_user,
              ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: send_otp ? Colors.blue : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: send_otp ? sendOtp : null,
                child: Text(
                  send_otp
                      ? "SEND OTP"
                      : "RESEND OTP IN ${formatOtpTime()}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),
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
                controller: confirm_pass,
                hint: "Confirm Password",
                icon: Icons.lock_outline,
                isPassword: true,
                obscure: obscureConfirm,
                toggle: () {
                  setState(() {
                    obscureConfirm = !obscureConfirm;
                  });
                },
              ),

              const SizedBox(height: 15),
              // PASSWORD HINT
              Container(
                padding:
                const EdgeInsets.all(15,),
                decoration: BoxDecoration(
                  color:Colors.blue.withOpacity(0.08,),
                  borderRadius:
                  BorderRadius.circular(18,),
                ),
              ),

              // SIGNUP BUTTON
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:const Color(0xFF1565C0),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(20,),
                    ),
                  ),

                  onPressed: isLoading ? null: signup,
                  child: isLoading
                      ? const CircularProgressIndicator(
                    color:Colors.white,
                  )

                      : const Text(
                    "CREATE ACCOUNT",
                    style: TextStyle(
                      color:Colors.white,
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
                        color:Colors.grey.shade700,
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