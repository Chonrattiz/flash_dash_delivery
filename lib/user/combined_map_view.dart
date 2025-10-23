import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart'; // Import symbols

import '../model/response/delivery_list_response.dart';
import '../model/response/login_response.dart';

class CombinedMapViewScreen extends StatefulWidget {
  final LoginResponse loginData;
  final List<Delivery> sentDeliveries;
  final List<Delivery> receivedDeliveries;
  final int selectedTabIndex;

  const CombinedMapViewScreen({
    super.key,
    required this.loginData,
    required this.sentDeliveries,
    required this.receivedDeliveries,
    required this.selectedTabIndex,
  });

  @override
  State<CombinedMapViewScreen> createState() => _CombinedMapViewScreenState();
}

class _CombinedMapViewScreenState extends State<CombinedMapViewScreen> {
  final Map<String, LatLng> _riderLocations = {};
  final List<StreamSubscription> _locationSubscriptions = [];
  bool _isLoading = true;
  LatLng? _userCurrentLocation;
  List<Delivery> _activeDeliveries = [];

  final List<Color> _orderColors = [
    Colors.red.shade700,
    Colors.blue.shade700,
    Colors.green.shade700,
    Colors.orange.shade700,
    Colors.teal.shade700,
    Colors.indigo.shade700,
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocationAndInitialize();
  }

  // (โค้ดส่วน _getUserLocationAndInitialize และ _initializeRiderListeners เหมือนเดิม)
  Future<void> _getUserLocationAndInitialize() async {
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
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() =>
          _userCurrentLocation = LatLng(position.latitude, position.longitude));
    } catch (e) {
      setState(() => _userCurrentLocation = const LatLng(16.2463, 103.2505));
    } finally {
      _initializeRiderListeners();
    }
  }

  void _initializeRiderListeners() {
    final relevantDeliveries = widget.selectedTabIndex == 0
        ? widget.sentDeliveries
        : widget.receivedDeliveries;
    final activeDeliveriesList = relevantDeliveries
        .where((d) =>
            (d.status == 'accepted' || d.status == 'picked_up') &&
            d.riderUID != null &&
            d.riderUID!.isNotEmpty)
        .toList();
    setState(() {
      _activeDeliveries = activeDeliveriesList;
    });
    final uniqueRiderIds = _activeDeliveries.map((d) => d.riderUID!).toSet();
    if (uniqueRiderIds.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    for (final riderId in uniqueRiderIds) {
      final stream = FirebaseFirestore.instance
          .collection('riders')
          .doc(riderId)
          .snapshots();
      final subscription = stream.listen((snapshot) {
        if (mounted && snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          if (data.containsKey('currentLocation')) {
            final GeoPoint location = data['currentLocation'];
            setState(() {
              _riderLocations[riderId] =
                  LatLng(location.latitude, location.longitude);
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
    final appBarTitle = widget.selectedTabIndex == 0
        ? 'ไรเดอร์ที่กำลังไปส่งของ'
        : 'ไรเดอร์ที่กำลังมาส่ง';
    final noRiderText = widget.selectedTabIndex == 0
        ? 'ไม่พบไรเดอร์ที่กำลังไปส่งของ'
        : 'ไม่พบไรเดอร์ที่กำลังมาส่ง';

    // ++ 1. สร้าง Map เพื่อเก็บสีสำหรับ Rider แต่ละคน (จาก Order แรกที่เจอ) ++
    final Map<String, Color> riderColors = {};
    for (var entry in _activeDeliveries.asMap().entries) {
      final index = entry.key;
      final delivery = entry.value;
      final riderId = delivery.riderUID;
      if (riderId != null && !riderColors.containsKey(riderId)) {
        riderColors[riderId] = _orderColors[index % _orderColors.length];
      }
    }

    // (โค้ดคำนวณ Map options เหมือนเดิม)
    LatLng initialCenter;
    double initialZoom;
    LatLngBounds? cameraBounds;
    List<LatLng> allPoints = [];
    // if (_userCurrentLocation != null) { allPoints.add(_userCurrentLocation!); } // เอาตำแหน่ง User ออก
    allPoints.addAll(_riderLocations.values);
    for (var delivery in _activeDeliveries) {
      allPoints.add(LatLng(delivery.senderAddress.coordinates.latitude,
          delivery.senderAddress.coordinates.longitude));
      allPoints.add(LatLng(delivery.receiverAddress.coordinates.latitude,
          delivery.receiverAddress.coordinates.longitude));
    }
    if (allPoints.length > 1) {
      cameraBounds = LatLngBounds.fromPoints(allPoints);
      initialCenter = cameraBounds.center;
      initialZoom = 10;
    } else if (allPoints.length == 1) {
      cameraBounds = null;
      initialCenter = allPoints.first;
      initialZoom = 15.0;
    } else {
      cameraBounds = null;
      initialCenter = const LatLng(16.2463, 103.2505);
      initialZoom = 15.0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle, style: GoogleFonts.prompt()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading || _userCurrentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : _activeDeliveries.isEmpty && _riderLocations.isEmpty && !_isLoading
              ? Center(
                  child: Text(noRiderText,
                      style: GoogleFonts.prompt(fontSize: 16)))
              : FlutterMap(
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: initialZoom,
                    initialCameraFit: cameraBounds != null
                        ? CameraFit.bounds(
                            bounds: cameraBounds,
                            padding: const EdgeInsets.all(50.0))
                        : null,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.flash_dash_delivery',
                    ),
                    MarkerLayer(
                      markers: [
                        // Markers ตำแหน่งผู้ส่งและผู้รับ (เหมือนเดิม)
                        ..._activeDeliveries.asMap().entries.expand((entry) {
                          int index = entry.key;
                          Delivery delivery = entry.value;
                          final color =
                              _orderColors[index % _orderColors.length];
                          final senderMarker = _buildLocationMarker(
                              LatLng(
                                  delivery.senderAddress.coordinates.latitude,
                                  delivery.senderAddress.coordinates.longitude),
                              Symbols.deployed_code_account,
                              color);
                          final receiverMarker = _buildLocationMarker(
                              LatLng(
                                  delivery.receiverAddress.coordinates.latitude,
                                  delivery
                                      .receiverAddress.coordinates.longitude),
                              Symbols.approval_delegation,
                              color);
                          return [senderMarker, receiverMarker];
                        }).toList(),

                        // ++ 2. แก้ไข Markers ตำแหน่งไรเดอร์ ให้ใช้สีจาก Map ที่สร้างไว้ ++
                        ..._riderLocations.entries.map((entry) {
                          final riderId = entry.key;
                          final latlng = entry.value;
                          // ดึงสีของ Rider คนนี้ (ถ้าไม่มี ใช้สีม่วงเป็น default)
                          final riderColor =
                              riderColors[riderId] ?? Colors.purple.shade700;

                          return Marker(
                            point: latlng,
                            width: 80,
                            height: 80,
                            child: Icon(
                              Symbols.moped,
                              // ++ 3. ใช้สีที่ดึงมา ++
                              color: riderColor,
                              size: 40,
                              shadows: const [
                                Shadow(color: Colors.black54, blurRadius: 10)
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
    );
  }

  // (Helper function _buildLocationMarker เหมือนเดิม)
  Marker _buildLocationMarker(LatLng point, IconData icon, Color color) {
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
                    offset: Offset(0, 4)),
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
