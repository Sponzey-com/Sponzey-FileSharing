import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sponzey_file_sharing/infrastructure/discovery/local_instance_registry.dart';

void main() {
  test(
    'macOS shared registry writes into WorkPlaces fallback directory',
    () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'sponzey-local-registry-test-',
      );
      addTearDown(() async {
        if (await sandbox.exists()) {
          await sandbox.delete(recursive: true);
        }
      });

      final homeDirectory = Directory(p.join(sandbox.path, 'home'));
      final workPlacesDirectory = Directory(
        p.join(homeDirectory.path, 'WorkPlaces'),
      );
      await workPlacesDirectory.create(recursive: true);

      final supportDirectory = Directory(p.join(sandbox.path, 'support'));
      final registry = FileLocalInstanceRegistry(
        environment: <String, String>{'HOME': homeDirectory.path},
        isMacOS: true,
        isWindows: false,
        applicationSupportDirectoryLoader: () async => supportDirectory,
      );

      const presence = LocalInstancePresence(
        userId: 'team',
        pairingProof: 'proof-001',
        instanceId: 'instance-01',
        displayName: 'Team Node',
        deviceId: 'device-01',
        deviceName: 'Mac Host',
        osType: 'macos',
        protocolVersion: '1.0',
        port: 38401,
        receiveAvailable: true,
        seenAtEpochMs: 123456789,
      );

      await registry.publish(presence);

      final sharedFile = File(
        p.join(
          workPlacesDirectory.path,
          '.sponzey-filesharing-runtime',
          'local-discovery',
          'peer-device-01.json',
        ),
      );
      expect(await sharedFile.exists(), isTrue);
    },
  );
}
