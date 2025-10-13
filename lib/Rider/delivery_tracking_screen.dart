import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:dotted_border/dotted_border.dart';
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

  // ✅ 1. เพิ่มตัวแปรสำหรับควบคุมสถานะของ Panel
  bool _isPanelExpanded = false;
  // ✅ 2. เพิ่ม Controller สำหรับสั่งงาน DraggableSheet
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _location.onLocationChanged.listen((LocationData currentLocation) {
      if (mounted) {
        setState(() {
          _currentRiderLocation = LatLng(
            currentLocation.latitude!,
            currentLocation.longitude!,
          );
        });
        _mapController.move(_currentRiderLocation!, 16.0);
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

  @override
  Widget build(BuildContext context) {
    final LatLng senderLocation = LatLng(
      widget.delivery.senderAddress.coordinates.latitude,
      widget.delivery.senderAddress.coordinates.longitude,
    );

    // กำหนดขนาดของ Panel
    const double minPanelSize = 0.22; // ขนาดตอนหุบ (ปรับให้เล็กลง)
    const double maxPanelSize = 0.6; // ขนาดตอนขยาย

    return Scaffold(
      body: Stack(
        children: [
          // --- 1. แผนที่ ---
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: senderLocation,
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 80.0,
                    height: 80.0,
                    point: senderLocation,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.storefront,
                          color: Colors.blue,
                          size: 40,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          color: Colors.blue,
                          child: const Text(
                            "Pick Up",
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
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
                          const Icon(
                            Icons.motorcycle,
                            color: Colors.green,
                            size: 40,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            color: Colors.green,
                            child: const Text(
                              "Me",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // --- 2. ปุ่ม Back ---
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

          // --- 3. แผงข้อมูลที่เลื่อนได้ (ปรับปรุงใหม่) ---
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
              builder:
                  (BuildContext context, ScrollController scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24.0),
                        ),
                        boxShadow: [
                          BoxShadow(blurRadius: 10.0, color: Colors.black26),
                        ],
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

  // --- Widget สำหรับสร้างเนื้อหาใน Panel ---
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

          // --- ส่วนหัวของ Panel ที่กดได้ ---
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
            // ทำให้ส่วนนี้ไม่มีสีพื้นหลัง เพื่อให้กดได้ทั้ง Row
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: Colors.grey,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pickup : ${widget.delivery.senderName}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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

          // --- ส่วนที่จะแสดงเมื่อ Panel ถูกขยาย ---
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
                              child: Image.file(
                                _pickedUpImageFile!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.grey,
                                size: 50,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- ปุ่มยืนยันรับสินค้า ---
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
                  child: const Text(
                    'รับสินค้า',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
