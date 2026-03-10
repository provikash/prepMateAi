import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiClient {
  static const String baseurl = 'https://prepmateAi.in';

  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    return http.post(
      Uri.parse('$baseurl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
  }
}
