import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

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
  final ApiService _apiService = ApiService();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _vehicleRegController;

  File? _profileImageFile;
  File? _vehicleImageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

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

  Future<void> _pickImage(Function(File) onImagePicked) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // ลดคุณภาพเพื่อลดขนาดไฟล์
      maxWidth: 1024, // จำกัดขนาดความกว้าง
    );
    if (pickedFile != null) {
      setState(() {
        onImagePicked(File(pickedFile.path));
      });
    }
  }

  Future<String?> _uploadImage(File? imageFile) async {
    if (imageFile == null) return null;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ImageConfig.imageUrl}/api/upload'),
    );
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      try {
        final decodedBody = jsonDecode(responseBody);
        if (decodedBody is Map<String, dynamic> &&
            decodedBody.containsKey('filename')) {
          return decodedBody['filename'];
        } else {
          throw Exception('Invalid response format from upload server.');
        }
      } on FormatException {
        throw Exception('Failed to parse upload server response.');
      }
    } else {
      final errorBody = await response.stream.bytesToString();
      throw Exception(
        'Failed to upload image. Status: ${response.statusCode}, Body: $errorBody',
      );
    }
  }

  Future<void> _showSuccessDialog() async {
    await Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('สำเร็จ!'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 50),
            SizedBox(height: 16),
            Text('แก้ไขข้อมูลของคุณเรียบร้อยแล้ว'),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('ตกลง', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showConfirmationDialog() {
    if (_isLoading) return;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('ยืนยันการแก้ไข'),
        content: const Text('คุณต้องการบันทึกการเปลี่ยนแปลงใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: _handleSaveChanges,
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

  // --- 🎯 จุดแก้ไข: ปรับปรุงการสร้าง Payload ให้ชัดเจน ---
  Future<void> _handleSaveChanges() async {
    Get.back(); // ปิด Confirmation Dialog
    setState(() => _isLoading = true);
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      // 1. ตรวจสอบว่ามีข้อมูลส่วนไหนเปลี่ยนแปลงบ้าง
      final bool nameChanged =
          _nameController.text != loginData?.userProfile?.name;
      final bool regChanged =
          _vehicleRegController.text !=
          (loginData?.roleSpecificData as Rider?)?.vehicleRegistration;
      final bool profileImageChanged = _profileImageFile != null;
      final bool vehicleImageChanged = _vehicleImageFile != null;

      if (!nameChanged &&
          !regChanged &&
          !profileImageChanged &&
          !vehicleImageChanged) {
        Get.back(); // ปิด loading
        Get.snackbar('ไม่มีการเปลี่ยนแปลง', 'คุณยังไม่ได้แก้ไขข้อมูลใดๆ');
        return;
      }

      // 2. สร้าง Map ว่างๆ เพื่อรวบรวมเฉพาะข้อมูลที่จะส่งไปอัปเดต
      Map<String, dynamic> updatedFields = {};

      if (nameChanged) {
        updatedFields['name'] = _nameController.text;
      }
      if (regChanged) {
        updatedFields['vehicle_registration'] = _vehicleRegController.text;
      }
      if (profileImageChanged) {
        final newProfileImage = await _uploadImage(_profileImageFile);
        if (newProfileImage != null) {
          updatedFields['image_profile'] = newProfileImage;
        }
      }
      if (vehicleImageChanged) {
        final newVehicleImage = await _uploadImage(_vehicleImageFile);
        if (newVehicleImage != null) {
          updatedFields['image_vehicle'] = newVehicleImage;
        }
      }

      // 3. ตรวจสอบอีกครั้งว่ามีข้อมูลให้อัปเดตจริงหรือไม่ (เผื่ออัปโหลดรูปล้มเหลว)
      if (updatedFields.isEmpty) {
        Get.back(); // ปิด loading
        Get.snackbar(
          'ไม่มีการเปลี่ยนแปลง',
          'คุณไม่ได้แก้ไขข้อมูลใดๆ หรือการอัปโหลดรูปภาพล้มเหลว',
        );
        return;
      }

      // 4. สร้าง Payload object จาก Map ที่มีเฉพาะข้อมูลที่เปลี่ยนแปลง
      final payload = UpdateRiderProfilePayload(
        name: updatedFields['name'],
        imageProfile: updatedFields['image_profile'],
        vehicleRegistration: updatedFields['vehicle_registration'],
        imageVehicle: updatedFields['image_vehicle'],
      );

      // 5. เรียกใช้ API
      final updatedLoginData = await _apiService.updateRiderProfile(
        token: loginData!.idToken,
        payload: payload,
      );

      Get.back(); // ปิด Loading Indicator
      await _showSuccessDialog();
      Get.back(result: updatedLoginData);
    } catch (e, stackTrace) {
      Get.back(); // ปิด loading

      debugPrint("--- ERROR SAVING PROFILE ---");
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      debugPrint("--------------------------");

      String errorMessage = e.toString().replaceAll("Exception: ", "");
      if (e.toString().contains(
        "'Null' is not a subtype of type 'Map<String, dynamic>'",
      )) {
        errorMessage =
            "ข้อมูลที่ได้รับจากเซิร์ฟเวอร์ไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง";
      }

      Get.snackbar(
        'เกิดข้อผิดพลาด',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
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
                    onTap: () => _pickImage((file) => _profileImageFile = file),
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
      padding: const EdgeInsets.fromLTRB(24.0, 60, 24, 24),
      child: Column(
        children: [
          _buildEditableInfoRow(
            controller: _nameController,
            icon: Icons.person_outline,
            title: 'ชื่อ - สกุล',
          ),
          _buildEditableInfoRow(
            controller: _phoneController,
            icon: Icons.phone_outlined,
            title: 'หมายเลขโทรศัพท์ (ไม่สามารถแก้ไขได้)',
            readOnly: true,
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
            onTap: () => _pickImage((file) => _vehicleImageFile = file),
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
