import 'dart:io';

import 'package:flash_dash_delivery/Rider/MainRider.dart';
import 'package:flash_dash_delivery/api/api_service_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:dotted_border/dotted_border.dart';

import '../api/api_service.dart';
import '../model/response/delivery_list_response.dart';
import '../model/response/login_response.dart';

enum TrackingStatus { pickingUp, delivering }

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
  // --- ตัวแปรสำหรับ UI และ Map ---
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  bool _isPanelExpanded = false;

  // --- ตัวแปรสำหรับ Location ---
  final Location _location = Location();
  LatLng? _currentRiderLocation;
  DateTime? _lastLocationUpdateTime;

  // --- ตัวแปรสำหรับ Image ---
  final ImagePicker _picker = ImagePicker();
  File? _pickedUpImageFile;
  File? _deliveredImageFile;

  // --- ตัวแปรสำหรับเรียกใช้ Services ---
  final ApiService _apiService = ApiService();
  final ImageUploadService _imageUploadService = ImageUploadService();

  // --- ตัวแปรสำหรับจัดการ State ---
  bool _isConfirmingPickup = false;
  bool _isConfirmingDelivery = false;
  TrackingStatus _currentStatus = TrackingStatus.pickingUp;

  @override
  void initState() {
    super.initState();
    _initializeLocationAndStartSendingUpdates();
  }

  Future<void> _initializeLocationAndStartSendingUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

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

    _location.onLocationChanged.listen((LocationData currentLocation) {
      if (!mounted) return;
      final newLocation = LatLng(
        currentLocation.latitude!,
        currentLocation.longitude!,
      );
      setState(() => _currentRiderLocation = newLocation);

      final now = DateTime.now();
      if (_lastLocationUpdateTime == null ||
          now.difference(_lastLocationUpdateTime!).inSeconds > 15) {
        print("Sending location to backend...");
        _apiService.updateRiderLocation(
          token: widget.loginData.idToken,
          latitude: newLocation.latitude,
          longitude: newLocation.longitude,
        );
        _lastLocationUpdateTime = now;
      }
    });
  }

  // ++ 1. สร้างฟังก์ชันกลางสำหรับแสดง Dialog ยืนยัน ++
  void _showConfirmationDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    // เปลี่ยนจาก Get.dialog เป็น showDialog
    showDialog(
      context: context, // ใช้ context ที่รับมา
      barrierDismissible: false, // ป้องกันการกดปิดนอก Dialog
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              child: const Text('ยกเลิก'),
              // เปลี่ยนจาก Get.back() เป็น Navigator.of(context).pop()
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: title == 'ยืนยันการรับสินค้า'
                    ? const Color(0xFF00897B)
                    : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('ยืนยัน'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // ปิด Dialog ก่อน
                onConfirm(); // แล้วค่อยเรียกฟังก์ชัน
              },
            ),
          ],
        );
      },
    );
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return Get.dialog<ImageSource>(
      AlertDialog(
        title: const Text('เลือกรูปภาพ'),
        content: const Text('คุณต้องการเลือกรูปภาพจากที่ใด?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: ImageSource.camera),
            child: const Text('กล้อง'),
          ),
          TextButton(
            onPressed: () => Get.back(result: ImageSource.gallery),
            child: const Text('คลังภาพ'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageForPickup() async {
    final ImageSource? source = await _showImageSourceDialog();
    if (source == null) return;
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (pickedFile != null)
      setState(() => _pickedUpImageFile = File(pickedFile.path));
  }

  Future<void> _pickImageForDelivery() async {
    final ImageSource? source = await _showImageSourceDialog();
    if (source == null) return;
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (pickedFile != null)
      setState(() => _deliveredImageFile = File(pickedFile.path));
  }

  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  Future<void> _handleConfirmPickup() async {
    if (_currentRiderLocation == null) {
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถระบุตำแหน่งของคุณได้',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    if (_pickedUpImageFile == null) {
      Get.snackbar(
        'โปรดทราบ',
        'กรุณาถ่ายรูปเพื่อยืนยันการรับสินค้า',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    final pickupLocation = LatLng(
      widget.delivery.senderAddress.coordinates.latitude,
      widget.delivery.senderAddress.coordinates.longitude,
    );
    final distance = _calculateDistance(_currentRiderLocation!, pickupLocation);

    if (distance > 200) {
      Get.snackbar(
        'คุณอยู่ไกลเกินไป',
        'กรุณาเข้าใกล้จุดรับสินค้าอีก ${distance.toStringAsFixed(0)} เมตร',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isConfirmingPickup = true);
    try {
      final imageUrl = await _imageUploadService.uploadImageToCloudinary(
        _pickedUpImageFile!,
      );
      await _apiService.confirmPickup(
        token: widget.loginData.idToken,
        deliveryId: widget.delivery.id,
        pickupImageURL: imageUrl,
      );
      if (mounted) {
        Get.dialog(
          AlertDialog(
            title: const Text('สำเร็จ'),
            content: const Text('ยืนยันการรับสินค้าเรียบร้อยแล้ว!'),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                  setState(() {
                    _currentStatus = TrackingStatus.delivering;
                    _isPanelExpanded = false;
                    _sheetController.animateTo(
                      0.22,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  });
                },
                child: const Text('ตกลง'),
              ),
            ],
          ),
          barrierDismissible: false,
        );
      }
    } catch (e) {
      Get.snackbar(
        'เกิดข้อผิดพลาด',
        e.toString().replaceFirst("Exception: ", ""),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isConfirmingPickup = false);
    }
  }

  Future<void> _handleConfirmDelivery() async {
    if (_currentRiderLocation == null) {
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถระบุตำแหน่งของคุณได้',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    if (_deliveredImageFile == null) {
      Get.snackbar(
        'โปรดทราบ',
        'กรุณาถ่ายรูปเพื่อยืนยันการส่งสินค้า',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final receiverLocation = LatLng(
      widget.delivery.receiverAddress.coordinates.latitude,
      widget.delivery.receiverAddress.coordinates.longitude,
    );
    final distance = _calculateDistance(
      _currentRiderLocation!,
      receiverLocation,
    );

    if (distance > 200) {
      Get.snackbar(
        'คุณอยู่ไกลเกินไป',
        'กรุณาเข้าใกล้จุดส่งสินค้าอีก ${distance.toStringAsFixed(0)} เมตร',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isConfirmingDelivery = true);
    try {
      final imageUrl = await _imageUploadService.uploadImageToCloudinary(
        _deliveredImageFile!,
      );
      await _apiService.confirmDelivery(
        token: widget.loginData.idToken,
        deliveryId: widget.delivery.id,
        deliveredImageURL: imageUrl,
      );
      if (mounted) {
        Get.dialog(
          AlertDialog(
            title: const Text('ส่งสำเร็จ!'),
            content: const Text('คุณได้จัดส่งสินค้าเรียบร้อยแล้ว'),
            actions: [
              TextButton(
                onPressed: () {
                  Get.offAll(
                    () => const RiderDashboardScreen(),
                    arguments: widget.loginData,
                  );
                },
                child: const Text('กลับสู่หน้าหลัก'),
              ),
            ],
          ),
          barrierDismissible: false,
        );
      }
    } catch (e) {
      Get.snackbar(
        'เกิดข้อผิดพลาด',
        e.toString().replaceFirst("Exception: ", ""),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isConfirmingDelivery = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng senderLocation = LatLng(
      widget.delivery.senderAddress.coordinates.latitude,
      widget.delivery.senderAddress.coordinates.longitude,
    );
    final LatLng receiverLocation = LatLng(
      widget.delivery.receiverAddress.coordinates.latitude,
      widget.delivery.receiverAddress.coordinates.longitude,
    );
    const double minPanelSize = 0.22;
    const double maxPanelSize = 0.6;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentStatus == TrackingStatus.pickingUp
                  ? senderLocation
                  : receiverLocation,
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
                        Icon(
                          _currentStatus == TrackingStatus.delivering
                              ? Icons.check_circle
                              : Icons.storefront,
                          color: _currentStatus == TrackingStatus.delivering
                              ? Colors.grey
                              : Colors.blue,
                          size: 40,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          color: _currentStatus == TrackingStatus.delivering
                              ? Colors.grey
                              : Colors.blue,
                          child: const Text(
                            "Pick Up",
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_currentStatus == TrackingStatus.delivering)
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: receiverLocation,
                      child: Column(
                        children: [
                          const Icon(Icons.home, color: Colors.red, size: 40),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            color: Colors.red,
                            child: const Text(
                              "Drop Off",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
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
              if (isExpanded != _isPanelExpanded)
                setState(() => _isPanelExpanded = isExpanded);
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
                        child: _currentStatus == TrackingStatus.pickingUp
                            ? _buildPickupPanelContent(maxPanelSize)
                            : _buildDeliveryPanelContent(maxPanelSize),
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
              if (!_isPanelExpanded)
                _sheetController.animateTo(
                  maxPanelSize,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
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
                  onTap: _pickImageForPickup,
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
                ElevatedButton(
                  // ++ 2. แก้ไขปุ่มให้เรียกใช้ Dialog ยืนยัน ++
                  onPressed: _isConfirmingPickup
                      ? null
                      : () {
                          _showConfirmationDialog(
                            // context: context, // ไม่ต้องส่ง context แล้ว เพราะฟังก์ชัน build มี context อยู่แล้ว
                            title: 'ยืนยันการรับสินค้า',
                            content:
                                'คุณแน่ใจหรือไม่ว่าต้องการยืนยันการรับสินค้า?',
                            onConfirm: _handleConfirmPickup,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isConfirmingPickup
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        )
                      : const Text('รับสินค้า', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDeliveryPanelContent(double maxPanelSize) {
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
              if (!_isPanelExpanded)
                _sheetController.animateTo(
                  maxPanelSize,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_pin_circle,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Drop-off : ${widget.delivery.receiverName}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.delivery.receiverAddress.detail,
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
                    "โปรดถ่ายรูปยืนยันการส่งสินค้า",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickImageForDelivery,
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
                      child: _deliveredImageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _deliveredImageFile!,
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
                ElevatedButton(
                  // ++ 3. แก้ไขปุ่มให้เรียกใช้ Dialog ยืนยัน ++
                  onPressed: _isConfirmingDelivery
                      ? null
                      : () {
                          _showConfirmationDialog(
                            // context: context, // ไม่ต้องส่ง context แล้ว
                            title: 'ยืนยันการส่งสินค้า',
                            content:
                                'คุณแน่ใจหรือไม่ว่าได้ส่งสินค้าถึงมือผู้รับเรียบร้อยแล้ว?',
                            onConfirm: _handleConfirmDelivery,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isConfirmingDelivery
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        )
                      : const Text(
                          'ยืนยันการส่งสินค้า',
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
