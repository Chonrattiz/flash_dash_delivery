import 'dart:io';
import 'package:flash_dash_delivery/user/profile_user.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

// Import model และ config ที่จำเป็น
import '../model/response/login_response.dart';
import '../config/image_config.dart';

class EditProfileScreen extends StatefulWidget {
  final LoginResponse loginData;

  const EditProfileScreen({
    super.key,
    required this.loginData,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;

  File? _newProfileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = widget.loginData.userProfile;
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phone);
    _passwordController = TextEditingController();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _newProfileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: $e');
    }
  }

  // **** 1. ฟังก์ชันแสดง Dialog ยืนยันการแก้ไข ****
  void _showConfirmationDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'คุณแน่ใจที่จะแก้ไขข้อมูล?',
          textAlign: TextAlign.center,
          style: GoogleFonts.prompt(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        contentPadding: const EdgeInsets.only(top: 10, bottom: 20),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          // ปุ่มยกเลิก
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('ยกเลิก', style: GoogleFonts.prompt()),
          ),
          const SizedBox(width: 12),
          // ปุ่มยืนยัน
          ElevatedButton(
            onPressed: () {
              Get.back(); // ปิด dialog ยืนยันก่อน
              // สำหรับ UI เท่านั้น: เรียก dialog สำเร็จเลย
              _showSuccessDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3498DB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('ยืนยัน', style: GoogleFonts.prompt()),
          ),
        ],
      ),
    );
  }

  // **** 2. ฟังก์ชันแสดง Dialog แก้ไขสำเร็จ ****
  void _showSuccessDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            // ** อย่าลืมเพิ่มรูปนี้ใน assets/image/success_hand.png **
            Image.asset(
              'assets/image/Ok Hand.png', 
              height: 100,
            ),
            const SizedBox(height: 20),
            Text(
              'แก้ไขสำเร็จ',
              style: GoogleFonts.prompt(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      barrierDismissible: true,
    ).then((_) {
      // เมื่อ dialog ปิด, กลับไปหน้าโปรไฟล์พร้อมส่งผลลัพธ์
      Get.back(result: true); 
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.loginData.userProfile;
    final String fullImageUrl = (user.imageProfile.isNotEmpty)
        ? "${ImageConfig.imageUrl}/upload/${user.imageProfile}"
        : "";

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE0F2F1), Color(0xFFFCE4EC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black54),
           onPressed: () => Get.off(
              () => const ProfileScreen(),
              arguments: widget.loginData, // ใช้ข้อมูลที่หน้านี้ได้รับมาส่งกลับไป
              transition: Transition.leftToRight, // เพิ่ม animation ให้เหมือนการ back
            ),
          ),
          title: Text(
            'แก้ไขโปรไฟล์',
            style: GoogleFonts.prompt(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // --- รูปโปรไฟล์ ---
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white.withOpacity(0.7),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _newProfileImage != null
                            ? FileImage(_newProfileImage!)
                            : (fullImageUrl.isNotEmpty
                                ? NetworkImage(fullImageUrl)
                                : null) as ImageProvider?,
                        child: fullImageUrl.isEmpty && _newProfileImage == null
                            ? const Icon(Icons.person,
                                size: 50, color: Colors.grey)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFF69F0AE),
                          child: Icon(Icons.camera_alt,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // --- ช่องกรอกข้อมูล ---
              _buildTextField(
                controller: _phoneController,
                label: 'เบอร์โทรศัพท์',
                icon: Icons.phone_outlined,
                enabled: false,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                label: 'รหัสผ่านใหม่ (ถ้าต้องการเปลี่ยน)',
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'ชื่อ-สกุล',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 50),

              // --- ปุ่มยืนยัน ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // **** 3. เปลี่ยน onPressed ให้เรียก Dialog ยืนยัน ****
                  onPressed: _showConfirmationDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3498DB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'ยืนยัน',
                    style: GoogleFonts.prompt(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget สำหรับสร้างช่องกรอกข้อความ
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.prompt(color: Colors.grey[700]),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor:
            enabled ? Colors.white.withOpacity(0.8) : Colors.grey.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

