import 'dart:convert';
import 'dart:typed_data';

class TcpIncomingTransferMetadata {
  const TcpIncomingTransferMetadata({
    required this.fileName,
    required this.fileSize,
    required this.chunkCount,
    this.sha256,
  });

  final String fileName;
  final int fileSize;
  final int chunkCount;
  final String? sha256;
}

class TcpIncomingTransferMetadataCodec {
  const TcpIncomingTransferMetadataCodec();

  Uint8List encode(TcpIncomingTransferMetadata metadata) {
    _validate(metadata);
    final payload = <String, Object?>{
      'fileName': metadata.fileName,
      'fileSize': metadata.fileSize,
      'chunkCount': metadata.chunkCount,
      if (metadata.sha256 != null && metadata.sha256!.isNotEmpty)
        'sha256': metadata.sha256,
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(payload)));
  }

  TcpIncomingTransferMetadata decode(List<int> payload) {
    try {
      final decoded = jsonDecode(utf8.decode(payload));
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Metadata payload must be an object.');
      }
      final metadata = TcpIncomingTransferMetadata(
        fileName: _requiredString(decoded, 'fileName'),
        fileSize: _requiredPositiveInt(decoded, 'fileSize'),
        chunkCount: _requiredPositiveInt(decoded, 'chunkCount'),
        sha256: _optionalString(decoded, 'sha256'),
      );
      _validate(metadata);
      return metadata;
    } catch (error) {
      if (error is FormatException &&
          error.message.startsWith('Invalid TCP metadata payload')) {
        rethrow;
      }
      throw FormatException('Invalid TCP metadata payload: $error');
    }
  }

  static String _requiredString(Map<String, Object?> source, String key) {
    final value = source[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Invalid TCP metadata payload: $key is required.');
    }
    return value.trim();
  }

  static String? _optionalString(Map<String, Object?> source, String key) {
    final value = source[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException('Invalid TCP metadata payload: $key is invalid.');
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int _requiredPositiveInt(Map<String, Object?> source, String key) {
    final value = source[key];
    if (value is! int || value <= 0) {
      throw FormatException(
        'Invalid TCP metadata payload: $key must be positive.',
      );
    }
    return value;
  }

  static void _validate(TcpIncomingTransferMetadata metadata) {
    if (metadata.fileName.trim().isEmpty) {
      throw const FormatException(
        'Invalid TCP metadata payload: fileName is required.',
      );
    }
    if (metadata.fileSize <= 0) {
      throw const FormatException(
        'Invalid TCP metadata payload: fileSize must be positive.',
      );
    }
    if (metadata.chunkCount <= 0) {
      throw const FormatException(
        'Invalid TCP metadata payload: chunkCount must be positive.',
      );
    }
  }
}
