import 'package:flash_dash_delivery/model/response/login_response.dart';
import 'package:flash_dash_delivery/user/main_user.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateDeliveryScreen extends StatefulWidget {  
  final LoginResponse loginData;
  const CreateDeliveryScreen({super.key, required this.loginData});


  @override
  State<CreateDeliveryScreen> createState() => _CreateDeliveryScreenState();
}

class _CreateDeliveryScreenState extends State<CreateDeliveryScreen> {
  // ใช้ ValueNotifier เพื่อจัดการว่าที่อยู่ไหนถูกเลือก
  final ValueNotifier<int> _selectedAddressIndex = ValueNotifier<int>(0);

  @override
  void dispose() {
    _selectedAddressIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // ใช้ Gradient เดียวกันกับหน้าอื่นๆ เพื่อความสอดคล้อง
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFC4DFCE), // C4DFCE
            Color(0xFFDDEBE3), // DDEBE3
            Color(0xFFF6F8F7), // F6F8F7
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Get.off(
              () => const MainUserPage(),
              arguments: widget.loginData, // ใช้ข้อมูลที่หน้านี้ได้รับมาส่งกลับไป
              transition: Transition.leftToRight, // เพิ่ม animation ให้เหมือนการ back
            ),
          ),
          title: Text(
            'สร้างการจัดส่งใหม่',
            style: GoogleFonts.prompt(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ส่วน ผู้รับ ---
              _buildSectionTitle('ผู้รับ'),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'ค้นหาด้วยหมายเลขโทรศัพท์',
                  hintStyle: GoogleFonts.prompt(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- ส่วน ที่อยู่จัดส่ง ---
              _buildSectionTitle('ที่อยู่จัดส่ง'),
              const SizedBox(height: 8),
              ValueListenableBuilder<int>(
                valueListenable: _selectedAddressIndex,
                builder: (context, selectedIndex, child) {
                  return Column(
                    children: [
                      _buildAddressCard(
                        title: 'Home',
                        address: '123 Elm Street, Anytown',
                        isSelected: selectedIndex == 0,
                        onTap: () {
                          _selectedAddressIndex.value = 0;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildAddressCard(
                        title: 'Home2',
                        address: '120 LA Street, Boytown',
                        isSelected: selectedIndex == 1,
                        onTap: () {
                          _selectedAddressIndex.value = 1;
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // --- ส่วน รายการ ---
              _buildSectionTitle('รายการ'),
              const SizedBox(height: 8),
              _buildItemField('สินค้าที่ 1'),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  // TODO: Implement logic to add a new item field
                  Get.snackbar('Action', 'Add new item clicked!');
                },
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFFB3E59F),
                      child: Icon(Icons.add, color: Colors.black54, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'เพิ่มรายการใหม่',
                      style: GoogleFonts.prompt(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- ส่วน ถ่ายรูป ---
              _buildSectionTitle('ถ่ายรูปบอกไรเดอร์'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  // TODO: Implement image picking logic
                  Get.snackbar('Action', 'Pick image clicked!');
                },
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.camera_alt_outlined,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- ปุ่มสร้างการจัดส่ง ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement create delivery logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF69F0AE),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'สร้างการจัดส่ง',
                    style: GoogleFonts.prompt(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget สำหรับสร้าง Title ของแต่ละ Section
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.prompt(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // Widget สำหรับสร้างการ์ดที่อยู่
  Widget _buildAddressCard({
    required String title,
    required String address,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: isSelected ? const Color(0xFF4CAF50) : Colors.grey,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.prompt(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.black87 : Colors.grey[700],
                  ),
                ),
                Text(
                  address,
                  style: GoogleFonts.prompt(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Widget สำหรับสร้างช่องกรอก "รายการ"
  Widget _buildItemField(String hint) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.prompt(color: Colors.grey[600]),
        prefixIcon: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
        suffixIcon: const Icon(Icons.calendar_today_outlined, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
