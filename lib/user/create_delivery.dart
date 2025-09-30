import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';

import '../model/response/login_response.dart';
import '../model/response/searchphon_response.dart';
import 'main_user.dart';
import '../api/api_service.dart';
import '../api/api_service_image.dart';
import '../model/request/create_delivery_request.dart';

// สร้าง Model สำหรับเก็บข้อมูลสินค้า
class DeliveryItemDetails {
  final File image;
  final String description;

  DeliveryItemDetails({required this.image, required this.description});
}

class CreateDeliveryScreen extends StatefulWidget {
  final LoginResponse loginData;
  const CreateDeliveryScreen({super.key, required this.loginData});

  @override
  State<CreateDeliveryScreen> createState() => _CreateDeliveryScreenState();
}

class _CreateDeliveryScreenState extends State<CreateDeliveryScreen> {
   // --- 1. Services & Controllers ---
  final ApiService _apiService = ApiService();
  final ApiServiceImage _apiServiceImage = ApiServiceImage();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

 // --- 2. State สำหรับ UI ---
  final ValueNotifier<int> _selectedSenderAddressIndex = ValueNotifier<int>(0);
  final ValueNotifier<int> _selectedReceiverAddressIndex = ValueNotifier<int>(0);
  final ImagePicker _picker = ImagePicker();
  DeliveryItemDetails? _deliveryItem;
  File? _riderImage;
  bool _isLoading = false; // สำหรับ Loading ใน Dialog ยืนยัน
  bool _isSearching = false;
  String? _searchError;
  FindUserResponse? _foundUser;

