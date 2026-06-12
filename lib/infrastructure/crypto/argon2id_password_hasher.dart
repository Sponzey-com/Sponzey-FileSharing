import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hashlib/hashlib.dart';
import 'package:sponzey_file_sharing/domain/services/password_hasher.dart';

class Argon2IdPasswordHasher implements PasswordHasher {
  Argon2IdPasswordHasher({Random? random})
    : _random = random ?? Random.secure();

  static const _security = Argon2Security.moderate;
  static const _hashLength = 32;
  final Random _random;

  @override
  Future<PasswordHashResult> hash(String plainTextPassword) async {
    final salt = List<int>.generate(16, (_) => _random.nextInt(256));
    final argon2 = Argon2.fromSecurity(
      _security,
      salt: salt,
      hashLength: _hashLength,
    );

    return PasswordHashResult(
      encodedHash: argon2.encode(utf8.encode(plainTextPassword)),
      saltBase64: base64Encode(salt),
      algorithm: 'argon2id',
      paramsJson: jsonEncode({
        'security': _security.name,
        'memoryKb': _security.m,
        'iterations': _security.t,
        'parallelism': _security.p,
        'hashLength': _hashLength,
      }),
    );
  }

  @override
  Future<bool> verify({
    required String plainTextPassword,
    required String encodedHash,
  }) async {
    return argon2Verify(encodedHash, utf8.encode(plainTextPassword));
  }
}

final passwordHasherProvider = Provider<PasswordHasher>((ref) {
  return Argon2IdPasswordHasher();
});
