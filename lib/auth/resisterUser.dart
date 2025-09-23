import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flash_dash_delivery/auth/welcome.dart';
import 'package:get/get.dart';

// --- นี่คือโค้ดของหน้า Sign up as User ทั้งหมด ---
class SignUpUserScreen extends StatefulWidget {
  const SignUpUserScreen({super.key});

  @override
  State<SignUpUserScreen> createState() => _SignUpUserScreenState();
}

class _SignUpUserScreenState extends State<SignUpUserScreen> {
  // ตัวแปรสำหรับจัดการแผนที่และตำแหน่ง
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  String _addressText = 'Tap map or use button to add address';
  final String _thunderforestApiKey = 'cd5e3bc759644565a4adf9cd53d143be';

  /// ฟังก์ชันสำหรับดึงตำแหน่งปัจจุบัน
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location services are disabled. Please enable the services',
          ),
        ),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permissions are permanently denied, we cannot request permissions.',
          ),
        ),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _updateAddressText();
        _mapController.move(_selectedLocation!, 15.0);
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  /// ฟังก์ชันสำหรับจัดการเมื่อมีการแตะบนแผนที่
  void _handleMapTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _selectedLocation = latlng;
      _updateAddressText();
    });
  }

  /// อัปเดตข้อความในช่อง Address
  void _updateAddressText() {
    if (_selectedLocation != null) {
      _addressText =
          'Lat: ${_selectedLocation!.latitude.toStringAsFixed(4)}, Lon: ${_selectedLocation!.longitude.toStringAsFixed(4)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFC4DFCE), // C4DFCE
              Color(0xFFDDEBE3), // DDEBE3
              Color(0xFFF6F8F7), // F6F8F7
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back), // ใช้ไอคอนที่ต้องการ
            onPressed: () {
              Get.to(() =>  WelcomePage());
            },
          ),
          title: const Text(
            'Sign up as User',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.camera_alt,
                          color: Color(0xFF4CAF50),
                          size: 40,
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_circle,
                          color: Color(0xFF4CAF50),
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _buildTextField(
                  icon: Icons.phone_outlined,
                  hintText: 'Phone Number',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  icon: Icons.lock_outline,
                  hintText: 'Password',
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(icon: Icons.person_outline, hintText: 'Name'),
                const SizedBox(height: 16),

                // --- นี่คือช่องที่เพิ่มเข้ามา ---
                _buildTextField(icon: Icons.home_outlined, hintText: 'Address'),
                const SizedBox(height: 16),

                // ---------------------------
                _buildTextField(
                  icon: Icons.location_on_outlined,
                  hintText: _addressText,
                ),
                const SizedBox(height: 16),

                // --- แผนที่จริง ---
                SizedBox(
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: const LatLng(
                          13.7563,
                          100.5018,
                        ), // Default to Bangkok
                        initialZoom: 6.0,
                        onTap: _handleMapTap, // Handle map taps
                      ),
                      children: [
                        TileLayer(
                          // --- นี่คือส่วนที่แก้ไข ---
                          urlTemplate:
                              'https://{s}.tile.thunderforest.com/atlas/{z}/{x}/{y}.png?apikey={apikey}',
                          additionalOptions: {'apikey': _thunderforestApiKey},
                          // -------------------------
                        ),
                        if (_selectedLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedLocation!,
                                width: 80,
                                height: 80,
                                child: const Icon(
                                  Icons.location_pin,
                                  size: 50,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Add Another Address',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement sign up logic for user
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF69F0AE),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required IconData icon,
    required String hintText,
    bool obscureText = false,
  }) {
    // ใช้ key เพื่อให้ Flutter รู้ว่าต้อง re-render เมื่อ hintText เปลี่ยน
    return TextFormField(
      key: ValueKey(hintText),
      initialValue: hintText.startsWith('Lat:') ? hintText : null,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText.startsWith('Lat:') ? null : hintText,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
      ),
      readOnly: hintText.startsWith('Lat:'),
    );
  }
}
