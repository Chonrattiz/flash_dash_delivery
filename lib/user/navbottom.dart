import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Import ทุกหน้าที่ Navbar จะต้องไป
import '../user/main_user.dart';
import '../user/profile_user.dart'; // ตรวจสอบชื่อไฟล์ให้ถูกต้อง
import '../user/My_Deliveries.dart'; // สร้างไฟล์นี้ถ้ายังไม่มี

// Import Model เพื่อให้รู้จัก LoginResponse
import '../model/response/login_response.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final LoginResponse loginData; // <-- รับข้อมูล LoginResponse เข้ามา

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.loginData, // <-- กำหนดให้ต้องส่งเข้ามา
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  // ฟังก์ชันที่จัดการการเปลี่ยนหน้าเมื่อกดปุ่ม
  void _onItemTapped(int index) {
    // ถ้ากดปุ่มเดิมที่อยู่แล้ว ไม่ต้องทำอะไร
    if (index == widget.selectedIndex) {
      return;
    }

    // ใช้ switch-case เพื่อกำหนดหน้าปลายทาง
    switch (index) {
      case 0: // Home
        // ใช้ Get.off() เพื่อ "แทนที่" หน้าปัจจุบัน ไม่ใช่ซ้อนทับ
        // และส่ง arguments ไปด้วยทุกครั้ง
        Get.off(
          () => const MainUserPage(),
          arguments: widget.loginData,
          transition: Transition.noTransition, // ไม่ต้องมี animation
        );
        break;
      case 1: // My Deliveries
        Get.off(
          () => const DeliveriesScreen(), // สร้างหน้านี้ด้วยนะครับ
          arguments: widget.loginData,
          transition: Transition.noTransition,
        );
        break;
      case 2: // Profile
        Get.off(
          () => const ProfileScreen(),
          arguments: widget.loginData,
          transition: Transition.noTransition,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping_outlined),
          label: 'My Deliveries',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
      currentIndex: widget.selectedIndex,
      selectedItemColor: const Color(0xFF4CAF50),
      unselectedItemColor: Colors.grey,
      onTap: _onItemTapped, // <-- เรียกใช้ฟังก์ชันที่จัดการ Logic ของเรา
      backgroundColor: const Color(0xFFFAF7F5),
      type: BottomNavigationBarType.fixed,
      elevation: 5,
    );
  }
}
