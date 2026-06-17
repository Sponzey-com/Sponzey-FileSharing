import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';

class TransferSessionKey {
  const TransferSessionKey({
    required this.direction,
    required this.transferId,
    required this.peerId,
    required this.authSessionId,
  });

  final TransferDirection direction;
  final String transferId;
  final String peerId;
  final String authSessionId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TransferSessionKey &&
            other.direction == direction &&
            other.transferId == transferId &&
            other.peerId == peerId &&
            other.authSessionId == authSessionId;
  }

  @override
  int get hashCode {
    return Object.hash(direction, transferId, peerId, authSessionId);
  }

  @override
  String toString() {
    return 'TransferSessionKey(${direction.name}, $peerId, $transferId)';
  }
}

enum TransferSessionEntryStatus { registered, closing, removed }

class TransferSessionRegistryResult {
  const TransferSessionRegistryResult({
    required this.registered,
    required this.status,
    this.issueCode,
  });

  final bool registered;
  final TransferSessionEntryStatus status;
  final String? issueCode;

  const TransferSessionRegistryResult.accepted()
    : registered = true,
      status = TransferSessionEntryStatus.registered,
      issueCode = null;

  const TransferSessionRegistryResult.rejected({
    required this.issueCode,
    required this.status,
  }) : registered = false;
}

class TransferSessionLifecycleResult<T> {
  const TransferSessionLifecycleResult({
    required this.status,
    this.value,
    this.issueCode,
  });

  final TransferSessionEntryStatus status;
  final T? value;
  final String? issueCode;
}

class TransferSessionRegistry<T extends Object> {
  TransferSessionRegistry({required this.direction});

  final TransferDirection direction;
  final Map<TransferSessionKey, _TransferSessionEntry<T>> _entries = {};
  final Set<TransferSessionKey> _removedKeys = {};

  TransferSessionRegistryResult register(TransferSessionKey key, T value) {
    if (key.direction != direction) {
      return const TransferSessionRegistryResult.rejected(
        issueCode: 'wrong_transfer_session_direction',
        status: TransferSessionEntryStatus.removed,
      );
    }
    if (_removedKeys.contains(key)) {
      return const TransferSessionRegistryResult.rejected(
        issueCode: 'removed_transfer_session',
        status: TransferSessionEntryStatus.removed,
      );
    }
    if (_entries.containsKey(key)) {
      return const TransferSessionRegistryResult.rejected(
        issueCode: 'duplicate_transfer_session',
        status: TransferSessionEntryStatus.registered,
      );
    }

    _entries[key] = _TransferSessionEntry<T>(
      value: value,
      status: TransferSessionEntryStatus.registered,
    );
    return const TransferSessionRegistryResult.accepted();
  }

  T? lookup(TransferSessionKey key) {
    if (key.direction != direction) {
      return null;
    }
    final entry = _entries[key];
    if (entry == null ||
        entry.status != TransferSessionEntryStatus.registered) {
      return null;
    }
    return entry.value;
  }

  TransferSessionLifecycleResult<T> markClosing(TransferSessionKey key) {
    if (key.direction != direction) {
      return TransferSessionLifecycleResult<T>(
        status: TransferSessionEntryStatus.removed,
        issueCode: 'wrong_transfer_session_direction',
      );
    }
    final entry = _entries[key];
    if (entry == null) {
      return TransferSessionLifecycleResult<T>(
        status: statusOf(key) ?? TransferSessionEntryStatus.removed,
        issueCode: 'missing_transfer_session',
      );
    }
    entry.status = TransferSessionEntryStatus.closing;
    return TransferSessionLifecycleResult<T>(
      status: entry.status,
      value: entry.value,
    );
  }

  T? remove(TransferSessionKey key) {
    if (key.direction != direction) {
      return null;
    }
    final entry = _entries.remove(key);
    _removedKeys.add(key);
    return entry?.value;
  }

  TransferSessionEntryStatus? statusOf(TransferSessionKey key) {
    if (key.direction != direction) {
      return null;
    }
    final entry = _entries[key];
    if (entry != null) {
      return entry.status;
    }
    if (_removedKeys.contains(key)) {
      return TransferSessionEntryStatus.removed;
    }
    return null;
  }
}

class _TransferSessionEntry<T> {
  _TransferSessionEntry({required this.value, required this.status});

  final T value;
  TransferSessionEntryStatus status;
}
