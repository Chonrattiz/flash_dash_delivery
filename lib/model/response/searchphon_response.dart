import 'login_response.dart'; // เพื่อใช้ Address model ที่มีอยู่แล้ว

class FindUserResponse {
  final String name;
  final String phone;         // ++ เพิ่มเข้ามา
  final String imageProfile;  // ++ เพิ่มเข้ามา
  final String role;          // ++ เพิ่มเข้ามา
  final List<Address> addresses;

  FindUserResponse({
    required this.name,
    required this.phone,        // ++ เพิ่มเข้ามา
    required this.imageProfile, // ++ เพิ่มเข้ามา
    required this.role,         // ++ เพิ่มเข้ามา
    required this.addresses,
  });

  factory FindUserResponse.fromJson(Map<String, dynamic> json) {
    var addressList = (json['addresses'] is List) ? json['addresses'] as List : [];
    List<Address> parsedAddresses =
        addressList.map((i) => Address.fromJson(i)).toList();

    return FindUserResponse(
      name: json['name'] ?? 'ไม่พบชื่อผู้ใช้',
      phone: json['phone'] ?? '',                   // ++ เพิ่มเข้ามา
      imageProfile: json['image_profile'] ?? '',     // ++ เพิ่มเข้ามา (key คือ image_profile)
      role: json['role'] ?? '',                     // ++ เพิ่มเข้ามา
      addresses: parsedAddresses,
    );
  }
}