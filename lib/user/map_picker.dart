import 'dart:async';

import 'package:flash_dash_delivery/model/response/login_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:osm_nominatim/osm_nominatim.dart';
import 'package:geolocator/geolocator.dart';

// ใช้คลาสนี้ส่งข้อมูลกลับ
class AddressResult {
  final LatLng coordinates;
  final String address;

  AddressResult({required this.coordinates, required this.address});
}

class MapPickerScreen extends StatefulWidget {
  final LoginResponse loginData;
  final Address? existingAddress; // 👈 ใช้เช็คว่าเป็น add หรือ edit

  const MapPickerScreen({
    super.key,
    required this.loginData,
    this.existingAddress,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _addressController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;

  // พิกัดเริ่มต้น
  final LatLng _initialCenter = const LatLng(16.2462, 103.2520);

  @override
  void initState() {
    super.initState();

    if (widget.existingAddress != null) {
      // ถ้าแก้ไข → set ค่าเก่า
      _addressController.text = widget.existingAddress!.detail;
      _mapController.move(
        LatLng(
          widget.existingAddress!.coordinates.latitude,
          widget.existingAddress!.coordinates.longitude,
        ),

        16.0,
      );
    } else {
      // ถ้าเพิ่มใหม่ → ใช้ตำแหน่งปัจจุบัน
      _determinePosition();
    }
  }

  // ฟังก์ชันดึงตำแหน่งปัจจุบัน
  Future<void> _determinePosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      _mapController.move(LatLng(position.latitude, position.longitude), 16.0);
    } catch (e) {
      _mapController.move(_initialCenter, 16.0);
    }
  }

  // ฟังก์ชันแปลงพิกัดเป็นที่อยู่
  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final nominatim = Nominatim(
        userAgent: 'flash_dash_delivery/1.0 (contact@email.com)',
      );
      final place = await nominatim.reverseSearch(
        lat: position.latitude,
        lon: position.longitude,
        addressDetails: true,
      );
      if (place.displayName.isNotEmpty) {
        _addressController.text = place.displayName;
      } else {
        _addressController.text = "ไม่สามารถค้นหาชื่อที่อยู่ได้";
      }
    } catch (e) {
      _addressController.text = "เกิดข้อผิดพลาดในการเชื่อมต่อ";
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // แผนที่
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 16.0,
              onPositionChanged: (position, hasGesture) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  if (position.center != null) {
                    _getAddressFromLatLng(position.center!);
                  }
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
            ],
          ),

          // หมุดกลาง
          const Center(
            child: Icon(Icons.location_pin, size: 50, color: Colors.red),
          ),

          // ปุ่ม Back
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

          // กล่องแสดงที่อยู่ + ปุ่มยืนยัน
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _addressController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'ที่อยู่ที่เลือก',
                        labelStyle: GoogleFonts.prompt(),
                        border: const OutlineInputBorder(),
                        suffixIcon: _isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_mapController.camera.center != null &&
                              _addressController.text.isNotEmpty) {
                            final result = AddressResult(
                              coordinates: _mapController.camera.center,
                              address: _addressController.text,
                            );

                            // ส่งกลับ พร้อม mode (add / edit)
                            Get.back(
                              result: {
                                "mode": widget.existingAddress == null
                                    ? "add"
                                    : "edit",
                                "data": result,
                                "oldAddress": widget.existingAddress,
                              },
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.existingAddress == null
                              ? 'บันทึกที่อยู่นี้'
                              : 'อัปเดตที่อยู่นี้',
                          style: GoogleFonts.prompt(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
