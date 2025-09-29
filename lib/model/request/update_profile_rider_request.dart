class UpdateRiderProfilePayload {
  String? name;
  String? password;
  String? imageProfile;
  String? imageVehicle;
  String? vehicleRegistration;

  UpdateRiderProfilePayload({
    this.name,
    this.password,
    this.imageProfile,
    this.imageVehicle,
    this.vehicleRegistration,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null && name!.isNotEmpty) data['name'] = name;
    if (password != null && password!.isNotEmpty) data['password'] = password;
    if (imageProfile != null && imageProfile!.isNotEmpty) {
      data['image_profile'] = imageProfile;
    }
    if (imageVehicle != null && imageVehicle!.isNotEmpty) {
      data['image_vehicle'] = imageVehicle;
    }
    if (vehicleRegistration != null && vehicleRegistration!.isNotEmpty) {
      data['vehicle_registration'] = vehicleRegistration;
    }
    return data;
  }
}
