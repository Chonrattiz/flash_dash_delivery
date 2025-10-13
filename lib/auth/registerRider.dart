import 'dart:io';
import 'package:flash_dash_delivery/auth/login.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

// --- Imports ที่จำเป็น ---
import '../api/api_service.dart';
import '../api/api_service_image.dart'; // <-- import service สำหรับอัปโหลดรูป
import '../model/request/register_request.dart';

class SignUpRiderScreen extends StatefulWidget {
  const SignUpRiderScreen({super.key});

  @override
  State<SignUpRiderScreen> createState() => _SignUpRiderScreenState();
}

class _SignUpRiderScreenState extends State<SignUpRiderScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  // ++ สร้าง instance ของ ApiServiceImage
  final ImageUploadService _imageUploadService = ImageUploadService();

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _licensePlateController = TextEditingController();

  bool _isLoading = false;

  File? _profileImage;
  File? _vehicleImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _showImageSourceActionSheet(bool isProfile) async {
    Get.bottomSheet(
      SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery, isProfile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.camera, isProfile);
              },
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  Future<void> _pickImage(ImageSource source, bool isProfile) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          if (isProfile) {
            _profileImage = File(pickedFile.path);
          } else {
            _vehicleImage = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: $e');
    }
  }

  // ++ ฟังก์ชัน _registerRider ที่แก้ไขใหม่ทั้งหมด ++
  void _registerRider() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_profileImage == null) {
      Get.snackbar('Error', 'Please select a profile picture.');
      return;
    }

    if (_vehicleImage == null) {
      Get.snackbar('Error', 'Please upload a vehicle photo.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. อัปโหลดรูปภาพทั้งสองไฟล์พร้อมกันโดยใช้ Future.wait
      //    เพื่อความรวดเร็วและประสิทธิภาพ
      final List<String> imageUrls = await Future.wait([
        _imageUploadService.uploadImageToCloudinary(_profileImage!),
        _imageUploadService.uploadImageToCloudinary(_vehicleImage!),
      ]);

      final String profileImageUrl = imageUrls[0];
      final String vehicleImageUrl = imageUrls[1];

      // 2. สร้าง Payload โดยใช้ URL ที่ได้กลับมา
      final userCore = UserCore(
        name: _nameController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
        imageProfile: profileImageUrl, // <-- ใช้ URL จริง
      );

      final riderDetails = RiderDetails(
        imageVehicle: vehicleImageUrl, // <-- ใช้ URL จริง
        vehicleRegistration: _licensePlateController.text,
      );

      final payload = RegisterRiderPayload(
        userCore: userCore,
        riderDetails: riderDetails,
      );

      // 3. ส่งข้อมูลไปลงทะเบียน
      final message = await _apiService.registerRider(payload);

      // 4. แสดงผลเมื่อสำเร็จ
      await Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Get.offAll(() => const LoginPage());
              },
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      // จัดการ Error ที่อาจเกิดขึ้น
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Error'),
          content: Text(e.toString().replaceAll('Exception: ', '')),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Get.back();
              },
            ),
          ],
        ),
      );
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
    // โค้ดส่วน UI ทั้งหมดสามารถใช้ของเดิมได้เลย ไม่ต้องแก้ไข
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFC4DFCE), Color(0xFFDDEBE3), Color(0xFFF6F8F7)],
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
                    child: GestureDetector(
                      onTap: () => _showImageSourceActionSheet(true),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : null,
                            child: _profileImage == null
                                ? const Icon(
                                    Icons.camera_alt,
                                    color: Color(0xFF4CAF50),
                                    size: 40,
                                  )
                                : null,
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_circle,
                              color: Color(0xFF4CAF50),
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildTextField(
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    hintText: 'Phone Number',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter phone number';
                      }
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
                      if (value == null || value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _nameController,
                    icon: Icons.person_outline,
                    hintText: 'Name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _licensePlateController,
                    icon: Icons.pin_outlined,
                    hintText: 'License plate',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter license plate';
                      }
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
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
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
      ),
    );
  }

  Widget _buildVehiclePhotoUpload() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.photo_camera_outlined, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _vehicleImage == null
                  ? 'Vehicle Photo'
                  : _vehicleImage!.path.split('/').last,
              style: TextStyle(
                color: _vehicleImage == null ? Colors.grey : Colors.black,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () {
              _showImageSourceActionSheet(false);
            },
            child: const Text(
              'Upload',
              style: TextStyle(
                color: Color(0xFF69F0AE),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
