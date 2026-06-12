import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/core/errors/app_exception.dart';

class AuthJwtClaims {
  const AuthJwtClaims({
    required this.subjectUserId,
    required this.deviceId,
    required this.peerUserId,
    required this.nonce,
    required this.issuedAtEpochSec,
    required this.expiresAtEpochSec,
    required this.jti,
    required this.protocolVersion,
    required this.sessionId,
  });

  final String subjectUserId;
  final String deviceId;
  final String peerUserId;
  final String nonce;
  final int issuedAtEpochSec;
  final int expiresAtEpochSec;
  final String jti;
  final String protocolVersion;
  final String sessionId;

  Map<String, Object> toJson() {
    return {
      'sub': subjectUserId,
      'device_id': deviceId,
      'peer_id': peerUserId,
      'nonce': nonce,
      'iat': issuedAtEpochSec,
      'exp': expiresAtEpochSec,
      'jti': jti,
      'protocol_version': protocolVersion,
      'session_id': sessionId,
    };
  }

  factory AuthJwtClaims.fromJson(Map<String, dynamic> json) {
    return AuthJwtClaims(
      subjectUserId: _readString(json, 'sub'),
      deviceId: _readString(json, 'device_id'),
      peerUserId: _readString(json, 'peer_id'),
      nonce: _readString(json, 'nonce'),
      issuedAtEpochSec: _readInt(json, 'iat'),
      expiresAtEpochSec: _readInt(json, 'exp'),
      jti: _readString(json, 'jti'),
      protocolVersion: _readString(json, 'protocol_version'),
      sessionId: _readString(json, 'session_id'),
    );
  }

  static String _readString(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is! String || value.trim().isEmpty) {
      throw AppException(
        code: 'auth_token_invalid_claim',
        message: '토큰 claim $key 가 유효하지 않습니다.',
      );
    }
    return value;
  }

  static int _readInt(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is! int) {
      throw AppException(
        code: 'auth_token_invalid_claim',
        message: '토큰 claim $key 가 유효하지 않습니다.',
      );
    }
    return value;
  }
}

class AuthJwtValidationRequest {
  const AuthJwtValidationRequest({
    required this.token,
    required this.signingKey,
    required this.expectedPeerUserId,
    required this.expectedNonce,
    required this.expectedProtocolVersion,
    required this.expectedSessionId,
    required this.nowEpochSec,
    required this.allowedClockSkewSec,
    required this.isReplayJti,
  });

  final String token;
  final List<int> signingKey;
  final String expectedPeerUserId;
  final String expectedNonce;
  final String expectedProtocolVersion;
  final String expectedSessionId;
  final int nowEpochSec;
  final int allowedClockSkewSec;
  final bool Function(String jti) isReplayJti;
}

class AuthJwtValidationResult {
  const AuthJwtValidationResult({required this.claims});

  final AuthJwtClaims claims;
}

class JwtTokenService {
  const JwtTokenService();

  static const _header = {'alg': 'HS256', 'typ': 'JWT'};

  String createToken({
    required AuthJwtClaims claims,
    required List<int> signingKey,
  }) {
    final headerPart = _base64UrlJson(_header);
    final payloadPart = _base64UrlJson(claims.toJson());
    final signaturePart = _sign(
      '$headerPart.$payloadPart',
      signingKey: signingKey,
    );
    return '$headerPart.$payloadPart.$signaturePart';
  }

  AuthJwtValidationResult validate(AuthJwtValidationRequest request) {
    final parts = request.token.split('.');
    if (parts.length != 3) {
      throw const AppException(
        code: 'auth_token_malformed',
        message: '인증 토큰 형식이 잘못되었습니다.',
      );
    }

    final expectedSignature = _sign(
      '${parts[0]}.${parts[1]}',
      signingKey: request.signingKey,
    );
    if (!_constantTimeEquals(parts[2], expectedSignature)) {
      throw const AppException(
        code: 'auth_token_invalid_signature',
        message: '인증 토큰 서명이 일치하지 않습니다.',
      );
    }

    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    if (payload is! Map<String, dynamic>) {
      throw const AppException(
        code: 'auth_token_invalid_payload',
        message: '인증 토큰 payload 가 유효하지 않습니다.',
      );
    }

    final claims = AuthJwtClaims.fromJson(payload);
    if (claims.peerUserId != request.expectedPeerUserId) {
      throw const AppException(
        code: 'auth_token_peer_mismatch',
        message: '인증 대상이 일치하지 않습니다.',
      );
    }
    if (claims.nonce != request.expectedNonce) {
      throw const AppException(
        code: 'auth_token_nonce_mismatch',
        message: '인증 nonce 가 일치하지 않습니다.',
      );
    }
    if (claims.protocolVersion != request.expectedProtocolVersion) {
      throw const AppException(
        code: 'auth_token_protocol_mismatch',
        message: '인증 프로토콜 버전이 일치하지 않습니다.',
      );
    }
    if (claims.sessionId != request.expectedSessionId) {
      throw const AppException(
        code: 'auth_token_session_mismatch',
        message: '인증 세션이 일치하지 않습니다.',
      );
    }
    if (claims.issuedAtEpochSec >
        request.nowEpochSec + request.allowedClockSkewSec) {
      throw const AppException(
        code: 'auth_token_from_future',
        message: '인증 토큰 시간이 유효하지 않습니다.',
      );
    }
    if (claims.expiresAtEpochSec <
        request.nowEpochSec - request.allowedClockSkewSec) {
      throw const AppException(
        code: 'auth_token_expired',
        message: '인증 토큰이 만료되었습니다.',
      );
    }
    if (request.isReplayJti(claims.jti)) {
      throw const AppException(
        code: 'auth_token_replay_detected',
        message: '이미 사용된 인증 토큰입니다.',
      );
    }

    return AuthJwtValidationResult(claims: claims);
  }

  String _base64UrlJson(Map<String, Object> value) {
    return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  }

  String _sign(String input, {required List<int> signingKey}) {
    final digest = Hmac(sha256, signingKey).convert(utf8.encode(input));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  bool _constantTimeEquals(String left, String right) {
    final leftBytes = utf8.encode(left);
    final rightBytes = utf8.encode(right);
    if (leftBytes.length != rightBytes.length) {
      return false;
    }

    var diff = 0;
    for (var index = 0; index < leftBytes.length; index += 1) {
      diff |= leftBytes[index] ^ rightBytes[index];
    }
    return diff == 0;
  }
}

final jwtTokenServiceProvider = Provider<JwtTokenService>((ref) {
  return const JwtTokenService();
});
