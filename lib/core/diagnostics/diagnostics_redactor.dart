import 'package:path/path.dart' as p;

class DiagnosticsRedactor {
  const DiagnosticsRedactor._();

  static final RegExp _jwtPattern = RegExp(
    r'\b[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b',
  );
  static final RegExp _sensitiveAssignmentPattern = RegExp(
    r'\b(password|passwd|pwd|jwt|token|session[-_ ]?key|secret|verifier|signing[-_ ]?key)\s*[:=]\s*[^,\s}\]]+',
    caseSensitive: false,
  );
  static final RegExp _unixPathPattern = RegExp(
    r'(?<![\w.])/(?:[^/\s,;:]+/)+[^/\s,;:]+',
  );
  static final RegExp _windowsPathPattern = RegExp(
    r'[A-Za-z]:\\(?:[^\\\s,;:]+\\)+[^\\\s,;:]+',
  );

  static Object? redactValue(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return redactText(value);
    }
    if (value is num || value is bool) {
      return value;
    }
    if (value is Iterable) {
      return value.map(redactValue).toList(growable: false);
    }
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key.toString(): _redactEntry(entry.key.toString(), entry.value),
      };
    }
    return redactText(value.toString());
  }

  static String? safePath(String? path) {
    if (path == null) {
      return null;
    }
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    if (!_looksLikePath(trimmed)) {
      return redactText(trimmed);
    }
    return '.../${_basename(trimmed)}';
  }

  static String redactText(String text) {
    var next = text.replaceAllMapped(
      _sensitiveAssignmentPattern,
      (match) => '${match.group(1)}=[redacted]',
    );
    next = next.replaceAll(_jwtPattern, '[redacted:jwt]');
    next = next.replaceAllMapped(
      _windowsPathPattern,
      (match) => '.../${_basename(match.group(0)!)}',
    );
    next = next.replaceAllMapped(
      _unixPathPattern,
      (match) => '.../${_basename(match.group(0)!)}',
    );
    return next;
  }

  static Object? _redactEntry(String key, Object? value) {
    if (_isSensitiveKey(key)) {
      return '[redacted:${_normalizedKey(key)}]';
    }
    if (_isPayloadKey(key)) {
      return '[redacted:payload]';
    }
    if (_isPathKey(key) && value is String) {
      return safePath(value);
    }
    return redactValue(value);
  }

  static bool _isSensitiveKey(String key) {
    final normalized = _normalizedKey(key);
    return normalized.contains('password') ||
        normalized == 'pwd' ||
        normalized.contains('token') ||
        normalized.contains('jwt') ||
        normalized.contains('sessionkey') ||
        normalized.contains('secret') ||
        normalized.contains('verifier') ||
        normalized.contains('signingkey');
  }

  static bool _isPayloadKey(String key) {
    final normalized = _normalizedKey(key);
    if (normalized.endsWith('excluded')) {
      return false;
    }
    return normalized.contains('payload') ||
        normalized.contains('filecontent') ||
        normalized.contains('rawbytes') ||
        normalized == 'chunkdata';
  }

  static bool _isPathKey(String key) {
    final normalized = _normalizedKey(key);
    return normalized.endsWith('path') ||
        normalized.contains('filepath') ||
        normalized.contains('savepath') ||
        normalized.contains('logfile');
  }

  static bool _looksLikePath(String value) {
    return value.startsWith('/') ||
        RegExp(r'^[A-Za-z]:\\').hasMatch(value) ||
        value.contains('\\');
  }

  static String _basename(String value) {
    return p.basename(value.replaceAll('\\', '/'));
  }

  static String _normalizedKey(String key) {
    return key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
