import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

// Import the new models we created
import '../model/request/login_request.dart';
import '../model/request/register_request.dart';
import '../model/response/login_response.dart';
import '../model/request/update_profile_request.dart';
import '../model/request/update_profile_rider_request.dart';

class ApiService {
  final String _baseUrl = AppConfig.baseUrl;

  // New function for user login
  Future<LoginResponse> login(LoginRequest payload) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'), // The endpoint from your Go backend
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(payload.toJson()),
    );

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the JSON.
      final responseBody = jsonDecode(response.body);
      return LoginResponse.fromJson(responseBody);
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to login');
    }
  }

  // --- Your existing register functions below ---

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
      return "Registration successful!";
    } else {
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
      return "Registration successful!";
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to register rider');
    }
  }

  // **** เพิ่มฟังก์ชันใหม่สำหรับอัปเดตโปรไฟล์ ****
  Future<LoginResponse> updateProfile({
    required String token, // ต้องใช้ Token เพื่อยืนยันตัวตน
    required UpdateProfilePayload payload,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/user/profile'), // Endpoint จากฝั่ง Go
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // <-- ส่ง Token ไปใน Header
      },
      body: jsonEncode(payload.toJson()),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      // Backend ของคุณจะส่งข้อมูลที่อัปเดตแล้วกลับมาใน key "updatedData"
      // เราจึงนำมาแปลงเป็น LoginResponse เพื่อส่งกลับไปให้หน้า Profile
      return LoginResponse.fromJson(responseBody['updatedData']);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to update profile');
    }
  }

  // +++ Add this new function to update a Rider's profile +++
  Future<LoginResponse> updateRiderProfile({
    required String token,
    required UpdateRiderProfilePayload payload,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/rider/profile'), // The new endpoint for riders
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // Send token for authentication
      },
      body: jsonEncode(payload.toJson()),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      // The Go backend returns the updated data in the "updatedData" key
      return LoginResponse.fromJson(responseBody['updatedData']);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to update rider profile');
    }
  }
}
