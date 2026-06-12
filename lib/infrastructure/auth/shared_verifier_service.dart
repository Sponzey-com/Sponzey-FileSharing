import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SharedVerifierService {
  const SharedVerifierService();

  static const _verifierContext = 'sponzey-filesharing-verifier-v1';
  static const _signingContext = 'sponzey-filesharing-signing-v1';

  String deriveVerifierBase64({
    required String userId,
    required String password,
  }) {
    final digest = Hmac(
      sha256,
      utf8.encode(_verifierContext),
    ).convert(utf8.encode('$userId::$password'));
    return base64Encode(digest.bytes);
  }

  List<int> deriveSigningKey({
    required String verifierBase64,
    required String sessionId,
    required String nonce,
    required String subjectUserId,
    required String peerUserId,
  }) {
    final verifier = base64Decode(verifierBase64);
    final digest = Hmac(sha256, verifier).convert(
      utf8.encode(
        '$_signingContext::$sessionId::$nonce::$subjectUserId::$peerUserId',
      ),
    );
    return digest.bytes;
  }
}

final sharedVerifierServiceProvider = Provider<SharedVerifierService>((ref) {
  return const SharedVerifierService();
});
