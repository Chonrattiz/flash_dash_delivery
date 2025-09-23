// ไฟล์นี้ใช้เก็บโครงสร้างข้อมูลที่จะส่งไปให้ Backend
// ตรงกับ Model ที่เราสร้างไว้ใน Go

class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates({required this.latitude, required this.longitude});

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };
}

class Address {
  final String detail;
  final Coordinates coordinates;

  Address({required this.detail, required this.coordinates});

  Map<String, dynamic> toJson() => {
        'detail': detail,
        'coordinates': coordinates.toJson(),
      };
}

class RiderDetails {
  final String imageVehicle;
  final String vehicleRegistration;

  RiderDetails({required this.imageVehicle, required this.vehicleRegistration});

  Map<String, dynamic> toJson() => {
        'image_vehicle': imageVehicle,
        'vehicle_registration': vehicleRegistration,
      };
}

class UserCore {
  final String name;
  final String phone;
  final String password;
  final String imageProfile;

  UserCore({
    required this.name,
    required this.phone,
    required this.password,
    required this.imageProfile,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'password': password,
        'image_profile': imageProfile,
      };
}

class RegisterCustomerPayload {
  final UserCore userCore;
  final Address address;

  RegisterCustomerPayload({required this.userCore, required this.address});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = userCore.toJson();
    data['address'] = address.toJson();
    return data;
  }
}

class RegisterRiderPayload {
  final UserCore userCore;
  final RiderDetails riderDetails;

  RegisterRiderPayload({required this.userCore, required this.riderDetails});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = userCore.toJson();
    data['rider_details'] = riderDetails.toJson();
    return data;
  }
}
