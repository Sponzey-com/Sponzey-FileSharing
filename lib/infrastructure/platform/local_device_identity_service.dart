import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/app_secure_storage.dart';

class LocalDeviceIdentity {
  const LocalDeviceIdentity({
    required this.deviceId,
    required this.instanceId,
    required this.osType,
  });

  final String deviceId;
  final String instanceId;
  final String osType;
}

abstract interface class LocalDeviceIdentityService {
  Future<LocalDeviceIdentity> load();
}

class SecureStorageLocalDeviceIdentityService
    implements LocalDeviceIdentityService {
  SecureStorageLocalDeviceIdentityService({
    required AppSecureStorage secureStorage,
    Random? random,
    required this.osType,
  }) : _secureStorage = secureStorage,
       _random = random ?? Random.secure(),
       _instanceId = _generateRandomId(random ?? Random.secure());

  static const _deviceIdKey = 'local_device_id';

  final AppSecureStorage _secureStorage;
  final Random _random;
  final String _instanceId;
  final String osType;

  @override
  Future<LocalDeviceIdentity> load() async {
    await _secureStorage.ensureReady();
    var deviceId = await _secureStorage.read(_deviceIdKey);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _generateDeviceId();
      await _secureStorage.write(key: _deviceIdKey, value: deviceId);
    }

    return LocalDeviceIdentity(
      deviceId: deviceId,
      instanceId: _instanceId,
      osType: osType,
    );
  }

  String _generateDeviceId() {
    return _generateRandomId(_random);
  }

  static String _generateRandomId(Random random) {
    return List<String>.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}

final localDeviceIdentityServiceProvider = Provider<LocalDeviceIdentityService>(
  (ref) {
    return SecureStorageLocalDeviceIdentityService(
      secureStorage: ref.watch(appSecureStorageProvider),
      osType: Platform.operatingSystem,
    );
  },
);
