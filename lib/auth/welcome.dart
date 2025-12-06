import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:flash_dash_delivery/auth/registerRider.dart';
import 'package:flash_dash_delivery/auth/resisterUser.dart';
import 'package:flash_dash_delivery/auth/login.dart';

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ดึงขนาดของหน้าจอมาเก็บไว้ในตัวแปร เพื่อนำไปคำนวณสัดส่วน
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFC4DFCE),
              Color(0xFFDDEBE3),
              Color(0xFFF6F8F7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        // 1. ทำให้หน้าจอเลื่อนได้ ป้องกันการ Overflow Error ในจอที่เล็กมากๆ
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight),
            child: Padding(
              // 2. ปรับ Padding ให้เป็นสัดส่วนกับความกว้างจอ
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 3. กำหนดขนาดรูปภาพให้เป็นสัดส่วนกับความกว้างจอ
                  Image.asset(
                    'assets/image/logowelcome.png',
                    width: screenWidth * 0.5, // ให้รูปกว้าง 50% ของจอ
                  ),
                  SizedBox(height: screenHeight * 0.04), // 4% ของความสูงจอ
                  Text(
                    'Flash-Dash Delivery',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jockeyOne(
                      // 4. ปรับขนาดฟอนต์ให้เป็นสัดส่วนกับความกว้างจอ
                      fontSize: screenWidth * 0.1, // 10% ของความกว้างจอ
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02), // 2% ของความสูงจอ
                  Text(
                    'Choose your role to get started',
                    style: GoogleFonts.inter(
                      fontSize: screenWidth * 0.04, // 4% ของความกว้างจอ
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05), // 5% ของความสูงจอ

                  // 5. ทำให้ปุ่มมีความกว้างเต็มพื้นที่ (แต่มี padding คุมอยู่)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF38E07B),
                        padding:
                            EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Get.to(() => const SignUpUserScreen());
                      },
                      child: Text(
                        'Sign up as User',
                        style: GoogleFonts.prompt(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w700,
                          color: const Color.fromARGB(255, 20, 20, 20),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFCFF3DE),
                        padding:
                            EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Get.to(() => const SignUpRiderScreen());
                      },
                      child: Text(
                        'Sign up as Rider',
                        style: GoogleFonts.prompt(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w700,
                          color: const Color.fromARGB(255, 20, 20, 20),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  TextButton(
                    onPressed: () {
                      Get.to(() => const LoginPage());
                    },
                    child: Text(
                      'Log In',
                      style: GoogleFonts.prompt(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF42E283),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
