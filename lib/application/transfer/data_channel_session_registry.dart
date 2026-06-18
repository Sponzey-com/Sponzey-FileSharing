import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';

enum DataChannelMode { legacyUdp, tcp }

enum DataChannelSessionEntryStatus { registered, closing, removed }

class DataChannelSessionKey {
  const DataChannelSessionKey({
    required this.peerId,
    required this.authSessionId,
    required this.direction,
  });

  final String peerId;
  final String authSessionId;
  final TcpDataChannelDirection direction;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DataChannelSessionKey &&
            other.peerId == peerId &&
            other.authSessionId == authSessionId &&
            other.direction == direction;
  }

  @override
  int get hashCode => Object.hash(peerId, authSessionId, direction);
}

class DataChannelSessionRegistryResult {
  const DataChannelSessionRegistryResult({
    required this.registered,
    required this.status,
    this.issueCode,
  });

  final bool registered;
  final DataChannelSessionEntryStatus status;
  final String? issueCode;

  const DataChannelSessionRegistryResult.accepted()
    : registered = true,
      status = DataChannelSessionEntryStatus.registered,
      issueCode = null;

  const DataChannelSessionRegistryResult.rejected({
    required this.status,
    required this.issueCode,
  }) : registered = false;
}

class DataChannelSessionLookup {
  const DataChannelSessionLookup({required this.key, required this.session});

  final DataChannelSessionKey key;
  final TcpDataPeerSessionSnapshot session;
}

abstract interface class DataChannelSessionRegistry {
  DataChannelMode get mode;

  DataChannelSessionRegistryResult register(
    DataChannelSessionKey key,
    TcpDataPeerSessionSnapshot session,
  );

  TcpDataPeerSessionSnapshot? lookup(DataChannelSessionKey key);

  TcpDataPeerSessionSnapshot? lookupByChannelId({
    required TcpDataChannelDirection direction,
    required TcpDataChannelId channelId,
  });

  DataChannelSessionLookup? lookupContextByChannelId({
    required TcpDataChannelDirection direction,
    required TcpDataChannelId channelId,
  });

  DataChannelSessionEntryStatus? statusOf(DataChannelSessionKey key);

  List<TcpDataPeerSessionSnapshot> snapshot();

  TcpDataPeerSessionSnapshot? remove(
    DataChannelSessionKey key, {
    bool allowReregister = false,
  });
}

class InMemoryDataChannelSessionRegistry implements DataChannelSessionRegistry {
  InMemoryDataChannelSessionRegistry({required this.mode});

  @override
  final DataChannelMode mode;

  final Map<DataChannelSessionKey, _DataChannelSessionEntry> _entries = {};
  final Set<DataChannelSessionKey> _removedKeys = {};

  @override
  DataChannelSessionRegistryResult register(
    DataChannelSessionKey key,
    TcpDataPeerSessionSnapshot session,
  ) {
    if (key.peerId != session.peerId || key.direction != session.direction) {
      return const DataChannelSessionRegistryResult.rejected(
        status: DataChannelSessionEntryStatus.removed,
        issueCode: 'data_channel_direction_mismatch',
      );
    }
    if (_removedKeys.contains(key)) {
      return const DataChannelSessionRegistryResult.rejected(
        status: DataChannelSessionEntryStatus.removed,
        issueCode: 'removed_data_channel_session',
      );
    }
    if (_entries.containsKey(key)) {
      return const DataChannelSessionRegistryResult.rejected(
        status: DataChannelSessionEntryStatus.registered,
        issueCode: 'duplicate_data_channel_session',
      );
    }

    _entries[key] = _DataChannelSessionEntry(
      session: session,
      status: DataChannelSessionEntryStatus.registered,
    );
    return const DataChannelSessionRegistryResult.accepted();
  }

  @override
  TcpDataPeerSessionSnapshot? lookup(DataChannelSessionKey key) {
    final entry = _entries[key];
    if (entry == null ||
        entry.status != DataChannelSessionEntryStatus.registered) {
      return null;
    }
    return entry.session;
  }

  @override
  TcpDataPeerSessionSnapshot? lookupByChannelId({
    required TcpDataChannelDirection direction,
    required TcpDataChannelId channelId,
  }) {
    return lookupContextByChannelId(
      direction: direction,
      channelId: channelId,
    )?.session;
  }

  @override
  DataChannelSessionLookup? lookupContextByChannelId({
    required TcpDataChannelDirection direction,
    required TcpDataChannelId channelId,
  }) {
    for (final entry in _entries.entries) {
      if (entry.key.direction != direction) {
        continue;
      }
      if (entry.value.status != DataChannelSessionEntryStatus.registered) {
        continue;
      }
      if (entry.value.session.channelId == channelId) {
        return DataChannelSessionLookup(
          key: entry.key,
          session: entry.value.session,
        );
      }
    }
    return null;
  }

  @override
  TcpDataPeerSessionSnapshot? remove(
    DataChannelSessionKey key, {
    bool allowReregister = false,
  }) {
    final entry = _entries.remove(key);
    if (allowReregister) {
      _removedKeys.remove(key);
    } else {
      _removedKeys.add(key);
    }
    return entry?.session;
  }

  @override
  DataChannelSessionEntryStatus? statusOf(DataChannelSessionKey key) {
    final entry = _entries[key];
    if (entry != null) {
      return entry.status;
    }
    if (_removedKeys.contains(key)) {
      return DataChannelSessionEntryStatus.removed;
    }
    return null;
  }

  @override
  List<TcpDataPeerSessionSnapshot> snapshot() {
    final entries = _entries.entries
        .where(
          (entry) =>
              entry.value.status == DataChannelSessionEntryStatus.registered,
        )
        .toList(growable: false);
    entries.sort((a, b) {
      final peerCompare = a.key.peerId.compareTo(b.key.peerId);
      if (peerCompare != 0) {
        return peerCompare;
      }
      final authCompare = a.key.authSessionId.compareTo(b.key.authSessionId);
      if (authCompare != 0) {
        return authCompare;
      }
      return a.key.direction.name.compareTo(b.key.direction.name);
    });
    return entries.map((entry) => entry.value.session).toList(growable: false);
  }
}

class _DataChannelSessionEntry {
  _DataChannelSessionEntry({required this.session, required this.status});

  final TcpDataPeerSessionSnapshot session;
  final DataChannelSessionEntryStatus status;
}
