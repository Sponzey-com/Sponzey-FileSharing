class PasswordHashResult {
  const PasswordHashResult({
    required this.encodedHash,
    required this.saltBase64,
    required this.algorithm,
    required this.paramsJson,
  });

  final String encodedHash;
  final String saltBase64;
  final String algorithm;
  final String paramsJson;
}

abstract interface class PasswordHasher {
  Future<PasswordHashResult> hash(String plainTextPassword);

  Future<bool> verify({
    required String plainTextPassword,
    required String encodedHash,
  });
}
