import 'package:flash_dash_delivery/auth/login.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// --- Imports ที่ต้องเพิ่ม/แก้ไข ---
import '../api/api_service.dart';
import '../model/request/register_request.dart';
import 'dart:io'; //
import 'package:image_picker/image_picker.dart';
import '../api/api_service_image.dart';

// -------------------------

class SignUpUserScreen extends StatefulWidget {
  const SignUpUserScreen({super.key});

  @override
  State<SignUpUserScreen> createState() => _SignUpUserScreenState();
}

class _SignUpUserScreenState extends State<SignUpUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final ApiServiceImage _apiServiceimage =
      ApiServiceImage(); // <-- สร้าง instance สำหรับรูปภาพ
  bool _isLoading = false;

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressDetailController = TextEditingController();

  final MapController _mapController = MapController();
  LatLng? _selectedLocation;

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // **** ฟังก์ชันสำหรับเลือกรูปภาพ (ฉบับแก้ไข) ****
  Future<void> _pickImage() async {
    // เปลี่ยนจาก Get.bottomSheet มาเป็น Get.dialog เพื่อแสดงผลตรงกลาง
    await Get.dialog(
      // ใช้ AlertDialog เป็น Widget หลักสำหรับสร้าง pop-up
      AlertDialog(
        // ทำให้ขอบมนสวยงาม
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        // เพิ่ม title ตามที่ต้องการ
        title: const Text(
          'Profile Picture',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        // เพิ่ม content เพื่ออธิบายเพิ่มเติม
        content: const Text(
          'Please select or take your profile picture.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15),
        ),
        // actions จะแสดงปุ่มต่างๆ แต่เราจะใช้ content ที่ปรับแต่งเองแทน
        // ดังนั้นเราจะใช้ Column ใน content เพื่อวางตัวเลือก
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        // ใช้ Column เพื่อจัดเรียงตัวเลือกในแนวตั้ง
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min, // ทำให้ Column สูงเท่าที่จำเป็น
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // ทำให้ปุ่มกว้างเต็ม
            children: <Widget>[
              // ปุ่มเลือกจากคลังภาพ
              ElevatedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('Photo Library'),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  _getImage(ImageSource.gallery);
                  Get.back(); // ปิด Dialog
                },
              ),
              const SizedBox(height: 8), // ระยะห่างระหว่างปุ่ม
              // ปุ่มถ่ายภาพ
              ElevatedButton.icon(
                icon: const Icon(Icons.photo_camera),
                label: const Text('Camera'),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  _getImage(ImageSource.camera);
                  Get.back(); // ปิด Dialog
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันย่อยสำหรับเรียกใช้ ImagePicker
  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: $e');
    }
  }

  void _registerCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedLocation == null) {
      // ใช้ Dialog แจ้งเตือนแทน Snackbar
      Get.dialog(
        AlertDialog(
          title: const Text('Missing Information'),
          content: const Text(
            'Please select an address on the map before proceeding.',
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    if (_profileImage == null) {
      Get.snackbar('Error', 'Please select a profile image');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 2. อัปโหลดรูปภาพก่อน และรอจนกว่าจะได้ URL กลับมา
      String imageUrl = await _apiServiceimage.uploadProfileImage(
        _profileImage!,
      );

      // 3. สร้าง Payload โดยใช้ imageUrl ที่ได้กลับมา
      final userCore = UserCore(
        name: _nameController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
        imageProfile: imageUrl, // <-- ใช้ URL ที่ได้จากการอัปโหลด
      );

      final address = Address(
        detail: _addressDetailController.text,
        coordinates: Coordinates(
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
        ),
      );

      final payload = RegisterCustomerPayload(
        userCore: userCore,
        address: address,
      );

      // 4. ส่งข้อมูลทั้งหมดไปลงทะเบียน
      final message = await _apiService.registerCustomer(payload);

      // 5. แสดงผลเมื่อสำเร็จ
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
              onPressed: () => Get.offAll(() => const LoginPage()),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      // จัดการ Error ที่อาจเกิดจากการอัปโหลดรูป หรือการลงทะเบียน
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Error'),
          content: Text(e.toString().replaceAll('Exception: ', '')),
          actions: [
            TextButton(child: const Text('Close'), onPressed: () => Get.back()),
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

  /// ฟังก์ชันสำหรับดึงตำแหน่งปัจจุบัน
  Future<void> _getCurrentLocation() async {
    // ... (โค้ดส่วนนี้เหมือนเดิม ไม่ต้องแก้ไข)
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        'Location Disabled',
        'Location services are disabled. Please enable them.',
      );
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar('Permission Denied', 'Location permissions are denied');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      Get.snackbar(
        'Permission Denied',
        'Location permissions are permanently denied.',
      );
      return;
    }
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _mapController.move(_selectedLocation!, 16.0);
      });
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  /// ฟังก์ชันสำหรับจัดการเมื่อมีการแตะบนแผนที่
  void _handleMapTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _selectedLocation = latlng;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _addressDetailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // โค้ดส่วน UI ทั้งหมดเหมือนเดิม ไม่ต้องแก้ไข
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
            onPressed: () => Get.back(),
          ),
          title: const Text(
            'Sign up as User',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: InkWell(
                    // ทำให้ Widget กดได้
                    onTap: _pickImage, // เมื่อกดให้เรียกฟังก์ชันเลือกรูป
                    borderRadius: BorderRadius.circular(50),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          // --- ส่วนสำคัญ: แสดงรูปภาพที่เลือก ---
                          // ถ้ามีรูป (_profileImage != null) ให้แสดงรูปนั้น
                          // ถ้ายังไม่มี ให้แสดง Icon กล้องเหมือนเดิม
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                          child: _profileImage == null
                              ? const Icon(
                                  Icons.camera_alt,
                                  color: Color(0xFF4CAF50),
                                  size: 40,
                                )
                              : null, // ถ้ามีรูปแล้ว ไม่ต้องแสดง child
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
                  validator: (v) => v!.isEmpty ? 'Phone is required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  icon: Icons.lock_outline,
                  hintText: 'Password',
                  obscureText: true,
                  validator: (v) => (v?.length ?? 0) < 6
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nameController,
                  icon: Icons.person_outline,
                  hintText: 'Name',
                  validator: (v) => v!.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _addressDetailController,
                  icon: Icons.home_outlined,
                  hintText: 'Address Detail (e.g. House No., Road)',
                  validator: (v) =>
                      v!.isEmpty ? 'Address detail is required' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: const LatLng(
                          16.47,
                          102.82,
                        ), // Default to Khon Kaen
                        initialZoom: 14.0,
                        onTap: _handleMapTap,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        ),
                        if (_selectedLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedLocation!,
                                width: 80,
                                height: 80,
                                child: const Icon(
                                  Icons.location_pin,
                                  size: 50,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.my_location, color: Colors.white),
                  label: const Text(
                    'Find My Location',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _registerCustomer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF69F0AE),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
}
