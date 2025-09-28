import 'dart:convert';
import '../model/request/register_request.dart' as req;
import '../model/response/login_response.dart' as res;
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

// Import the new models we created
import '../model/request/login_request.dart';
import '../model/request/update_profile_request.dart';
import '../model/request/update_profile_rider_request.dart';
import '../model/request/address_request.dart';

class ApiService {
  final String _baseUrl = AppConfig.baseUrl;

  // New function for user login
  Future<res.LoginResponse> login(LoginRequest payload) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'), // The endpoint from your Go backend
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(payload.toJson()),
    );

    if (response.statusCode == 200) {
      print("DEBUG LOGIN RESPONSE: ${response.body}");
      final responseBody = jsonDecode(response.body);
      return res.LoginResponse.fromJson(responseBody);
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to login');
    }
  }

  // --- Your existing register functions below ---

  // ฟังก์ชันสำหรับสมัครสมาชิก Customer
  Future<String> registerCustomer(req.RegisterCustomerPayload payload) async {
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
  Future<String> registerRider(req.RegisterRiderPayload payload) async {
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
  Future<res.LoginResponse> updateProfile({
    required String token,
    required UpdateProfilePayload payload,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/user/profile'), // Endpoint จากฝั่ง Go
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload.toJson()),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      // ✅ ใช้ทั้ง body เลย ไม่ต้องไปหา updatedData
      return res.LoginResponse.fromJson(responseBody);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to update profile');
    }
  }

  // +++ Add this new function to update a Rider's profile +++
  Future<res.LoginResponse> updateRiderProfile({
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
      return res.LoginResponse.fromJson(responseBody['updatedData']);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to update rider profile');
    }
  }

  // **** ฟังก์ชันใหม่สำหรับ "เพิ่ม" ที่อยู่ ****
  Future<List<res.Address>> addAddress({
    required String token,
    required AddressPayload payload,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/user/addresses'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload.toJson()),
    );

    if (response.statusCode == 201) {
      final responseBody = jsonDecode(response.body);
      final List<dynamic> addressList = responseBody['addresses'];
      return addressList.map((json) => res.Address.fromJson(json)).toList();
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to add address');
    }
  }

  // **** ฟังก์ชันใหม่สำหรับ "อัปเดต" ที่อยู่ ****
  Future<List<res.Address>> updateAddress({
    required String token,
    required String addressId,
    required AddressPayload payload,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/user/addresses/$addressId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload.toJson()),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final List<dynamic> addressList = responseBody['addresses'];
      // ตอนนี้ Dart รู้จัก Address.fromJson แล้ว
      return addressList.map((json) => res.Address.fromJson(json)).toList();
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to update address');
    }
  }
}
