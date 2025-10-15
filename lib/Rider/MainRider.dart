import 'package:flash_dash_delivery/Rider/delivery_tracking_screen.dart';
import 'package:flash_dash_delivery/Rider/profile_rider.dart';
import 'package:flash_dash_delivery/Rider/rider_order_details_screen.dart';
import 'package:flash_dash_delivery/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/response/login_response.dart';
import '../model/response/delivery_list_response.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  int _selectedIndex = 0;
  LoginResponse? loginData;

  final ApiService _apiService = ApiService();
  List<Delivery> _pendingDeliveries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments;
    if (arguments is LoginResponse) {
      loginData = arguments;
      _checkAndNavigateToActiveDelivery();
    } else {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar('Error', 'ไม่พบข้อมูลผู้ใช้งาน');
    }
  }

  Future<void> _checkAndNavigateToActiveDelivery() async {
    if (loginData == null) return;
    try {
      final Delivery? activeDelivery = await _apiService.getCurrentDelivery(
        token: loginData!.idToken,
      );
      if (activeDelivery != null && mounted) {
        print(
            "พบงานที่กำลังทำอยู่! (${activeDelivery.id}), กำลังนำทางไปที่หน้า Tracking...");
        Get.offAll(
          () => DeliveryTrackingScreen(
            delivery: activeDelivery,
            loginData: loginData!,
          ),
        );
      } else {
        print("ไม่พบงานที่กำลังทำอยู่, กำลังโหลดรายการงานใหม่...");
        _fetchPendingDeliveries();
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการตรวจสอบงานที่ค้างอยู่: $e");
      Get.snackbar(
        'Error',
        'ไม่สามารถตรวจสอบสถานะงานล่าสุดได้: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      _fetchPendingDeliveries();
    }
  }

  // +++ 1. ปรับฟังก์ชันนี้เล็กน้อยให้ return Future<void> เพื่อใช้กับ onRefresh +++
  Future<void> _fetchPendingDeliveries() async {
    if (loginData == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // เมื่อมีการรีเฟรช เราไม่จำเป็นต้องแสดง Loading Indicator เต็มจอ
    // ดังนั้นเราจะเช็คว่าถ้าไม่ใช่การโหลดครั้งแรก ก็ไม่ต้อง set _isLoading เป็น true
    // แต่ RefreshIndicator จะแสดงวงกลมหมุนๆ ของมันเอง
    try {
      final deliveries =
          await _apiService.getPendingDeliveries(token: loginData!.idToken);
      if (mounted) {
        setState(() {
          _pendingDeliveries = deliveries;
          _isLoading = false; // ปิด loading indicator เมื่อโหลดเสร็จ
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Get.snackbar(
          'Error',
          'ไม่สามารถโหลดรายการออเดอร์ได้: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  void _navigateToProfile() {
    Get.to(
      () => RiderProfileScreen(),
      arguments: loginData,
      transition: Transition.fadeIn,
    );
  }

  void _navigateToOrderDetails(Delivery delivery) {
    Get.to(
      () => RiderOrderDetailsScreen(),
      arguments: {
        'loginData': loginData,
        'delivery': delivery,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final String username = loginData?.userProfile.name ?? 'Rider';
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
          Expanded(
            // +++ 2. แก้ไขส่วน Expanded ให้ใช้ RefreshIndicator +++
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    // onRefresh ต้องการฟังก์ชันที่เป็น Future<void>
                    // ซึ่งเราได้ปรับ _fetchPendingDeliveries ไว้แล้ว
                    onRefresh: _fetchPendingDeliveries,
                    child: _pendingDeliveries.isEmpty
                        ? Stack(
                            // ใช้ Stack เพื่อให้ Text('ไม่มีงาน...') สามารถถูกดึงเพื่อรีเฟรชได้
                            children: [
                              ListView(), // ListView ว่างๆ เพื่อให้ RefreshIndicator ทำงานได้
                              const Center(
                                  child: Text('ไม่มีงานที่รอการจัดส่ง')),
                            ],
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                            itemCount: _pendingDeliveries.length,
                            itemBuilder: (context, index) {
                              final delivery = _pendingDeliveries[index];
                              return _buildOrderCard(delivery: delivery);
                            },
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

  // โค้ดส่วนที่เหลือ (_buildCustomAppBar และ _buildOrderCard) เหมือนเดิมทุกประการ
  // ...
  Widget _buildCustomAppBar({
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
                        backgroundImage:
                            (imageUrl != null && imageUrl.isNotEmpty)
                                ? NetworkImage(imageUrl)
                                : null,
                        child: (imageUrl == null || imageUrl.isEmpty)
                            ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey,
                              )
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

  Widget _buildOrderCard({required Delivery delivery}) {
    final senderDetailParts = delivery.senderAddress.detail.split(',');
    final pickup =
        senderDetailParts.isNotEmpty ? senderDetailParts.first : 'N/A';
    final pickupDetails = senderDetailParts.length > 1
        ? senderDetailParts.sublist(1).join(',').trim()
        : 'N/A';

    final receiverDetailParts = delivery.receiverAddress.detail.split(',');
    final deliveryLocation =
        receiverDetailParts.isNotEmpty ? receiverDetailParts.first : 'N/A';

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
                onPressed: () => _navigateToOrderDetails(delivery),
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
