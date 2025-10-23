import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async'; // --- [คงไว้] --- ยังคงใช้สำหรับ Debounce การค้นหา

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
  // --- 1. Services & Controllers (คงเดิม) ---
  final ApiService _apiService = ApiService();
  final ImageUploadService _imageUploadService = ImageUploadService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // --- 2. State สำหรับ UI (คงเดิม) ---
  final ValueNotifier<int> _selectedSenderAddressIndex = ValueNotifier<int>(0);
  final ValueNotifier<int> _selectedReceiverAddressIndex =
      ValueNotifier<int>(0);
  final ImagePicker _picker = ImagePicker();
  DeliveryItemDetails? _deliveryItem;
  File? _riderImage;
  bool _isLoading = false; // สำหรับ Loading ใน Dialog ยืนยัน
  bool _isSearching = false; // Loading ตอนยิง API ค้นหา
  String? _searchError;

  // --- [แก้ไข] --- 3. State สำหรับข้อมูล (รวมร่าง) ---
  // ลบ _foundUser แล้วใช้ _selectedReceiver แทน
  // FindUserResponse? _foundUser;
  FindUserResponse? _selectedReceiver; // State กลางสำหรับเก็บผู้รับที่ถูกเลือก

  // State ใหม่สำหรับลิสต์ลูกค้า
  bool _isUsersLoading = true; // เปิดมาให้โหลดลิสต์ก่อน
  List<FindUserResponse> _allCustomers = [];

  // --- [แก้ไข] ---
  @override
  void initState() {
    super.initState();
    // เรียกฟังก์ชันดึงลูกค้าทั้งหมด
    _fetchAllCustomers();
  }

  // --- [แก้ไข] --- เพิ่มฟังก์ชันสำหรับดึงลูกค้าทั้งหมด (ที่ไม่ใช่ตัวเอง)
  Future<void> _fetchAllCustomers() async {
    try {
      final customers = await _apiService.getAllCustomers(
        token: widget.loginData.idToken,
      );
      if (mounted) {
        setState(() {
          _allCustomers = customers;
          _isUsersLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUsersLoading = false;
        });
      }
      // ไม่ต้องโชว์ Snackbar ก็ได้ เพราะอาจจะแค่เน็ตไม่ดี
      print('Failed to load customer list: $e');
    }
  }

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
    // --- [แก้ไข] --- 3A. ตรวจสอบข้อมูลเบื้องต้น
    if (_selectedReceiver == null) {
      Get.snackbar('ข้อมูลไม่ครบถ้วน', 'กรุณาค้นหาหรือเลือกผู้รับก่อน');
      return;
    }
    if (_deliveryItem == null) {
      Get.snackbar('ข้อมูลไม่ครบถ้วน', 'กรุณาเพิ่มรายการสินค้าก่อน');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // --- 3B. อัปโหลดรูปภาพทั้งหมดก่อน (เหมือนเดิม) ---
      final List<Future<String?>> uploadTasks = [
        _imageUploadService.uploadImageToCloudinary(_deliveryItem!.image),
        if (_riderImage != null)
          _imageUploadService.uploadImageToCloudinary(_riderImage!),
      ];

      final List<String?> uploadResults = await Future.wait(uploadTasks);
      final String itemImageFilename = uploadResults[0]!;
      final String? riderNoteImageFilename =
          uploadResults.length > 1 ? uploadResults[1] : null;

      // --- [แก้ไข] --- 3C. รวบรวมข้อมูลทั้งหมด
      final List<Address> senderAddresses =
          (widget.loginData.roleSpecificData as List).cast<Address>();
      final String senderAddressId =
          senderAddresses[_selectedSenderAddressIndex.value].id;

      // ใช้ _selectedReceiver ที่เป็น State กลาง
      final String receiverAddressId =
          _selectedReceiver!.addresses[_selectedReceiverAddressIndex.value].id;

      final payload = CreateDeliveryPayload(
        receiverPhone: _selectedReceiver!.phone, // ใช้เบอร์จาก State กลาง
        senderAddressId: senderAddressId,
        receiverAddressId: receiverAddressId,
        itemDescription: _deliveryItem!.description,
        itemImageFilename: itemImageFilename,
        riderNoteImageFilename: riderNoteImageFilename,
      );

      // --- 3D. เรียก API เพื่อสร้างการจัดส่ง (เหมือนเดิม) ---
      final message = await _apiService.createDelivery(
        token: widget.loginData.idToken,
        payload: payload,
      );

      Get.back(); // ปิด Dialog ยืนยัน
      Get.snackbar('สำเร็จ', message,
          backgroundColor: Colors.green, colorText: Colors.white);

      // กลับไปหน้าหลักหลังจากสร้างสำเร็จ
      Get.offAll(() => const MainUserPage(), arguments: widget.loginData);
    } catch (e) {
      Get.back(); // ปิด Dialog ยืนยัน
      Get.snackbar(
          'เกิดข้อผิดพลาด', e.toString().replaceAll('Exception: ', ''));
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
          // --- [แก้ไข] --- เคลียร์ State กลาง เมื่อช่องค้นหาว่าง
          _selectedReceiver = null;
          _searchError = null;
        });
      }
    });
  }

  Future<void> _searchForUser(String phone) async {
    setState(() {
      _isSearching = true;
      _searchError = null;
      _selectedReceiver =
          null; // --- [แก้ไข] --- เคลียร์ State กลาง ทุกครั้งที่ค้นหา
    });
    try {
      final result = await _apiService.findUserByPhone(
        token: widget.loginData.idToken,
        phone: phone,
      );
      setState(() {
        _selectedReceiver = result; // --- [แก้ไข] --- อัปเดต State กลาง
        _selectedReceiverAddressIndex.value = 0; // Reset index ผู้รับ
      });
    } catch (e) {
      setState(() {
        _searchError = e.toString().replaceAll('Exception: ', '');
        // _selectedReceiver ถูกเคลียร์ไปตั้งแต่ตอนเริ่มค้นหาแล้ว
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  // --- (ฟังก์ชันจัดการรูปภาพ _pickImageFromSource, _showImageSourcePicker เหมือนเดิม) ---
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

  // --- (ฟังก์ชันจัดการ Dialog ต่างๆ _showAddItemDialog, _showItemDetailDialog, _showConfirmationDialog เหมือนเดิม) ---
  Future<void> _showAddItemDialog() async {
    File? itemImage;
    final descriptionController = TextEditingController();

    final result = await Get.dialog<DeliveryItemDetails>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(
                top: 8,
                right: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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

  void _showConfirmationDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            Center(child: Image.asset('assets/image/confusrd.png', height: 60)),
        content: Text('ต้องการจัดส่งสินค้าใช่หรือไม่?',
            textAlign: TextAlign.center,
            style:
                GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          Row(
            children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: Text('ยกเลิก', style: GoogleFonts.prompt()))),
              const SizedBox(width: 16),
              Expanded(
                child: StatefulBuilder(builder: (context, setDialogState) {
                  return ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setDialogState(() {});
                            _handleCreateDelivery();
                          },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF69F0AE)),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 3))
                        : Text('ยืนยัน', style: GoogleFonts.prompt()),
                  );
                }),
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
    final List<Address> senderAddresses =
        (widget.loginData.roleSpecificData as List).cast<Address>();

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
            onPressed: () => Get.off(() => const MainUserPage(),
                arguments: widget.loginData,
                transition: Transition.leftToRight),
          ),
          title: Text('สร้างการจัดส่งใหม่',
              style: GoogleFonts.prompt(
                  fontWeight: FontWeight.w600, color: Colors.black87)),
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
                emptyListMessage:
                    'คุณยังไม่มีที่อยู่, กรุณาไปที่หน้าโปรไฟล์เพื่อเพิ่ม',
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('ผู้รับ (ปลายทาง)'),
              const SizedBox(height: 8),
              _buildReceiverField(), // ช่องค้นหา
              _buildSearchResult(), // แสดง Error (ถ้ามี)

              // --- [แก้ไข] --- Widget ใหม่สำหรับแสดงรายละเอียดผู้รับ (ชื่อ + ที่อยู่)
              _buildReceiverDetails(),

              // --- [แก้ไข] --- เพิ่มส่วนลิสต์รายชื่อ
              const SizedBox(height: 24),
              _buildSectionTitle('หรือเลือกจากรายชื่อ'),
              const SizedBox(height: 8),
              _buildCustomerList(), // ลิสต์แนวนอน

              const SizedBox(height: 24),
              _buildSectionTitle('รายการ'),
              const SizedBox(height: 8),
              if (_deliveryItem != null)
                _buildItemCard(_deliveryItem!)
              else
                _buildAddItemButton(),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('สร้างการจัดส่ง',
                      style: GoogleFonts.prompt(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
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
        onTap: () => _showItemDetailDialog(item),
        borderRadius: BorderRadius.circular(
          12,
        ),
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
    // --- [แก้ไข] --- Widget นี้จะแสดงเฉพาะ Error
    if (_searchError != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          _searchError!,
          style: TextStyle(color: Colors.red.shade700),
        ),
      );
    }
    // ไม่ต้องแสดงชื่อผู้รับที่นี่แล้ว
    return const SizedBox.shrink();
  }

  // --- [แก้ไข] --- Widget ใหม่สำหรับแสดงรายละเอียดผู้รับ (ชื่อ + ที่อยู่)
  Widget _buildReceiverDetails() {
    // ถ้ายังไม่ได้เลือกใครเลย (ทั้งจากการค้นหา หรือการกด)
    if (_selectedReceiver == null) {
      return const SizedBox.shrink();
    }

    // ถ้าเลือกแล้ว, ให้แสดงชื่อและที่อยู่
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ผู้รับ: ${_selectedReceiver!.name}',
            style:
                GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          _buildAddressSelection(
            addresses: _selectedReceiver!.addresses,
            notifier: _selectedReceiverAddressIndex,
            emptyListMessage: 'ผู้รับยังไม่มีที่อยู่',
          ),
        ],
      ),
    );
  }

  // --- [แก้ไข] --- Widget ใหม่สำหรับแสดงลิสต์ลูกค้า (แนวนอน)
  Widget _buildCustomerList() {
    if (_isUsersLoading) {
      return Container(
        height: 120, // กำหนดความสูง
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_allCustomers.isEmpty) {
      // ถ้าไม่มีลูกค้าคนอื่นเลย ก็ไม่ต้องแสดงอะไร
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 120, // กำหนดความสูง
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _allCustomers.length,
        itemBuilder: (context, index) {
          final customer = _allCustomers[index];

          // เช็คว่าคนที่เลือกอยู่ (ถ้ามี) คือคนนี้หรือไม่
          final bool isSelected = _selectedReceiver?.phone == customer.phone;

          return GestureDetector(
            onTap: () {
              // --- เมื่อกดเลือกจากลิสต์ ---
              setState(() {
                _selectedReceiver = customer; // 1. อัปเดต State กลาง
                _selectedReceiverAddressIndex.value = 0; // 2. Reset ที่อยู่
                _searchController.text =
                    customer.phone; // 3. อัปเดตช่องค้นหา (เผื่อ)
                _searchError = null; // 4. เคลียร์ error
              });
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF4CAF50)
                      : Colors.grey.shade300,
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: (customer.imageProfile.isNotEmpty
                            ? NetworkImage(customer.imageProfile)
                            : const AssetImage('assets/image/confusrd.png'))
                        as ImageProvider,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      customer.name,
                      style: GoogleFonts.prompt(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 2.0,
              ),
              child: Icon(
                Icons.location_on_outlined,
                color: isSelected ? const Color(0xFF4CAF50) : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
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
