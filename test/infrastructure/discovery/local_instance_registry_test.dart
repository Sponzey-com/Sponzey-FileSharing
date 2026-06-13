import 'dart:convert';
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
        discoveryGroupTag: 'group-tag-001',
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

      final legacyFile = File(
        p.join(
          workPlacesDirectory.path,
          '.sponzey-filesharing-runtime',
          'local-discovery',
          'peer-device-01.json',
        ),
      );
      await legacyFile.parent.create(recursive: true);
      await legacyFile.writeAsString('legacy');

      await registry.publish(presence);

      final sharedFile = File(
        p.join(
          workPlacesDirectory.path,
          '.sponzey-filesharing-runtime',
          'local-discovery',
          'peer-instance-01.json',
        ),
      );
      expect(await sharedFile.exists(), isTrue);
      expect(await legacyFile.exists(), isFalse);
      expect(await sharedFile.readAsString(), contains('discoveryGroupTag'));
      expect(await sharedFile.readAsString(), isNot(contains('pairingProof')));
    },
  );

  test('decodes legacy pairingProof registry entries as group tags', () {
    final presence = LocalInstancePresence.fromJson(const <String, Object?>{
      'userId': 'team',
      'pairingProof': 'legacy-proof',
      'instanceId': 'instance-01',
      'displayName': 'Team Node',
      'deviceId': 'device-01',
      'deviceName': 'Mac Host',
      'osType': 'macos',
      'protocolVersion': '1.0',
      'port': 38401,
      'receiveAvailable': true,
      'seenAtEpochMs': 123456789,
    });

    expect(presence.discoveryGroupTag, 'legacy-proof');
  });

  test('keeps multiple runtime instances that share one device id', () async {
    final sandbox = await Directory.systemTemp.createTemp(
      'sponzey-local-registry-test-',
    );
    addTearDown(() async {
      if (await sandbox.exists()) {
        await sandbox.delete(recursive: true);
      }
    });

    final registry = FileLocalInstanceRegistry(
      baseDirectories: [sandbox],
      isMacOS: false,
      isWindows: false,
      applicationSupportDirectoryLoader: () async => sandbox,
    );

    await registry.publish(
      const LocalInstancePresence(
        userId: 'team',
        discoveryGroupTag: 'group-tag-001',
        instanceId: 'instance-01',
        displayName: 'First Window',
        deviceId: 'same-device',
        deviceName: 'Mac Host',
        osType: 'macos',
        protocolVersion: '1.0',
        port: 40201,
        receiveAvailable: true,
        seenAtEpochMs: 123456789,
      ),
    );
    await registry.publish(
      const LocalInstancePresence(
        userId: 'team',
        discoveryGroupTag: 'group-tag-001',
        instanceId: 'instance-02',
        displayName: 'Second Window',
        deviceId: 'same-device',
        deviceName: 'Mac Host',
        osType: 'macos',
        protocolVersion: '1.0',
        port: 40202,
        receiveAvailable: true,
        seenAtEpochMs: 123456790,
      ),
    );

    final entries = await registry.listActive(
      now: DateTime.fromMillisecondsSinceEpoch(123456800),
      maxAge: const Duration(minutes: 1),
    );
    expect(entries.map((entry) => entry.instanceId).toSet(), {
      'instance-01',
      'instance-02',
    });
    expect(entries.map((entry) => entry.port).toSet(), {40201, 40202});

    await registry.remove('instance-01');

    final remaining = await registry.listActive(
      now: DateTime.fromMillisecondsSinceEpoch(123456800),
      maxAge: const Duration(minutes: 1),
    );
    expect(remaining.map((entry) => entry.instanceId), ['instance-02']);
  });

  test(
    'uses registry file modified time when payload clock is stale',
    () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'sponzey-local-registry-test-',
      );
      addTearDown(() async {
        if (await sandbox.exists()) {
          await sandbox.delete(recursive: true);
        }
      });

      final registry = FileLocalInstanceRegistry(
        baseDirectories: [sandbox],
        isMacOS: false,
        isWindows: false,
        applicationSupportDirectoryLoader: () async => sandbox,
      );
      final now = DateTime(2026, 4, 9, 12, 0, 0);
      final modifiedAt = now.subtract(const Duration(seconds: 5));
      final oldPayloadSeenAt = now.subtract(const Duration(hours: 1));
      final file = File(p.join(sandbox.path, 'peer-instance-skewed.json'));
      await file.writeAsString(
        jsonEncode(
          const LocalInstancePresence(
              userId: 'team',
              discoveryGroupTag: 'group-tag-001',
              instanceId: 'instance-skewed',
              displayName: 'Windows VM',
              deviceId: 'same-device',
              deviceName: 'Windows Host',
              osType: 'windows',
              protocolVersion: '1.0',
              port: 40202,
              receiveAvailable: true,
              seenAtEpochMs: 1,
            ).toJson()
            ..['seenAtEpochMs'] = oldPayloadSeenAt.millisecondsSinceEpoch,
        ),
      );
      await file.setLastModified(modifiedAt);

      final entries = await registry.listActive(
        now: now,
        maxAge: const Duration(seconds: 30),
      );

      expect(entries, hasLength(1));
      expect(entries.single.instanceId, 'instance-skewed');
      expect(
        entries.single.seenAtEpochMs,
        greaterThan(oldPayloadSeenAt.millisecondsSinceEpoch),
      );
    },
  );
}
