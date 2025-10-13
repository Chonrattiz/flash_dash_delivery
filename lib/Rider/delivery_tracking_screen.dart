import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:dotted_border/dotted_border.dart';

import '../api/api_service.dart'; // ++ 1. Import ApiService เข้ามา
import '../model/response/delivery_list_response.dart';
import '../model/response/login_response.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  final Delivery delivery;
  final LoginResponse loginData;

  const DeliveryTrackingScreen({
    super.key,
    required this.delivery,
    required this.loginData,
  });

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  final MapController _mapController = MapController();
  final Location _location = Location();
  LatLng? _currentRiderLocation;

  File? _pickedUpImageFile;
  final ImagePicker _picker = ImagePicker();

  bool _isPanelExpanded = false;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // ++ 2. เพิ่มตัวแปรสำหรับส่งตำแหน่ง ++
  final ApiService _apiService = ApiService();
  DateTime? _lastLocationUpdateTime; // ตัวแปรสำหรับหน่วงเวลาการส่ง

  @override
  void initState() {
    super.initState();
    _initializeLocationAndStartSendingUpdates(); // เปลี่ยนชื่อฟังก์ชันให้ชัดเจน
  }

  Future<void> _initializeLocationAndStartSendingUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // --- ส่วนตรวจสอบ Permission เหมือนเดิม ---
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    // --- ส่วนรับและส่งตำแหน่ง (ปรับปรุงใหม่) ---
    _location.onLocationChanged.listen((LocationData currentLocation) {
      if (!mounted) return;

      final newLocation = LatLng(
        currentLocation.latitude!,
        currentLocation.longitude!,
      );

      // 1. อัปเดตตำแหน่งบนแผนที่ของไรเดอร์ทันที
      setState(() {
        _currentRiderLocation = newLocation;
      });
      _mapController.move(newLocation, 16.0);

      // ++ 3. เพิ่ม Logic การส่งตำแหน่งไปที่ Backend ++
      // หน่วงเวลาการส่งทุกๆ 15 วินาที เพื่อไม่ให้ยิง API บ่อยเกินไป
      final now = DateTime.now();
      if (_lastLocationUpdateTime == null ||
          now.difference(_lastLocationUpdateTime!).inSeconds > 15) {
        
        print("Sending location to backend...");
        // เรียกใช้ API เพื่อส่งตำแหน่ง
        _apiService.updateRiderLocation(
          token: widget.loginData.idToken,
          latitude: newLocation.latitude,
          longitude: newLocation.longitude,
        );
        // อัปเดตเวลาที่ส่งล่าสุด
        _lastLocationUpdateTime = now;
      }
    });
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        _pickedUpImageFile = File(pickedFile.path);
      });
    }
  }

  // --- โค้ดส่วน UI ที่เหลือเหมือนเดิมทั้งหมด ไม่มีการแก้ไข ---
  @override
  Widget build(BuildContext context) {
    final LatLng senderLocation = LatLng(
      widget.delivery.senderAddress.coordinates.latitude,
      widget.delivery.senderAddress.coordinates.longitude,
    );
    const double minPanelSize = 0.22;
    const double maxPanelSize = 0.6;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: senderLocation,
              initialZoom: 16.0,
            ),
            children: [
               TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flash_dash_delivery',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 80.0,
                    height: 80.0,
                    point: senderLocation,
                    child: Column(
                      children: [
                        const Icon(Icons.storefront, color: Colors.blue, size: 40),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          color: Colors.blue,
                          child: const Text("Pick Up", style: TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ],
                    ),
                  ),
                  if (_currentRiderLocation != null)
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: _currentRiderLocation!,
                      child: Column(
                        children: [
                          const Icon(Icons.motorcycle, color: Colors.green, size: 40),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            color: Colors.green,
                            child: const Text("Me", style: TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 40,
            left: 16,
            child: SafeArea(
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Get.back(),
                ),
              ),
            ),
          ),
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              final isExpanded = notification.extent > minPanelSize + 0.02;
              if (isExpanded != _isPanelExpanded) {
                setState(() => _isPanelExpanded = isExpanded);
              }
              return true;
            },
            child: DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: minPanelSize,
              minChildSize: minPanelSize,
              maxChildSize: maxPanelSize,
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
                    boxShadow: [BoxShadow(blurRadius: 10.0, color: Colors.black26)],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: _buildPickupPanelContent(maxPanelSize),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupPanelContent(double maxPanelSize) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              if (!_isPanelExpanded) {
                _sheetController.animateTo(
                  maxPanelSize,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.inventory_2, color: Colors.grey, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pickup : ${widget.delivery.senderName}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.delivery.senderAddress.detail,
                        style: const TextStyle(color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isPanelExpanded)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 32),
                const Center(
                  child: Text(
                    "โปรดถ่ายรูปยืนยันการรับสินค้า",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickImage,
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    color: Colors.grey.shade400,
                    strokeWidth: 1,
                    dashPattern: const [6, 3],
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _pickedUpImageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_pickedUpImageFile!, fit: BoxFit.cover),
                            )
                          : const Center(
                              child: Icon(Icons.camera_alt, color: Colors.grey, size: 50),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Logic ยืนยันรับสินค้า
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('รับสินค้า', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}