import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_frame_codec.dart';

class TransferDataAuthContext {
  TransferDataAuthContext._({
    required this.transferId,
    required this.sessionHash,
    required this.keyId,
    required DataFrameAuthenticator authenticator,
  }) : _authenticator = authenticator;

  final String transferId;
  final int sessionHash;
  final String keyId;
  final DataFrameAuthenticator _authenticator;
  bool _disposed = false;

  DataFrameAuthenticator get authenticator {
    if (_disposed) {
      throw StateError('Transfer data auth context has been disposed.');
    }
    return _authenticator;
  }

  void dispose() {
    _disposed = true;
  }

  static TransferDataAuthContext derive({
    required String sessionId,
    required String localNodeId,
    required String remoteNodeId,
    required String transferId,
    required String selectedPathId,
    required String nonce,
  }) {
    final material = utf8.encode(
      [
        'sponzey-data-v1',
        sessionId,
        localNodeId,
        remoteNodeId,
        transferId,
        selectedPathId,
        nonce,
      ].join('|'),
    );
    final digest = sha256.convert(material).bytes;
    final sessionHashBytes = digest.take(8).toList(growable: false);
    var sessionHash = 0;
    for (final byte in sessionHashBytes) {
      sessionHash = (sessionHash << 8) | byte;
    }
    return TransferDataAuthContext._(
      transferId: transferId,
      sessionHash: sessionHash,
      keyId: base64Url.encode(digest.take(9).toList(growable: false)),
      authenticator: DataFrameAuthenticator(key: digest),
    );
  }
}
