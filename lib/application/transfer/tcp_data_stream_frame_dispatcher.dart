import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_stream_frame.dart';

enum TcpDataStreamFrameRoute { metadata, chunk, complete, cancel, error }

extension TcpDataStreamFrameRouteDirection on TcpDataStreamFrameRoute {
  TransferDirection get expectedDirection => TransferDirection.incoming;
}

class TcpDataStreamFrameDispatcher {
  const TcpDataStreamFrameDispatcher();

  TcpDataStreamFrameRoute routeFor(TcpDataStreamFrameType type) {
    switch (type) {
      case TcpDataStreamFrameType.metadata:
        return TcpDataStreamFrameRoute.metadata;
      case TcpDataStreamFrameType.chunk:
        return TcpDataStreamFrameRoute.chunk;
      case TcpDataStreamFrameType.complete:
        return TcpDataStreamFrameRoute.complete;
      case TcpDataStreamFrameType.cancel:
        return TcpDataStreamFrameRoute.cancel;
      case TcpDataStreamFrameType.error:
        return TcpDataStreamFrameRoute.error;
    }
  }
}
