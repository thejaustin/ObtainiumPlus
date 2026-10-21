import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/padded_block_cipher/padded_block_cipher_impl.dart';
import 'package:pointycastle/paddings/pkcs7.dart';

/// Password-based encryption for exported backups.
///
/// v2 format: PBKDF2-HMAC-SHA256 (random 16-byte salt) -> AES-256-GCM
/// (random 12-byte nonce, 128-bit tag), wrapped in a small JSON envelope so
/// the file is recognisable and versioned. Legacy v1 files (SHA-256(password
/// + timestamp) -> AES-CBC, from the pre-May export service) are still
/// readable.
class BackupCrypto {
  BackupCrypto._();

  static const _formatKey = 'obtainiumEncryptedBackup';
  static const _version = 2;
  static const _iterations = 310000;
  static const _passwordKey = 'backup-password';
  static const _storage = FlutterSecureStorage();

  /// True for both the v2 envelope and the legacy {"encrypted": true} one.
  static bool isEncrypted(String content) {
    try {
      final decoded = jsonDecode(content);
      return decoded is Map &&
          (decoded[_formatKey] != null || decoded['encrypted'] == true);
    } catch (_) {
      return false;
    }
  }

  static Future<String> encrypt(String plaintext, String password) =>
      compute(_encrypt, [plaintext, password]);

  /// Throws [BackupPasswordError] when the password is wrong.
  static Future<String> decrypt(String content, String password) =>
      compute(_decrypt, [content, password]);

  static Future<String?> storedPassword() async {
    try {
      return await _storage.read(key: _passwordKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> storePassword(String? password) async {
    if (password == null || password.isEmpty) {
      await _storage.delete(key: _passwordKey);
    } else {
      await _storage.write(key: _passwordKey, value: password);
    }
  }

  static Uint8List _randomBytes(int n) {
    final rnd = Random.secure();
    return Uint8List.fromList(List.generate(n, (_) => rnd.nextInt(256)));
  }

  static Uint8List _deriveKey(String password, Uint8List salt, int iterations) {
    final kdf = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iterations, 32));
    return kdf.process(Uint8List.fromList(utf8.encode(password)));
  }

  static String _encrypt(List<String> args) {
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final key = _deriveKey(args[1], salt, _iterations);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)));
    final data = cipher.process(Uint8List.fromList(utf8.encode(args[0])));
    return jsonEncode({
      _formatKey: _version,
      'kdf': 'pbkdf2-sha256',
      'iterations': _iterations,
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'data': base64Encode(data),
    });
  }

  static String _decrypt(List<String> args) {
    final envelope = jsonDecode(args[0]) as Map<String, dynamic>;
    final password = args[1];
    try {
      if (envelope[_formatKey] != null) {
        final salt = base64Decode(envelope['salt'] as String);
        final nonce = base64Decode(envelope['nonce'] as String);
        final iterations = envelope['iterations'] as int;
        final key = _deriveKey(password, salt, iterations);
        final cipher = GCMBlockCipher(AESEngine())
          ..init(
            false,
            AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)),
          );
        final plain = cipher.process(base64Decode(envelope['data'] as String));
        return utf8.decode(plain);
      }
      // Legacy v1: SHA-256(password + salt) key, AES-CBC/PKCS7, no MAC.
      final key = Uint8List.fromList(
        crypto.sha256
            .convert(utf8.encode(password + (envelope['salt'] as String)))
            .bytes,
      );
      final iv = base64Decode(envelope['iv'] as String);
      final cipher =
          PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(AESEngine()))
            ..init(
              false,
              PaddedBlockCipherParameters(
                ParametersWithIV(KeyParameter(key), iv),
                null,
              ),
            );
      final plain = cipher.process(base64Decode(envelope['data'] as String));
      final text = utf8.decode(plain);
      jsonDecode(text); // wrong password yields garbage, not JSON
      return text;
    } catch (_) {
      throw const BackupPasswordError();
    }
  }
}

class BackupPasswordError implements Exception {
  const BackupPasswordError();
  @override
  String toString() => 'Wrong backup password';
}
