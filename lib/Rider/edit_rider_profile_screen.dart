import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

// Imports for API communication
import '../api/api_service.dart';
import '../api/api_service_image.dart'; // ✅ Import the image service
import '../model/request/update_profile_rider_request.dart';
import '../model/response/login_response.dart';
import '../config/image_config.dart';

class EditRiderProfileScreen extends StatefulWidget {
  // ✅ Reverted to a parameter-less constructor
  const EditRiderProfileScreen({super.key});

  @override
  State<EditRiderProfileScreen> createState() => _EditRiderProfileScreenState();
}

class _EditRiderProfileScreenState extends State<EditRiderProfileScreen> {
  // ✅ Added ApiServiceImage
  final ApiService _apiService = ApiService();
  final ApiServiceImage _apiServiceImage = ApiServiceImage();

  // ✅ Added nullable loginData to hold data from arguments
  LoginResponse? loginData;

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
    // ✅ Reverted to using Get.arguments to fetch initial data
    final arguments = Get.arguments;
    if (arguments is LoginResponse) {
      loginData = arguments;
      final user = loginData!.userProfile;
      final rider = loginData!.roleSpecificData as Rider?;

      _nameController = TextEditingController(text: user.name);
      _phoneController = TextEditingController(text: user.phone);
      _vehicleRegController = TextEditingController(
        text: rider?.vehicleRegistration ?? '',
      );
    } else {
      // Fallback if arguments are not provided correctly
      _nameController = TextEditingController();
      _phoneController = TextEditingController();
      _vehicleRegController = TextEditingController();
      // Navigate back if data is missing
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Get.back();
          Get.snackbar('เกิดข้อผิดพลาด', 'ไม่สามารถโหลดข้อมูลโปรไฟล์ได้');
        }
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

  // ✅ Simplified image picking logic
  Future<void> _pickImage(bool isProfileImage) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1024,
    );
    if (pickedFile != null) {
      setState(() {
        if (isProfileImage) {
          _profileImageFile = File(pickedFile.path);
        } else {
          _vehicleImageFile = File(pickedFile.path);
        }
      });
    }
  }

  // The manual _uploadImage function is no longer needed.

  // ✅ Replaced with the robust logic from the user example
  Future<void> _handleSaveChanges() async {
    Get.back(); // Close Confirmation Dialog
    if (_isLoading) return;

    setState(() => _isLoading = true);
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      // Step 1: Upload images using ApiServiceImage if new files were picked.
      final String? newProfileImageFilename = _profileImageFile != null
          ? await _apiServiceImage.uploadProfileImage(_profileImageFile!)
          : null;
      final String? newVehicleImageFilename = _vehicleImageFile != null
          ? await _apiServiceImage.uploadProfileImage(_vehicleImageFile!)
          : null;

      // ✅ Changed to use the state variable `loginData`
      final user = loginData!.userProfile;
      final rider = loginData!.roleSpecificData as Rider?;

      // Step 2: Create the payload, sending data only if it has changed.
      final payload = UpdateRiderProfilePayload(
        name: _nameController.text != user.name ? _nameController.text : null,
        vehicleRegistration:
            _vehicleRegController.text != rider?.vehicleRegistration
            ? _vehicleRegController.text
            : null,
        imageProfile: newProfileImageFilename,
        imageVehicle: newVehicleImageFilename,
      );

      // Step 3: Check if there's actually anything to update.
      if (payload.name == null &&
          payload.vehicleRegistration == null &&
          payload.imageProfile == null &&
          payload.imageVehicle == null) {
        Get.back(); // Close loading
        Get.snackbar('ไม่มีการเปลี่ยนแปลง', 'คุณยังไม่ได้แก้ไขข้อมูลใดๆ');
        setState(() => _isLoading = false); // Reset loading state on button
        return;
      }

      // Step 4: Call the API service.
      final updatedLoginData = await _apiService.updateRiderProfile(
        // ✅ Changed to use the state variable `loginData`
        token: loginData!.idToken,
        payload: payload,
      );

      Get.back(); // Close Loading Indicator
      await _showSuccessDialog();
      Get.back(result: updatedLoginData); // Go back with new data
    } catch (e) {
      Get.back(); // Close loading
      Get.snackbar(
        'เกิดข้อผิดพลาด',
        e.toString().replaceAll("Exception: ", ""),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Your existing dialogs are great, keeping them.
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
            onPressed:
                _handleSaveChanges, // This now calls the correct function
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

  // --- 🎯 YOUR UI CODE STARTS HERE ---
  // The logic above now correctly powers your existing beautiful UI.
  @override
  Widget build(BuildContext context) {
    // ✅ Added a null check for loginData
    if (loginData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = loginData!.userProfile;
    final rider = loginData!.roleSpecificData as Rider?;

    final String? profileImageFilename = user.imageProfile;
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
                    // ✅ Simplified onTap
                    onTap: () => _pickImage(true),
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
            // ✅ Simplified onTap
            onTap: () => _pickImage(false),
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
