import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/data_channel_session_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/incoming_transfer_session_runner.dart';
import 'package:sponzey_file_sharing/application/transfer/incoming_transfer_session_state_machine.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_accepted_session_factory.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_hello_expectation_resolver.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_inbound_handshake_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_inbound_listener_event_coordinator.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_handshake_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_promotion_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_registry_promotion_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_channel_context_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatch_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatcher.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_listener_stream_subscription_coordinator.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_stream_frame_event_coordinator.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_stream_frame_pipeline_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_stream_frame_runner_adapter.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_transfer_frame_context_store.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_session_registry.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_stream_frame.dart';

void main() {
  test('publishes coordinator result for frame stream event', () async {
    final listener = _FakeTcpDataListener();
    final executor = _RecordingIncomingExecutor();
    final subscription = _subscription(listener, executor);
    addTearDown(subscription.stop);

    await subscription.start();
    final resultFuture = subscription.results.first;
    listener.emitFrame(_received());

    final result = await resultFuture.timeout(const Duration(seconds: 2));
    expect(result.applied, isTrue);
    expect(executor.calls, ['writeChunk', 'scheduleAckBatch']);
  });

  test('publishes issue result for frame error stream event', () async {
    final listener = _FakeTcpDataListener();
    final executor = _RecordingIncomingExecutor();
    final subscription = _subscription(listener, executor);
    addTearDown(subscription.stop);

    await subscription.start();
    final resultFuture = subscription.results.first;
    listener.emitFrameError(
      const TcpDataReceivedStreamFrameError(
        channelId: TcpDataChannelId('channel-1'),
        issueCode: 'malformed_tcp_data_stream_frame',
        error: 'bad frame',
      ),
    );

    final result = await resultFuture.timeout(const Duration(seconds: 2));
    expect(result.applied, isFalse);
    expect(result.issueCode, 'malformed_tcp_data_stream_frame');
    expect(executor.calls, isEmpty);
  });

  test('start is idempotent and does not duplicate subscriptions', () async {
    final listener = _FakeTcpDataListener();
    final subscription = _subscription(listener, _RecordingIncomingExecutor());
    addTearDown(subscription.stop);

    await subscription.start();
    await subscription.start();
    final results = <TcpIncomingStreamFrameEventCoordinatorResult>[];
    final resultSubscription = subscription.results.listen(results.add);
    addTearDown(resultSubscription.cancel);

    listener.emitFrame(_received());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(results, hasLength(1));
  });

  test('stop cancels listener subscriptions', () async {
    final listener = _FakeTcpDataListener();
    final subscription = _subscription(listener, _RecordingIncomingExecutor());

    await subscription.start();
    await subscription.stop();
    final results = <TcpIncomingStreamFrameEventCoordinatorResult>[];
    final resultSubscription = subscription.results.listen(results.add);
    addTearDown(resultSubscription.cancel);

    listener.emitFrame(_received());
    listener.emitAccepted(_accepted());
    listener.emitHello(_hello());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(results, isEmpty);
  });

  test(
    'registers inbound TCP session from accepted connection and hello',
    () async {
      final listener = _FakeTcpDataListener();
      final registry = InMemoryDataChannelSessionRegistry(
        mode: DataChannelMode.tcp,
      );
      final subscription = _subscription(
        listener,
        _RecordingIncomingExecutor(),
        dataRegistry: registry,
      );
      addTearDown(subscription.stop);

      await subscription.start();
      final resultFuture = subscription.results.first;
      listener.emitAccepted(_accepted());
      listener.emitHello(_hello());

      final result = await resultFuture.timeout(const Duration(seconds: 2));
      expect(result.applied, isTrue);
      expect(result.issueCode, isNull);
      expect(
        registry.lookup(
          const DataChannelSessionKey(
            peerId: 'peer-1',
            authSessionId: 'auth-1',
            direction: TcpDataChannelDirection.inbound,
          ),
        ),
        isNotNull,
      );
    },
  );

  test(
    'publishes resolver rejection without registering inbound session',
    () async {
      final listener = _FakeTcpDataListener();
      final registry = InMemoryDataChannelSessionRegistry(
        mode: DataChannelMode.tcp,
      );
      final subscription = _subscription(
        listener,
        _RecordingIncomingExecutor(),
        dataRegistry: registry,
        resolver: const _RejectingHelloExpectationResolver(),
      );
      addTearDown(subscription.stop);

      await subscription.start();
      final resultFuture = subscription.results.first;
      listener.emitAccepted(_accepted());
      listener.emitHello(_hello());

      final result = await resultFuture.timeout(const Duration(seconds: 2));
      expect(result.applied, isFalse);
      expect(result.issueCode, 'tcp_data_hello_peer_not_authenticated');
      expect(
        registry.lookup(
          const DataChannelSessionKey(
            peerId: 'peer-1',
            authSessionId: 'auth-1',
            direction: TcpDataChannelDirection.inbound,
          ),
        ),
        isNull,
      );
    },
  );

  test(
    'publishes hello error and clears pending accepted connection',
    () async {
      final listener = _FakeTcpDataListener();
      final registry = InMemoryDataChannelSessionRegistry(
        mode: DataChannelMode.tcp,
      );
      final subscription = _subscription(
        listener,
        _RecordingIncomingExecutor(),
        dataRegistry: registry,
      );
      addTearDown(subscription.stop);

      await subscription.start();
      final results = <TcpIncomingStreamFrameEventCoordinatorResult>[];
      final resultSubscription = subscription.results.listen(results.add);
      addTearDown(resultSubscription.cancel);

      listener.emitAccepted(_accepted());
      listener.emitHelloError(
        const TcpDataReceivedHelloError(
          channelId: TcpDataChannelId('channel-1'),
          issueCode: 'malformed_tcp_data_hello',
          error: 'bad hello',
        ),
      );
      listener.emitHello(_hello());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(results.map((result) => result.issueCode), [
        'malformed_tcp_data_hello',
        'missing_tcp_data_accepted_connection',
      ]);
      expect(
        registry.lookup(
          const DataChannelSessionKey(
            peerId: 'peer-1',
            authSessionId: 'auth-1',
            direction: TcpDataChannelDirection.inbound,
          ),
        ),
        isNull,
      );
    },
  );
}

