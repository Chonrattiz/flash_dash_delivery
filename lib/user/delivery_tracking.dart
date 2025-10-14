import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../api/api_service.dart';
import '../model/response/delivery_list_response.dart';
import '../model/response/login_response.dart';
import '../model/response/searchphon_response.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  // เรายังรับ delivery เริ่มต้นมาเหมือนเดิม เพื่อเอา ID ไปใช้ดักฟัง
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
  // ++ State ส่วนใหญ่ยังเหมือนเดิม ++
  final ApiService _apiService = ApiService();
  UserProfile? _riderProfile;
  bool _isLoadingRider = true;
  StreamSubscription? _locationSubscription;
  LatLng? _riderCurrentLocation;

  @override
  void initState() {
    super.initState();
    // เราจะดึงข้อมูลไรเดอร์แค่ครั้งเดียวตอนเริ่มต้นก็พอ เพราะไม่น่าจะเปลี่ยน
    _initializeRiderDataAndTracking();
  }

  // ฟังก์ชันนี้ยังทำงานเหมือนเดิม
  void _initializeRiderDataAndTracking() {
    if (widget.delivery.riderUID != null &&
        widget.delivery.riderUID!.isNotEmpty) {
      _fetchRiderProfileAndStartListening(widget.delivery.riderUID!);
    } else {
      if (mounted) {
        setState(() {
          _isLoadingRider = false;
        });
      }
    }
  }

  // ฟังก์ชันนี้ยังทำงานเหมือนเดิม
  Future<void> _fetchRiderProfileAndStartListening(String riderPhone) async {
    try {
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

  // ฟังก์ชันนี้ยังทำงานเหมือนเดิม
  void _startListeningToRiderLocation(String riderPhone) {
    final riderDocStream = FirebaseFirestore.instance
        .collection('riders')
        .doc(riderPhone)
        .snapshots();

    _locationSubscription = riderDocStream.listen((DocumentSnapshot snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        if (data.containsKey('currentLocation')) {
          final GeoPoint location = data['currentLocation'];
          if (mounted) {
            setState(() {
              _riderCurrentLocation =
                  LatLng(location.latitude, location.longitude);
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ++ 1. จุดแก้ไขหลัก: ใช้ StreamBuilder หุ้ม Body ทั้งหมด ++
      body: StreamBuilder<DocumentSnapshot>(
        // ตั้งค่าให้ Stream ดักฟัง Document ของ Delivery นี้โดยเฉพาะ
        // *** สำคัญ: ต้องแน่ใจว่า collection ชื่อ 'deliveries' หรือถ้าเป็นชื่ออื่นให้แก้ตามจริง ***
        stream: FirebaseFirestore.instance
            .collection('deliveries')
            .doc(widget.delivery.id) // ใช้ ID จาก delivery ที่รับมา
            .snapshots(),
        builder: (context, snapshot) {
          // --- จัดการสถานะต่างๆ ของ Stream ---
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            // ขณะรอข้อมูลครั้งแรก ให้แสดง Loading กลางจอ
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('ไม่พบข้อมูล Delivery'));
          }

          // --- เมื่อมีข้อมูลล่าสุดแล้ว ---
          // ++ 2. แปลงข้อมูลล่าสุดที่ได้จาก Stream เป็น Object Delivery ++
          final liveDelivery =
              Delivery.fromJson(snapshot.data!.data() as Map<String, dynamic>);

          // คำนวณค่าพิกัดจากข้อมูลล่าสุด
          final senderLocation = LatLng(
            liveDelivery.senderAddress.coordinates.latitude,
            liveDelivery.senderAddress.coordinates.longitude,
          );
          final receiverLocation = LatLng(
            liveDelivery.receiverAddress.coordinates.latitude,
            liveDelivery.receiverAddress.coordinates.longitude,
          );
          final mapBounds = LatLngBounds(senderLocation, receiverLocation);

          // ++ 3. นำ UI เดิมทั้งหมดมาวางไว้ที่นี่ และใช้ข้อมูลจาก 'liveDelivery' ++
          return Stack(
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
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.flash_dash_delivery',
                  ),
                  MarkerLayer(
                    markers: [
                      _buildPinMarker(
                        senderLocation,
                        Symbols.deployed_code_account,
                        Colors.blue.shade700,
                      ),
                      _buildPinMarker(
                        receiverLocation,
                        Symbols.approval_delegation,
                        Colors.green.shade600,
                      ),
                      if (_riderCurrentLocation != null)
                        Marker(
                          point: _riderCurrentLocation!,
                          width: 80,
                          height: 80,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                top: 15,
                                child: Icon(
                                  Symbols.moped_package,
                                  color: const Color.fromARGB(255, 221, 0, 0),
                                  size: 35,
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
                      // ++ 4. ส่ง 'liveDelivery' ที่เป็นข้อมูลล่าสุดเข้าไปใน Panel ++
                      child: _buildPanelContent(liveDelivery),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ++ 5. แก้ไข Widget ย่อย ให้รับ 'Delivery' object เป็นพารามิเตอร์ ++
  Widget _buildPanelContent(Delivery delivery) {
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
          // ใช้ข้อมูลจาก delivery ที่รับเข้ามา
          _buildStatusTracker(delivery.status),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
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
          _buildItemDetailsCard(delivery),
          // Widget นี้จะแสดงก็ต่อเมื่อ delivery.pickupImage มีค่าเท่านั้น
          _buildRiderImageCard(
            'ไรเดอร์มารับสินค้าเเล้ว',
            delivery.pickupImage,
          ),
          _buildRiderImageCard(
            'ไรเดอร์ส่งสำเร็จ',
            delivery.deliveredImage,
          ),
        ],
      ),
    );
  }

  // แก้ไขให้รับพารามิเตอร์
  Widget _buildItemDetailsCard(Delivery delivery) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'รายละเอียดพัสดุ',
          style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                delivery.itemImage,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Symbols.image_not_supported, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                delivery.itemDescription,
                style: GoogleFonts.prompt(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusTracker(String currentStatus) {
    int activeStep = 0;
    switch (currentStatus) {
      case 'pending':
        activeStep = 0;
        break;
      case 'accepted':
        activeStep = 1;
        break;
      case 'picked_up':
        activeStep = 2;
        break;
      case 'delivered':
        activeStep = 3;
        break;
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
            left: 30,
            right: 30,
            child: Row(
              children: [
                Expanded(
                  flex: activeStep,
                  child: Container(height: lineHeight, color: activeColor),
                ),
                Expanded(
                  flex: 3 - activeStep,
                  child: Container(height: lineHeight, color: inactiveColor),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusStep(
                'รอไรเดอร์รับ',
                Symbols.hourglass_empty,
                activeStep >= 0,
                circleRadius,
                24,
              ),
              _buildStatusStep(
                'กำลังไปรับ',
                Symbols.work,
                activeStep >= 1,
                circleRadius,
                24,
              ),
              _buildStatusStep(
                'กำลังไปส่ง',
                Symbols.moped,
                activeStep >= 2,
                circleRadius,
                24,
              ),
              _buildStatusStep(
                'ส่งสำเร็จ',
                Symbols.inventory,
                activeStep >= 3,
                circleRadius,
                24,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStep(
    String title,
    IconData icon,
    bool isActive,
    double radius,
    double iconSize,
  ) {
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

  Widget _buildUserCard({
    required String title,
    required String name,
    required String phone,
    required String imageUrl,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
          child: imageUrl.isEmpty
              ? const Icon(Symbols.person, color: Colors.grey)
              : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.prompt(color: Colors.grey[600])),
            Text(
              name,
              style: GoogleFonts.prompt(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(phone, style: GoogleFonts.prompt(color: Colors.grey[700])),
          ],
        ),
      ],
    );
  }

  Widget _buildRiderImageCard(String title, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  ),
            errorBuilder: (context, error, stackTrace) => Container(
              height: 200,
              alignment: Alignment.center,
              child: const Icon(Symbols.broken_image,
                  color: Colors.grey, size: 50),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
      ],
    );
  }

  Marker _buildPinMarker(LatLng point, IconData icon, Color color) {
    return Marker(
      width: 80.0,
      height: 80.0,
      point: point,
      alignment: Alignment.topCenter,
      child: Transform.translate(
        offset: const Offset(0, 20),
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
