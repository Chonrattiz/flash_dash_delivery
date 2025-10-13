import 'package:flash_dash_delivery/Rider/profile_rider.dart';
import 'package:flash_dash_delivery/Rider/rider_order_details_screen.dart';
import 'package:flash_dash_delivery/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/response/login_response.dart';
import '../config/image_config.dart';
import '../model/response/delivery_list_response.dart'; // 1. Import Delivery model

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  int _selectedIndex = 0;
  LoginResponse? loginData;

  // 2. สร้าง State สำหรับเก็บข้อมูลและสถานะการโหลด
  final ApiService _apiService = ApiService();
  List<Delivery> _pendingDeliveries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments;
    if (arguments is LoginResponse) {
      loginData = arguments;
      // 3. เรียก API เพื่อดึงข้อมูลเมื่อหน้าจอถูกสร้าง
      _fetchPendingDeliveries();
    }
  }

  // 4. สร้างฟังก์ชันสำหรับเรียก API
  Future<void> _fetchPendingDeliveries() async {
    if (loginData == null) return;
    try {
      final deliveries = await _apiService.getPendingDeliveries(
        token: loginData!.idToken
      );
      setState(() {
        _pendingDeliveries = deliveries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Error',
        'Failed to load deliveries: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _navigateToProfile() {
    Get.to(
      () => RiderProfileScreen(),
      arguments: loginData,
      transition: Transition.fadeIn,
    );
  }

  // แก้ไขให้นำทางพร้อมกับส่งข้อมูล delivery ทั้งก้อนไป
  void _navigateToOrderDetails(Delivery delivery) {
    Get.to(
      () => RiderOrderDetailsScreen(),
      arguments: {
        'loginData': loginData,
        'delivery': delivery, // ส่งข้อมูล delivery ที่เลือกไปด้วย
      },
      transition: Transition.fadeIn,
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      _navigateToProfile();
    } else {
      // กลับมาหน้าหลัก ไม่ต้องทำอะไร
    }
  }

  @override
  Widget build(BuildContext context) {
    final String username = loginData?.userProfile.name ?? 'Rider';
    final String? imageFilename = loginData?.userProfile.imageProfile;
  final String fullImageUrl = loginData?.userProfile.imageProfile ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildCustomAppBar(
            username: username,
            imageUrl: fullImageUrl,
            onProfileTap: _navigateToProfile,
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
          // 5. เปลี่ยนส่วนแสดงผล Card ให้เป็นแบบไดนามิก
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _pendingDeliveries.isEmpty
                ? Center(child: Text('ไม่มีงานที่รอการจัดส่ง'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                    itemCount: _pendingDeliveries.length,
                    itemBuilder: (context, index) {
                      final delivery = _pendingDeliveries[index];
                      return _buildOrderCard(delivery: delivery);
                    },
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

  Widget _buildCustomAppBar({
    // ... โค้ดส่วนนี้เหมือนเดิม ...
    required String username,
    String? imageUrl,
    required VoidCallback onProfileTap,
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
                GestureDetector(
                  onTap: onProfileTap,
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

  // 6. อัปเดต Widget ให้รับ Delivery object และจัดการแสดงผลตามที่ต้องการ
  Widget _buildOrderCard({required Delivery delivery}) {
    // --- Logic การตัดคำ ---
    final senderDetailParts = delivery.senderAddress.detail.split(',');
    final pickup = senderDetailParts.isNotEmpty
        ? senderDetailParts.first
        : 'N/A';
    final pickupDetails = senderDetailParts.length > 1
        ? senderDetailParts.sublist(1).join(',').trim()
        : 'N/A';

    final receiverDetailParts = delivery.receiverAddress.detail.split(',');
    final deliveryLocation = receiverDetailParts.isNotEmpty
        ? receiverDetailParts.first
        : 'N/A';

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
                        'Delivery: $deliveryLocation',
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
                onPressed: () =>
                    _navigateToOrderDetails(delivery), // ส่ง delivery ไปด้วย
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