TcpIncomingListenerStreamSubscriptionCoordinator _subscription(
  _FakeTcpDataListener listener,
  IncomingTransferSessionEffectExecutor executor, {
  DataChannelSessionRegistry? dataRegistry,
  TcpDataHelloExpectationResolverPort resolver =
      const _AcceptingHelloExpectationResolver(),
}) {
  final registry =
      dataRegistry ??
      InMemoryDataChannelSessionRegistry(mode: DataChannelMode.tcp);
  return TcpIncomingListenerStreamSubscriptionCoordinator(
    listener: listener,
    inboundCoordinator: _inboundCoordinator(registry),
    helloExpectationResolver: resolver,
    coordinator: _coordinator(executor),
  );
}

TcpDataInboundListenerEventCoordinator _inboundCoordinator(
  DataChannelSessionRegistry registry,
) {
  return TcpDataInboundListenerEventCoordinator(
    command: TcpDataInboundHandshakeCommand(
      acceptedSessionFactory: const TcpDataAcceptedSessionFactory(),
      registryPromotionCommand: TcpDataSessionRegistryPromotionCommand(
        registry: registry,
        promotionCommand: TcpDataSessionPromotionCommand(
          handshakeCommand: TcpDataSessionHandshakeCommand(
            proofVerifier: const _AllowProofVerifier(),
          ),
        ),
      ),
    ),
  );
}

