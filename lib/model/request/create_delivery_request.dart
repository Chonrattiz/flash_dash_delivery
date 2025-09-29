class CreateDeliveryPayload {
  final String receiverPhone;
  final String senderAddressId;
  final String receiverAddressId;
  final String itemDescription;
  final String itemImageFilename;
  final String? riderNoteImageFilename; // อาจเป็น null ได้

  CreateDeliveryPayload({
    required this.receiverPhone,
    required this.senderAddressId,
    required this.receiverAddressId,
    required this.itemDescription,
    required this.itemImageFilename,
    this.riderNoteImageFilename,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{
      'receiverPhone': receiverPhone,
      'senderAddressId': senderAddressId,
      'receiverAddressId': receiverAddressId,
      'itemDescription': itemDescription,
      'itemImageFilename': itemImageFilename,
    };
    if (riderNoteImageFilename != null) {
      data['riderNoteImageFilename'] = riderNoteImageFilename;
    }
    return data;
  }
}
