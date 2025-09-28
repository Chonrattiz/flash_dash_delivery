// lib/model/request/address_request.dart
class CoordinatesPayload {
  final double latitude;
  final double longitude;

  CoordinatesPayload({required this.latitude, required this.longitude});

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };
}

class AddressPayload {
  final String detail;
  final CoordinatesPayload coordinates;

  AddressPayload({
    required this.detail,
    required this.coordinates,
  });

  Map<String, dynamic> toJson() => {
        'detail': detail,
        'coordinates': coordinates.toJson(),
      };
}
