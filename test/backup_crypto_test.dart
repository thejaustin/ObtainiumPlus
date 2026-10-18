import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/utils/backup_crypto.dart';

void main() {
  const plain = '{"apps":[{"id":"a"}],"settings":{"github-creds":"t"}}';

  test('v2 round-trips and is recognised as encrypted', () async {
    final sealed = await BackupCrypto.encrypt(plain, 'hunter2');
    expect(BackupCrypto.isEncrypted(sealed), isTrue);
    expect(sealed.contains('github-creds'), isFalse);
    expect(await BackupCrypto.decrypt(sealed, 'hunter2'), plain);
  });

  test('wrong password is rejected (authenticated)', () async {
    final sealed = await BackupCrypto.encrypt(plain, 'right');
    expect(
      BackupCrypto.decrypt(sealed, 'wrong'),
      throwsA(isA<BackupPasswordError>()),
    );
  });

  test('plain exports are not treated as encrypted', () {
    expect(BackupCrypto.isEncrypted(plain), isFalse);
    expect(BackupCrypto.isEncrypted('not json'), isFalse);
  });

  test('legacy v1 backups (SHA-256 key, AES-CBC) still decrypt', () async {
    const password = 'old';
    const salt = '1700000000000';
    final key = enc.Key(
      Uint8List.fromList(sha256.convert(utf8.encode(password + salt)).bytes),
    );
    final iv = enc.IV.fromSecureRandom(16);
    final encrypted = enc.Encrypter(
      enc.AES(key, mode: enc.AESMode.cbc, padding: 'PKCS7'),
    ).encrypt(plain, iv: iv);
    final legacy = jsonEncode({
      'encrypted': true,
      'salt': salt,
      'iv': iv.base64,
      'data': encrypted.base64,
    });
    expect(BackupCrypto.isEncrypted(legacy), isTrue);
    expect(await BackupCrypto.decrypt(legacy, password), plain);
  });
}
