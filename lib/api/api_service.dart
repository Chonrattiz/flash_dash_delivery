import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../model/request/register_request.dart';

class ApiService {
  final String _baseUrl = AppConfig.baseUrl;

  // ฟังก์ชันสำหรับสมัครสมาชิก Customer
  Future<String> registerCustomer(RegisterCustomerPayload payload) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register/customer'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(payload.toJson()),
    );

    if (response.statusCode == 200) {
      // สำเร็จ
      return "Registration successful!";
    } else {
      // ไม่สำเร็จ
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to register customer');
    }
  }

  // ฟังก์ชันสำหรับสมัครสมาชิก Rider
  Future<String> registerRider(RegisterRiderPayload payload) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register/rider'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(payload.toJson()),
    );

    if (response.statusCode == 200) {
      // สำเร็จ
      return "Registration successful!";
    } else {
      // ไม่สำเร็จ
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to register rider');
    }
  }
}
