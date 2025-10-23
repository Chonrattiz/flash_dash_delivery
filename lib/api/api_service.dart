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
import '../model/response/searchphon_response.dart';
import '../model/request/create_delivery_request.dart';
import '../model/response/delivery_list_response.dart';

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

  // +++ ฟังก์ชันสำหรับอัปเดตโปรไฟล์ Rider +++
  Future<res.LoginResponse> updateRiderProfile({
    required String token,
    required UpdateRiderProfilePayload payload,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/rider/profile'), // Endpoint ฝั่ง Go
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload.toJson()),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);

      // ✅ backend ส่งกลับมาเป็น { message, updatedData: { userProfile, roleSpecificData } }
      // เราแปลง updatedData กลับเป็น LoginResponse ได้เลย
      if (responseBody['updatedData'] != null) {
        return res.LoginResponse.fromJson(responseBody['updatedData']);
      } else {
        return res.LoginResponse.fromJson(responseBody);
      }
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
    print("📤 Sending payload (add): ${jsonEncode(payload.toJson())}");
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

      // ✅ Debug: ดูว่า backend ส่งอะไรกลับมา
      print("📦 addAddress response: $responseBody");

      if (responseBody is Map<String, dynamic>) {
        // ถ้า backend ส่งกลับมาเป็น object เดียว
        if (responseBody.containsKey('addresses')) {
          // กรณี backend ส่ง array addresses
          final List<dynamic> addressList = responseBody['addresses'];
          return addressList.map((json) => res.Address.fromJson(json)).toList();
        } else {
          // กรณี backend ส่ง address เดียว
          return [res.Address.fromJson(responseBody)];
        }
      }

      return [];
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
    print("📤 Sending payload (update): ${jsonEncode(payload.toJson())}");
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

  // **** เพิ่มฟังก์ชันใหม่สำหรับ "ค้นหา" ผู้ใช้ ****
  Future<FindUserResponse> findUserByPhone({
    required String token,
    required String phone,
  }) async {
    // สร้าง URL พร้อม Query Parameter (เช่น .../find?phone=098xxxxxxx)
    final uri = Uri.parse(
      '$_baseUrl/api/users/find',
    ).replace(queryParameters: {'phone': phone});

    final response = await http.get(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // ส่ง Token เพื่อยืนยันตัวตน
      },
    );

    if (response.statusCode == 200) {
      // ถ้าค้นหาเจอ, แปลง JSON ที่ได้กลับมาเป็น FindUserResponse
      final responseBody = jsonDecode(response.body);
      return FindUserResponse.fromJson(responseBody);
    } else {
      // ถ้าไม่เจอ (404) หรือเกิดข้อผิดพลาดอื่นๆ
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to find user');
    }
  }

  // +++ ฟังก์ชันใหม่สำหรับดึงลูกค้ทั้งหมด (ที่ไม่ใช่ Rider) +++
  Future<List<FindUserResponse>> getAllCustomers({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/users/customers'), // Endpoint ใหม่
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      // Backend ส่งกลับมาเป็น { "customers": [...] }
      final List<dynamic> customerListJson = responseBody['customers'];

      // แปลง List ของ JSON เป็น List ของ FindUserResponse
      return customerListJson
          .map((json) => FindUserResponse.fromJson(json))
          .toList();
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to fetch customers');
    }
  }

  // **** เพิ่มฟังก์ชันใหม่สำหรับ "สร้าง" การจัดส่ง ****
  Future<String> createDelivery({
    required String token,
    required CreateDeliveryPayload payload,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/deliveries'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload.toJson()),
    );

    if (response.statusCode == 201) {
      // 201 Created
      final responseBody = jsonDecode(response.body);
      return responseBody['message'];
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to create delivery');
    }
  }

  Future<DeliveryListResponse> getDeliveries({required String token}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/user/deliveries'), // Endpoint จากฝั่ง Go
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // ส่ง Token เพื่อยืนยันตัวตน
      },
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      // แปลง JSON ที่ได้กลับมาเป็น DeliveryListResponse
      return DeliveryListResponse.fromJson(responseBody);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to fetch deliveries');
    }
  }

  // +++ ฟังก์ชันใหม่สำหรับ Rider ดึงงานที่รออยู่ +++
  Future<List<Delivery>> getPendingDeliveries({required String token}) async {
    final response = await http.get(
      // Endpoint จากฝั่ง Go ที่คุณสร้างไว้
      Uri.parse('$_baseUrl/api/rider/deliveries/pending'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // ส่ง Token เพื่อยืนยันตัวตน
      },
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);

      // Backend ส่งกลับมาเป็น { "pendingDeliveries": [...] }
      // เราจึงต้องดึงข้อมูลจาก key "pendingDeliveries"
      final List<dynamic> deliveryListJson = responseBody['pendingDeliveries'];

      // แปลง List ของ JSON เป็น List ของ Delivery object
      return deliveryListJson.map((json) => Delivery.fromJson(json)).toList();
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(
        errorBody['error'] ?? 'Failed to fetch pending deliveries',
      );
    }
  }

  // +++ ฟังก์ชันใหม่สำหรับ Rider กดรับงาน +++
  Future<String> acceptDelivery({
    required String token,
    required String deliveryId,
  }) async {
    final response = await http.post(
      // Endpoint ที่เราสร้างและทดสอบบน Postman
      Uri.parse('$_baseUrl/api/rider/deliveries/$deliveryId/accept'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-T',
        'Authorization': 'Bearer $token', // ส่ง Token เพื่อยืนยันตัวตน
      },
      // POST request นี้ไม่ต้องมี body
    );

    if (response.statusCode == 200) {
      // 200 OK: รับงานสำเร็จ
      final responseBody = jsonDecode(response.body);
      return responseBody[
          'message']; // คืนค่าข้อความ "Delivery accepted successfully"
    } else {
      // กรณีเกิด Error (เช่น 409 Conflict เมื่องานถูกรับไปแล้ว)
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to accept delivery');
    }
  }

  /// อัปเดตตำแหน่งล่าสุดของไรเดอร์ไปยังเซิร์ฟเวอร์
  Future<void> updateRiderLocation({
    required String token,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/rider/location'), // Endpoint ที่เราสร้างใน Go
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
      );

      if (response.statusCode != 200) {
        // ถ้าไม่สำเร็จ ให้โยน Error
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to update location');
      }
      // ถ้าสำเร็จ ไม่ต้องทำอะไร
      print('Location updated successfully');
    } catch (e) {
      // พิมพ์ error ออกมาดู แต่ไม่หยุดการทำงานของแอป
      print('Error updating location: $e');
    }
  }

  // +++ ฟังก์ชันใหม่สำหรับยืนยันการรับสินค้า +++
  Future<String> confirmPickup({
    required String token,
    required String deliveryId,
    required String pickupImageURL,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/rider/deliveries/$deliveryId/pickup'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'pickupImageURL': pickupImageURL}),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody['message'];
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to confirm pickup');
    }
  }

  // +++ ฟังก์ชันใหม่สำหรับยืนยันการส่งสินค้า +++
  Future<String> confirmDelivery({
    required String token,
    required String deliveryId,
    required String deliveredImageURL,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/rider/deliveries/$deliveryId/deliver'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'deliveredImageURL': deliveredImageURL}),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody['message'];
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to confirm delivery');
    }
  }

  /// ตรวจสอบงานที่ไรเดอร์ทำค้างอยู่ (สถานะ accepted หรือ picked_up)
  Future<Delivery?> getCurrentDelivery({required String token}) async {
    final response = await http.get(
      Uri.parse(
          '$_baseUrl/api/rider/deliveries/current'), // Endpoint ที่เราออกแบบไว้
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    // 200 OK หมายถึงมีงานค้างอยู่
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      // Backend ควรจะส่งข้อมูล delivery กลับมาทั้ง object
      return Delivery.fromJson(responseBody);
    }
    // 204 หรือ 404 หมายถึงไม่มีงานค้าง
    else if (response.statusCode == 204 || response.statusCode == 404) {
      return null;
    }
    // กรณีอื่นๆ คือ Error
    else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to get current delivery');
    }
  }
}
