import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatch_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatcher.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_stream_frame.dart';

class TcpIncomingTransferFrameContextKey {
  const TcpIncomingTransferFrameContextKey({
    required this.peerId,
    required this.authSessionId,
    required this.transferId,
  });

  final String peerId;
  final String authSessionId;
  final String transferId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TcpIncomingTransferFrameContextKey &&
            other.peerId == peerId &&
            other.authSessionId == authSessionId &&
            other.transferId == transferId;
  }

  @override
  int get hashCode => Object.hash(peerId, authSessionId, transferId);
}

class TcpIncomingTransferFrameContext {
  const TcpIncomingTransferFrameContext({
    required this.key,
    required this.route,
    required this.frame,
    required this.session,
  });

  final TcpIncomingTransferFrameContextKey key;
  final TcpDataStreamFrameRoute route;
  final TcpDataStreamFrame frame;
  final TcpDataPeerSessionSnapshot session;
}

class TcpIncomingTransferFrameContextStageResult {
  const TcpIncomingTransferFrameContextStageResult({
    required this.staged,
    this.key,
    this.issueCode,
  });

  final bool staged;
  final TcpIncomingTransferFrameContextKey? key;
  final String? issueCode;
}

abstract interface class TcpIncomingTransferFrameContextStore {
  Map<TcpIncomingTransferFrameContextKey, TcpIncomingTransferFrameContext>
  get entries;

  void stage(
    TcpIncomingTransferFrameContextKey key,
    TcpIncomingTransferFrameContext context,
  );

  TcpIncomingTransferFrameContext? lookup(
    TcpIncomingTransferFrameContextKey key,
  );

  TcpIncomingTransferFrameContext? clear(
    TcpIncomingTransferFrameContextKey key,
  );
}

class InMemoryTcpIncomingTransferFrameContextStore
    implements TcpIncomingTransferFrameContextStore {
  final Map<TcpIncomingTransferFrameContextKey, TcpIncomingTransferFrameContext>
  _entries = {};

  @override
  Map<TcpIncomingTransferFrameContextKey, TcpIncomingTransferFrameContext>
  get entries => Map.unmodifiable(_entries);

  @override
  void stage(
    TcpIncomingTransferFrameContextKey key,
    TcpIncomingTransferFrameContext context,
  ) {
    _entries[key] = context;
  }

  @override
  TcpIncomingTransferFrameContext? lookup(
    TcpIncomingTransferFrameContextKey key,
  ) {
    return _entries[key];
  }

  @override
  TcpIncomingTransferFrameContext? clear(
    TcpIncomingTransferFrameContextKey key,
  ) {
    return _entries.remove(key);
  }
}

class TcpIncomingTransferFrameContextStageCommand {
  const TcpIncomingTransferFrameContextStageCommand();

  TcpIncomingTransferFrameContextStageResult stage({
    required TcpIncomingTransferFrameContextStore store,
    required TcpDataStreamFrameDispatchDecision decision,
  }) {
    if (!decision.allowed ||
        decision.peerId == null ||
        decision.authSessionId == null ||
        decision.transferId == null ||
        decision.route == null ||
        decision.frame == null ||
        decision.session == null) {
      return const TcpIncomingTransferFrameContextStageResult(
        staged: false,
        issueCode: 'tcp_stream_frame_context_not_allowed',
      );
    }

    final key = TcpIncomingTransferFrameContextKey(
      peerId: decision.peerId!,
      authSessionId: decision.authSessionId!,
      transferId: decision.transferId!,
    );
    store.stage(
      key,
      TcpIncomingTransferFrameContext(
        key: key,
        route: decision.route!,
        frame: decision.frame!,
        session: decision.session!,
      ),
    );
    return TcpIncomingTransferFrameContextStageResult(staged: true, key: key);
  }
}
