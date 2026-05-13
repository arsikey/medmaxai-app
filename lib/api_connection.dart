class API{
  static const String baseUrl = "http://192.168.1.19:3000";

  static const String hostConnect = "$baseUrl/api";
  static const String login = "$hostConnect/login";
  static const String signup = "$hostConnect/signup";
  static const String sendOtp = "$hostConnect/sendOtp";
  static const String forgotPassword = "$hostConnect/forgotPassword";
  static const String verifyFace = "$baseUrl/api/verifyFace";
}