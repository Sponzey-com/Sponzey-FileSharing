import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sponzey_file_sharing/infrastructure/platform/app_platform_directories.dart';

class LocalInstancePresence {
  const LocalInstancePresence({
    required this.userId,
    String? discoveryGroupTag,
    @Deprecated(
      'Use discoveryGroupTag. This is kept for legacy registry files.',
    )
    String? pairingProof,
    required this.instanceId,
    required this.displayName,
    required this.deviceId,
    required this.deviceName,
    required this.osType,
    required this.protocolVersion,
    required this.port,
    required this.receiveAvailable,
    required this.seenAtEpochMs,
  }) : assert(
         (discoveryGroupTag != null && discoveryGroupTag != '') ||
             (pairingProof != null && pairingProof != ''),
         'Local instance presence requires a discovery group tag.',
       ),
       discoveryGroupTag = discoveryGroupTag ?? pairingProof ?? '';

  final String userId;
  final String discoveryGroupTag;

  @Deprecated('Use discoveryGroupTag. This is a legacy migration alias.')
  String get pairingProof => discoveryGroupTag;

  final String instanceId;
  final String displayName;
  final String deviceId;
  final String deviceName;
  final String osType;
  final String protocolVersion;
  final int port;
  final bool receiveAvailable;
  final int seenAtEpochMs;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'userId': userId,
      'discoveryGroupTag': discoveryGroupTag,
      'instanceId': instanceId,
      'displayName': displayName,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'osType': osType,
      'protocolVersion': protocolVersion,
      'port': port,
      'receiveAvailable': receiveAvailable,
      'seenAtEpochMs': seenAtEpochMs,
    };
  }

  factory LocalInstancePresence.fromJson(Map<String, Object?> json) {
    return LocalInstancePresence(
      userId: json['userId'] as String,
      discoveryGroupTag:
          json['discoveryGroupTag'] as String? ??
          json['pairingProof'] as String,
      instanceId: json['instanceId'] as String,
      displayName: json['displayName'] as String,
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      osType: json['osType'] as String,
      protocolVersion: json['protocolVersion'] as String,
      port: json['port'] as int,
      receiveAvailable: json['receiveAvailable'] as bool,
      seenAtEpochMs: json['seenAtEpochMs'] as int,
    );
  }
}

abstract interface class LocalInstanceRegistry {
  Future<void> publish(LocalInstancePresence presence);

  Future<List<LocalInstancePresence>> listActive({
    required DateTime now,
    required Duration maxAge,
  });

  Future<void> remove(String instanceId);
}

class FileLocalInstanceRegistry implements LocalInstanceRegistry {
  FileLocalInstanceRegistry({
    List<Directory>? baseDirectories,
    Map<String, String>? environment,
    bool? isWindows,
    bool? isMacOS,
    Future<Directory> Function()? applicationSupportDirectoryLoader,
  }) : _baseDirectories = baseDirectories,
       _environment = environment ?? Platform.environment,
       _isWindows = isWindows ?? Platform.isWindows,
       _isMacOS = isMacOS ?? Platform.isMacOS,
       _applicationSupportDirectoryLoader =
           applicationSupportDirectoryLoader ??
           AppPlatformDirectories.getApplicationSupportDirectory;

  final List<Directory>? _baseDirectories;
  final Map<String, String> _environment;
  final bool _isWindows;
  final bool _isMacOS;
  final Future<Directory> Function() _applicationSupportDirectoryLoader;

  @override
  Future<void> publish(LocalInstancePresence presence) async {
    final directories = await _resolveBaseDirectories();
    final payload = jsonEncode(presence.toJson());
    for (final directory in directories) {
      try {
        await directory.create(recursive: true);
        final file = File(_filePath(directory, presence.instanceId));
        await file.writeAsString(payload, flush: true);
        final legacyFile = File(_filePath(directory, presence.deviceId));
        if (legacyFile.path != file.path && await legacyFile.exists()) {
          await legacyFile.delete();
        }
      } on FileSystemException {
        continue;
      }
    }
  }

