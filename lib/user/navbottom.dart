import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  // 1. ประกาศตัวแปรเพื่อรับค่าจากข้างนอก
  final int selectedIndex;
  final Function(int) onItemTapped;

  // 2. กำหนดให้ต้องส่งค่าเหล่านี้เข้ามาตอนสร้าง Widget
  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    // 3. ใช้ค่าที่รับเข้ามาในการแสดงผล
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
      currentIndex: selectedIndex, // <-- ใช้ค่าที่รับมา
      selectedItemColor: const Color(0xFF4CAF50),
      unselectedItemColor: Colors.grey,
      onTap: onItemTapped, // <-- ใช้ฟังก์ชันที่รับมา
      backgroundColor: const Color(0xFFFAF7F5),
      type: BottomNavigationBarType.fixed,
      elevation: 5,
    );
  }
}
