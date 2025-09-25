import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // ไม่จำเป็นต้องใช้แล้ว
import '../model/response/login_response.dart';
import '../config/image_config.dart';
import '../auth/login.dart';

class RiderProfileScreen extends StatefulWidget {
  const RiderProfileScreen({super.key});

  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  int _selectedIndex = 1;
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

  void _onItemTapped(int index) {
    if (index == 0) {
      Get.back();
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  // ++ แก้ไขฟังก์ชัน _signOut() ให้เหมือนกับหน้า ProfileScreen ++
  void _signOut() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Sign Out'), // เปลี่ยน Title
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          // ปุ่มยกเลิก
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          // ปุ่มยืนยัน
          TextButton(
            onPressed: () {
              // ไม่มีการเรียกใช้ Firebase.signOut()
              // กลับไปหน้า Login และล้างหน้าจอเก่าทั้งหมด
              Get.offAll(() => const LoginPage());
            },
            // เปลี่ยน Text และ Style ให้เหมือนกัน
            child: const Text('OK', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editProfilePicture() {
    Get.snackbar(
      'Edit Profile',
      'Functionality to edit profile picture coming soon!',
    );
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

    final String name = user?.name ?? 'N/A';
    final String phone = user?.phone ?? 'N/A';
    final String vehicleRegistration = rider?.vehicleRegistration ?? 'N/A';

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
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: _buildProfileCard(
                name: name,
                phone: phone,
                vehicleRegistration: vehicleRegistration,
                vehicleImageUrl: fullVehicleImageUrl,
              ),
            ),
          ),
          _buildCustomAppBar(),
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
                    backgroundImage: (fullProfileImageUrl.isNotEmpty)
                        ? NetworkImage(fullProfileImageUrl)
                        : null,
                    child: (fullProfileImageUrl.isEmpty)
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                ),
                Positioned(
                  right: -8,
                  bottom: 4,
                  child: GestureDetector(
                    onTap: _editProfilePicture,
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
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF4CAF50),
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildCustomAppBar() {
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
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Flash-Dash\nDelivery',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.exit_to_app, color: Colors.black54),
                label: const Text(
                  'Sign out',
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard({
    required String name,
    required String phone,
    required String vehicleRegistration,
    required String vehicleImageUrl,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 60),
          _buildInfoRow(
            icon: Icons.person_outline,
            title: 'ชื่อ - สกุล',
            value: name,
          ),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            title: 'หมายเลขโทรศัพท์',
            value: phone,
          ),
          _buildInfoRow(
            icon: Icons.directions_car_outlined,
            title: 'เลขทะเบียน',
            value: vehicleRegistration,
          ),
          const SizedBox(height: 20),
          if (vehicleImageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                vehicleImageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.grey,
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey.shade600, size: 28),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200, height: 1),
        ],
      ),
    );
  }
}
