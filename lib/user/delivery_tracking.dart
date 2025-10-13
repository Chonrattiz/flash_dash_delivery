import 'dart:async'; // <-- 1. Import 'async' เพื่อใช้ StreamSubscription
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- 2. Import Firestore
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../api/api_service.dart';
import '../model/response/delivery_list_response.dart';
import '../model/response/login_response.dart';
import '../model/response/searchphon_response.dart'; // <-- 3. Import FindUserResponse

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
  late LatLng senderLocation;
  late LatLng receiverLocation;
  late LatLngBounds mapBounds;

  // ++ State สำหรับข้อมูลโปรไฟล์ไรเดอร์ ++
  final ApiService _apiService = ApiService();
  UserProfile? _riderProfile;
  bool _isLoadingRider = true;

  // ++ State สำหรับ Real-time Tracking ++
  StreamSubscription? _locationSubscription;
  LatLng? _riderCurrentLocation;

  @override
  void initState() {
    super.initState();
    // --- ตั้งค่าพิกัดเริ่มต้น ---
    senderLocation = LatLng(
      widget.delivery.senderAddress.coordinates.latitude,
      widget.delivery.senderAddress.coordinates.longitude,
    );
    receiverLocation = LatLng(
      widget.delivery.receiverAddress.coordinates.latitude,
      widget.delivery.receiverAddress.coordinates.longitude,
    );
    mapBounds = LatLngBounds(senderLocation, receiverLocation);

    // --- เริ่มกระบวนการดึงข้อมูล ---
    _initializeRiderDataAndTracking();
  }

  // ++ ฟังก์ชันสำคัญ: จัดการการดึงข้อมูลและเริ่ม Tracking ++
  void _initializeRiderDataAndTracking() {
    // ตรวจสอบก่อนว่ามีไรเดอร์รับงานแล้วหรือยัง
    if (widget.delivery.riderUID != null && widget.delivery.riderUID!.isNotEmpty) {
      // ถ้ามี ให้ไปดึงข้อมูลโปรไฟล์ และเริ่มดักฟังตำแหน่ง
      _fetchRiderProfileAndStartListening(widget.delivery.riderUID!);
    } else {
      // ถ้ายังไม่มี ให้ตั้งค่าสถานะว่าโหลดเสร็จแล้ว (แต่ไม่มีข้อมูล)
      if (mounted) {
        setState(() {
          _isLoadingRider = false;
        });
      }
    }
  }

  Future<void> _fetchRiderProfileAndStartListening(String riderPhone) async {
    try {
      // 1. ดึงข้อมูลโปรไฟล์ไรเดอร์ (ทำครั้งเดียว)
      final FindUserResponse response = await _apiService.findUserByPhone(
        token: widget.loginData.idToken,
        phone: riderPhone,
      );

      if (mounted) {
        setState(() {
          _riderProfile = UserProfile(
            name: response.name,
            phone: response.phone,
            imageProfile: response.imageProfile,
            role: response.role,
          );
          _isLoadingRider = false;
        });

        // 2. เมื่อได้ข้อมูลโปรไฟล์แล้ว ให้เริ่ม "ดักฟัง" ตำแหน่ง Real-time
        _startListeningToRiderLocation(riderPhone);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRider = false;
        });
      }
      print("Error fetching rider profile: $e");
    }
  }

  void _startListeningToRiderLocation(String riderPhone) {
    // สมมติว่าใน Firestore มี collection 'riders' และ document ID คือเบอร์โทร
    final riderDocStream =
        FirebaseFirestore.instance.collection('riders').doc(riderPhone).snapshots();

    _locationSubscription = riderDocStream.listen((DocumentSnapshot snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;

        // สมมติว่าใน document มี field 'currentLocation' ที่เป็น GeoPoint
        if (data.containsKey('currentLocation')) {
          final GeoPoint location = data['currentLocation'];
          if (mounted) {
            setState(() {
              _riderCurrentLocation = LatLng(location.latitude, location.longitude);
            });
          }
        }
      }
    });
  }

  // ++ สำคัญมาก: หยุดการดักฟังเมื่อออกจากหน้าจอ ++
  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: mapBounds,
                padding: const EdgeInsets.all(80.0),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              MarkerLayer(
                markers: [
                  _buildPinMarker(senderLocation, Symbols.approval_delegation, Colors.blue.shade700),
                  _buildPinMarker(receiverLocation, Symbols.deployed_code_account, Colors.green.shade600),
                  
                  // ++ Marker ของไรเดอร์ จะแสดงก็ต่อเมื่อมีตำแหน่งแล้ว ++
                  if (_riderCurrentLocation != null)
                    Marker(
                      point: _riderCurrentLocation!,
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Symbols.navigation, color: Colors.purple.shade700, size: 60),
                          Positioned(
                            top: 15,
                            child: Icon(Symbols.moped, color: Colors.white, size: 30),
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
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.35,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24.0),
                    topRight: Radius.circular(24.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10.0,
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: _buildPanelContent(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPanelContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 5,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatusTracker(widget.delivery.status),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          
          // ++ แก้ไข _buildUserCard ของไรเดอร์ ให้แสดงข้อมูลจาก State ++
          _buildUserCard(
            title: 'ไรเดอร์',
            name: _isLoadingRider
                ? 'กำลังโหลด...'
                : _riderProfile?.name ?? 'ยังไม่มีผู้รับงาน',
            phone: _isLoadingRider ? '' : _riderProfile?.phone ?? '-',
            imageUrl: _isLoadingRider ? '' : _riderProfile?.imageProfile ?? '',
          ),
          const SizedBox(height: 16),
          _buildUserCard(
            title: 'ผู้ส่ง',
            name: widget.delivery.senderName,
            phone: widget.delivery.senderUID,
            imageUrl: widget.delivery.senderImageProfile,
          ),
          const SizedBox(height: 16),
          _buildUserCard(
            title: 'ผู้รับ',
            name: widget.delivery.receiverName,
            phone: widget.delivery.receiverUID,
            imageUrl: widget.delivery.receiverImageProfile,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildItemDetailsCard(),
        ],
      ),
    );
  }

  // --- Widget ย่อยๆ สำหรับสร้าง UI (ไม่มีการแก้ไข) ---
  Widget _buildStatusTracker(String currentStatus) {
    int activeStep = 0;
    switch (currentStatus) {
      case 'pending':   activeStep = 0; break;
      case 'accepted':  activeStep = 1; break;
      case 'picked_up': activeStep = 2; break;
      case 'delivered': activeStep = 3; break;
    }
    final activeColor = Colors.green;
    final inactiveColor = Colors.grey.shade300;
    final double circleRadius = 20;
    final double lineHeight = 4;

    return SizedBox(
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: circleRadius - (lineHeight / 2),
            left: 30, right: 30,
            child: Row(
              children: [
                Expanded(flex: activeStep, child: Container(height: lineHeight, color: activeColor)),
                Expanded(flex: 3 - activeStep, child: Container(height: lineHeight, color: inactiveColor)),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusStep('รอไรเดอร์รับ', Symbols.hourglass_empty, activeStep >= 0, circleRadius, 24),
              _buildStatusStep('กำลังไปรับ', Symbols.work, activeStep >= 1, circleRadius, 24),
              _buildStatusStep('กำลังไปส่ง', Symbols.moped, activeStep >= 2, circleRadius, 24),
              _buildStatusStep('ส่งสำเร็จ', Symbols.inventory, activeStep >= 3, circleRadius, 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStep(String title, IconData icon, bool isActive, double radius, double iconSize) {
    final activeColor = Colors.green;
    final inactiveColor = Colors.grey.shade300;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: isActive ? activeColor : inactiveColor,
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.prompt(
            color: isActive ? Colors.black87 : Colors.grey,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard({required String title, required String name, required String phone, required String imageUrl}) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
          child: imageUrl.isEmpty ? const Icon(Symbols.person, color: Colors.grey) : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.prompt(color: Colors.grey[600])),
            Text(name, style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(phone, style: GoogleFonts.prompt(color: Colors.grey[700])),
          ],
        )
      ],
    );
  }

  Widget _buildItemDetailsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('รายละเอียดพัสดุ', style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(widget.delivery.itemImage, width: 60, height: 60, fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
                errorBuilder: (context, error, stackTrace) => const Icon(Symbols.image_not_supported, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.delivery.itemDescription, style: GoogleFonts.prompt())),
          ],
        )
      ],
    );
  }

  Marker _buildPinMarker(LatLng point, IconData icon, Color color) {
    return Marker(
      width: 80.0,
      height: 80.0,
      point: point,
      alignment: Alignment.topCenter, // ใช้ alignment ปกติ
      child: Transform.translate(
        offset: const Offset(
          0,
          20,
        ), // ✅ ปรับค่าตรงนี้เพื่อขยับหมุดลง (20–30 กำลังดี)
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.location_on,
              color: color,
              size: 60,
              shadows: const [
                Shadow(
                  blurRadius: 10.0,
                  color: Colors.black26,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            Positioned(
              top: 15,
              child: Icon(icon, color: Colors.white, size: 30),
            ),
          ],
        ),
      ),
    );
  }
}