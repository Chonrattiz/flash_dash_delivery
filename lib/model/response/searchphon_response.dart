import 'login_response.dart'; // เพื่อใช้ Address model ที่มีอยู่แล้ว

class FindUserResponse {
  final String name;
  final List<Address> addresses;

  FindUserResponse({
    required this.name,
    required this.addresses,
  });

  factory FindUserResponse.fromJson(Map<String, dynamic> json) {
    // ดึง list ของที่อยู่ออกมา และป้องกันกรณีที่มันเป็น null หรือไม่ใช่ List
    var addressList = (json['addresses'] is List) ? json['addresses'] as List : [];
    
    // แปลง list นั้นให้เป็น List<Address>
    List<Address> parsedAddresses =
        addressList.map((i) => Address.fromJson(i)).toList();

    return FindUserResponse(
      name: json['name'] ?? 'ไม่พบชื่อผู้ใช้',
      addresses: parsedAddresses,
    );
  }
}

