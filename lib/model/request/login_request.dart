class LoginRequest {
  final String phone;
  final String password;

  LoginRequest({required this.phone, required this.password});

  // Converts the Dart object into a JSON map.
  Map<String, dynamic> toJson() {
    return {'phone': phone, 'password': password};
  }
}
