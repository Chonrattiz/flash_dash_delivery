import 'package:flash_dash_delivery/user/edit_profile.dart';
import 'package:flash_dash_delivery/user/map_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// Import model, config, และ Navbar
import '../config/image_config.dart';
import '../auth/login.dart';
import 'navbottom.dart';
import '../model/response/login_response.dart';
import '../api/api_service.dart'; // ✅ API Service
import '../model/request/address_request.dart'; // ✅ Payload สำหรับเพิ่ม/แก้ไขที่อยู่

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  LoginResponse? loginData;
  final ApiService _apiService = ApiService(); // ✅ instance API service

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments;
    if (arguments is LoginResponse) {
      setState(() {
        loginData = arguments;
      });
    }
  }

  // --- 1. ฟังก์ชันแก้ไขโปรไฟล์ ---
  Future<void> _navigateToEditProfile() async {
    if (loginData == null) return;

    final result = await Get.to<LoginResponse>(
      () => EditProfileScreen(loginData: loginData!),
      transition: Transition.rightToLeft,
    );

    if (result != null) {
      setState(() {
        loginData = result;
      });
      Get.snackbar(
        'สำเร็จ',
        'ข้อมูลโปรไฟล์ของคุณถูกอัปเดตแล้ว',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  // --- 2. ฟังก์ชันเพิ่ม/แก้ไขที่อยู่ ---
  Future<void> _navigateAndHandleAddress({Address? existingAddress}) async {
  if (loginData == null) return;

  final result = await Get.to(
    () => MapPickerScreen(
      loginData: loginData!,
      existingAddress: existingAddress,
    ),
    transition: Transition.downToUp,
  );

  if (result != null && result is Map<String, dynamic>) {
    final mode = result["mode"];
    final data = result["data"] as AddressResult;
    final oldAddress = result["oldAddress"] as Address?;

    try {
      List<Address> updatedAddresses = [];

      if (mode == "add") {
        updatedAddresses = await _apiService.addAddress(
          token: loginData!.idToken,
          payload: AddressPayload(
            detail: data.address,
            coordinates: CoordinatesPayload(
              latitude: data.coordinates.latitude,
              longitude: data.coordinates.longitude,
            ),
          ),
        );
        Get.snackbar("สำเร็จ", "เพิ่มที่อยู่เรียบร้อยแล้ว",
            backgroundColor: Colors.green, colorText: Colors.white);
      } else if (mode == "edit" && oldAddress != null) {
        updatedAddresses = await _apiService.updateAddress(
          token: loginData!.idToken,
          addressId: oldAddress.id,
          payload: AddressPayload(
            detail: data.address,
            coordinates: CoordinatesPayload(
              latitude: data.coordinates.latitude,
              longitude: data.coordinates.longitude,
            ),
          ),
        );
        Get.snackbar("สำเร็จ", "แก้ไขที่อยู่เรียบร้อยแล้ว",
            backgroundColor: Colors.orange, colorText: Colors.white);
      }

      setState(() {
        loginData = LoginResponse(
          message: loginData!.message,
          idToken: loginData!.idToken,
          userProfile: loginData!.userProfile,
          roleSpecificData: updatedAddresses,
        );
      });
    } catch (e) {
      Get.snackbar("ผิดพลาด", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}



  // --- 3. ฟังก์ชันออกจากระบบ ---
  void _signOut() {
    Get.dialog(
      AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.offAll(() => const LoginPage());
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = loginData?.userProfile;
  final addresses = (loginData?.roleSpecificData is List)
    ? (loginData!.roleSpecificData as List).cast<Address>()
    : <Address>[];
    final String fullImageUrl =
        (user?.imageProfile != null && user!.imageProfile.isNotEmpty)
            ? "${ImageConfig.imageUrl}/upload/${user.imageProfile}"
            : "";

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
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(user, fullImageUrl),
              _buildAddressSection(addresses),
            ],
          ),
        ),
        bottomNavigationBar: loginData != null
            ? CustomBottomNavBar(selectedIndex: 2, loginData: loginData!)
            : null,
      ),
    );
  }

  // --- 4. Header ---
  Widget _buildProfileHeader(UserProfile? user, String imageUrl) {
    return Container(
      padding: const EdgeInsets.only(top: 5, bottom: 24, left: 16, right: 16),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout, color: Colors.red, size: 20),
                  label: Text(
                    'Sign out',
                    style: GoogleFonts.prompt(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'โปรไฟล์ของฉัน',
                  style: GoogleFonts.prompt(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              child: imageUrl.isEmpty
                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              user?.name ?? 'Guest User',
              style: GoogleFonts.prompt(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.phone ?? '-',
              style: GoogleFonts.prompt(fontSize: 20, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _navigateToEditProfile(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
              ),
              child: Text(
                'แก้ไขโปรไฟล์',
                style: GoogleFonts.prompt(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 5. Address Section ---
  Widget _buildAddressSection(List<Address> addresses) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40.0, 5.0, 40.0, 1.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ที่อยู่',
                style: GoogleFonts.prompt(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _navigateAndHandleAddress(),
                child: Text(
                  'เพิ่มที่อยู่',
                  style: GoogleFonts.prompt(
                    fontSize: 16,
                    color: const Color(0xFF247FE2),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (addresses.isEmpty)
            const Text("No addresses found.")
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];
                return _buildAddressCard(
                  title: 'Address ${index + 1}',
                  details: address.detail,
                  onEdit: () => _navigateAndHandleAddress(existingAddress: address),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- 6. Address Card ---
  Widget _buildAddressCard({
    required String title,
    required String details,
    required VoidCallback onEdit,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withOpacity(0.7),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withOpacity(0.5),
        ),
      ),
      child: ListTile(
        title: Text(
          title,
          style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(details, style: GoogleFonts.prompt()),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.grey),
          onPressed: onEdit,
        ),
      ),
    );
  }
}
