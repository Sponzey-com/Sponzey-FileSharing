import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class AppSecureStorage {
  Future<void> ensureReady();

  Future<String?> read(String key);

  Future<void> write({required String key, required String value});

  Future<void> delete(String key);
}

class MemoryAppSecureStorage implements AppSecureStorage {
  MemoryAppSecureStorage({Random? random})
    : _random = random ?? Random.secure();

  static const _memoryReadyKey = '__memory_ready__';

  final Random _random;
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> ensureReady() async {
    if (_values.containsKey(_memoryReadyKey)) {
      return;
    }

    final marker = List<int>.generate(
      16,
      (_) => _random.nextInt(256),
    ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    _values[_memoryReadyKey] = marker;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<String?> read(String key) async {
    return _values[key];
  }

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }
}

final appSecureStorageProvider = Provider<AppSecureStorage>((ref) {
  return MemoryAppSecureStorage();
});
