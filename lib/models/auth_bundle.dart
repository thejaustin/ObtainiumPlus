class AuthBundle {
  final String email;
  final String aasToken;
  final String authToken;
  final Map<String, dynamic> deviceConfig;

  AuthBundle({
    required this.email,
    required this.aasToken,
    required this.authToken,
    required this.deviceConfig,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'aasToken': aasToken,
    'authToken': authToken,
    'deviceConfig': deviceConfig,
  };

  factory AuthBundle.fromJson(Map<String, dynamic> json) {
    return AuthBundle(
      email: json['email'] ?? '',
      aasToken: json['aasToken'] ?? '',
      authToken: json['authToken'] ?? '',
      deviceConfig: json['deviceConfig'] ?? {},
    );
  }
}
