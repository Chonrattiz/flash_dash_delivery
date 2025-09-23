import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:flash_dash_delivery/auth/registerRider.dart';
import 'package:flash_dash_delivery/auth/resisterUser.dart'; 
import 'package:flash_dash_delivery/auth/login.dart';

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
         width: double.infinity,
        height: double.infinity,
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/image/logowelcome.png'), 
              const SizedBox(height: 40),
              Text(
                'Flash-Dash Delivery',
                style: GoogleFonts.jockeyOne(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Choose your role to get started',
                style: GoogleFonts.inter(
                  fontSize: 20,
                   fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF38E07B), // สีปุ่ม
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 90),
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
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color.fromARGB(255, 20, 20, 20),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFCFF3DE), // สีปุ่ม
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 80),
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
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color.fromARGB(255, 20, 20, 20),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Get.to(() => const Login());
                },
                child: Text(
                  'Log In',
                  style: GoogleFonts.prompt(
                    fontSize: 24, 
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF42E283),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
