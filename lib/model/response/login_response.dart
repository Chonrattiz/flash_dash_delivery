// This file contains all the models needed to parse the successful login response from the backend.

// The main container for the entire login response.
class LoginResponse {
  final String message;
  final String idToken;
  final UserProfile userProfile;
  final dynamic
  roleSpecificData; // Can be a Rider object or a List of Address objects

  LoginResponse({
    required this.message,
    required this.idToken,
    required this.userProfile,
    this.roleSpecificData,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // First, parse the user profile to determine the role.
    final userProfile = UserProfile.fromJson(json['userProfile']);
    dynamic specificData;

    // Based on the role, parse the roleSpecificData accordingly.
    if (json['roleSpecificData'] != null) {
      if (userProfile.role == 'customer') {
        // If customer, it's a list of addresses.
        var addressList = json['roleSpecificData'] as List;
        specificData = addressList.map((i) => Address.fromJson(i)).toList();
      } else if (userProfile.role == 'rider') {
        // If rider, it's a single rider object.
        specificData = Rider.fromJson(json['roleSpecificData']);
      }
    }

    return LoginResponse(
      message: json['message'],
      idToken: json['idToken'],
      userProfile: userProfile,
      roleSpecificData: specificData,
    );
  }
}

// Model for the 'userProfile' part of the response.
class UserProfile {
  final String name;
  final String phone;
  final String imageProfile;
  final String role;

  UserProfile({
    required this.name,
    required this.phone,
    required this.imageProfile,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      imageProfile: json['image_profile'] ?? '',
      role: json['role'] ?? '',
    );
  }
}

// Model for a single Address (used for customers).
class Address {
  final String id;
  final String detail;
  final Coordinates coordinates;

  Address({required this.id, required this.detail, required this.coordinates});

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? '',
      detail: json['detail'] ?? '',
      coordinates: Coordinates.fromJson(json['coordinates']),
    );
  }
}

// Model for Coordinates, nested within an Address.
class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates({required this.latitude, required this.longitude});

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }
}

// Model for Rider details (used for riders).

class Rider {
  final String imageVehicle;
  final String vehicleRegistration;

  Rider({required this.imageVehicle, required this.vehicleRegistration});

  factory Rider.fromJson(Map<String, dynamic> json) {
    return Rider(
      // ต้องเป็น 'ImageVehicle' และ 'VehicleRegistration' (ตัวพิมพ์ใหญ่)
      imageVehicle: json['image_vehicle'] ?? '',
      vehicleRegistration: json['vehicle_registration'] ?? '',
    );
  }
}
