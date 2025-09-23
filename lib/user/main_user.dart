import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'navbottom.dart'; // ตรวจสอบว่า path ไปยังไฟล์ navbottom ถูกต้อง

class MainUserPage extends StatefulWidget {
  const MainUserPage({super.key});

  @override
  State<MainUserPage> createState() => _MainUserPageState();
}

class _MainUserPageState extends State<MainUserPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. ใช้ Container เป็น Widget ตัวนอกสุดเพื่อกำหนดพื้นหลัง Gradient
    return Container(
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
      // 2. ใช้ Scaffold ที่มีพื้นหลังโปร่งใส
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Home',
            style: GoogleFonts.prompt(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent, // ทำให้ AppBar โปร่งใส
          elevation: 0,
          automaticallyImplyLeading: false,
        ),

        // 3. Body มีแค่การ์ดข้อมูลหลักอย่างเดียว
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildInfoCard(), // การ์ดข้อมูลหลัก
          ),
        ),

        // 4. เรียกใช้ CustomBottomNavBar เหมือนเดิม
        bottomNavigationBar: CustomBottomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }

  /// Widget สำหรับสร้างการ์ดข้อมูลตรงกลาง (ยังคงเดิม)
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
        // เพิ่มเงาเล็กน้อยเพื่อให้การ์ดลอยขึ้นมา
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Flash-Dash Delivery',
            textAlign: TextAlign.center,
            style: GoogleFonts.jockeyOne(
              fontSize: 32,
              color: const Color(0xFF004D40),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"คลิกเดียว ทันใจ"',
            textAlign: TextAlign.center,
            style: GoogleFonts.prompt(
              fontSize: 22,
              color: const Color(0xFFD32F2F),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'พร้อมให้บริการจัดส่งพัสดุของคุณ',
            textAlign: TextAlign.center,
            style: GoogleFonts.prompt(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          // *** แก้ path รูป delivery หลักของคุณที่นี่ ***
          Image.asset(
            'assets/image/mainuser.png',
            height: 200,
          ),
        ],
      ),
    );
  }
}