  @override
  Future<List<LocalInstancePresence>> listActive({
    required DateTime now,
    required Duration maxAge,
  }) async {
    final merged = <String, LocalInstancePresence>{};
    final directories = await _resolveBaseDirectories();

    for (final directory in directories) {
      if (!await directory.exists()) {
        continue;
      }

      await for (final entity in directory.list(followLinks: false)) {
        if (entity is! File || !entity.path.endsWith('.json')) {
          continue;
        }

        try {
          final raw = jsonDecode(await entity.readAsString());
          if (raw is! Map<String, Object?>) {
            continue;
          }

          final presence = LocalInstancePresence.fromJson(raw);
          final stat = await entity.stat();
          final seenAt = _effectiveSeenAt(presence, stat.modified);
          if (now.difference(seenAt) > maxAge) {
            await entity.delete();
            continue;
          }

          final effectivePresence = _withSeenAt(presence, seenAt);
          final existing = merged[effectivePresence.instanceId];
          if (existing == null ||
              existing.seenAtEpochMs < effectivePresence.seenAtEpochMs) {
            merged[effectivePresence.instanceId] = effectivePresence;
          }
        } on FileSystemException {
          continue;
        } on FormatException {
          continue;
        } on TypeError {
          continue;
        }
      }
    }

    return merged.values.toList(growable: false);
  }

  @override
  Future<void> remove(String instanceId) async {
    final directories = await _resolveBaseDirectories();
    for (final directory in directories) {
      final file = File(_filePath(directory, instanceId));
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<List<Directory>> _resolveBaseDirectories() async {
    if (_baseDirectories != null) {
      return _baseDirectories;
    }

    final directories = <String, Directory>{
      Directory.systemTemp.path: Directory(
        p.join(
          Directory.systemTemp.path,
          'sponzey-filesharing-local-discovery',
        ),
      ),
    };

    try {
      final supportDirectory = await _applicationSupportDirectoryLoader();
      directories[supportDirectory.path] = Directory(
        p.join(supportDirectory.path, 'runtime', 'local-discovery'),
      );
    } on FileSystemException {
      // Fall back to temp-based and shared registries only.
    }

    for (final directory in _resolveSharedRegistryDirectories()) {
      directories[directory.path] = directory;
    }

    return directories.values.toList(growable: false);
  }

  String _filePath(Directory directory, String instanceId) {
    return p.join(directory.path, 'peer-$instanceId.json');
  }

  DateTime _effectiveSeenAt(
    LocalInstancePresence presence,
    DateTime fileModifiedAt,
  ) {
    final payloadSeenAt = DateTime.fromMillisecondsSinceEpoch(
      presence.seenAtEpochMs,
    );
    return payloadSeenAt.isAfter(fileModifiedAt)
        ? payloadSeenAt
        : fileModifiedAt;
  }

  LocalInstancePresence _withSeenAt(
    LocalInstancePresence presence,
    DateTime seenAt,
  ) {
    return LocalInstancePresence(
      userId: presence.userId,
      discoveryGroupTag: presence.discoveryGroupTag,
      instanceId: presence.instanceId,
      displayName: presence.displayName,
      deviceId: presence.deviceId,
      deviceName: presence.deviceName,
      osType: presence.osType,
      protocolVersion: presence.protocolVersion,
      port: presence.port,
      receiveAvailable: presence.receiveAvailable,
      seenAtEpochMs: seenAt.millisecondsSinceEpoch,
    );
  }

  List<Directory> _resolveSharedRegistryDirectories() {
    final directories = <Directory>[];

    if (_isMacOS) {
      final home = _environment['HOME'];
      if (home != null && home.isNotEmpty) {
        final workPlacesRoot = Directory(p.join(home, 'WorkPlaces'));
        if (workPlacesRoot.existsSync()) {
          directories.add(
            Directory(
              p.join(
                workPlacesRoot.path,
                '.sponzey-filesharing-runtime',
                'local-discovery',
              ),
            ),
          );
        }
      }
    }

    if (_isWindows) {
      const windowsRoots = <String>[r'Y:\', r'Z:\', r'\\Mac\WorkPlaces'];
      for (final root in windowsRoots) {
        final rootDirectory = Directory(root);
        if (!rootDirectory.existsSync()) {
          continue;
        }
        directories.add(
          Directory(
            p.join(root, '.sponzey-filesharing-runtime', 'local-discovery'),
          ),
        );
      }
    }

    return directories;
  }
}

final localInstanceRegistryProvider = Provider<LocalInstanceRegistry>((ref) {
  return FileLocalInstanceRegistry();
});
