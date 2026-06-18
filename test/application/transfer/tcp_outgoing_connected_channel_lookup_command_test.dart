import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/data_channel_session_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_outgoing_connected_channel_lookup_command.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';

void main() {
  test('returns connected outbound channel id', () {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );
    registry.register(
      const DataChannelSessionKey(
        peerId: 'peer-1',
        authSessionId: 'auth-1',
        direction: TcpDataChannelDirection.outbound,
      ),
      _session(
        direction: TcpDataChannelDirection.outbound,
        status: TcpDataPeerSessionStatus.connected,
      ),
    );
    const command = TcpOutgoingConnectedChannelLookupCommand();

    final result = command.lookup(
      registry: registry,
      peerId: 'peer-1',
      authSessionId: 'auth-1',
    );

    expect(result.found, isTrue);
    expect(result.channelId, const TcpDataChannelId('channel-1'));
    expect(result.issueCode, isNull);
  });

  test('rejects missing outbound channel', () {
    const command = TcpOutgoingConnectedChannelLookupCommand();

    final result = command.lookup(
      registry: InMemoryDataChannelSessionRegistry(mode: DataChannelMode.tcp),
      peerId: 'peer-1',
      authSessionId: 'auth-1',
    );

    expect(result.found, isFalse);
    expect(result.issueCode, 'missing_tcp_outgoing_data_channel');
  });

  test('does not use inbound session as outgoing channel', () {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );
    registry.register(
      const DataChannelSessionKey(
        peerId: 'peer-1',
        authSessionId: 'auth-1',
        direction: TcpDataChannelDirection.inbound,
      ),
      _session(
        direction: TcpDataChannelDirection.inbound,
        status: TcpDataPeerSessionStatus.connected,
      ),
    );
    const command = TcpOutgoingConnectedChannelLookupCommand();

    final result = command.lookup(
      registry: registry,
      peerId: 'peer-1',
      authSessionId: 'auth-1',
    );

    expect(result.found, isFalse);
    expect(result.issueCode, 'missing_tcp_outgoing_data_channel');
  });

  test('rejects outbound channel that is not connected', () {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );
    registry.register(
      const DataChannelSessionKey(
        peerId: 'peer-1',
        authSessionId: 'auth-1',
        direction: TcpDataChannelDirection.outbound,
      ),
      _session(
        direction: TcpDataChannelDirection.outbound,
        status: TcpDataPeerSessionStatus.authenticating,
      ),
    );
    const command = TcpOutgoingConnectedChannelLookupCommand();

    final result = command.lookup(
      registry: registry,
      peerId: 'peer-1',
      authSessionId: 'auth-1',
    );

    expect(result.found, isFalse);
    expect(result.issueCode, 'tcp_outgoing_data_channel_not_connected');
  });
}

TcpDataPeerSessionSnapshot _session({
  required TcpDataChannelDirection direction,
  required TcpDataPeerSessionStatus status,
}) {
  return TcpDataPeerSessionSnapshot(
    peerId: 'peer-1',
    sessionId: const TcpDataSessionId('session-1'),
    channelId: const TcpDataChannelId('channel-1'),
    direction: direction,
    status: status,
    localEndpointLabel: '10.0.0.1:50000',
    remoteEndpointLabel: '10.0.0.2:50001',
  );
}
