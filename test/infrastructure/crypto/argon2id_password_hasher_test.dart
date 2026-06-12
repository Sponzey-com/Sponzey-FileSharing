import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/infrastructure/crypto/argon2id_password_hasher.dart';

void main() {
  group('Argon2IdPasswordHasher', () {
    test('hashes and verifies a password', () async {
      final hasher = Argon2IdPasswordHasher();
      const password = 'correct horse battery staple';

      final result = await hasher.hash(password);

      expect(result.algorithm, 'argon2id');
      expect(result.encodedHash, isNotEmpty);
      expect(result.saltBase64, isNotEmpty);
      expect(
        await hasher.verify(
          plainTextPassword: password,
          encodedHash: result.encodedHash,
        ),
        isTrue,
      );
    });

    test('rejects a wrong password', () async {
      final hasher = Argon2IdPasswordHasher();
      final result = await hasher.hash('secret');

      final isValid = await hasher.verify(
        plainTextPassword: 'wrong-secret',
        encodedHash: result.encodedHash,
      );

      expect(isValid, isFalse);
    });
  });
}
