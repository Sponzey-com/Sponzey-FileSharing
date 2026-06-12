import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/core/errors/app_exception.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/discovery_group_tag_service.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/jwt_token_service.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/shared_verifier_service.dart';

void main() {
  const verifierService = SharedVerifierService();
  const jwtService = JwtTokenService();

  test('creates and validates password-derived jwt', () {
    final verifier = verifierService.deriveVerifierBase64(
      userId: 'alice',
      password: 'shared-secret',
    );
    final signingKey = verifierService.deriveSigningKey(
      verifierBase64: verifier,
      sessionId: 'session-1',
      nonce: 'nonce-1',
      subjectUserId: 'alice',
      peerUserId: 'bob',
    );
    final token = jwtService.createToken(
      claims: const AuthJwtClaims(
        subjectUserId: 'alice',
        deviceId: 'device-a',
        peerUserId: 'bob',
        nonce: 'nonce-1',
        issuedAtEpochSec: 100,
        expiresAtEpochSec: 120,
        jti: 'jti-1',
        protocolVersion: '1.0',
        sessionId: 'session-1',
      ),
      signingKey: signingKey,
    );

    final result = jwtService.validate(
      AuthJwtValidationRequest(
        token: token,
        signingKey: signingKey,
        expectedPeerUserId: 'bob',
        expectedNonce: 'nonce-1',
        expectedProtocolVersion: '1.0',
        expectedSessionId: 'session-1',
        nowEpochSec: 110,
        allowedClockSkewSec: 5,
        isReplayJti: (_) => false,
      ),
    );

    expect(result.claims.subjectUserId, 'alice');
    expect(result.claims.peerUserId, 'bob');
  });

  test('does not validate jwt with discovery group tag as signing key', () {
    final verifier = verifierService.deriveVerifierBase64(
      userId: 'alice',
      password: 'shared-secret',
    );
    final discoveryGroupTag = const DiscoveryGroupTagService().deriveTag(
      protocolVersion: '1.0',
      userId: 'alice',
      password: 'shared-secret',
    );
    final signingKey = verifierService.deriveSigningKey(
      verifierBase64: verifier,
      sessionId: 'session-1',
      nonce: 'nonce-1',
      subjectUserId: 'alice',
      peerUserId: 'bob',
    );
    final token = jwtService.createToken(
      claims: const AuthJwtClaims(
        subjectUserId: 'alice',
        deviceId: 'device-a',
        peerUserId: 'bob',
        nonce: 'nonce-1',
        issuedAtEpochSec: 100,
        expiresAtEpochSec: 120,
        jti: 'jti-1',
        protocolVersion: '1.0',
        sessionId: 'session-1',
      ),
      signingKey: signingKey,
    );

    expect(discoveryGroupTag, isNot(verifier));
    expect(
      () => jwtService.validate(
        AuthJwtValidationRequest(
          token: token,
          signingKey: utf8.encode(discoveryGroupTag),
          expectedPeerUserId: 'bob',
          expectedNonce: 'nonce-1',
          expectedProtocolVersion: '1.0',
          expectedSessionId: 'session-1',
          nowEpochSec: 110,
          allowedClockSkewSec: 5,
          isReplayJti: (_) => false,
        ),
      ),
      throwsA(
        isA<AppException>().having(
          (e) => e.code,
          'code',
          'auth_token_invalid_signature',
        ),
      ),
    );
  });

  test('rejects expired, wrong nonce, replayed, and wrong verifier tokens', () {
    final verifier = verifierService.deriveVerifierBase64(
      userId: 'alice',
      password: 'shared-secret',
    );
    final signingKey = verifierService.deriveSigningKey(
      verifierBase64: verifier,
      sessionId: 'session-1',
      nonce: 'nonce-1',
      subjectUserId: 'alice',
      peerUserId: 'bob',
    );
    final token = jwtService.createToken(
      claims: const AuthJwtClaims(
        subjectUserId: 'alice',
        deviceId: 'device-a',
        peerUserId: 'bob',
        nonce: 'nonce-1',
        issuedAtEpochSec: 100,
        expiresAtEpochSec: 102,
        jti: 'jti-1',
        protocolVersion: '1.0',
        sessionId: 'session-1',
      ),
      signingKey: signingKey,
    );

    expect(
      () => jwtService.validate(
        AuthJwtValidationRequest(
          token: token,
          signingKey: signingKey,
          expectedPeerUserId: 'bob',
          expectedNonce: 'nonce-1',
          expectedProtocolVersion: '1.0',
          expectedSessionId: 'session-1',
          nowEpochSec: 200,
          allowedClockSkewSec: 1,
          isReplayJti: (_) => false,
        ),
      ),
      throwsA(
        isA<AppException>().having((e) => e.code, 'code', 'auth_token_expired'),
      ),
    );

    expect(
      () => jwtService.validate(
        AuthJwtValidationRequest(
          token: token,
          signingKey: signingKey,
          expectedPeerUserId: 'bob',
          expectedNonce: 'wrong-nonce',
          expectedProtocolVersion: '1.0',
          expectedSessionId: 'session-1',
          nowEpochSec: 101,
          allowedClockSkewSec: 1,
          isReplayJti: (_) => false,
        ),
      ),
      throwsA(
        isA<AppException>().having(
          (e) => e.code,
          'code',
          'auth_token_nonce_mismatch',
        ),
      ),
    );

    expect(
      () => jwtService.validate(
        AuthJwtValidationRequest(
          token: token,
          signingKey: signingKey,
          expectedPeerUserId: 'bob',
          expectedNonce: 'nonce-1',
          expectedProtocolVersion: '1.0',
          expectedSessionId: 'session-1',
          nowEpochSec: 101,
          allowedClockSkewSec: 1,
          isReplayJti: (jti) => jti == 'jti-1',
        ),
      ),
      throwsA(
        isA<AppException>().having(
          (e) => e.code,
          'code',
          'auth_token_replay_detected',
        ),
      ),
    );

    final wrongVerifier = verifierService.deriveVerifierBase64(
      userId: 'alice',
      password: 'another-secret',
    );
    final wrongSigningKey = verifierService.deriveSigningKey(
      verifierBase64: wrongVerifier,
      sessionId: 'session-1',
      nonce: 'nonce-1',
      subjectUserId: 'alice',
      peerUserId: 'bob',
    );

    expect(
      () => jwtService.validate(
        AuthJwtValidationRequest(
          token: token,
          signingKey: wrongSigningKey,
          expectedPeerUserId: 'bob',
          expectedNonce: 'nonce-1',
          expectedProtocolVersion: '1.0',
          expectedSessionId: 'session-1',
          nowEpochSec: 101,
          allowedClockSkewSec: 1,
          isReplayJti: (_) => false,
        ),
      ),
      throwsA(
        isA<AppException>().having(
          (e) => e.code,
          'code',
          'auth_token_invalid_signature',
        ),
      ),
    );
  });
}
