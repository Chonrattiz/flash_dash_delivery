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
              Get.to(() => WelcomePage());
            },
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
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
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Image.asset('assets/image/login.png', height: 250),
                ),
                const SizedBox(height: 20),

                // Phone number field with controller
                _buildTextField(
                  controller: _phoneController,
                  hintText: 'Phone Number',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // Password field with controller
                _buildTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
                const SizedBox(height: 40),

                // Login Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38E07B),
                    minimumSize: const Size(double.infinity, 56),
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
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(height: 40),

                Text(
                  "Don't have an account?",
                  style: GoogleFonts.prompt(
                    fontSize: 17,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),

                // Register buttons
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

  Widget _buildTextField({
    TextEditingController? controller, // Make controller nullable for reuse
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller, // Assign the controller here
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
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
      ),
    );
  }

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
      onPressed: onPressed,
      child: Text(text, style: GoogleFonts.prompt(fontWeight: FontWeight.w600)),
    );
  }
}
