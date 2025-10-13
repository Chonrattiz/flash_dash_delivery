import 'package:flash_dash_delivery/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/image_config.dart';
import '../model/response/delivery_list_response.dart';
import '../model/response/login_response.dart';

class RiderOrderDetailsScreen extends StatefulWidget {
  const RiderOrderDetailsScreen({super.key});

  @override
  State<RiderOrderDetailsScreen> createState() =>
      _RiderOrderDetailsScreenState();
}

class _RiderOrderDetailsScreenState extends State<RiderOrderDetailsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // ฟังก์ชันเรียก API เพื่อรับงาน
  Future<void> _acceptJob(String token, String deliveryId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // เรียกใช้ API (ส่วนนี้เหมือนเดิม)
      await _apiService.acceptDelivery(token: token, deliveryId: deliveryId);

      if (mounted) {
        // --- 2. ปรับปรุง Snackbar ให้แสดงข้อความตามที่ต้องการ ---
        Get.snackbar(
          'สำเร็จ!',
          'คุณรับงานสำเร็จแล้ว', // เปลี่ยนเป็นข้อความนี้
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.back(result: true);
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'เกิดข้อผิดพลาด',
          e.toString().replaceFirst('Exception: ', ''),
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- 1. เพิ่มฟังก์ชันสำหรับแสดง Dialog ยืนยัน ---
  void _showConfirmationDialog(LoginResponse loginData, Delivery delivery) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('ยืนยันการรับงาน'),
        content: const Text('คุณต้องการรับงานนี้ใช่หรือไม่?'),
        actions: [
          TextButton(
            child: const Text('ยกเลิก'),
            onPressed: () => Get.back(), // กดแล้วปิด Dialog
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              foregroundColor: Colors.white,
            ),
            child: const Text('ยืนยัน'),
            onPressed: () {
              Get.back(); // ปิด Dialog ก่อน
              _acceptJob(loginData.idToken, delivery.id); // แล้วค่อยเรียก API
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> arguments =
        Get.arguments as Map<String, dynamic>;
    final LoginResponse? loginData = arguments['loginData'];
    final Delivery? deliveryData = arguments['delivery'];

    final String riderUsername = loginData?.userProfile.name ?? 'Rider';

    if (deliveryData == null || loginData == null) {
      return const Scaffold(
        body: Center(child: Text('Error: Data not found!')),
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
              child: _buildDetailsCard(
                delivery: deliveryData,
                loginData: loginData,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard({
    required Delivery delivery,
    required LoginResponse loginData,
  }) {
    // ... (ส่วนประกาศตัวแปร senderImageUrl, receiverImageUrl ฯลฯ เหมือนเดิม)
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
            // ... (ส่วนแสดงผลข้อมูลต่างๆ ของ Card เหมือนเดิม)
            // Sender Info
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

            // Location Timeline
            _buildLocationTimeline(
              pickupLocation: delivery.senderAddress.detail,
              deliveryLocation: delivery.receiverAddress.detail,
            ),
            const SizedBox(height: 20),

            // Receiver Info
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
                      delivery.receiverName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'โทรศัพท์ ${delivery.receiverUID}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
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

            // --- 3. แก้ไขปุ่ม "รับงาน" ให้เรียกใช้ Dialog ---
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      // เมื่อกดปุ่ม ให้เรียกฟังก์ชันแสดง Dialog
                      _showConfirmationDialog(loginData, delivery);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    )
                  : const Text('รับงาน', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets (เหมือนเดิมทั้งหมด) ---
  // ... ( _buildLocationTimeline, _buildItemImage, _buildPlaceholderImage, _buildCustomAppBar)
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
