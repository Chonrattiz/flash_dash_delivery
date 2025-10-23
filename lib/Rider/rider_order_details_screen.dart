import 'package:flash_dash_delivery/Rider/delivery_tracking_screen.dart';
import 'package:flash_dash_delivery/Rider/map_preview_screen.dart'; // Make sure this import is correct
import 'package:flash_dash_delivery/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; // Import google_fonts

import '../config/image_config.dart'; // Make sure this import exists and is correct
import '../model/response/delivery_list_response.dart';
import '../model/response/login_response.dart';

class RiderOrderDetailsScreen extends StatefulWidget {
  const RiderOrderDetailsScreen({super.key});

  @override
  State<RiderOrderDetailsScreen> createState() =>
      _RiderOrderDetailsScreenState();
}

class _RiderOrderDetailsScreenState extends State<RiderOrderDetailsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // --- Function to show success dialog and navigate ---
  void _showSuccessAndNavigateDialog(
    Delivery delivery,
    LoginResponse loginData,
  ) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('สำเร็จ!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 50),
            const SizedBox(height: 16),
            Text('คุณรับงานสำเร็จแล้ว',
                style: GoogleFonts.prompt()), // Use GoogleFonts
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              // Use Get.off to go to the new screen and remove the current one
              Get.off(
                () => DeliveryTrackingScreen(
                  delivery: delivery,
                  loginData: loginData,
                ),
              );
            },
            child: Text('ตกลง',
                style: GoogleFonts.prompt(fontSize: 16)), // Use GoogleFonts
          ),
        ],
      ),
      barrierDismissible: false, // Prevent dismissing by tapping outside
    );
  }

  // --- Function to call the API ---
  Future<void> _acceptJob(
    String token,
    String deliveryId,
    Delivery delivery,
    LoginResponse loginData,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.acceptDelivery(token: token, deliveryId: deliveryId);

      if (mounted) {
        _showSuccessAndNavigateDialog(delivery, loginData);
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'เกิดข้อผิดพลาด',
          e.toString().replaceFirst('Exception: ', ''),
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- Confirmation Dialog ---
  void _showConfirmationDialog(LoginResponse loginData, Delivery delivery) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('ยืนยันการรับงาน',
            style: GoogleFonts.prompt()), // Use GoogleFonts
        content: Text('คุณต้องการรับงานนี้ใช่หรือไม่?',
            style: GoogleFonts.prompt()), // Use GoogleFonts
        actions: [
          TextButton(
              child: Text('ยกเลิก',
                  style: GoogleFonts.prompt()), // Use GoogleFonts
              onPressed: () => Get.back()),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              foregroundColor: Colors.white,
            ),
            child:
                Text('ยืนยัน', style: GoogleFonts.prompt()), // Use GoogleFonts
            onPressed: () {
              Get.back();
              _acceptJob(loginData.idToken, delivery.id, delivery, loginData);
            },
          ),
        ],
      ),
    );
  }

  // --- Function to show image preview dialog ---
  void _showImagePreviewDialog(String imageUrl) {
    Get.dialog(
      AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 200,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                alignment: Alignment.center,
                child: Text('ไม่สามารถโหลดรูปภาพได้',
                    style: GoogleFonts.prompt()), // Use GoogleFonts
              );
            },
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> arguments;

    try {
      arguments = Get.arguments as Map<String, dynamic>;
    } catch (e) {
      return Scaffold(
        // Return Scaffold for consistency
        appBar: AppBar(
            title:
                Text('Error', style: GoogleFonts.prompt())), // Use GoogleFonts
        body: Center(
            child: Text('Error: Invalid arguments passed.',
                style: GoogleFonts.prompt())), // Use GoogleFonts
      );
    }

    final LoginResponse? loginData = arguments['loginData'];
    final Delivery? deliveryData = arguments['delivery'];

    // Check for null data after casting
    if (deliveryData == null || loginData == null) {
      return Scaffold(
        // Return Scaffold for consistency
        appBar: AppBar(
            title:
                Text('Error', style: GoogleFonts.prompt())), // Use GoogleFonts
        body: Center(
          child: Text('Error: Data not found! Check arguments.',
              style: GoogleFonts.prompt()), // Use GoogleFonts
        ),
      );
    }

    final String riderUsername = loginData.userProfile.name; // Safe now

    return Scaffold(
      backgroundColor: const Color(0xFFFDEBED),
      body: Column(
        children: [
          _buildCustomAppBar(username: riderUsername),
          Transform.translate(
            offset: const Offset(0.0, -24.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'รายละเอียด',
                style: GoogleFonts.prompt(
                  // Use GoogleFonts
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0FC964),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: _buildDetailsCard(
                delivery: deliveryData, // Already checked for null
                loginData: loginData, // Already checked for null
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard({
    required Delivery delivery,
    required LoginResponse loginData,
  }) {
    final String senderImageUrl = delivery.senderImageProfile;
    final String receiverImageUrl = delivery.receiverImageProfile;
    final String itemImageUrl = delivery.itemImage;
    final String riderNoteImageUrl = delivery.riderNoteImage;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender Info
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: senderImageUrl.isNotEmpty
                      ? NetworkImage(senderImageUrl)
                      : null,
                  child: senderImageUrl.isEmpty
                      ? const Icon(Icons.person, size: 30, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      delivery.senderName,
                      style: GoogleFonts.prompt(
                        // Use GoogleFonts
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'โทรศัพท์ ${delivery.senderUID}',
                      style: GoogleFonts.prompt(
                          color: Colors.grey, fontSize: 14), // Use GoogleFonts
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 30),

            // Location Timeline
            _buildLocationTimeline(
              pickupLocation: delivery.senderAddress.detail,
              deliveryLocation: delivery.receiverAddress.detail,
            ),
            const SizedBox(height: 20),

            // Receiver Info
            const Divider(height: 30),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: receiverImageUrl.isNotEmpty
                      ? NetworkImage(receiverImageUrl)
                      : null,
                  child: receiverImageUrl.isEmpty
                      ? const Icon(Icons.person, size: 30, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      delivery.receiverName,
                      style: GoogleFonts.prompt(
                        // Use GoogleFonts
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'โทรศัพท์ ${delivery.receiverUID}',
                      style: GoogleFonts.prompt(
                          color: Colors.grey, fontSize: 14), // Use GoogleFonts
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Pickup image(s)',
              style: GoogleFonts.prompt(
                // Use GoogleFonts
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF77869E),
              ),
            ),
            const SizedBox(height: 10),
            // --- Item Images Row ---
            Row(
              children: [
                if (itemImageUrl.isNotEmpty)
                  _buildItemImage(
                      imageUrl: itemImageUrl,
                      onTap: () => _showImagePreviewDialog(itemImageUrl)),
                if (itemImageUrl.isNotEmpty && riderNoteImageUrl.isNotEmpty)
                  const SizedBox(width: 10),
                if (riderNoteImageUrl.isNotEmpty)
                  _buildItemImage(
                      imageUrl: riderNoteImageUrl,
                      onTap: () => _showImagePreviewDialog(riderNoteImageUrl)),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'รายละเอียดสินค้า',
              style: GoogleFonts.prompt(
                  fontSize: 16, fontWeight: FontWeight.bold), // Use GoogleFonts
            ),
            const SizedBox(height: 4),
            Text(
              delivery.itemDescription,
              style: GoogleFonts.prompt(
                  fontSize: 14, color: Colors.black87), // Use GoogleFonts
            ),
            const SizedBox(height: 10),
            // --- View Map Button ---
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  Get.to(
                    () => MapPreviewScreen(
                      delivery: delivery,
                    ),
                    transition: Transition.rightToLeft,
                  );
                },
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Text(
                  'View Map Route',
                  style: GoogleFonts.prompt(
                    // Use GoogleFonts
                    color: const Color(0xFF006970),
                    fontSize: 15,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Accept Job Button ---
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      _showConfirmationDialog(loginData, delivery);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    )
                  : Text('รับงาน',
                      style:
                          GoogleFonts.prompt(fontSize: 18)), // Use GoogleFonts
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildLocationTimeline({
    required String pickupLocation,
    required String deliveryLocation,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, color: Colors.red, size: 20),
            ...List.generate(
              5,
              (index) => Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                width: 3,
                height: 3,
                decoration: const BoxDecoration(
                  color: Color(0xFF27B777),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF27B777), width: 1.5),
              ),
              child: const Icon(
                Icons.circle,
                color: Color(0xFF27B777),
                size: 8,
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pickup Location',
                style: GoogleFonts.prompt(
                    color: const Color(0xFF77869E),
                    fontSize: 12), // Use GoogleFonts
              ),
              const SizedBox(height: 2),
              Text(
                pickupLocation,
                style: GoogleFonts.prompt(
                  // Use GoogleFonts
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Delivery Location',
                style: GoogleFonts.prompt(
                    color: const Color(0xFF77869E),
                    fontSize: 12), // Use GoogleFonts
              ),
              const SizedBox(height: 2),
              Text(
                deliveryLocation,
                style: GoogleFonts.prompt(
                  // Use GoogleFonts
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemImage(
      {required String imageUrl, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildPlaceholderImage(); // Show placeholder while loading
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderImage(); // Show placeholder on error
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 32),
    );
  }

  Widget _buildCustomAppBar({required String username, String? imageUrl}) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      child: Container(
        height: 186.0,
        color: const Color(0xFFCEF1C3),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.black54,
                  ),
                  onPressed: () => Get.back(),
                ),
                // --- Centered Title ---
                // Use Expanded and Center to ensure title stays centered
                // regardless of IconButton width
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Flash-Dash',
                          style: GoogleFonts.prompt(
                            // Use GoogleFonts
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Delivery',
                          style: GoogleFonts.prompt(
                              fontSize: 18,
                              color: Colors.black54), // Use GoogleFonts
                        ),
                      ],
                    ),
                  ),
                ),
                // Add SizedBox to balance the IconButton on the left if needed
                // Or keep empty if title centering works well
                const SizedBox(width: 48), // Match IconButton width approx
              ],
            ),
          ),
        ),
      ),
    );
  }
} // End of _RiderOrderDetailsScreenState
