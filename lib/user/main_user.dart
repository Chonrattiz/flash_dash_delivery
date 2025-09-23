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
        appBar: PreferredSize(
        preferredSize: const Size.fromHeight(180.0), // กำหนดความสูงของ AppBar
        child: AppBar(
          backgroundColor: const Color(0xFFDE7676), // สีพื้นหลังของ AppBar
          automaticallyImplyLeading: false, // ไม่แสดงปุ่ม back อัตโนมัติ
          elevation: 0, // ไม่มีเงา
          // ทำให้ AppBar มีขอบมนด้านล่าง
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
          ),
          // ใช้ flexibleSpace เพื่อจัดวางเนื้อหาให้อยู่ตรงกลางได้อย่างยืดหยุ่น
          flexibleSpace: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome Poder !!',
                    style: GoogleFonts.prompt(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Action สำหรับปุ่มสั่งสินค้า
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // *** แก้ path รูป scooter ของคุณที่นี่ ***
                        Image.asset('assets/image/moto.png', height: 35),
                        const SizedBox(width: 10),
                        Text(
                          'ส่งสินค้า',
                          style: GoogleFonts.prompt(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
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
      ),
       // --- Body ที่ถูกแก้ไขใหม่ ---
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // สำคัญ! เพื่อให้ textAlign.center ทำงานได้
            children: [
              Text(
                'Flash-Dash Delivery',
                textAlign: TextAlign.center,
                style: GoogleFonts.jockeyOne(
                  fontSize: 42,
                  color: const Color(0xFF004D40),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '"คลิกเดียว ทันใจ"',
                textAlign: TextAlign.center,
                style: GoogleFonts.prompt(
                  fontSize: 32,
                  color: const Color(0xFFD32F2F),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'พร้อมให้บริการจัดส่งพัสดุของคุณ',
                textAlign: TextAlign.center,
                style: GoogleFonts.prompt(
                  fontSize: 22,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),
              Image.asset(
                'assets/image/mainuser.png',
                height: 250,
              ),
            ],
          ),
        ),
      ),
      // --------------------------

      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        ),
      ),
    );
  }
}