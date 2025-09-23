import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const FlashDashApp());
}

class FlashDashApp extends StatelessWidget {
  const FlashDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WelcomePage(),
    );
  }
}

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
              Image.asset('assets/flash_dash_icon.png'), // เพิ่ม path รูปที่ต้องการ
              const SizedBox(height: 40),
              Text(
                'Flash-Dash Delivery',
                style: GoogleFonts.lato(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Choose your role to get started',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // สีปุ่ม
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 100),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  // เส้นทางไปหน้า "Sign up as User"
                },
                child: Text(
                  'Sign up as User',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // สีปุ่ม
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 100),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  // เส้นทางไปหน้า "Sign up as Rider"
                },
                child: Text(
                  'Sign up as Rider',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  // เส้นทางไปหน้า "Log In"
                },
                child: Text(
                  'Log In',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: Colors.green,
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
