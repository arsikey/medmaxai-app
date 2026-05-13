import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'api_connection.dart';
import 'login_page.dart';

class ForgotPassPage extends StatefulWidget {
  const ForgotPassPage({super.key});

  @override
  State<ForgotPassPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPassPage> {
  final TextEditingController email = TextEditingController();
  final TextEditingController otp = TextEditingController();
  final TextEditingController newPassword = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool isLoading = false;

  Timer? otp_timer;
  int otp_seconds = 0;
  bool send_otp = true;

  Future<void> sendOtp() async {
    if (email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email first")),
      );
      return;
    }

    final email_value = email.text.trim();

    final email_valid = RegExp(
      r'^[\w\.-]+@[\w\.-]+\.\w{2,}$',
    ).hasMatch(email_value);

    if (!email_valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email address")),
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
          SnackBar(content: Text(data['message'] ?? "OTP sent successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Failed to send OTP")),
        );
      }
    } catch (e) {
      print("SEND OTP ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server Error")),
      );
    }
  }

  Future<void> resetPassword() async {
    if (email.text.isEmpty ||
        otp.text.isEmpty ||
        newPassword.text.isEmpty ||
        confirmPassword.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (newPassword.text != confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    final password_value = newPassword.text;
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

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(API.forgotPassword),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email.text.trim(),
          "otp": otp.text.trim(),
          "new_password": newPassword.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Password reset successful")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Reset failed")),
        );
      }
    } catch (e) {
      print("RESET PASSWORD ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server Error")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  String formatOtpTime() {
    final minutes = otp_seconds ~/ 60;
    final seconds = otp_seconds % 60;

    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  Widget customField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? toggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.blue),
          suffixIcon: isPassword
              ? IconButton(
                  onPressed: toggle,
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }

  @override
  void dispose() {
    email.dispose();
    otp.dispose();
    newPassword.dispose();
    confirmPassword.dispose();
    otp_timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              const Text(
                "Forgot Password",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Enter your email and OTP to reset your password.",
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 30),

              customField(
                controller: email,
                hint: "Email",
                icon: Icons.email,
              ),

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

              customField(
                controller: newPassword,
                hint: "New Password",
                icon: Icons.lock,
                isPassword: true,
                obscure: obscurePassword,
                toggle: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
              ),

              customField(
                controller: confirmPassword,
                hint: "Confirm New Password",
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

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: isLoading ? null : resetPassword,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "RESET PASSWORD",
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
      ),
    );
  }
}