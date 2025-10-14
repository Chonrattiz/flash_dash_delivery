import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// Import services และ models ที่จำเป็น
import '../api/api_service.dart';
import '../model/response/delivery_list_response.dart';
import '../model/response/login_response.dart';
import 'navbottom.dart';
import 'delivery_tracking.dart';
import 'combined_map_view.dart';

class DeliveriesScreen extends StatefulWidget {
  const DeliveriesScreen({super.key});

  @override
  State<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen> {
  // --- 1. Services & State Management ---
  final ApiService _apiService = ApiService();
  LoginResponse? loginData;
  int _selectedTabIndex = 0;

  // State สำหรับเก็บข้อมูลที่ดึงมาจาก API
  bool _isLoading = true;
  String? _error;
  List<Delivery> _sentDeliveries = [];
  List<Delivery> _receivedDeliveries = [];

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments;
    if (arguments is LoginResponse) {
      loginData = arguments;
      // เมื่อได้ loginData แล้ว ให้เริ่มดึงข้อมูลการจัดส่ง
      _fetchDeliveries();
    } else {
      // กรณีฉุกเฉินที่ไม่ได้รับข้อมูลผู้ใช้
      setState(() {
        _isLoading = false;
        _error = "ไม่พบข้อมูลผู้ใช้";
      });
    }
  }

  // --- 2. ฟังก์ชันหลักสำหรับดึงข้อมูลจาก API ---
  Future<void> _fetchDeliveries() async {
    if (loginData == null) return;
    
    // ตั้งค่าสถานะ Loading (สำหรับ Pull-to-Refresh)
    if (!_isLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final response = await _apiService.getDeliveries(token: loginData!.idToken);
      setState(() {
        _sentDeliveries = response.sentDeliveries;
        _receivedDeliveries = response.receivedDeliveries;
        _error = null; // เคลียร์ error เก่า (ถ้ามี)
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // เลือกว่าจะแสดงข้อมูลชุดไหน โดยอิงจาก Tab ที่ถูกเลือก
    final currentList = _selectedTabIndex == 0 ? _sentDeliveries : _receivedDeliveries;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3F3),
      appBar: AppBar(
        title: Text('My Deliveries', style: GoogleFonts.prompt(fontWeight: FontWeight.w600, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),

        floatingActionButton: FloatingActionButton(
        onPressed: () {
          // เมื่อกดปุ่ม ให้เปิดหน้าจอแผนที่รวม
          Get.to(
            // ++ แก้ไขตรงนี้: เพิ่ม selectedTabIndex เข้าไป ++
            () => CombinedMapViewScreen(
              loginData: loginData!,
              sentDeliveries: _sentDeliveries,
              receivedDeliveries: _receivedDeliveries,
              selectedTabIndex: _selectedTabIndex, // <-- ส่งสถานะของ Tab ปัจจุบันไปด้วย
            ),
            transition: Transition.downToUp,
          );
        },
        backgroundColor: const Color(0xFFB3E59F),
        child: const Icon(Icons.map_outlined, color: Colors.black87),
      ),

      body: Column(
        children: [
          _buildToggleButtons(),
          const SizedBox(height: 20),
          Expanded(
            // --- 3. จัดการการแสดงผลตาม State ---
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('เกิดข้อผิดพลาด: $_error', style: GoogleFonts.prompt()))
                    : currentList.isEmpty
                        ? Center(child: Text('ไม่มีรายการ', style: GoogleFonts.prompt(fontSize: 16, color: Colors.grey[600])))
                        : RefreshIndicator(
                            onRefresh: _fetchDeliveries, // <-- เพิ่มความสามารถในการดึงเพื่อรีเฟรช
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: currentList.length,
                              itemBuilder: (context, index) {
                                final item = currentList[index];
                                return _buildDeliveryCard(item);
                              },
                            ),
                          ),
          ),
        ],
      ),
      bottomNavigationBar: loginData != null
          ? CustomBottomNavBar(selectedIndex: 1, loginData: loginData!)
          : null,
    );
  }

  // --- 4. Widget ย่อยๆ ที่มีการแก้ไข ---
  
  // รับ Delivery object เข้ามาทั้งก้อน
 Widget _buildDeliveryCard(Delivery item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: InkWell( // <-- ห่อด้วย InkWell เพื่อให้กดได้
        borderRadius: BorderRadius.circular(16), // ทำให้ ripple effect ขอบมน
        onTap: () {
          // --- เมื่อกด ให้เปิดหน้า Tracking ---
          Get.to(
            () => DeliveryTrackingScreen(
              delivery: item, // ส่งข้อมูล delivery ของรายการที่กด
              loginData: loginData!, // ส่งข้อมูลผู้ใช้ไปด้วย
            ),
            transition: Transition.rightToLeft, // Animation แบบเลื่อนจากขวามาซ้าย
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: Colors.grey[400], size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // ใช้ helper function ใน model เพื่อแสดง Title
                      item.getTitle(loginData!.userProfile.phone),
                      style: GoogleFonts.prompt(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: item.getStatusColor(), // ใช้ helper function ใน model
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.status,
                          style: GoogleFonts.prompt(
                              fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // (Widget _buildToggleButtons, _buildTabButton ไม่มีการแก้ไข)
  Widget _buildToggleButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Expanded(child: _buildTabButton('รายการที่จัดส่ง', 0)),
            Expanded(child: _buildTabButton('รายการที่ต้องรับ', 1)),
          ],
        ),
      ),
    );
  }
  Widget _buildTabButton(String text, int index) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB3E59F) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.prompt(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.black87 : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

