import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// Import model และ Navbar
import '../model/response/login_response.dart';
import 'navbottom.dart';

// สร้าง Model จำลองสำหรับข้อมูลพัสดุแต่ละชิ้น
class DeliveryItem {
  final String title;
  final String status;
  final Color statusColor;

  DeliveryItem({
    required this.title,
    required this.status,
    required this.statusColor,
  });
}

class DeliveriesScreen extends StatefulWidget {
  const DeliveriesScreen({super.key});

  @override
  State<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen> {
  LoginResponse? loginData;
  int _selectedTabIndex = 0; // 0 = รายการที่จัดส่ง, 1 = รายการที่ต้องรับ

  // --- ข้อมูลจำลอง ---
  final List<DeliveryItem> _itemsToSend = [
    DeliveryItem(title: 'Package To Pear', status: 'Waiting for Rider', statusColor: Colors.orange),
    DeliveryItem(title: 'Package To Momo', status: 'Rider Accepted', statusColor: Colors.blue),
    DeliveryItem(title: 'Package To Bam', status: 'Rider Picked Up', statusColor: Colors.purple),
    DeliveryItem(title: 'Package To Poder', status: 'Delivered', statusColor: Colors.green),
  ];

  final List<DeliveryItem> _itemsToReceive = [
    DeliveryItem(title: 'Package From Pear', status: 'Waiting for Rider', statusColor: Colors.orange),
    DeliveryItem(title: 'Package From Momo', status: 'Rider Accepted', statusColor: Colors.blue),
    DeliveryItem(title: 'Package From Bam', status: 'Rider Picked Up', statusColor: Colors.purple),
    DeliveryItem(title: 'Package From Poder', status: 'Delivered', statusColor: Colors.green),
  ];
  // --------------------

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

  @override
  Widget build(BuildContext context) {
    // เลือกว่าจะแสดงข้อมูลชุดไหน โดยอิงจาก Tab ที่ถูกเลือก
    final currentList = _selectedTabIndex == 0 ? _itemsToSend : _itemsToReceive;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3F3), // สีพื้นหลังตามดีไซน์
      appBar: AppBar(
        title: Text(
          'My Deliveries',
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _buildToggleButtons(),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: currentList.length,
              itemBuilder: (context, index) {
                final item = currentList[index];
                return _buildDeliveryCard(
                  title: item.title,
                  status: item.status,
                  statusColor: item.statusColor,
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: loginData != null
          ? CustomBottomNavBar(
              selectedIndex: 1, // 1 คือ index ของหน้า My Deliveries
              loginData: loginData!,
            )
          : null,
    );
  }

  // Widget สำหรับสร้างปุ่มสลับ Tab
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
            Expanded(
              child: _buildTabButton('รายการที่จัดส่ง', 0),
            ),
            Expanded(
              child: _buildTabButton('รายการที่ต้องรับ', 1),
            ),
          ],
        ),
      ),
    );
  }

  // Widget สำหรับสร้างปุ่มแต่ละอันใน ToggleButtons
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

  // Widget สำหรับสร้างการ์ดแสดงข้อมูลพัสดุ
  Widget _buildDeliveryCard({
    required String title,
    required String status,
    required Color statusColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            // Icon
            Icon(Icons.inventory_2_outlined, color: Colors.grey[400], size: 36),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.prompt(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: GoogleFonts.prompt(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}
