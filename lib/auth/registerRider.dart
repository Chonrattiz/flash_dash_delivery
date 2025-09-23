import 'package:flash_dash_delivery/Rider/mainRider.dart';
import 'package:flutter/material.dart';
import 'package:flash_dash_delivery/auth/welcome.dart';
import 'package:get/get.dart';

class SignUpRiderScreen extends StatelessWidget {
  const SignUpRiderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ใช้ Container ครอบ Scaffold เพื่อสร้างพื้นหลังแบบ Gradient
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
      child: Scaffold(
        // ทำให้ Scaffold โปร่งใสเพื่อให้มองเห็น Gradient ด้านหลัง
        backgroundColor: Colors.transparent,

        // 1. AppBar
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back), // ใช้ไอคอนที่ต้องการ
            onPressed: () {
              Get.to(() => WelcomePage());
            },
          ),
          title: const Text(
            'Sign up as Rider',
            style: TextStyle(fontWeight: FontWeight.bold), // ทำให้ตัวหนังสือหนา
          ),
          centerTitle: true, // ทำให้ Title อยู่กึ่งกลาง
          // --------------------------
          backgroundColor: Colors.transparent, // AppBar โปร่งใส
          elevation: 0,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // 2. Profile Picture Upload
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor:
                            Colors.white, // เปลี่ยนเป็นสีขาวเพื่อให้เด่นขึ้น
                        child: Icon(
                          Icons.camera_alt,
                          color: Color(0xFF4CAF50),
                          size: 40,
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_circle,
                          color: Color(0xFF4CAF50),
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // 3. Input Fields
                _buildTextField(
                  icon: Icons.phone_outlined,
                  hintText: 'Phone Number',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  icon: Icons.lock_outline,
                  hintText: 'Password',
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(icon: Icons.person_outline, hintText: 'Name'),
                const SizedBox(height: 16),
                _buildTextField(
                  icon: Icons.pin_outlined,
                  hintText: 'License plate',
                ),
                const SizedBox(height: 16),

                // 4. Vehicle Photo Upload
                _buildVehiclePhotoUpload(),
                const SizedBox(height: 40),

                // 5. Sign Up Button
                ElevatedButton(
                  onPressed: () {
                    {
                      Get.to(() => const RiderDashboardScreen());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF69F0AE), // สีปุ่ม
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
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
  Widget _buildTextField({
    required IconData icon,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.white, // เปลี่ยนเป็นสีขาวเพื่อให้ตัดกับ Gradient
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
      ),
    );
  }

  // Helper Widget สำหรับส่วนอัปโหลดรูปรถ
  Widget _buildVehiclePhotoUpload() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white, // เปลี่ยนเป็นสีขาว
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.photo_camera_outlined, color: Colors.grey),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'vehicle photo',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement vehicle photo upload logic
            },
            child: const Text(
              'Upload',
              style: TextStyle(
                color: Color(0xFF69F0AE),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