TcpIncomingStreamFrameEventCoordinator _coordinator(
  IncomingTransferSessionEffectExecutor executor,
) {
  final dataRegistry = InMemoryDataChannelSessionRegistry(
    mode: DataChannelMode.tcp,
  );
  dataRegistry.register(
    const DataChannelSessionKey(
      peerId: 'peer-1',
      authSessionId: 'auth-1',
      direction: TcpDataChannelDirection.inbound,
    ),
    const TcpDataPeerSessionSnapshot(
      peerId: 'peer-1',
      sessionId: TcpDataSessionId('session-1'),
      channelId: TcpDataChannelId('channel-1'),
      direction: TcpDataChannelDirection.inbound,
      status: TcpDataPeerSessionStatus.connected,
      localEndpointLabel: '10.0.0.1:50000',
      remoteEndpointLabel: '10.0.0.2:50001',
    ),
  );
  final runnerRegistry = TransferSessionRegistry<IncomingTransferSessionRunner>(
    direction: TransferDirection.incoming,
  );
  runnerRegistry.register(
    const TransferSessionKey(
      direction: TransferDirection.incoming,
      transferId: 'transfer-1',
      peerId: 'peer-1',
      authSessionId: 'auth-1',
    ),
    IncomingTransferSessionRunner(
      executor: executor,
      initialState: IncomingTransferSessionState.receiving,
    ),
  );
  return TcpIncomingStreamFrameEventCoordinator(
    dataChannelRegistry: dataRegistry,
    incomingRunnerRegistry: runnerRegistry,
    frameContextStore: InMemoryTcpIncomingTransferFrameContextStore(),
    pipeline: const TcpIncomingStreamFramePipelineCommand(
      dispatchCommand: TcpDataStreamFrameDispatchCommand(
        contextCommand: TcpDataStreamFrameChannelContextCommand(),
        dispatcher: TcpDataStreamFrameDispatcher(),
      ),
      stageCommand: TcpIncomingTransferFrameContextStageCommand(),
      runnerAdapter: TcpIncomingStreamFrameRunnerAdapter(),
    ),
  );
}

TcpDataReceivedStreamFrame _received() {
  return TcpDataReceivedStreamFrame(
    channelId: const TcpDataChannelId('channel-1'),
    frame: TcpDataStreamFrame(
      type: TcpDataStreamFrameType.chunk,
      transferId: 'transfer-1',
      sequence: 1,
      payload: Uint8List.fromList([1, 2, 3]),
    ),
  );
}

class _FakeTcpDataListener implements TcpDataListenerPort {
  final _accepted = StreamController<TcpDataAcceptedConnection>.broadcast();
  final _hellos = StreamController<TcpDataReceivedHello>.broadcast();
  final _helloErrors = StreamController<TcpDataReceivedHelloError>.broadcast();
  final _frames = StreamController<TcpDataReceivedStreamFrame>.broadcast();
  final _frameErrors =
      StreamController<TcpDataReceivedStreamFrameError>.broadcast();

  void emitFrame(TcpDataReceivedStreamFrame frame) {
    _frames.add(frame);
  }

  void emitFrameError(TcpDataReceivedStreamFrameError error) {
    _frameErrors.add(error);
  }

  void emitAccepted(TcpDataAcceptedConnection accepted) {
    _accepted.add(accepted);
  }

  void emitHello(TcpDataReceivedHello hello) {
    _hellos.add(hello);
  }

  void emitHelloError(TcpDataReceivedHelloError error) {
    _helloErrors.add(error);
  }

  @override
  Stream<TcpDataAcceptedConnection> get acceptedConnections => _accepted.stream;

  @override
  Stream<TcpDataReceivedStreamFrameError> get frameErrors =>
      _frameErrors.stream;

  @override
  Stream<TcpDataReceivedStreamFrame> get frames => _frames.stream;

  @override
  Stream<TcpDataReceivedHelloError> get helloErrors => _helloErrors.stream;

  @override
  Stream<TcpDataReceivedHello> get hellos => _hellos.stream;

