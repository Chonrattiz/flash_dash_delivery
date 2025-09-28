// +++ Add this new class for updating a rider's profile +++
class UpdateRiderProfilePayload {
  final String? name;
  final String? password; // Add if you allow password changes
  final String? imageProfile;
  final String? imageVehicle;
  final String? vehicleRegistration;

  UpdateRiderProfilePayload({
    this.name,
    this.password,
    this.imageProfile,
    this.imageVehicle,
    this.vehicleRegistration,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    // Only include fields that are not null to avoid overwriting with empty data
    if (name != null) data['name'] = name;
    if (password != null) data['password'] = password;
    if (imageProfile != null) data['image_profile'] = imageProfile;
    if (imageVehicle != null) data['image_vehicle'] = imageVehicle;
    if (vehicleRegistration != null)
      data['vehicle_registration'] = vehicleRegistration;
    return data;
  }
}
