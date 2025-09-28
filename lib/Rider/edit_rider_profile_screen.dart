import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

// Imports for API communication

import '../api/api_service.dart';
import '../model/request/update_profile_rider_request.dart';
import '../model/response/login_response.dart';

import '../config/image_config.dart';

class EditRiderProfileScreen extends StatefulWidget {
  const EditRiderProfileScreen({super.key});

  @override
  State<EditRiderProfileScreen> createState() => _EditRiderProfileScreenState();
}

class _EditRiderProfileScreenState extends State<EditRiderProfileScreen> {
  LoginResponse? loginData;
  final ApiService _apiService = ApiService(); // Instantiate ApiService

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _vehicleRegController;

  File? _profileImageFile;
  File? _vehicleImageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false; // State for loading indicator

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments;
    if (arguments is LoginResponse) {
      loginData = arguments;
      final user = loginData?.userProfile;
      final rider = (loginData?.roleSpecificData is Rider)
          ? (loginData!.roleSpecificData as Rider)
          : null;

      _nameController = TextEditingController(text: user?.name ?? '');
      _phoneController = TextEditingController(text: user?.phone ?? '');
      _vehicleRegController = TextEditingController(
        text: rider?.vehicleRegistration ?? '',
      );
    } else {
      _nameController = TextEditingController();
      _phoneController = TextEditingController();
      _vehicleRegController = TextEditingController();
    }
  }

  Future<void> _pickProfileImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _profileImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickVehicleImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _vehicleImageFile = File(pickedFile.path);
      });
    }
  }

  // --- This is a placeholder function ---
  // In a real app, this would upload the file to a server (like Firebase Storage)
  // and return the downloadable URL or filename.
  Future<String?> _uploadImage(File? imageFile) async {
    if (imageFile == null) return null;
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    // Return a fake filename for demonstration
    return "uploads/new_image_${DateTime.now().millisecondsSinceEpoch}.jpg";
  }

  void _showConfirmationDialog() {
    if (_isLoading) return; // Prevent multiple clicks

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('ยืนยันการแก้ไข'),
        content: const Text('คุณต้องการบันทึกการเปลี่ยนแปลงใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: _handleSaveChanges, // Call the save logic
            child: const Text(
              'ยืนยัน',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSaveChanges() async {
    // Close the confirmation dialog first
    Get.back();

    setState(() {
      _isLoading = true;
    });

    // Show loading indicator
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      // --- จุดแก้ไข: ตรวจสอบว่าข้อมูลแต่ละส่วนมีการเปลี่ยนแปลงจริงหรือไม่ ---
      final bool nameChanged =
          _nameController.text != loginData?.userProfile?.name;
      final bool regChanged =
          _vehicleRegController.text !=
          (loginData?.roleSpecificData as Rider?)?.vehicleRegistration;
      final bool profileImageChanged = _profileImageFile != null;
      final bool vehicleImageChanged = _vehicleImageFile != null;

      // ถ้าไม่มีอะไรเปลี่ยนแปลงเลย ให้แจ้งผู้ใช้และหยุดการทำงาน
      if (!nameChanged &&
          !regChanged &&
          !profileImageChanged &&
          !vehicleImageChanged) {
        Get.back(); // ปิด loading
        Get.snackbar('ไม่มีการเปลี่ยนแปลง', 'คุณยังไม่ได้แก้ไขข้อมูลใดๆ');
        return; // ออกจากฟังก์ชัน
      }

      // อัปโหลดรูปภาพเฉพาะเมื่อมีการเลือกรูปใหม่เท่านั้น
      final String? newProfileImage = profileImageChanged
          ? await _uploadImage(_profileImageFile)
          : null;
      final String? newVehicleImage = vehicleImageChanged
          ? await _uploadImage(_vehicleImageFile)
          : null;

      // เตรียม payload โดยใส่เฉพาะข้อมูลที่มีการเปลี่ยนแปลง
      final payload = UpdateRiderProfilePayload(
        name: nameChanged ? _nameController.text : null,
        imageProfile: newProfileImage,
        vehicleRegistration: regChanged ? _vehicleRegController.text : null,
        imageVehicle: newVehicleImage,
        // You can add a password field here if needed
      );

      // เรียก API
      final updatedLoginData = await _apiService.updateRiderProfile(
        token: loginData!.idToken,
        payload: payload,
      );

      // ปิด loading
      Get.back();

      Get.snackbar(
        'สำเร็จ',
        'ข้อมูลโปรไฟล์ถูกบันทึกแล้ว',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // กลับไปหน้าโปรไฟล์พร้อมส่งข้อมูลใหม่กลับไป
      Get.back(result: updatedLoginData);
    } catch (e) {
      // ปิด loading
      Get.back();
      Get.snackbar(
        'เกิดข้อผิดพลาด',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleRegController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = loginData?.userProfile;
    final rider = (loginData?.roleSpecificData is Rider)
        ? (loginData!.roleSpecificData as Rider)
        : null;

    final String? profileImageFilename = user?.imageProfile;
    final String? vehicleImageFilename = rider?.imageVehicle;

    final String fullProfileImageUrl =
        (profileImageFilename != null && profileImageFilename.isNotEmpty)
        ? "${ImageConfig.imageUrl}/upload/$profileImageFilename"
        : "";

    final String fullVehicleImageUrl =
        (vehicleImageFilename != null && vehicleImageFilename.isNotEmpty)
        ? "${ImageConfig.imageUrl}/upload/$vehicleImageFilename"
        : "";

    return Scaffold(
      backgroundColor: const Color(0xFFFDEBED),
      body: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 130.0),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: _buildEditForm(fullVehicleImageUrl),
            ),
          ),
          _buildEditAppBar(),
          Positioned(
            top: 130 - 50,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _profileImageFile != null
                        ? FileImage(_profileImageFile!) as ImageProvider
                        : (fullProfileImageUrl.isNotEmpty
                              ? NetworkImage(fullProfileImageUrl)
                              : null),
                    child:
                        (_profileImageFile == null &&
                            fullProfileImageUrl.isEmpty)
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                ),
                Positioned(
                  right: -8,
                  bottom: 4,
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 20,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Job'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: 1,
        selectedItemColor: const Color(0xFF4CAF50),
        onTap: (index) {
          if (index == 0) Get.back();
        },
      ),
    );
  }

  Widget _buildEditAppBar() {
    return Container(
      height: 184,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFCEF1C3),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.black87,
                ),
                onPressed: () => Get.back(),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 12.0),
                child: Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditForm(String vehicleImageUrl) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 60),
          _buildEditableInfoRow(
            controller: _nameController,
            icon: Icons.person_outline,
            title: 'ชื่อ - สกุล',
          ),
          _buildEditableInfoRow(
            controller: _phoneController,
            icon: Icons.phone_outlined,
            title: 'หมายเลขโทรศัพท์ (ไม่สามารถแก้ไขได้)', // Note: Phone is UID
            readOnly: true, // Make phone number read-only
          ),
          _buildEditableInfoRow(
            controller: _vehicleRegController,
            icon: Icons.directions_car_outlined,
            title: 'เลขทะเบียน',
          ),
          const SizedBox(height: 20),
          const Text(
            "รูปรถยนต์",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickVehicleImage,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                image: _vehicleImageFile != null
                    ? DecorationImage(
                        image: FileImage(_vehicleImageFile!),
                        fit: BoxFit.cover,
                      )
                    : (vehicleImageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(vehicleImageUrl),
                              fit: BoxFit.cover,
                            )
                          : null),
              ),
              child: (_vehicleImageFile == null && vehicleImageUrl.isEmpty)
                  ? const Center(
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.grey,
                        size: 50,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _isLoading ? null : _showConfirmationDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              disabledBackgroundColor: Colors.grey,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'ยืนยันการแก้ไข',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEditableInfoRow({
    required TextEditingController controller,
    required IconData icon,
    required String title,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: title,
          labelStyle: TextStyle(color: readOnly ? Colors.grey : null),
          prefixIcon: Icon(icon, color: Colors.grey.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4CAF50)),
          ),
        ),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: readOnly ? Colors.grey.shade700 : null,
        ),
      ),
    );
  }
}
