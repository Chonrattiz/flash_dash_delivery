import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

// Import services และ models ทั้งหมดที่จำเป็น
import '../api/api_service.dart';
import '../api/api_service_image.dart';
import '../model/request/update_profile_request.dart';
import '../model/response/login_response.dart';
import '../config/image_config.dart';

class EditProfileScreen extends StatefulWidget {
  final LoginResponse loginData;
  const EditProfileScreen({super.key, required this.loginData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Services
  final ApiService _apiService = ApiService();
  final ApiServiceImage _apiServiceImage = ApiServiceImage();

  // Controllers & State
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  File? _newProfileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = widget.loginData.userProfile;
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phone);
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- 1. ฟังก์ชันหลักสำหรับจัดการการอัปเดตทั้งหมด ---
  Future<void> _handleUpdateProfile() async {
    // ป้องกันการกดซ้ำซ้อน
    if (_isLoading) return;
    
    setState(() => _isLoading = true);

    try {
      String? updatedImageFilename;

      // 1A. ตรวจสอบว่ามีการเลือกรูปใหม่หรือไม่ ถ้ามี ให้อัปโหลด
      if (_newProfileImage != null) {
        updatedImageFilename = await _apiServiceImage.uploadProfileImage(_newProfileImage!);
      }

      // 1B. สร้าง Payload สำหรับส่งไปอัปเดตข้อมูล
      final payload = UpdateProfilePayload(
        // ส่งค่าไปก็ต่อเมื่อมีการเปลี่ยนแปลงจากเดิม หรือเป็นรหัสผ่านใหม่
        name: _nameController.text != widget.loginData.userProfile.name ? _nameController.text : null,
        password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
        imageProfile: updatedImageFilename,
      );
      
      // 1C. ตรวจสอบว่ามีข้อมูลให้อัปเดตหรือไม่
      if (payload.name == null && payload.password == null && payload.imageProfile == null) {
          Get.back(); // ปิด dialog ยืนยัน
          Get.snackbar('ไม่มีการเปลี่ยนแปลง', 'คุณยังไม่ได้แก้ไขข้อมูลใดๆ');
          setState(() => _isLoading = false);
          return;
      }

      // 1D. เรียก API เพื่ออัปเดตโปรไฟล์
      final updatedLoginData = await _apiService.updateProfile(
        token: widget.loginData.idToken,
        payload: payload,
      );

      Get.back(); // ปิด Dialog ยืนยัน
      _showSuccessDialog(updatedLoginData); // แสดง Dialog สำเร็จและส่งข้อมูลใหม่ไป

    } catch (e) {
      Get.back(); // ปิด Dialog ยืนยัน
      Get.snackbar('เกิดข้อผิดพลาด', e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  // --- 2. Dialogs และ Image Picker ---
  void _showConfirmationDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('ยืนยันการแก้ไข', textAlign: TextAlign.center, style: GoogleFonts.prompt(fontWeight: FontWeight.w600)),
        content: Text('คุณแน่ใจที่จะแก้ไขข้อมูล?', textAlign: TextAlign.center, style: GoogleFonts.prompt()),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('ยกเลิก', style: GoogleFonts.prompt(color: Colors.grey[700]))),
          const SizedBox(width: 12),
          // ใช้ StatefulBuilder เพื่อให้ปุ่มอัปเดตตัวเองเมื่อ isLoading เปลี่ยน
          StatefulBuilder(
            builder: (context, setDialogState) {
              return ElevatedButton(
                onPressed: _isLoading ? null : () {
                  // อัปเดต UI ของ dialog ให้แสดง loading
                  setDialogState(() {}); 
                  _handleUpdateProfile();
                },
                child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                    : Text('ยืนยัน', style: GoogleFonts.prompt()),
              );
            },
          ),
        ],
      ),
       barrierDismissible: !_isLoading, // ป้องกันการกดออกขณะโหลด
    );
  }

  void _showSuccessDialog(LoginResponse updatedData) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Image.asset('assets/image/Ok Hand.png', height: 100),
            const SizedBox(height: 20),
            Text('แก้ไขสำเร็จ', style: GoogleFonts.prompt(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
          ],
        ),
      ),
      barrierDismissible: true,
    ).then((_) {
      // เมื่อ dialog ปิด, กลับไปหน้าโปรไฟล์พร้อมส่ง "ข้อมูลที่อัปเดตแล้ว" กลับไป
      Get.back(result: updatedData);
    });
  }
  
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _newProfileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: $e');
    }
  }


  // --- 3. UI Code ---
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
            onPressed: () => Get.back(), // ใช้ Get.back() ธรรมดา
          ),
          title: Text('แก้ไขโปรไฟล์', style: GoogleFonts.prompt(color: Colors.black87, fontWeight: FontWeight.w600)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
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
                            : (fullImageUrl.isNotEmpty ? NetworkImage(fullImageUrl) : null) as ImageProvider?,
                        child: fullImageUrl.isEmpty && _newProfileImage == null
                            ? const Icon(Icons.person, size: 50, color: Colors.grey)
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
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showConfirmationDialog, // เรียก Dialog ยืนยัน
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3498DB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('ยืนยัน', style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
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
        fillColor: enabled ? Colors.white.withOpacity(0.8) : Colors.grey.withOpacity(0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
    );
  }
}

