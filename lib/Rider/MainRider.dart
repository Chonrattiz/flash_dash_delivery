import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../model/response/login_response.dart';

// --- นี่คือโค้ดของหน้า Rider Dashboard ทั้งหมด ---
class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  // ตัวแปรสำหรับจัดการ Bottom Navigation Bar
    int _selectedIndex = 0;  LoginResponse? loginData;
  @override
  void initState() {
    super.initState();
    // 2. รับข้อมูลจาก arguments ตอนที่หน้าจอนี้ถูกสร้างขึ้นมาครั้งแรก
    // เราใช้ initState() เพราะมันจะทำงานแค่ครั้งเดียวตอนเริ่มต้น
    final arguments = Get.arguments;
    if (arguments is LoginResponse) {
      // ตรวจสอบว่าข้อมูลที่ส่งมาเป็นประเภท LoginResponse จริงๆ
      // จากนั้นเก็บข้อมูลไว้ในตัวแปร loginData
      setState(() {
        loginData = arguments;
      });
    }
  }
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- โค้ดส่วน build() ถูกแก้ไขใหม่ทั้งหมด ---
  @override
  Widget build(BuildContext context) {
       final String username = loginData?.userProfile.name ?? 'Rider'; 
    return Scaffold(
      backgroundColor: Colors.grey[100], // สีพื้นหลังของ body
      // เราจะไม่ใช้ appBar ของ Scaffold แต่จะสร้างทุกอย่างใน Column
      body: Column(
        children: [
          // ส่วนที่ 1: Custom AppBar จะอยู่บนสุด
           _buildCustomAppBar(username: username),

          // ส่วนที่ 2: ป้าย "รายการออเดอร์"
          // เราใช้ Transform.translate เพื่อ "ดึง" วิดเจ็ตนี้ให้ลอยขึ้นไปในแนวตั้ง
          Transform.translate(
            // offset คือระยะที่จะย้ายวิดเจ็ต (แนวนอน, แนวตั้ง)
            // ค่าลบในแนวตั้ง (y) หมายถึงการดึงขึ้น
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

          // ส่วนที่ 3: รายการออเดอร์ที่สามารถเลื่อนได้
          Expanded(
            child: SingleChildScrollView(
              // ปรับ padding ด้านบนเล็กน้อยเพื่อไม่ให้ชิดกับป้ายเกินไป
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

  /// Widget สำหรับสร้าง Custom AppBar (โค้ดเดิม ไม่มีการแก้ไข)
  Widget _buildCustomAppBar({required String username}) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      child: Container(
        height: 186.0, // กำหนดความสูงของ AppBar ให้แน่นอน
        color: const Color(0xFFCEF1C3),
        child: SafeArea(
          bottom: false, // ไม่ใช้ SafeArea ด้านล่างเพราะจะติดกับวิดเจ็ตอื่น
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
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      backgroundImage: NetworkImage(
                        'https://placehold.co/100x100/A0E0A0/000000?text=User',
                      ),
                    ),
                    const SizedBox(height: 8),
                     Text(
                      username,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget สำหรับสร้างการ์ดรายการออเดอร์ (โค้ดเดิม ไม่มีการแก้ไข)
  Widget _buildOrderCard({
    required String pickup,
    required String pickupDetails,
    required String delivery,
  }) {
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
                      const SizedBox(height: 8),
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
