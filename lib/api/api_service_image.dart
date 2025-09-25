import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../config/image_config.dart';

class ApiServiceImage {
  final String _imgagebaseUrl = ImageConfig.imageUrl;

  /// Uploads a profile image and returns only the filename.
  Future<String> uploadProfileImage(File imageFile) async {
    final uri = Uri.parse('$_imgagebaseUrl/upload');
    var request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath(
        'file', // Make sure this key matches your backend ('file' or 'image')
        imageFile.path,
      ),
    );

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      if (responseBody['filename'] != null) {
        // **** จุดแก้ไขหลัก ****
        // 1. รับ URL เต็มๆ มาจาก server
        String fullUrl = responseBody['filename'];
        
        // 2. ใช้ Uri.parse เพื่อแยกส่วนประกอบของ URL
        //    แล้วดึงเอา path ส่วนสุดท้าย (ซึ่งก็คือชื่อไฟล์) ออกมา
        String fileName = Uri.parse(fullUrl).pathSegments.last;
        
        // 3. คืนค่ากลับไปเป็นชื่อไฟล์อย่างเดียว
        return fileName; 
      } else {
        throw Exception('API Error: imageUrl not found in response');
      }
    } else {
      throw Exception('Failed to upload image. Status code: ${response.statusCode}');
    }
  }
}