import 'dart:core';

/// Security utility for validating and sanitizing URLs
class URLValidator {
  URLValidator._();

  /// List of allowed deep link hosts for Obtainium
  static const List<String> _allowedDeepLinkHosts = [
    'add',
    'app',
    'apps',
  ];

  /// List of allowed URL schemes for app sources
  static const List<String> _allowedSourceSchemes = [
    'http',
    'https',
  ];

  /// Expected deep link scheme for Obtainium
  static const String _deepLinkScheme = 'obtainium';

  /// Validates a deep link URI
  /// Returns true if the URI is safe to process
  static bool isValidDeepLink(Uri uri) {
    // Check scheme
    if (uri.scheme.toLowerCase() != _deepLinkScheme) {
      print('⚠️ SECURITY: Invalid deep link scheme: ${uri.scheme}');
      return false;
    }

    // Check host is whitelisted
    if (!_allowedDeepLinkHosts.contains(uri.host.toLowerCase())) {
      print('⚠️ SECURITY: Unauthorized deep link host: ${uri.host}');
      return false;
    }

    return true;
  }

  /// Validates an app source URL
  /// Returns true if the URL is from an allowed scheme
  static bool isValidSourceURL(String url) {
    try {
      final uri = Uri.parse(url);

      // Check scheme is allowed
      if (!_allowedSourceSchemes.contains(uri.scheme.toLowerCase())) {
        print('⚠️ SECURITY: Disallowed URL scheme: ${uri.scheme}');
        return false;
      }

      // Check for obvious malicious patterns
      if (_containsSuspiciousPatterns(url)) {
        print('⚠️ SECURITY: URL contains suspicious patterns');
        return false;
      }

      return true;
    } catch (e) {
      print('⚠️ SECURITY: Invalid URL format: $e');
      return false;
    }
  }

  /// Checks for suspicious patterns in URLs
  static bool _containsSuspiciousPatterns(String url) {
    final suspiciousPatterns = [
      // JavaScript protocol
      RegExp(r'javascript:', caseSensitive: false),
      // Data URLs (can contain embedded scripts)
      RegExp(r'data:text/html', caseSensitive: false),
      // File protocol (local file access)
      RegExp(r'file:', caseSensitive: false),
      // Excessive URL encoding (obfuscation attempt)
      RegExp(r'%[0-9a-fA-F]{2}{5,}'),
    ];

    for (final pattern in suspiciousPatterns) {
      if (pattern.hasMatch(url)) {
        return true;
      }
    }

    return false;
  }

  /// Sanitizes a string to prevent injection attacks
  /// Removes potentially dangerous characters
  static String sanitizeInput(String input) {
    // Remove null bytes
    String sanitized = input.replaceAll(RegExp(r'\x00'), '');

    // Remove control characters (except newline, carriage return, tab)
    sanitized = sanitized.replaceAll(
      RegExp(r'[\x01-\x08\x0B\x0C\x0E-\x1F\x7F]'),
      '',
    );

    return sanitized.trim();
  }

  /// Validates JSON input for app import
  /// Returns true if the JSON appears safe
  static bool isValidJSONInput(String jsonString) {
    // Check length (prevent DoS via huge JSON)
    if (jsonString.length > 1000000) {
      // 1MB limit
      print('⚠️ SECURITY: JSON input exceeds size limit');
      return false;
    }

    // Basic validation - actual JSON parsing will happen elsewhere
    // Just check for obvious attack patterns
    if (_containsSuspiciousPatterns(jsonString)) {
      return false;
    }

    return true;
  }
}