  @override
  void dispose() {
    _selectedSenderAddressIndex.dispose();
    _selectedReceiverAddressIndex.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
  //ฟังก์ชันหลักสำหรับจัดการการสร้างการจัดส่ง ---
  Future<void> _handleCreateDelivery() async {
    // --- 3A. ตรวจสอบข้อมูลเบื้องต้น ---
    if (_foundUser == null || _searchController.text.isEmpty) {
      Get.snackbar('ข้อมูลไม่ครบถ้วน', 'กรุณาค้นหาและเลือกผู้รับก่อน');
      return;
    }
    if (_deliveryItem == null) {
      Get.snackbar('ข้อมูลไม่ครบถ้วน', 'กรุณาเพิ่มรายการสินค้าก่อน');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // --- 3B. อัปโหลดรูปภาพทั้งหมดก่อน ---
      final List<Future<String?>> uploadTasks = [
        _apiServiceImage.uploadProfileImage(_deliveryItem!.image),
        if (_riderImage != null) _apiServiceImage.uploadProfileImage(_riderImage!),
      ];

      final List<String?> uploadResults = await Future.wait(uploadTasks);
      final String itemImageFilename = uploadResults[0]!;
      final String? riderNoteImageFilename = uploadResults.length > 1 ? uploadResults[1] : null;

      // --- 3C. รวบรวมข้อมูลทั้งหมด ---
      final List<Address> senderAddresses = (widget.loginData.roleSpecificData as List).cast<Address>();
      final String senderAddressId = senderAddresses[_selectedSenderAddressIndex.value].id;
      final String receiverAddressId = _foundUser!.addresses[_selectedReceiverAddressIndex.value].id;

      final payload = CreateDeliveryPayload(
        receiverPhone: _searchController.text,
        senderAddressId: senderAddressId,
        receiverAddressId: receiverAddressId,
        itemDescription: _deliveryItem!.description,
        itemImageFilename: itemImageFilename,
        riderNoteImageFilename: riderNoteImageFilename,
      );

      // --- 3D. เรียก API เพื่อสร้างการจัดส่ง ---
      final message = await _apiService.createDelivery(
        token: widget.loginData.idToken,
        payload: payload,
      );
      
      Get.back(); // ปิด Dialog ยืนยัน
      Get.snackbar('สำเร็จ', message, backgroundColor: Colors.green, colorText: Colors.white);
      
      // กลับไปหน้าหลักหลังจากสร้างสำเร็จ
      Get.offAll(() => const MainUserPage(), arguments: widget.loginData);

    } catch (e) {
      Get.back(); // ปิด Dialog ยืนยัน
      Get.snackbar('เกิดข้อผิดพลาด', e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ฟังก์ชันจัดการการค้นหา ---
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (query.isNotEmpty && query.length >= 10) {
        _searchForUser(query);
      } else {
        setState(() {
          _foundUser = null;
          _searchError = null;
        });
      }
    });
  }

  Future<void> _searchForUser(String phone) async {
    setState(() {
      _isSearching = true;
      _searchError = null;
      _foundUser = null;
    });
    try {
      final result = await _apiService.findUserByPhone(
        token: widget.loginData.idToken,
        phone: phone,
      );
      setState(() {
        _foundUser = result;
        _selectedReceiverAddressIndex.value = 0; // Reset index ผู้รับ
      });
    } catch (e) {
      setState(() {
        _searchError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  // ฟังก์ชันจัดการรูปภาพ ---
  Future<File?> _pickImageFromSource(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      Get.snackbar('เกิดข้อผิดพลาด', 'ไม่สามารถเลือกรูปภาพได้: $e');
    }
    return null;
  }

  void _showImageSourcePicker(Function(File) onImageSelected) {
    Get.dialog(
      AlertDialog(
        title: Text('เลือกรูปภาพ', style: GoogleFonts.prompt()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('เลือกจากคลังภาพ', style: GoogleFonts.prompt()),
              onTap: () async {
                Get.back();
                final image = await _pickImageFromSource(ImageSource.gallery);
                if (image != null) onImageSelected(image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text('ถ่ายภาพ', style: GoogleFonts.prompt()),
              onTap: () async {
                Get.back();
                final image = await _pickImageFromSource(ImageSource.camera);
                if (image != null) onImageSelected(image);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันจัดการ Dialog ต่างๆ ---

  // Dialog สำหรับ "เพิ่มรายการใหม่"
  Future<void> _showAddItemDialog() async {
    File? itemImage;
    final descriptionController = TextEditingController();

    final result = await Get.dialog<DeliveryItemDetails>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        child: StatefulBuilder(
          // ใช้ StatefulBuilder เพื่ออัปเดต UI ภายใน Dialog
          builder: (context, setDialogState) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Container หลักสำหรับเนื้อหา
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5), // สีพื้นหลังเทาอ่อน
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Title ---
                        Center(
                          child: Text(
                            'เพิ่มรายการใหม่',
                            style: GoogleFonts.prompt(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4CAF50),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- รูปสินค้า ---
                        Text(
                          'รูปสินค้า',
                          style: GoogleFonts.prompt(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: GestureDetector(
                            onTap: () => _showImageSourcePicker(
                              (image) =>
                                  setDialogState(() => itemImage = image),
                            ),
                            child: Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade300),
                                image: itemImage != null
                                    ? DecorationImage(
                                        image: FileImage(itemImage!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: itemImage == null
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_outlined,
                                            size: 40,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 4),
                                          Icon(
                                            Icons.add_circle_outline,
                                            size: 20,
                                            color: Colors.grey[400],
                                          ),
                                        ],
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- รายละเอียดสินค้า ---
                        Text(
                          'รายละเอียดสินค้า :',
                          style: GoogleFonts.prompt(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: descriptionController,
                          decoration: InputDecoration(
                            hintText: 'รายละเอียดสินค้า',
                            hintStyle: GoogleFonts.prompt(),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 32),

                        // --- ปุ่มเพิ่มรายการ ---
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (itemImage != null &&
                                  descriptionController.text.isNotEmpty) {
                                final newItem = DeliveryItemDetails(
                                  image: itemImage!,
                                  description: descriptionController.text,
                                );
                                Get.back(result: newItem);
                              } else {
                                Get.snackbar(
                                  'ผิดพลาด',
                                  'กรุณาใส่รูปและรายละเอียดสินค้า',
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3498DB),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              'เพิ่มรายการ',
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
                // --- ปุ่ม Close ---
                Positioned(
                  top: -10,
                  right: -10,
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    if (result != null) {
      setState(() => _deliveryItem = result);
    }
  }

  void _showItemDetailDialog(DeliveryItemDetails item) {
    Get.dialog(
      // ใช้ Dialog widget เพื่อให้เราควบคุม UI ได้เต็มที่
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent, // ทำให้พื้นหลัง dialog หลักโปร่งใส
        child: Stack(
          // clipBehavior: Clip.none, // อนุญาตให้ปุ่ม Close อยู่นอกกรอบได้เล็กน้อย
          children: [
            // Container หลักสำหรับเนื้อหา
            Container(
              margin: const EdgeInsets.only(
                top: 8,
                right: 8,
              ), // เว้นที่ให้ปุ่ม Close
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- Header สีเขียว ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),

                      child: Text(
                        'รายละเอียด',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.prompt(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                    // --- Content สีขาว ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              item.image,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'รายละเอียดสินค้า :',
                            style: GoogleFonts.prompt(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              item.description,
                              style: GoogleFonts.prompt(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // --- ปุ่ม Close (กากบาท) ---
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog สำหรับ "ยืนยันการจัดส่ง"
  void _showConfirmationDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(child: Image.asset('assets/image/confusrd.png', height: 60)),
        content: Text('ต้องการจัดส่งสินค้าใช่หรือไม่?', textAlign: TextAlign.center, style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => Get.back(), child: Text('ยกเลิก', style: GoogleFonts.prompt()))),
              const SizedBox(width: 16),
              Expanded(
                child: StatefulBuilder(
                  builder: (context, setDialogState) {
                    return ElevatedButton(
                      onPressed: _isLoading ? null : () {
                        setDialogState(() {});
                        _handleCreateDelivery();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF69F0AE)),
                      child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                          : Text('ยืนยัน', style: GoogleFonts.prompt()),
                    );
                  }
                ),
              ),
            ],
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      ),
       barrierDismissible: !_isLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Address> senderAddresses = (widget.loginData.roleSpecificData as List).cast<Address>();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFC4DFCE), Color(0xFFDDEBE3), Color(0xFFF6F8F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Get.off(() => const MainUserPage(), arguments: widget.loginData, transition: Transition.leftToRight),
          ),
          title: Text('สร้างการจัดส่งใหม่', style: GoogleFonts.prompt(fontWeight: FontWeight.w600, color: Colors.black87)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('ที่อยู่ผู้ส่ง (ต้นทาง)'),
              const SizedBox(height: 8),
              _buildAddressSelection(
                addresses: senderAddresses,
                notifier: _selectedSenderAddressIndex,
                emptyListMessage: 'คุณยังไม่มีที่อยู่, กรุณาไปที่หน้าโปรไฟล์เพื่อเพิ่ม',
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('ผู้รับ (ปลายทาง)'),
              const SizedBox(height: 8),
              _buildReceiverField(),
              _buildSearchResult(),
              if (_foundUser != null) ...[
                const SizedBox(height: 12),
                _buildAddressSelection(
                  addresses: _foundUser!.addresses,
                  notifier: _selectedReceiverAddressIndex,
                  emptyListMessage: 'ผู้รับยังไม่มีที่อยู่',
                ),
              ],
              const SizedBox(height: 24),
              _buildSectionTitle('รายการ'),
              const SizedBox(height: 8),
              if (_deliveryItem != null) _buildItemCard(_deliveryItem!) else _buildAddItemButton(),
              const SizedBox(height: 24),
              _buildSectionTitle('ถ่ายรูปบอกไรเดอร์'),
              const SizedBox(height: 8),
              _buildRiderPhotoPicker(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showConfirmationDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF69F0AE),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('สร้างการจัดส่ง', style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // --- Widget ย่อยๆ สำหรับสร้าง UI ---

  Widget _buildItemCard(DeliveryItemDetails item) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: InkWell(
        // ใช้ InkWell ห่อ child ของ Card
        onTap: () =>
            _showItemDetailDialog(item), // <-- เพิ่ม onTap ให้เรียก Dialog
        borderRadius: BorderRadius.circular(
          12,
        ), // ทำให้ ripple effect ขอบมนตาม Card
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  item.image,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.description,
                  style: GoogleFonts.prompt(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.receipt_long_outlined, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddItemButton() {
    return GestureDetector(
      onTap: _showAddItemDialog,
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFB3E59F),
            child: Icon(Icons.add, color: Colors.black54, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'เพิ่มรายการใหม่',
            style: GoogleFonts.prompt(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderPhotoPicker() {
    return GestureDetector(
      onTap: () => _showImageSourcePicker(
        (image) => setState(() => _riderImage = image),
      ),
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          image: _riderImage != null
              ? DecorationImage(
                  image: FileImage(_riderImage!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _riderImage == null
            ? const Center(
                child: Icon(
                  Icons.camera_alt_outlined,
                  size: 50,
                  color: Colors.grey,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildReceiverField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        hintText: 'ค้นหาด้วยหมายเลขโทรศัพท์',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _isSearching
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSearchResult() {
    if (_searchError != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          _searchError!,
          style: TextStyle(color: Colors.red.shade700),
        ),
      );
    }
    if (_foundUser != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Text(
          'ผู้รับ: ${_foundUser!.name}',
          style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }
    return const SizedBox.shrink(); // ถ้าไม่มีอะไรให้แสดง ก็ไม่ต้องแสดงอะไรเลย
  }

  Widget _buildAddressSelection({
    required List<Address> addresses,
    required ValueNotifier<int> notifier,
    required String emptyListMessage,
  }) {
    if (addresses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Text(emptyListMessage)),
      );
    }
    return ValueListenableBuilder<int>(
      valueListenable: notifier,
      builder: (context, selectedIndex, child) {
        return Column(
          children: List.generate(addresses.length, (index) {
            final address = addresses[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildAddressCard(
                title: 'ที่อยู่ ${index + 1}',
                address: address.detail,
                isSelected: selectedIndex == index,
                onTap: () => notifier.value = index,
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildAddressCard({
    required String title,
    required String address,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // <-- จัดให้อยู่ชิดบน
          children: [
            // Icon
            Padding(
              padding: const EdgeInsets.only(
                top: 2.0,
              ), // <-- ขยับไอคอนลงเล็กน้อย
              child: Icon(
                Icons.location_on_outlined,
                color: isSelected ? const Color(0xFF4CAF50) : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            // **** ใช้ Expanded ห่อ Column ****
            // เพื่อบอกให้ Column นี้ใช้พื้นที่ที่เหลือทั้งหมด
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.prompt(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.black87 : Colors.grey[700],
                    ),
                  ),
                  // Text ที่อยู่จะสามารถตัดบรรทัดได้เองโดยอัตโนมัติ
                  Text(
                    address,
                    style: GoogleFonts.prompt(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
