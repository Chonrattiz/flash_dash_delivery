import 'package:flash_dash_delivery/Rider/delivery_tracking_screen.dart';
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

  // --- ฟังก์ชันสำหรับแสดง Dialog เมื่อรับงานสำเร็จ และ Navigate ---
  void _showSuccessAndNavigateDialog(
    Delivery delivery,
    LoginResponse loginData,
  ) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('สำเร็จ!'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 50),
            SizedBox(height: 16),
            Text('คุณรับงานสำเร็จแล้ว'),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              // ใช้ Get.off เพื่อไปยังหน้าใหม่และลบหน้าปัจจุบันออกจาก Stack
              Get.off(
                () => DeliveryTrackingScreen(
                  delivery: delivery,
                  loginData: loginData,
                ),
              );
            },
            child: const Text('ตกลง', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      barrierDismissible: false, // ไม่ให้กดปิดนอก Dialog
    );
  }

  // --- ฟังก์ชันเรียก API ---
  Future<void> _acceptJob(
    String token,
    String deliveryId,
    Delivery delivery,
    LoginResponse loginData,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.acceptDelivery(token: token, deliveryId: deliveryId);

      if (mounted) {
        // ✅ เรียกใช้ Dialog ใหม่แทน Snackbar
        _showSuccessAndNavigateDialog(delivery, loginData);
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

  // --- ✅ แก้ไข Dialog ยืนยันให้มี Content ---
  void _showConfirmationDialog(LoginResponse loginData, Delivery delivery) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('ยืนยันการรับงาน'),
        // ✅ เพิ่มเนื้อหาส่วนนี้เข้าไป
        content: const Text('คุณต้องการรับงานนี้ใช่หรือไม่?'),
        actions: [
          TextButton(child: const Text('ยกเลิก'), onPressed: () => Get.back()),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              foregroundColor: Colors.white,
            ),
            child: const Text('ยืนยัน'),
            onPressed: () {
              Get.back();
              _acceptJob(loginData.idToken, delivery.id, delivery, loginData);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> arguments;

    // ป้องกัน Error กรณี arguments ไม่ใช่ Map
    try {
      arguments = Get.arguments as Map<String, dynamic>;
    } catch (e) {
      return const Scaffold(
        body: Center(child: Text('Error: Invalid arguments passed to screen.')),
      );
    }

    // ใช้ Key ที่ถูกต้องในการดึงข้อมูล
    final LoginResponse? loginData = arguments['loginData'];
    final Delivery? deliveryData = arguments['delivery'];

    final String riderUsername = loginData?.userProfile.name ?? 'Rider';

    // ตรวจสอบว่าข้อมูลที่ได้รับมาเป็น null หรือไม่
    if (deliveryData == null || loginData == null) {
      return const Scaffold(
        body: Center(
          child: Text('Error: Data not found! Check argument keys.'),
        ),
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
    // ดึง URL เต็มๆ มาจาก Model โดยตรง ไม่ต้องต่อ String แล้ว
    final String senderImageUrl = delivery.senderImageProfile;
    final String receiverImageUrl = delivery.receiverImageProfile;
    final String itemImageUrl = delivery.itemImage;
    final String riderNoteImageUrl = delivery.riderNoteImage;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 20),

            // --- "รับงาน" Button ---
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
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

  // --- Helper Widgets ---
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
