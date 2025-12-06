import 'package:flash_dash_delivery/Rider/MainRider.dart';
import 'package:flash_dash_delivery/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import 'package:flash_dash_delivery/auth/registerRider.dart';
import 'package:flash_dash_delivery/auth/resisterUser.dart';
import 'package:flash_dash_delivery/auth/welcome.dart';
import 'package:flash_dash_delivery/user/main_user.dart';

// Import our service and models
import '../model/request/login_request.dart';
import '../model/response/login_response.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers to get text from TextFields
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();

  // State variable to show a loading indicator
  bool _isLoading = false;

  @override
  void dispose() {
    // Clean up the controllers when the widget is removed
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // The main login logic
  Future<void> _login() async {
    // Basic validation
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter phone number and password');
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      final request = LoginRequest(
        phone: _phoneController.text,
        password: _passwordController.text,
      );

      final LoginResponse response = await _apiService.login(request);

      // 1. Check the role from the response
      final userRole = response.userProfile.role;

      print('Login successful for user: ${response.userProfile.name}');
      print('Role: $userRole');

      // 2. Navigate based on the role and pass the entire 'response' object
      if (userRole == 'customer') {
        Get.offAll(() => const MainUserPage(), arguments: response);
      } else if (userRole == 'rider') {
        Get.offAll(() => const RiderDashboardScreen(), arguments: response);
      } else {
        // Handle cases where role is unknown or not supported
        Get.snackbar(
          'Login Error',
          'Unsupported user role: $userRole',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      // Show error message if login fails
      Get.snackbar(
        'Login Failed',
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ), // Clean up the error message
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      // This will always run, whether login succeeds or fails
      if (mounted) {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ดึงขนาดของหน้าจอมาใช้งาน
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFC4DFCE), Color(0xFFDDEBE3), Color(0xFFF6F8F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // ใช้ Get.back() จะดีกว่า เพราะเป็นการย้อนกลับไปหน้าก่อนหน้าจริงๆ
              Get.back();
            },
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
          title: Text(
            'Login',
            style: GoogleFonts.prompt(
              // ปรับขนาดฟอนต์ตามความกว้างจอ
              fontSize: screenWidth * 0.07,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            // ปรับ Padding ด้านข้างให้เป็นสัดส่วน
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ปรับขนาดรูปภาพตามความสูงจอ
                Image.asset('assets/image/login.png',
                    height: screenHeight * 0.25),
                SizedBox(height: screenHeight * 0.02),

                _buildTextField(
                  controller: _phoneController,
                  hintText: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  // ส่งขนาดจอเข้าไปเพื่อคำนวณสัดส่วน
                  context: context,
                ),
                SizedBox(height: screenHeight * 0.02),

                _buildTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: true,
                  context: context,
                ),
                SizedBox(height: screenHeight * 0.05),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38E07B),
                      // ปรับ Padding ภายในปุ่มให้เป็นสัดส่วน
                      padding:
                          EdgeInsets.symmetric(vertical: screenHeight * 0.018),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Login',
                            style: GoogleFonts.prompt(
                              fontSize: screenWidth * 0.055,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),

                Text(
                  "Don't have an account?",
                  style: GoogleFonts.prompt(
                    fontSize: screenWidth * 0.04,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),

                // Register buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildRegisterButton(
                        text: 'Register as User',
                        onPressed: () => Get.to(() => const SignUpUserScreen()),
                        context: context,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.04), // ระยะห่างระหว่างปุ่ม
                    Expanded(
                      child: _buildRegisterButton(
                        text: 'Register as Rider',
                        onPressed: () =>
                            Get.to(() => const SignUpRiderScreen()),
                        context: context,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context, // รับ context เข้ามา
    TextEditingController? controller,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    // ดึงขนาดจอมาใช้ที่นี่ด้วย
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.prompt(color: Colors.black54),
        filled: true,
        fillColor: const Color(0xFFCBF9DD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        // ปรับ contentPadding ให้เป็นสัดส่วน
        contentPadding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.02,
          horizontal: screenWidth * 0.05,
        ),
      ),
    );
  }

  Widget _buildRegisterButton({
    required BuildContext context, // รับ context เข้ามา
    required String text,
    required VoidCallback onPressed,
  }) {
    // ดึงขนาดจอมาใช้ที่นี่ด้วย
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 177, 236, 203),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        // ปรับ padding ให้เป็นสัดส่วน
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.02, vertical: screenHeight * 0.015),
        elevation: 0,
      ),
      onPressed: onPressed,
      child: Text(
        text,
        textAlign: TextAlign.center, // ทำให้ข้อความอยู่กลางปุ่มเสมอ
        style: GoogleFonts.prompt(
          fontWeight: FontWeight.w600,
          fontSize: screenWidth * 0.035, // ปรับขนาดฟอนต์ให้พอดี
        ),
      ),
    );
  }
}
