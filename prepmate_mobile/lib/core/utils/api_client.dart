import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiClient {
  static const String baseUrl = 'http://127.0.0.1:8000/api/users';


  static Future<Map<String, dynamic>> registerUser(
      String email,
      String password,
      String fullName,
      ) async {

    final response = await http.post(
      Uri.parse("$baseUrl/register/"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json"
      },
      body: jsonEncode({
        "email": email,
        "password": password,
        "full_name": fullName
      }),
    );

    print("STATUS CODE: ${response.statusCode}");
    print("RESPONSE BODY: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Signup failed: ${response.body}");
    }
  }



       // verify OTP

  static Future<Map<String, dynamic>> verifyOTP(String email, String otp) async {

    final response = await http.post(
      Uri.parse("$baseUrl/verify-otp/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "otp": otp
      }),
    );

    print("OTP RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("OTP verification failed");
    }
  }



  //login

  static Future login(String email, String password) async {

    final response = await http.post(
      Uri.parse("$baseUrl/login/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password
      }),
    );

    return jsonDecode(response.body);
  }

}
