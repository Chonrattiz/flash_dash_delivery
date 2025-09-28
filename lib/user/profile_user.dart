import 'package:flash_dash_delivery/user/edit_profile.dart';
import 'package:flash_dash_delivery/user/map_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// Import model, config, และ Navbar
import '../model/response/login_response.dart';
import '../config/image_config.dart';
import '../auth/login.dart';
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
    final arguments = Get.arguments;
    if (arguments is LoginResponse) {
      setState(() {
        loginData = arguments;
      });
    }
  }

   // --- 1. ฟังก์ชันสำหรับนำทางไปหน้าแก้ไขโปรไฟล์ และรอรับข้อมูลกลับมา ---
  Future<void> _navigateToEditProfile() async {
    if (loginData == null) return;

    // ใช้ await เพื่อ "รอ" ให้หน้า EditProfile ปิดและส่งผลลัพธ์กลับมา
    final result = await Get.to<LoginResponse>(
      () => EditProfileScreen(loginData: loginData!),
      transition: Transition.rightToLeft,
    );

    // ตรวจสอบว่ามีข้อมูลใหม่ (result) ส่งกลับมาหรือไม่
    if (result != null) {
      // ถ้ามี, ให้อัปเดต state ของหน้านี้ด้วยข้อมูลใหม่
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
  
  // --- 2. ฟังก์ชันสำหรับนำทางไปหน้าแผนที่ และรอรับข้อมูลกลับมา ---
  Future<void> _navigateAndHandleAddress({Address? existingAddress}) async {
    if (loginData == null) return;

    final result = await Get.to<AddressResult>(
      () => MapPickerScreen(loginData: loginData!),
      transition: Transition.downToUp,
    );

    if (result != null) {
      // TODO: เรียก API เพื่อเพิ่มหรือแก้ไขที่อยู่ตรงนี้
      // if (existingAddress == null) {
      //   // เรียก API เพิ่มที่อยู่ใหม่
      // } else {
      //   // เรียก API อัปเดตที่อยู่เดิมโดยใช้ existingAddress.id
      // }
      Get.snackbar(
        'สำเร็จ',
        'ที่อยู่ใหม่คือ: ${result.address}',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
      // TODO: หลังจาก API ทำงานสำเร็จ, ให้อัปเดต loginData ด้วยรายการที่อยู่ใหม่ที่ได้จาก Backend
    }
  }

  //ออกจากระบบนะ
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

    // **** UI EDIT 1: ห่อ Scaffold ด้วย Container เพื่อใส่ Gradient ****
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFC4DFCE), // C4DFCE
            Color(0xFFDDEBE3), // DDEBE3
            Color(0xFFF6F8F7), // F6F8F7
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),

      child: Scaffold(
        // **** UI EDIT 2: ทำให้ Scaffold โปร่งใสเพื่อแสดง Gradient ****
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

      // **** 2. เพิ่ม bottomNavigationBar และส่งข้อมูลที่จำเป็นไปให้ ****
      // ถ้ายังไม่มีข้อมูล ไม่ต้องแสดง Navbar
    );
  }

  Widget _buildProfileHeader(UserProfile? user, String imageUrl) {
    // **** UI EDIT 3: ทำให้ Header โปร่งใส และปรับ Padding ให้สวยงาม ****
    return Container(
      padding: const EdgeInsets.only(top: 5, bottom: 24, left: 16, right: 16),
      // ไม่ต้องกำหนดสีพื้นหลัง เพื่อให้เห็น Gradient
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.red,
                    size: 20,
                    fontWeight: FontWeight.w600,
                  ),
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
              backgroundImage: imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl)
                  : null,
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
              onPressed: () {
                Get.off(
                  () => EditProfileScreen(loginData: loginData!),
                  transition: Transition.rightToLeft,
                );
              },
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
                onPressed: () async {
                  final result = await Get.to<AddressResult>(
                    // ส่ง loginData เข้าไปใน Constructor
                    () => MapPickerScreen(loginData: loginData!),
                    transition: Transition.downToUp,
                  );
                },
                child: Text(
                  'เพิ่มที่อยู่',
                  style: GoogleFonts.prompt(
                    fontSize: 16,
                    color: const Color(0xFF247FE2), // สีเขียวเข้มขึ้นเล็กน้อย
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
                  // ส่งฟังก์ชันจัดการที่อยู่เข้าไป (สำหรับแก้ไขที่อยู่เดิม)
                  onEdit: () => _navigateAndHandleAddress(existingAddress: address),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAddressCard({required String title, required String details, required VoidCallback onEdit,}) {
    // **** UI EDIT 4: ทำให้การ์ดที่อยู่โปร่งแสงและมีเส้นขอบ ****
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withOpacity(0.7), // ทำให้การ์ดกึ่งโปร่งใส
      elevation: 0, // ไม่ต้องมีเงา
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withOpacity(0.5),
        ), // เพิ่มเส้นขอบบางๆ
      ),
       child: ListTile(
        title: Text(title, style: GoogleFonts.prompt(fontWeight: FontWeight.w600)),
        subtitle: Text(details, style: GoogleFonts.prompt()),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.grey),
          // **** แก้ไข: เรียกใช้ onEdit ที่ส่งเข้ามา ****
          onPressed: onEdit,
        ),
      ),
    );
  }
}
