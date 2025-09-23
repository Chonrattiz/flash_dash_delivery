import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flash_dash_delivery/auth/registerRider.dart';
import 'package:flash_dash_delivery/auth/resisterUser.dart';
import 'package:get/get.dart';
import 'package:flash_dash_delivery/auth/welcome.dart';
import 'package:flash_dash_delivery/user/main_user.dart';


class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. ใช้ Container เป็น Widget ตัวนอกสุดเพื่อกำหนดพื้นหลัง Gradient
    return Container(
      decoration: BoxDecoration(
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
        backgroundColor: Colors.transparent, // << สำคัญ: ทำให้ Scaffold โปร่งใส
        // 3. นำ AppBar กลับมา และทำให้โปร่งใสเช่นกัน
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back), // ใช้ไอคอนที่ต้องการ
            onPressed: () {
              // การใช้ Get.to จะเป็นการเปิดหน้า WelcomePage ใหม่ซ้อนขึ้นมา
              // หากต้องการย้อนกลับไปหน้าที่แล้วจริงๆ ควรใช้ Get.back();
              Get.to(() =>  WelcomePage());
            },
          ),
          backgroundColor: Colors.transparent, // << สำคัญ: ทำให้ AppBar โปร่งใส
          elevation: 0, // ลบเงาใต้ AppBar
          foregroundColor:
              Colors.black, // กำหนดสีของไอคอนและตัวหนังสือใน AppBar
          title: Text(
            'Login',
            style: GoogleFonts.prompt(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
        ),

        // Body ของหน้า Login เหมือนเดิมทุกอย่าง
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // *** ใส่ path รูปของคุณที่นี่ ***
                Align(
                  alignment: Alignment.centerRight,
                  child: Image.asset(
                    'assets/image/login.png', // <--- แก้เป็น path รูปของคุณ
                    height: 250,
                  ),
                ),
                const SizedBox(height: 20),

                // ช่องใส่เบอร์โทรศัพท์
                _buildTextField(hintText: 'Phone Number'),
                const SizedBox(height: 16),

                // ช่องใส่รหัสผ่าน
                _buildTextField(hintText: 'Password', obscureText: true),
                const SizedBox(height: 40),

                // ปุ่ม Login
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38E07B),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () { 
                     Get.to(() =>  MainUserPage());
                  },
                  child: Text(
                    'Login',
                    style: GoogleFonts.prompt(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // ข้อความ "Don't have an account?"
                Text(
                  "Don't have an account?",
                  style: GoogleFonts.prompt(
                    fontSize: 17,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),

                // ปุ่ม Register
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRegisterButton(
                      text: 'Register as User',
                      onPressed: () => Get.to(() => const SignUpUserScreen()),
                    ),
                    _buildRegisterButton(
                      text: 'Register as Rider',
                      onPressed: () => Get.to(() => const SignUpRiderScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widget สำหรับสร้างช่องกรอกข้อมูล
  Widget _buildTextField({required String hintText, bool obscureText = false}) {
    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.prompt(color: Colors.black54),
        filled: true,
        fillColor: const Color(0xFFCBF9DD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none, // ไม่มีเส้นขอบ
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
      ),
    );
  }

  // Widget สำหรับสร้างปุ่ม Register เพื่อลดการเขียนโค้ดซ้ำ
  Widget _buildRegisterButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 177, 236, 203),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 0,
      ),
      onPressed: onPressed, // <-- ใช้ onPressed ที่รับเข้ามา
      child: Text(text, style: GoogleFonts.prompt(fontWeight: FontWeight.w600)),
    );
  }
}
