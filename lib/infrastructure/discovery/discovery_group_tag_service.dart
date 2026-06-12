import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiscoveryGroupTagService {
  const DiscoveryGroupTagService();

  static const _tagContext = 'sponzey-filesharing-discovery-group-v1';

  String deriveTag({
    required String protocolVersion,
    required String userId,
    required String password,
  }) {
    final digest = Hmac(
      sha256,
      utf8.encode(_tagContext),
    ).convert(utf8.encode('$protocolVersion::$userId::$password'));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  String preview(String value, {int length = 12}) {
    if (value.isEmpty) {
      return '';
    }
    final safeLength = value.length < length ? value.length : length;
    return value.substring(0, safeLength);
  }
}

final discoveryGroupTagServiceProvider = Provider<DiscoveryGroupTagService>((
  ref,
) {
  return const DiscoveryGroupTagService();
});
