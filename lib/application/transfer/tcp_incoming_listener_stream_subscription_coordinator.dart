import 'dart:async';

import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_hello_expectation_resolver.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_inbound_listener_event_coordinator.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_stream_frame_event_coordinator.dart';

abstract interface class TcpIncomingListenerSubscriptionPort {
  Stream<TcpIncomingStreamFrameEventCoordinatorResult> get results;

  bool get isRunning;

  Future<void> start();

  Future<void> stop();

  Future<void> dispose();
}

class TcpIncomingListenerStreamSubscriptionCoordinator
    implements TcpIncomingListenerSubscriptionPort {
  TcpIncomingListenerStreamSubscriptionCoordinator({
    required this.listener,
    required this.inboundCoordinator,
    required this.helloExpectationResolver,
    required this.coordinator,
  });

  final TcpDataListenerPort listener;
  final TcpDataInboundListenerEventCoordinator inboundCoordinator;
  final TcpDataHelloExpectationResolverPort helloExpectationResolver;
  final TcpIncomingStreamFrameEventCoordinator coordinator;
  final StreamController<TcpIncomingStreamFrameEventCoordinatorResult>
  _resultsController =
      StreamController<
        TcpIncomingStreamFrameEventCoordinatorResult
      >.broadcast();
  StreamSubscription<TcpDataAcceptedConnection>? _acceptedSubscription;
  StreamSubscription<TcpDataReceivedHello>? _helloSubscription;
  StreamSubscription<TcpDataReceivedHelloError>? _helloErrorSubscription;
  StreamSubscription<TcpDataReceivedStreamFrame>? _frameSubscription;
  StreamSubscription<TcpDataReceivedStreamFrameError>? _frameErrorSubscription;
  Future<void> _frameProcessing = Future<void>.value();

  @override
  Stream<TcpIncomingStreamFrameEventCoordinatorResult> get results =>
      _resultsController.stream;

  @override
  bool get isRunning =>
      _acceptedSubscription != null ||
      _helloSubscription != null ||
      _helloErrorSubscription != null ||
      _frameSubscription != null ||
      _frameErrorSubscription != null;

  @override
  Future<void> start() async {
    if (isRunning) {
      return;
    }
    _acceptedSubscription = listener.acceptedConnections.listen(
      inboundCoordinator.handleAccepted,
    );
    _helloSubscription = listener.hellos.listen(_handleHello);
    _helloErrorSubscription = listener.helloErrors.listen(_handleHelloError);
    _frameSubscription = listener.frames.listen(_handleFrame);
    _frameErrorSubscription = listener.frameErrors.listen(_handleFrameError);
  }

  @override
  Future<void> stop() async {
    await _acceptedSubscription?.cancel();
    await _helloSubscription?.cancel();
    await _helloErrorSubscription?.cancel();
    await _frameSubscription?.cancel();
    await _frameErrorSubscription?.cancel();
    _acceptedSubscription = null;
    _helloSubscription = null;
    _helloErrorSubscription = null;
    _frameSubscription = null;
    _frameErrorSubscription = null;
    await _frameProcessing;
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _resultsController.close();
  }

  void _handleFrame(TcpDataReceivedStreamFrame frame) {
    _frameProcessing = _frameProcessing
        .then((_) {
          return coordinator.handleFrame(frame).then(_emitResult);
        })
        .catchError((Object _) {
          _emitResult(
            const TcpIncomingStreamFrameEventCoordinatorResult(
              applied: false,
              issueCode: 'tcp_incoming_frame_pipeline_failed',
            ),
          );
        });
    unawaited(_frameProcessing);
  }

  void _handleFrameError(TcpDataReceivedStreamFrameError error) {
    _frameProcessing = _frameProcessing.then((_) {
      _emitResult(coordinator.handleFrameError(error));
    });
    unawaited(_frameProcessing);
  }

  void _handleHello(TcpDataReceivedHello received) {
    final resolution = helloExpectationResolver.resolve(received);
    if (!resolution.accepted || resolution.expectation == null) {
      _emitResult(
        TcpIncomingStreamFrameEventCoordinatorResult(
          applied: false,
          issueCode:
              resolution.issueCode ?? 'tcp_data_hello_expectation_rejected',
        ),
      );
      return;
    }

    final result = inboundCoordinator.handleHello(
      received: received,
      expectation: resolution.expectation!,
    );
    _emitResult(
      TcpIncomingStreamFrameEventCoordinatorResult(
        applied: result.registered,
        issueCode: result.issueCode,
      ),
    );
  }

  void _handleHelloError(TcpDataReceivedHelloError error) {
    final result = inboundCoordinator.handleHelloError(error);
    _emitResult(
      TcpIncomingStreamFrameEventCoordinatorResult(
        applied: false,
        issueCode: result.issueCode,
      ),
    );
  }

  void _emitResult(TcpIncomingStreamFrameEventCoordinatorResult result) {
    if (!_resultsController.isClosed) {
      _resultsController.add(result);
    }
  }
}
