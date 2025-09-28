import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/image_config.dart';
import '../model/response/login_response.dart';

class RiderOrderDetailsScreen extends StatelessWidget {
  const RiderOrderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // รับข้อมูลผู้ใช้ (Rider) ที่ส่งมาจากหน้า Dashboard
    final LoginResponse? loginData = Get.arguments;
    final String username = loginData?.userProfile.name ?? 'Rider';
    final String? imageFilename = loginData?.userProfile.imageProfile;

    final String fullImageUrl =
        (imageFilename != null && imageFilename.isNotEmpty)
        ? "${ImageConfig.imageUrl}/upload/$imageFilename"
        : "";

    return Scaffold(
      backgroundColor: const Color(0xFFFDEBED),
      body: Column(
        children: [
          // ใช้ AppBar ที่มีดีไซน์เหมือนหน้า Dashboard
          _buildCustomAppBar(username: username, imageUrl: fullImageUrl),
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
                'รายละเอียด',
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
              child: _buildDetailsCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Customer Info Header ---
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(
                    "https://picsum.photos/id/237/120/120",
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Davidson Edgar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'โทรศัพท์ 08123456789',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 30),

            // --- Location Details ---
            _buildLocationTimeline(),
            const SizedBox(height: 20),

            // --- Pickup Images ---
            const Text(
              'Pickup image(s)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF77869E),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildPlaceholderImage(),
                const SizedBox(width: 10),
                _buildPlaceholderImage(),
              ],
            ),
            const SizedBox(height: 20),

            // --- Product Details ---
            const Text(
              'รายละเอียดสินค้า',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'เอาวางไว้ตึก 4 ให้หน่อยนะ',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 10),

            // --- View Map Route ---
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: const Text(
                  'View Map Route',
                  style: TextStyle(
                    color: Color(0xFF006970),
                    fontSize: 15,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Accept Job Button ---
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('รับงาน', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  // Widget สำหรับสร้าง Timeline ของสถานที่ (เวอร์ชันแก้ไข)
  Widget _buildLocationTimeline() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stepper UI (Icons and dotted line)
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, color: Colors.red, size: 20),
            ...List.generate(
              5, // จำนวนจุด
              (index) => Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                width: 3,
                height: 3,
                decoration: const BoxDecoration(
                  color: Color(0xFF27B777),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF27B777), width: 1.5),
              ),
              child: const Icon(
                Icons.circle,
                color: Color(0xFF27B777),
                size: 8,
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        // Location text
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pickup Location',
                style: TextStyle(color: Color(0xFF77869E), fontSize: 12),
              ),
              SizedBox(height: 2),
              Text(
                'มหาวิทยาลัยมหาสารคาม',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 24), // Spacing to align with the next icon
              Text(
                'Delivery Location',
                style: TextStyle(color: Color(0xFF77869E), fontSize: 12),
              ),
              SizedBox(height: 2),
              Text(
                'หอพักชายท่าขอนยาง',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget สำหรับรูปภาพ Placeholder
  Widget _buildPlaceholderImage() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 32),
    );
  }

  // AppBar ที่ใช้ร่วมกัน
  Widget _buildCustomAppBar({required String username, String? imageUrl}) {
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
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.black54,
                  ),
                  onPressed: () => Get.back(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(80.0, 0, 0, 0),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
