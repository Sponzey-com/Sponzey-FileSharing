import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/data_channel_session_registry.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';

void main() {
  const outgoingKey = DataChannelSessionKey(
    peerId: 'peer-1',
    authSessionId: 'auth-1',
    direction: TcpDataChannelDirection.outbound,
  );
  const incomingKey = DataChannelSessionKey(
    peerId: 'peer-1',
    authSessionId: 'auth-1',
    direction: TcpDataChannelDirection.inbound,
  );

  const outgoingSession = TcpDataPeerSessionSnapshot(
    peerId: 'peer-1',
    sessionId: TcpDataSessionId('session-out'),
    channelId: TcpDataChannelId('channel-out'),
    direction: TcpDataChannelDirection.outbound,
    status: TcpDataPeerSessionStatus.connected,
    localEndpointLabel: '10.0.0.1:50000',
    remoteEndpointLabel: '10.0.0.2:50001',
  );
  const incomingSession = TcpDataPeerSessionSnapshot(
    peerId: 'peer-1',
    sessionId: TcpDataSessionId('session-in'),
    channelId: TcpDataChannelId('channel-in'),
    direction: TcpDataChannelDirection.inbound,
    status: TcpDataPeerSessionStatus.connected,
    localEndpointLabel: '10.0.0.1:50001',
    remoteEndpointLabel: '10.0.0.2:50000',
  );

  test('mode is fixed when registry is created', () {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );

    expect(registry.mode, DataChannelMode.tcp);
  });

  test('keeps inbound and outbound channels separate for the same peer', () {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );

    expect(registry.register(outgoingKey, outgoingSession).registered, isTrue);
    expect(registry.register(incomingKey, incomingSession).registered, isTrue);

    expect(registry.lookup(outgoingKey)?.channelId, outgoingSession.channelId);
    expect(registry.lookup(incomingKey)?.channelId, incomingSession.channelId);
  });

  test('rejects duplicate channel registration', () {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );
    registry.register(outgoingKey, outgoingSession);

    final result = registry.register(outgoingKey, outgoingSession);

    expect(result.registered, isFalse);
    expect(result.issueCode, 'duplicate_data_channel_session');
    expect(result.status, DataChannelSessionEntryStatus.registered);
  });

  test('does not revive removed sessions from late events', () {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );
    registry.register(outgoingKey, outgoingSession);

    expect(registry.remove(outgoingKey), outgoingSession);
    expect(
      registry.statusOf(outgoingKey),
      DataChannelSessionEntryStatus.removed,
    );

    final lateResult = registry.register(outgoingKey, outgoingSession);

    expect(lateResult.registered, isFalse);
    expect(lateResult.issueCode, 'removed_data_channel_session');
    expect(registry.lookup(outgoingKey), isNull);
  });

  test('allows explicit re-registration for negotiated channel recovery', () {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );
    registry.register(outgoingKey, outgoingSession);

    expect(
      registry.remove(outgoingKey, allowReregister: true),
      outgoingSession,
    );
    expect(registry.statusOf(outgoingKey), isNull);

    final result = registry.register(outgoingKey, outgoingSession);

    expect(result.registered, isTrue);
    expect(registry.lookup(outgoingKey), outgoingSession);
  });

  test('rejects key and session direction mismatch', () {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );

    final result = registry.register(outgoingKey, incomingSession);

    expect(result.registered, isFalse);
    expect(result.issueCode, 'data_channel_direction_mismatch');
    expect(registry.lookup(outgoingKey), isNull);
  });

  test('finds registered session by direction and channel id', () {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );
    registry.register(incomingKey, incomingSession);

    expect(
      registry.lookupByChannelId(
        direction: TcpDataChannelDirection.inbound,
        channelId: incomingSession.channelId,
      ),
      incomingSession,
    );
    expect(
      registry.lookupByChannelId(
        direction: TcpDataChannelDirection.outbound,
        channelId: incomingSession.channelId,
      ),
      isNull,
    );
  });

  test('snapshots only currently registered sessions', () {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );
    registry.register(outgoingKey, outgoingSession);
    registry.register(incomingKey, incomingSession);

    expect(registry.snapshot(), [incomingSession, outgoingSession]);

    registry.remove(outgoingKey);

    expect(registry.snapshot(), [incomingSession]);
  });
}
