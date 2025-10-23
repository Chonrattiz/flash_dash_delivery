import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';

// Import model ที่มี Address และ Coordinates

// Import model Delivery
import '../model/response/delivery_list_response.dart'; // หรือ path ที่ถูกต้อง

class MapPreviewScreen extends StatelessWidget {
  final Delivery delivery;

  const MapPreviewScreen({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    // ดึงพิกัด
    final LatLng pickupLatLng = LatLng(
      delivery.senderAddress.coordinates.latitude,
      delivery.senderAddress.coordinates.longitude,
    );
    final LatLng deliveryLatLng = LatLng(
      delivery.receiverAddress.coordinates.latitude,
      delivery.receiverAddress.coordinates.longitude,
    );

    // คำนวณจุดกึ่งกลางและ Zoom Level ที่เหมาะสม (แบบง่ายๆ)
    final LatLngBounds bounds = LatLngBounds(pickupLatLng, deliveryLatLng);
    final LatLng center = bounds.center;
    // อาจจะต้องปรับค่า Zoom เพิ่มเติมตามระยะทางจริง
    double zoom = 13.0; // ค่าเริ่มต้น

    return Scaffold(
      appBar: AppBar(
        title: Text('ดูเส้นทาง', style: GoogleFonts.prompt()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(), // ใช้ Get.back() เพื่อกลับไปหน้าก่อนหน้า
        ),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: center, // ให้จุดกึ่งกลางเป็น Center เริ่มต้น
          initialZoom: zoom,
          // ลองคำนวณ Zoom จาก Bounds (อาจจะต้องปรับค่า padding เพิ่มเติม)
          // initialCameraFit: CameraFit.bounds(
          //   bounds: bounds,
          //   padding: const EdgeInsets.all(50.0), // เพิ่ม padding รอบๆ
          // ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName:
                'com.example.flash_dash_delivery', // <-- แก้เป็น package name ของคุณ
          ),
          MarkerLayer(
            markers: [
              // Marker จุดรับของ (Sender)
              Marker(
                point: pickupLatLng,
                width: 80,
                height: 80,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('รับ',
                          style: GoogleFonts.prompt(
                              color: Colors.white, fontSize: 10)),
                    ),
                    const Icon(
                      Icons.location_pin,
                      size: 35,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
              // Marker จุดส่งของ (Receiver)
              Marker(
                point: deliveryLatLng,
                width: 80,
                height: 80,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green[600],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('ส่ง',
                          style: GoogleFonts.prompt(
                              color: Colors.white, fontSize: 10)),
                    ),
                    const Icon(
                      Icons.location_pin,
                      size: 35,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // (Optional) แสดงเส้นตรงเชื่อมระหว่าง 2 จุด
          PolylineLayer(
            polylines: [
              Polyline(
                points: [pickupLatLng, deliveryLatLng],
                color: Colors.blue,
                strokeWidth: 3,
              ),
            ],
          )
        ],
      ),
    );
  }
}
