import 'package:flash_dash_delivery/Rider/profile_rider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/response/login_response.dart';
import '../config/image_config.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  int _selectedIndex = 0;
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

  // ++ 1. สร้างฟังก์ชันสำหรับนำทางไปหน้า Profile โดยเฉพาะ ++
  void _navigateToProfile() {
    Get.to(
      () => const RiderProfileScreen(),
      arguments: loginData, // ส่งข้อมูลทั้งหมดไปที่หน้า Profile
      transition: Transition.rightToLeft,
    );
  }

  // ++ 2. แก้ไข _onItemTapped ให้เรียกใช้ฟังก์ชันใหม่ ++
  void _onItemTapped(int index) {
    if (index == 1) {
      // ถ้ากดที่ปุ่ม Profile ให้เรียกฟังก์ชันนำทาง
      _navigateToProfile();
    } else {
      // ถ้ากดปุ่มอื่น ให้แค่เปลี่ยน state ของ index
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String username = loginData?.userProfile.name ?? 'Rider';
    final String? imageFilename = loginData?.userProfile.imageProfile;

    final String fullImageUrl =
        (imageFilename != null && imageFilename.isNotEmpty)
        ? "${ImageConfig.imageUrl}/upload/$imageFilename"
        : "";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // ++ 3. ส่งฟังก์ชัน _navigateToProfile เข้าไปใน AppBar ++
          _buildCustomAppBar(
            username: username,
            imageUrl: fullImageUrl,
            onProfileTap: _navigateToProfile, // <-- ส่งฟังก์ชันเข้าไป
          ),
          Transform.translate(
            offset: const Offset(0.0, -24.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                'รายการออเดอร์',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0FC964),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: Column(
                children: [
                  _buildOrderCard(
                    pickup: 'มหาวิทยาลัยมหาสารคาม',
                    pickupDetails: '123 Main st, thailand',
                    delivery: 'หอพักชาท่าขอนยาง',
                  ),
                  _buildOrderCard(
                    pickup: 'เสริมไทยคอมเพล็กซ์',
                    pickupDetails: '456 Market Rd, thailand',
                    delivery: 'คณะวิทยาการสารสนเทศ',
                  ),
                  _buildOrderCard(
                    pickup: 'ตลาดน้อย',
                    pickupDetails: '789 River St, thailand',
                    delivery: 'โรงพยาบาลสุทธาเวช',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Job'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF4CAF50),
        onTap: _onItemTapped,
      ),
    );
  }

  // ++ 4. แก้ไข AppBar ให้รับฟังก์ชัน onProfileTap และเพิ่ม GestureDetector ++
  Widget _buildCustomAppBar({
    required String username,
    String? imageUrl,
    required VoidCallback onProfileTap, // <-- รับฟังก์ชันเข้ามา
  }) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      child: Container(
        height: 186.0,
        color: const Color(0xFFCEF1C3),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Flash-Dash',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Delivery',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                  ],
                ),
                // หุ้ม Column ที่มีรูปและชื่อด้วย GestureDetector
                GestureDetector(
                  onTap:
                      onProfileTap, // <-- เมื่อกด ให้เรียกฟังก์ชันที่ส่งเข้ามา
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        child: (imageUrl == null || imageUrl.isEmpty)
                            ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey,
                              )
                            : null,
                        backgroundImage:
                            (imageUrl != null && imageUrl.isNotEmpty)
                            ? NetworkImage(imageUrl)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard({
    required String pickup,
    required String pickupDetails,
    required String delivery,
  }) {
    // โค้ดส่วนนี้ไม่มีการแก้ไข
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFF4CAF50),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pickup : $pickup',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pickupDetails,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Delivery: $delivery',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0FC964),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 80,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'รายละเอียด',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
