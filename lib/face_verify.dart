import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api_connection.dart';

class FaceVerifyPage extends StatefulWidget {
  final bool returnResult;

  const FaceVerifyPage({
    super.key,
    this.returnResult = false,
  });

  @override
  State<FaceVerifyPage> createState() => _FaceVerifyPageState();
}

class _FaceVerifyPageState extends State<FaceVerifyPage> {
  File? selfieImage;
  bool isLoading = false;

  String resultText = "No verification yet";
  String? recognizedName;
  double? distance;

  final ImagePicker picker = ImagePicker();

  Future<void> takeSelfieAndVerify() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        selfieImage = File(image.path);
        isLoading = true;
        resultText = "Verifying face...";
        recognizedName = null;
        distance = null;
      });

      final request = HttpClient();

      final uri = Uri.parse(API.verifyFace);

      final multipartRequest = await request.postUrl(uri);

      final boundary =
          "----flutter_boundary_${DateTime.now().millisecondsSinceEpoch}";

      multipartRequest.headers.set(
        HttpHeaders.contentTypeHeader,
        "multipart/form-data; boundary=$boundary",
      );

      final fileBytes = await selfieImage!.readAsBytes();
      final fileName = selfieImage!.path.split('/').last;

      multipartRequest.add(utf8.encode("--$boundary\r\n"));
      multipartRequest.add(
        utf8.encode(
          'Content-Disposition: form-data; name="selfie"; filename="$fileName"\r\n',
        ),
      );
      multipartRequest.add(utf8.encode("Content-Type: image/jpeg\r\n\r\n"));
      multipartRequest.add(fileBytes);
      multipartRequest.add(utf8.encode("\r\n--$boundary--\r\n"));

      final response = await multipartRequest.close();
      final responseBody = await response.transform(utf8.decoder).join();

      final data = jsonDecode(responseBody);

      if (data['success'] == true && data['verified'] == true) {
        setState(() {
          resultText = "Authorized";
          recognizedName = data['name'];
          distance = double.tryParse(data['distance'].toString());
        });

        if (widget.returnResult) {
          await Future.delayed(const Duration(milliseconds: 700));

          if (!mounted) return;

          Navigator.pop(context, {
            "authorized": true,
            "name": data['name'],
            "distance": data['distance'],
          });
        }
      } else {
        setState(() {
          resultText = "Unknown / Unauthorized";
          recognizedName = null;
          distance = data['distance'] != null
              ? double.tryParse(data['distance'].toString())
              : null;
        });

        if (widget.returnResult) {
          await Future.delayed(const Duration(milliseconds: 700));

          if (!mounted) return;

          Navigator.pop(context, {
            "authorized": false,
            "name": null,
            "distance": data['distance'],
          });
        }
      }
    } catch (e) {
      setState(() {
        resultText = "Connection error";
      });

      print("FACE VERIFY ERROR: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget resultBox() {
    Color color;
    IconData icon;

    if (resultText == "Authorized") {
      color = Colors.green;
      icon = Icons.verified_user;
    } else if (resultText.contains("Unknown")) {
      color = Colors.red;
      icon = Icons.error;
    } else if (resultText.contains("Verifying")) {
      color = Colors.orange;
      icon = Icons.hourglass_top;
    } else {
      color = Colors.grey;
      icon = Icons.face;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 35,
          ),

          const SizedBox(height: 10),

          Text(
            resultText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          if (recognizedName != null) ...[
            const SizedBox(height: 8),
            Text(
              "Name: $recognizedName",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          if (distance != null) ...[
            const SizedBox(height: 5),
            Text(
              "Distance: ${distance!.toStringAsFixed(4)}",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget imageBox() {
    return Container(
      width: double.infinity,
      height: 320,
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
      child: selfieImage == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt,
                  size: 70,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 15),
                Text(
                  "Take a selfie to verify",
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.file(
                selfieImage!,
                fit: BoxFit.cover,
              ),
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
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: const Text(
          "Face Authorization",
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
                        Icons.face_retouching_natural,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),

                    const SizedBox(width: 18),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Face Verification",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 6),

                          Text(
                            "Verify nurse identity before dispensing.",
                            style: TextStyle(
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

              imageBox(),

              const SizedBox(height: 20),

              resultBox(),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: isLoading ? null : takeSelfieAndVerify,
                  icon: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                  ),
                  label: Text(
                    isLoading ? "Verifying..." : "Take Selfie and Verify",
                    style: const TextStyle(
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