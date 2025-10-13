import 'package:firebase_core/firebase_core.dart'; // <-- 1. เพิ่ม import นี้
import 'firebase_options.dart'; // <-- 2. เพิ่ม import นี้

import 'auth/welcome.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// 3. ทำให้ฟังก์ชัน main เป็น 'async'
void main() async {
  // 4. ตรวจสอบให้แน่ใจว่า Flutter พร้อมทำงานก่อน Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // 5. เริ่มต้นการเชื่อมต่อ Firebase โดยใช้ไฟล์ options ที่สร้างไว้
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'FlashDash',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: WelcomePage(), // ถ้า WelcomePage ไม่มี const constructor ให้ลบ const ออก
    );
  }
}
