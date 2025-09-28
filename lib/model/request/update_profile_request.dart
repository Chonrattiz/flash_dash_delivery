// lib/model/request/update_profile_request.dart

class UpdateProfilePayload {
  // ใช้ String? (nullable) เพราะผู้ใช้อาจไม่ได้ต้องการอัปเดตทุก field
  final String? name;
  final String? password;
  final String? imageProfile; // จะเก็บแค่ชื่อไฟล์

  UpdateProfilePayload({
    this.name,
    this.password,
    this.imageProfile,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    // เพิ่มข้อมูลลงใน map เฉพาะ field ที่มีค่า (ไม่ใช่ null)
    if (name != null) {
      data['name'] = name;
    }
    if (password != null) {
      data['password'] = password;
    }
    if (imageProfile != null) {
      data['image_profile'] = imageProfile;
    }
    return data;
  }
}