import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:prepmate_mobile/core/services/storage.dart';

class ApiClient {
  static const String baseUrl = 'http://10.176.105.1:8000/api/v1/';

  static Future<Map<String, dynamic>> registerUser(
    String email,
    String password,
    String name,
    String passwordConfirm,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/register/"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password,
        "password_confirm": passwordConfirm,
        "name": name,
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

  static Future<Map<String, dynamic>> verifyOTP(
    String email,
    String otp,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/verify-otp/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "otp": otp}),
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
      Uri.parse("$baseUrl/auth/login/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final accessToken = data["tokens"]?["access"];

      if (accessToken != null) {
        await TokenService.saveToken(accessToken);
      } else {
        throw Exception("Token missing");
      }

      return data;

    } else {
      throw Exception(data["message"] ?? "Login failed");
    }


  }
}
