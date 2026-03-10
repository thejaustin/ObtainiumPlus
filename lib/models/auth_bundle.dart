class AuthBundle {
  final String email;
  final String aasToken;
  final String authToken;
  final Map<String, dynamic> deviceConfig;
  /// When this token was issued (null for legacy/anonymous bundles without tracking).
  final DateTime? tokenIssuedAt;

  AuthBundle({
    required this.email,
    required this.aasToken,
    required this.authToken,
    required this.deviceConfig,
    this.tokenIssuedAt,
  });

  /// OAuth2 tokens from Google expire in 3600 s. We refresh at 55 min to give
  /// a safe buffer. AAS-based anonymous tokens don't have a hard expiry.
  bool get isExpired {
    if (aasToken.isNotEmpty) return false; // AAS/anonymous — no short expiry
    if (tokenIssuedAt == null) return false; // legacy bundle — assume valid
    return DateTime.now().difference(tokenIssuedAt!) > const Duration(minutes: 55);
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'aasToken': aasToken,
    'authToken': authToken,
    'deviceConfig': deviceConfig,
    if (tokenIssuedAt != null) 'tokenIssuedAt': tokenIssuedAt!.toIso8601String(),
  };

  factory AuthBundle.fromJson(Map<String, dynamic> json) {
    return AuthBundle(
      email: json['email'] ?? '',
      aasToken: json['aasToken'] ?? '',
      authToken: json['authToken'] ?? '',
      deviceConfig: json['deviceConfig'] ?? {},
      tokenIssuedAt: json['tokenIssuedAt'] != null
          ? DateTime.tryParse(json['tokenIssuedAt'])
          : null,
    );
  }
}
