import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// Import model และ config ที่จำเป็น
import '../model/response/login_response.dart';
import '../config/image_config.dart';
import '../auth/login.dart'; // สำหรับ Sign out

// **** 1. Import CustomBottomNavBar ของคุณเข้ามา ****
import 'navbottom.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  LoginResponse? loginData;

  @override
  void initState() {
    super.initState();
    // รับข้อมูล LoginResponse ที่ส่งมาจากหน้า Login หรือหน้าอื่นๆ
    final arguments = Get.arguments;
    if (arguments is LoginResponse) {
      setState(() {
        loginData = arguments;
      });
    }
  }

  // ฟังก์ชันสำหรับ Sign Out
  void _signOut() {
    Get.dialog(
      AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
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

    final String fullImageUrl = (user?.imageProfile != null && user!.imageProfile.isNotEmpty)
        ? "${ImageConfig.imageUrl}/upload/${user.imageProfile}"
        : "";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(user, fullImageUrl),
            _buildAddressSection(addresses),
          ],
        ),
      ),
      // **** 2. เพิ่ม bottomNavigationBar และส่งข้อมูลที่จำเป็นไปให้ ****
      bottomNavigationBar: loginData != null
          ? CustomBottomNavBar(
              selectedIndex: 2, // 2 คือ index ของหน้า Profile
              loginData: loginData!, // ส่งข้อมูลที่หน้านี้ได้รับมา ให้ Navbar จัดการต่อ
            )
          : null, // ถ้ายังไม่มีข้อมูล ไม่ต้องแสดง Navbar
    );
  }

  // ... โค้ดส่วนที่เหลือของ Widget _buildProfileHeader และ _buildAddressSection เหมือนเดิม ...
  Widget _buildProfileHeader(UserProfile? user, String imageUrl) {
    return Container(
      padding: const EdgeInsets.only(top: 40, bottom: 24),
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E9), // สีเขียวอ่อน
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 80), // Spacer
                  Text(
                    'โปรไฟล์ของฉัน',
                    style: GoogleFonts.prompt(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout, color: Colors.red, size: 20),
                    label: Text(
                      'Sign out',
                      style: GoogleFonts.prompt(color: Colors.red),
                    ),
                  ),
                ],
              ),
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
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.phone ?? '-',
              style: GoogleFonts.prompt(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Get.snackbar('Coming Soon', 'Edit Profile page is not yet implemented.');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
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

  Widget _buildAddressSection(List<Address> addresses) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ที่อยู่',
                style: GoogleFonts.prompt(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Get.snackbar('Coming Soon', 'Add Address page is not yet implemented.');
                },
                child: Text(
                  'เพิ่มที่อยู่',
                  style: GoogleFonts.prompt(
                    color: const Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAddressCard({required String title, required String details}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: ListTile(
        title: Text(title, style: GoogleFonts.prompt(fontWeight: FontWeight.w600)),
        subtitle: Text(details, style: GoogleFonts.prompt()),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.grey),
          onPressed: () {
            Get.snackbar('Coming Soon', 'Edit Address for "$title" is not yet implemented.');
          },
        ),
      ),
    );
  }
}
