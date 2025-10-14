import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../model/response/delivery_list_response.dart';
import '../model/response/login_response.dart';

class CombinedMapViewScreen extends StatefulWidget {
  final LoginResponse loginData;
  final List<Delivery> sentDeliveries;
  final List<Delivery> receivedDeliveries;
  final int selectedTabIndex; // ++ 1. เพิ่ม parameter เพื่อรับค่า Tab index ++

  const CombinedMapViewScreen({
    super.key,
    required this.loginData,
    required this.sentDeliveries,
    required this.receivedDeliveries,
    required this.selectedTabIndex, // ++ เพิ่มเข้ามาใน constructor ++
  });

  @override
  State<CombinedMapViewScreen> createState() => _CombinedMapViewScreenState();
}

class _CombinedMapViewScreenState extends State<CombinedMapViewScreen> {
  final Map<String, LatLng> _riderLocations = {};
  final List<StreamSubscription> _locationSubscriptions = [];
  bool _isLoading = true;
  LatLng? _userCurrentLocation;

  @override
  void initState() {
    super.initState();
    _getUserLocationAndInitialize();
  }

  Future<void> _getUserLocationAndInitialize() async {
    // ... โค้ดส่วนนี้เหมือนเดิม ...
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _userCurrentLocation = const LatLng(16.2463, 103.2505));
      _initializeRiderListeners();
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _userCurrentLocation = const LatLng(16.2463, 103.2505));
        _initializeRiderListeners();
        return;
      }
    }
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() => _userCurrentLocation = LatLng(position.latitude, position.longitude));
    } catch (e) {
      setState(() => _userCurrentLocation = const LatLng(16.2463, 103.2505));
    } finally {
      _initializeRiderListeners();
    }
  }

  void _initializeRiderListeners() {
    // ++ 2. เลือก list ที่จะใช้ตาม selectedTabIndex ++
    final relevantDeliveries = widget.selectedTabIndex == 0
        ? widget.sentDeliveries   // ถ้า Tab คือ "รายการที่จัดส่ง"
        : widget.receivedDeliveries; // ถ้า Tab คือ "รายการที่ต้องรับ"

    // ++ 3. ใช้ list ที่เลือกมาเพื่อกรองหาไรเดอร์ ++
    final activeDeliveries = relevantDeliveries.where((d) =>
        (d.status == 'accepted' || d.status == 'picked_up') &&
        d.riderUID != null && d.riderUID!.isNotEmpty).toList();
        
    final uniqueRiderIds = activeDeliveries.map((d) => d.riderUID!).toSet();
    
    if (uniqueRiderIds.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    // ... ส่วนที่เหลือของฟังก์ชันเหมือนเดิมทุกประการ ...
    for (final riderId in uniqueRiderIds) {
      final stream = FirebaseFirestore.instance.collection('riders').doc(riderId).snapshots();
      final subscription = stream.listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          if (data.containsKey('currentLocation')) {
            final GeoPoint location = data['currentLocation'];
            setState(() {
              _riderLocations[riderId] = LatLng(location.latitude, location.longitude);
              if (_isLoading) _isLoading = false;
            });
          }
        }
      });
      _locationSubscriptions.add(subscription);
    }
  }

  @override
  void dispose() {
    for (var sub in _locationSubscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ++ 4. เปลี่ยนหัวข้อ AppBar และข้อความตาม Tab ที่เลือก ++
    final appBarTitle = widget.selectedTabIndex == 0
        ? 'ไรเดอร์ที่กำลังไปส่งของ'
        : 'ไรเดอร์ที่กำลังมาส่ง';
    final noRiderText = widget.selectedTabIndex == 0
        ? 'ไม่พบไรเดอร์ที่กำลังไปส่งของ'
        : 'ไม่พบไรเดอร์ที่กำลังมาส่ง';

    // ... โค้ดคำนวณ Map options เหมือนเดิม ...
    LatLng initialCenter;
    double initialZoom;
    LatLngBounds? cameraBounds;

    if (_riderLocations.length > 1) {
      cameraBounds = LatLngBounds.fromPoints(_riderLocations.values.toList());
      initialCenter = cameraBounds.center;
      initialZoom = 10;
    } else if (_riderLocations.length == 1) {
      cameraBounds = null;
      initialCenter = _riderLocations.values.first;
      initialZoom = 16.0;
    } else {
      cameraBounds = null;
      initialCenter = _userCurrentLocation ?? const LatLng(16.2463, 103.2505);
      initialZoom = 15.0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle, style: GoogleFonts.prompt()), // <-- ใช้หัวข้อใหม่
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading || _userCurrentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : _riderLocations.isEmpty && !_isLoading
              ? Center(child: Text(noRiderText, style: GoogleFonts.prompt(fontSize: 16))) // <-- ใช้ข้อความใหม่
              : FlutterMap(
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: initialZoom,
                    initialCameraFit: cameraBounds != null 
                        ? CameraFit.bounds(
                            bounds: cameraBounds,
                            padding: const EdgeInsets.all(50.0),
                          )
                        : null,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.flash_dash_delivery',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _userCurrentLocation!,
                          child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                        ),
                        ..._riderLocations.values.map((latlng) {
                          return Marker(
                            point: latlng,
                            child: Icon(
                              Symbols.moped,
                              color: Colors.purple.shade700,
                              size: 40,
                              shadows: const [Shadow(color: Colors.black54, blurRadius: 10)],
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
    );
  }
}