  @override
  Future<TcpDataListenerBinding> bind(TcpDataListenerBindRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<void> close() async {
    await _accepted.close();
    await _hellos.close();
    await _helloErrors.close();
    await _frames.close();
    await _frameErrors.close();
  }
}

TcpDataAcceptedConnection _accepted() {
  return const TcpDataAcceptedConnection(
    channelId: TcpDataChannelId('channel-1'),
    localEndpoint: TcpDataEndpoint(host: '10.0.0.1', port: 50001),
    remoteEndpoint: TcpDataEndpoint(host: '10.0.0.2', port: 50000),
  );
}

TcpDataReceivedHello _hello() {
  return const TcpDataReceivedHello(
    channelId: TcpDataChannelId('channel-1'),
    hello: TcpDataSessionHello(
      sessionId: TcpDataSessionId('session-1'),
      peerId: 'peer-1',
      instanceId: 'instance-1',
      authSessionId: 'auth-1',
      protocolVersion: 1,
      dataProtocolVersion: 1,
      proof: 'proof-1',
    ),
  );
}

class _AcceptingHelloExpectationResolver
    implements TcpDataHelloExpectationResolverPort {
  const _AcceptingHelloExpectationResolver();

  @override
  TcpDataHelloExpectationResolution resolve(TcpDataReceivedHello received) {
    return const TcpDataHelloExpectationResolution.accepted(
      TcpDataSessionHandshakeExpectation(
        peerId: 'peer-1',
        authSessionId: 'auth-1',
        protocolVersion: 1,
        dataProtocolVersion: 1,
      ),
    );
  }
}

class _RejectingHelloExpectationResolver
    implements TcpDataHelloExpectationResolverPort {
  const _RejectingHelloExpectationResolver();

  @override
  TcpDataHelloExpectationResolution resolve(TcpDataReceivedHello received) {
    return const TcpDataHelloExpectationResolution.rejected(
      issueCode: 'tcp_data_hello_peer_not_authenticated',
    );
  }
}

class _AllowProofVerifier implements TcpDataSessionProofVerifier {
  const _AllowProofVerifier();

  @override
  bool verify(TcpDataSessionHello hello) => true;
}

class _RecordingIncomingExecutor
    implements IncomingTransferSessionEffectExecutor {
  final List<String> calls = [];

  @override
  Future<void> bufferOutOfOrderChunk() async {
    calls.add('bufferOutOfOrderChunk');
  }

  @override
  Future<void> cancelTransfer() async {
    calls.add('cancelTransfer');
  }

  @override
  Future<void> cleanupPartialFile() async {
    calls.add('cleanupPartialFile');
  }

  @override
  Future<void> completeCancellation() async {
    calls.add('completeCancellation');
  }

  @override
  Future<void> completeTransfer() async {
    calls.add('completeTransfer');
  }

  @override
  Future<void> failTransfer() async {
    calls.add('failTransfer');
  }

  @override
  Future<void> finalizeFile() async {
    calls.add('finalizeFile');
  }

  @override
  Future<void> flushBufferedChunks() async {
    calls.add('flushBufferedChunks');
  }

  @override
  Future<void> openIncomingWriter() async {
    calls.add('openIncomingWriter');
  }

  @override
  Future<void> prepareStorage() async {
    calls.add('prepareStorage');
  }

  @override
  Future<void> rejectTransferInit() async {
    calls.add('rejectTransferInit');
  }

  @override
  Future<void> scheduleAckBatch() async {
    calls.add('scheduleAckBatch');
  }

  @override
  Future<void> scheduleNackBatch() async {
    calls.add('scheduleNackBatch');
  }

  @override
  Future<void> sendTransferInitAck() async {
    calls.add('sendTransferInitAck');
  }

  @override
  Future<void> verifyIncomingDigest() async {
    calls.add('verifyIncomingDigest');
  }

  @override
  Future<void> writeChunk() async {
    calls.add('writeChunk');
  }
}
