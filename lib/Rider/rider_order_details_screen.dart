import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/image_config.dart';
import '../model/response/delivery_list_response.dart';
import '../model/response/login_response.dart';

class RiderOrderDetailsScreen extends StatelessWidget {
  const RiderOrderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // "เปิดกล่อง" (Map) เพื่อหยิบข้อมูลออกมาทีละชิ้น
    final Map<String, dynamic> arguments =
        Get.arguments as Map<String, dynamic>;
    final LoginResponse? loginData = arguments['loginData'];
    final Delivery? deliveryData = arguments['delivery'];

    // ดึงข้อมูล Rider (เหมือนเดิม)
    final String riderUsername = loginData?.userProfile.name ?? 'Rider';

    // ตรวจสอบว่ามีข้อมูล delivery ส่งมาหรือไม่
    if (deliveryData == null) {
      return const Scaffold(
        body: Center(child: Text('Error: Delivery data not found!')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDEBED),
      body: Column(
        children: [
          _buildCustomAppBar(username: riderUsername),
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
              // ส่งข้อมูล delivery ที่ถูกต้องเข้าไปใน Card
              child: _buildDetailsCard(delivery: deliveryData),
            ),
          ),
        ],
      ),
    );
  }

  // Widget สำหรับสร้าง Card แสดงรายละเอียดทั้งหมด
  Widget _buildDetailsCard({required Delivery delivery}) {
    // สร้าง URL รูปภาพเต็มของผู้ส่ง, ผู้รับ, และพัสดุ
    final String senderImageUrl = (delivery.senderImageProfile.isNotEmpty)
        ? "${ImageConfig.imageUrl}/upload/${delivery.senderImageProfile}"
        : "";

    final String receiverImageUrl = (delivery.receiverImageProfile.isNotEmpty)
        ? "${ImageConfig.imageUrl}/upload/${delivery.receiverImageProfile}"
        : "";

    final String itemImageUrl = (delivery.itemImage.isNotEmpty)
        ? "${ImageConfig.imageUrl}/upload/${delivery.itemImage}"
        : "";

    final String riderNoteImageUrl = (delivery.riderNoteImage.isNotEmpty)
        ? "${ImageConfig.imageUrl}/upload/${delivery.riderNoteImage}"
        : "";

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Customer (Sender) Info Header ---
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: senderImageUrl.isNotEmpty
                      ? NetworkImage(senderImageUrl)
                      : null,
                  child: senderImageUrl.isEmpty
                      ? const Icon(Icons.person, size: 30, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      delivery.senderName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'โทรศัพท์ ${delivery.senderUID}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 30),

            // --- Location Details ---
            _buildLocationTimeline(
              pickupLocation: delivery.senderAddress.detail,
              deliveryLocation: delivery.receiverAddress.detail,
            ),
            const SizedBox(height: 20),

            // ++ ส่วนข้อมูลผู้รับที่เพิ่มกลับเข้ามา ++
            const Divider(height: 30),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: receiverImageUrl.isNotEmpty
                      ? NetworkImage(receiverImageUrl)
                      : null,
                  child: receiverImageUrl.isEmpty
                      ? const Icon(Icons.person, size: 30, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      delivery.receiverName, // <-- แสดงชื่อผู้รับ
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'โทรศัพท์ ${delivery.receiverUID}', // <-- แสดงเบอร์ผู้รับ
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
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
                if (itemImageUrl.isNotEmpty)
                  _buildItemImage(imageUrl: itemImageUrl),
                if (itemImageUrl.isNotEmpty && riderNoteImageUrl.isNotEmpty)
                  const SizedBox(width: 10),
                if (riderNoteImageUrl.isNotEmpty)
                  _buildItemImage(imageUrl: riderNoteImageUrl),
              ],
            ),
            const SizedBox(height: 20),

            // --- Product Details ---
            const Text(
              'รายละเอียดสินค้า',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              delivery.itemDescription,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 10),

            // --- View Map Route ---
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  /* TODO: Implement map view */
                },
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
              onPressed: () {
                /* TODO: Implement accept job API call */
              },
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

  // Widget สำหรับสร้าง Timeline ของสถานที่
  Widget _buildLocationTimeline({
    required String pickupLocation,
    required String deliveryLocation,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, color: Colors.red, size: 20),
            ...List.generate(
              5,
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pickup Location',
                style: TextStyle(color: Color(0xFF77869E), fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                pickupLocation,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Delivery Location',
                style: TextStyle(color: Color(0xFF77869E), fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                deliveryLocation,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget สำหรับแสดงรูปภาพพัสดุ
  Widget _buildItemImage({required String imageUrl}) {
    if (imageUrl.isEmpty) {
      return _buildPlaceholderImage();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholderImage();
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      ),
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
                const Padding(
                  padding: EdgeInsets.fromLTRB(80.0, 0, 0, 0),
                  child: Column(
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
