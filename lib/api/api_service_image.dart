import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../config/image_config.dart';
import '../model/request/register_request.dart';
// Note: You may need to adjust the path '../' based on your folder structure.

class ApiServiceImage {
  // Use the correct variable name from your config file
  final String _baseUrl = ImageConfig.imageUrl; 

  // Function for user registration
  Future<String> registerCustomer(RegisterCustomerPayload payload) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register/customer'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload.toJson()),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body)['message'];
    } else {
      throw Exception(json.decode(response.body)['error'] ?? 'Unknown registration error');
    }
  }

  // Function for uploading a profile image
  Future<String> uploadProfileImage(File imageFile) async {
    // The endpoint should be specific for uploads, e.g., '/upload'
    final uri = Uri.parse('$_baseUrl/upload'); 

    var request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath(
        'image', // This 'key' must match the one your backend expects
        imageFile.path,
      ),
    );

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      if (responseBody['imageUrl'] != null) {
        return responseBody['imageUrl'];
      } else {
        throw Exception('API Error: imageUrl not found in response');
      }
    } else {
      throw Exception('Failed to upload image. Status code: ${response.statusCode}');
    }
  }
  
  // You can add other functions like login here as well
}

