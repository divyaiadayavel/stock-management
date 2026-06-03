// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class ApiService {
//   // 🔗 CHANGE THIS TO YOUR SERVER URL
//   static const String baseUrl = "https://your-api-url.com/api";

//   // =========================
//   // 🔁 COMMON POST METHOD
//   // =========================
//   static Future<Map<String, dynamic>> post(
//     String endpoint,
//     Map<String, dynamic> data,
//   ) async {
//     try {
//       final res = await http.post(
//         Uri.parse("$baseUrl/$endpoint"),
//         body: jsonEncode(data),
//         headers: {"Content-Type": "application/json"},
//       );

//       final decoded = jsonDecode(res.body);

//       return decoded;
//     } catch (e) {
//       return {"status": false, "message": "Server error: $e"};
//     }
//   }

//   // =========================
//   // 🔐 LOGIN USER
//   // =========================
//   static Future<Map<String, dynamic>> login(
//     String email,
//     String password,
//   ) async {
//     return post("login.php", {"email": email, "password": password});
//   }

//   // =========================
//   // 📝 REGISTER USER
//   // =========================
//   static Future<Map<String, dynamic>> register(
//     String name,
//     String email,
//     String password,
//   ) async {
//     return post("register.php", {
//       "name": name,
//       "email": email,
//       "password": password,
//     });
//   }

//   // =========================
//   // 📧 FORGOT PASSWORD
//   // =========================
//   static Future<Map<String, dynamic>> forgotPassword(String email) async {
//     return post("forgot_password.php", {"email": email});
//   }

//   // =========================
//   // 🔢 VERIFY OTP
//   // =========================
//   static Future<Map<String, dynamic>> verifyOtp(
//     String email,
//     String otp,
//   ) async {
//     return post("verify_otp.php", {"email": email, "otp": otp});
//   }

//   // =========================
//   // 🔑 RESET PASSWORD
//   // =========================
//   static Future<Map<String, dynamic>> resetPassword(
//     String email,
//     String password,
//   ) async {
//     return post("reset_password.php", {"email": email, "password": password});
//   }

//   // =========================
//   // 🧪 MOCK LOGIN (OPTIONAL)
//   // =========================
//   static Future<Map<String, dynamic>> mockLogin(
//     String email,
//     String password,
//   ) async {
//     await Future.delayed(const Duration(seconds: 1));

//     return {
//       "status": true,
//       "data": {
//         "id": 1,
//         "name": "Test User",
//         "role": "admin", // change: admin / staff / cashier
//       },
//     };
//   }
// }
