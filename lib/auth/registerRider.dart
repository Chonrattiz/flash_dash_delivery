import 'package:flutter/material.dart';
import 'package:get/get.dart';

// --- Imports ที่ต้องเพิ่ม/แก้ไข ---
import '../api/api_service.dart';
import '../model/request/register_request.dart';
import '../Rider/mainRider.dart'; // <-- ตรวจสอบว่า Path ไปยัง RiderDashboardScreen ถูกต้อง
// -------------------------

class SignUpRiderScreen extends StatefulWidget {
  const SignUpRiderScreen({super.key});

  @override
  State<SignUpRiderScreen> createState() => _SignUpRiderScreenState();
}

class _SignUpRiderScreenState extends State<SignUpRiderScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _licensePlateController = TextEditingController();

  bool _isLoading = false;

  void _registerRider() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userCore = UserCore(
      name: _nameController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
      imageProfile: "https://example.com/profiles/default.jpg", // ค่าชั่วคราว
    );

    final riderDetails = RiderDetails(
      imageVehicle: "https://example.com/vehicles/default.jpg", // ค่าชั่วคราว
      vehicleRegistration: _licensePlateController.text,
    );

    final payload = RegisterRiderPayload(
      userCore: userCore,
      riderDetails: riderDetails,
    );

    try {
      final message = await _apiService.registerRider(payload);

      // --- ส่วนที่แก้ไข: เปลี่ยนจาก Snackbar เป็น Dialog ---
      // แสดง Dialog แจ้งเตือนเมื่อสำเร็จ
      await Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                // เมื่อกด OK ให้ไปยังหน้า Dashboard และลบหน้าก่อนหน้าทั้งหมด
                Get.offAll(() => const RiderDashboardScreen());
              },
            ),
          ],
        ),
        barrierDismissible: false, // ไม่ให้กดปิด dialog ที่พื้นหลังได้
      );
      // --- จบส่วนแก้ไข ---

    } catch (e) {

      // --- ส่วนที่แก้ไข: เปลี่ยนจาก Snackbar เป็น Dialog ---
      // แสดง Dialog แจ้งเตือนเมื่อเกิด Error
      Get.dialog(
         AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Error'),
          content: Text(e.toString().replaceAll('Exception: ', '')),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                // เมื่อกด Close ให้ปิดแค่ Dialog
                Get.back();
              },
            ),
          ],
        ),
      );
      // --- จบส่วนแก้ไข ---

    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFC4DFCE),
            Color(0xFFDDEBE3),
            Color(0xFFF6F8F7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Get.back();
            },
          ),
          title: const Text(
            'Sign up as Rider',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.camera_alt, color: Color(0xFF4CAF50), size: 40),
                        ),
                        Container(
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.add_circle, color: Color(0xFF4CAF50), size: 28),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildTextField(
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    hintText: 'Phone Number',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter phone number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _passwordController,
                    icon: Icons.lock_outline,
                    hintText: 'Password',
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _nameController,
                    icon: Icons.person_outline,
                    hintText: 'Name',
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your name';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _licensePlateController,
                    icon: Icons.pin_outlined,
                    hintText: 'License plate',
                     validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter license plate';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildVehiclePhotoUpload(),
                  const SizedBox(height: 40),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _registerRider,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF69F0AE),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Sign Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    required String? Function(String?) validator,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }

  Widget _buildVehiclePhotoUpload() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.photo_camera_outlined, color: Colors.grey),
          const SizedBox(width: 16),
          const Expanded(child: Text('vehicle photo', style: TextStyle(color: Colors.grey, fontSize: 16))),
          TextButton(
            onPressed: () {
              // TODO: Implement vehicle photo upload logic
            },
            child: const Text('Upload', style: TextStyle(color: Color(0xFF69F0AE), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

