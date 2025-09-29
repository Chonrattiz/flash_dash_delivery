import 'package:flutter/material.dart';
import 'login_response.dart'; // เพื่อใช้ Coordinates

class Delivery {
  final String id;
  final String senderUID;
  final String receiverUID;
  final String itemDescription;
  final String itemImage;
  final String status;
  final String senderName;
  final String receiverName;

  Delivery({
    required this.id,
    required this.senderUID,
    required this.receiverUID,
    required this.itemDescription,
    required this.itemImage,
    required this.status,
    required this.senderName,
    required this.receiverName,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'] ?? '',
      senderUID: json['senderUID'] ?? '',
      receiverUID: json['receiverUID'] ?? '',
      itemDescription: json['itemDescription'] ?? 'No description',
      itemImage: json['itemImage'] ?? '',
      status: json['status'] ?? 'unknown',
      senderName: json['senderName'] ?? 'Unknown Sender',
      receiverName: json['receiverName'] ?? 'Unknown Receiver',
    );
  }

  // Helper เพื่อความสะดวกในการแสดงผล
  String getTitle(String currentUserPhone) {
    return senderUID == currentUserPhone
        ? 'Package to ${receiverName}'
        : 'Package from ${senderName}';
  }

  Color getStatusColor() {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'picked_up':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class DeliveryListResponse {
  final List<Delivery> sentDeliveries;
  final List<Delivery> receivedDeliveries;

  DeliveryListResponse({required this.sentDeliveries, required this.receivedDeliveries});

  factory DeliveryListResponse.fromJson(Map<String, dynamic> json) {
    var sentList = (json['sentDeliveries'] as List? ?? []).map((i) => Delivery.fromJson(i)).toList();
    var receivedList = (json['receivedDeliveries'] as List? ?? []).map((i) => Delivery.fromJson(i)).toList();
    return DeliveryListResponse(
      sentDeliveries: sentList,
      receivedDeliveries: receivedList,
    );
  }
}
