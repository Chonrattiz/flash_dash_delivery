import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../config/image_config.dart';
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
  late LatLng senderLocation;
  late LatLng receiverLocation;
  late LatLngBounds mapBounds;

  @override
  void initState() {
    super.initState();
    // ดึงพิกัดจากข้อมูลที่ส่งมา
    senderLocation = LatLng(
      widget.delivery.senderAddress.coordinates.latitude,
      widget.delivery.senderAddress.coordinates.longitude,
    );
    receiverLocation = LatLng(
      widget.delivery.receiverAddress.coordinates.latitude,
      widget.delivery.receiverAddress.coordinates.longitude,
    );

    // คำนวณขอบเขตของแผนที่ให้แสดงหมุดทั้งหมดพอดี
    mapBounds = LatLngBounds(senderLocation, receiverLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // --- 1. แผนที่ (อยู่ชั้นล่างสุด) ---
          FlutterMap(
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: mapBounds,
                padding: const EdgeInsets.all(50.0), // เพิ่มระยะห่างจากขอบ
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              MarkerLayer(
                markers: [
                  // หมุดผู้ส่ง (เรียกใช้ฟังก์ชันใหม่)
                  _buildPinMarker(
                    senderLocation,
                    Symbols.approval_delegation,
                    Colors.blue.shade700,
                  ),
                  // หมุดผู้รับ (เรียกใช้ฟังก์ชันใหม่)
                  _buildPinMarker(
                    receiverLocation,
                    Symbols.deployed_code_account,
                    Colors.green.shade600,
                  ),
                ],
              ),
            ],
          ),

          // --- 2. ปุ่ม Back (ลอยอยู่ด้านบน) ---
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

          // --- 3. แผงข้อมูลที่เลื่อนได้ (Draggable Sheet) ---
          DraggableScrollableSheet(
            initialChildSize: 0.35, // ขนาดเริ่มต้น (35% ของหน้าจอ)
            minChildSize: 0.35, // ขนาดเล็กสุด
            maxChildSize: 0.8, // ขนาดใหญ่สุด
            builder: (BuildContext context, ScrollController scrollController) {
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

  // --- Widget สำหรับสร้างเนื้อหาใน Panel ---
  Widget _buildPanelContent() {
    // **** จุดแก้ไข: สร้าง URL รูปภาพ ****
    final String senderImageUrl = widget.delivery.senderImageProfile ?? '';
    final String receiverImageUrl = widget.delivery.receiverImageProfile ?? '';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "ขีด" สำหรับให้รู้ว่าเลื่อนได้
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

          // --- Status Tracker ---
          _buildStatusTracker(widget.delivery.status),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // --- ข้อมูล ไรเดอร์, ผู้ส่ง, ผู้รับ ---
          _buildUserCard(
            title: 'ไรเดอร์',
            name: widget.delivery.riderUID ?? 'ยังไม่มีผู้รับงาน',
            phone: '-',
            imageUrl: '', // ยังไม่มีข้อมูลรูปไรเดอร์
          ),
          const SizedBox(height: 16),
          _buildUserCard(
            title: 'ผู้ส่ง',
            name: widget.delivery.senderName,
            phone: widget.delivery.senderUID,
            imageUrl: senderImageUrl, // <-- ใช้ URL ที่สร้างขึ้น
          ),
          const SizedBox(height: 16),
          _buildUserCard(
            title: 'ผู้รับ',
            name: widget.delivery.receiverName,
            phone: widget.delivery.receiverUID,
            imageUrl: receiverImageUrl, // <-- ใช้ URL ที่สร้างขึ้น
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // --- รายละเอียดพัสดุ ---
          _buildItemDetailsCard(),
        ],
      ),
    );
  }

  // --- Widget ย่อยๆ สำหรับสร้าง UI ---

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
    final double circleRadius = 23; // <-- กำหนดรัศมีวงกลมเป็นตัวแปร
    final double lineHeight = 5; // <-- กำหนดความหนาเส้นเป็นตัวแปร

    return SizedBox(
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // --- ชั้นที่ 1: เส้นเชื่อมพื้นหลัง ---
          Positioned(
            top: circleRadius - (lineHeight / 2),
            left: 30, // ระยะห่างจากขอบซ้าย
            right: 30, // ระยะห่างจากขอบขวา
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

          // --- ชั้นที่ 2: วงกลมและข้อความ (วางทับเส้น) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusStep(
                'รอไรเดอร์รับ',
                Symbols.hourglass_empty,
                activeStep >= 0,
                circleRadius,
              ),
              _buildStatusStep(
                'กำลังไปรับ',
                Symbols.work,
                activeStep >= 1,
                circleRadius,
              ),
              _buildStatusStep(
                'กำลังไปส่ง',
                Symbols.moped_package,
                activeStep >= 2,
                circleRadius,
              ),
              _buildStatusStep(
                'ส่งสำเร็จ',
                Symbols.inventory,
                activeStep >= 3,
                circleRadius,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(bool isActive) {
    return Expanded(
      child: Padding(
        // Padding นี้สำหรับปรับ "ความยาว" ของเส้น (ซ้าย-ขวา)
        padding: const EdgeInsets.symmetric(horizontal: 1.0),
        // ✅ เพิ่ม Padding อีกชั้นเพื่อปรับ "ตำแหน่ง" (บน-ล่าง)
        child: Container(
          height: 5,
          decoration: BoxDecoration(
            color: isActive ? Colors.green : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusStep(
    String title,
    IconData icon,
    bool isActive,
    double radius,
  ) {
    final activeColor = Colors.green;
    final inactiveColor = Colors.grey.shade300;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: radius, // <-- ใช้ค่ารัศมีจากตัวแปร
          backgroundColor: isActive ? activeColor : inactiveColor,
          child: Icon(icon, color: Colors.white, size: 30),
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
              ? const Icon(Icons.person, color: Colors.grey)
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

  Widget _buildItemDetailsCard() {
    final imageUrl = widget.delivery.itemImage ?? '';
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
                imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                // เพิ่ม placeholder ขณะโหลด
                loadingBuilder: (context, child, progress) {
                  return progress == null
                      ? child
                      : const SizedBox(
                          width: 60,
                          height: 60,
                          child: Center(child: CircularProgressIndicator()),
                        );
                },
                // เพิ่ม fallback กรณีโหลดรูปไม่ได้
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    width: 60,
                    height: 60,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.delivery.itemDescription,
                style: GoogleFonts.prompt(),
              ),
            ),
          ],
        ),
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
