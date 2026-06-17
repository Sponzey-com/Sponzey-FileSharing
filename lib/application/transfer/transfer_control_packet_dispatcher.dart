import 'package:sponzey_file_sharing/infrastructure/auth/auth_packet.dart';

enum TransferControlPacketRoute {
  transferInit,
  transferInitAck,
  transferChunk,
  transferChunkAck,
  transferChunkNack,
  transferWindowUpdate,
  transferComplete,
  transferCompleteAck,
  ignored,
}

class TransferControlPacketDispatcher {
  const TransferControlPacketDispatcher();

  TransferControlPacketRoute routeFor(AuthPacketType type) {
    switch (type) {
      case AuthPacketType.transferInit:
        return TransferControlPacketRoute.transferInit;
      case AuthPacketType.transferInitAck:
        return TransferControlPacketRoute.transferInitAck;
      case AuthPacketType.transferChunk:
        return TransferControlPacketRoute.transferChunk;
      case AuthPacketType.transferChunkAck:
        return TransferControlPacketRoute.transferChunkAck;
      case AuthPacketType.transferChunkNack:
        return TransferControlPacketRoute.transferChunkNack;
      case AuthPacketType.transferWindowUpdate:
        return TransferControlPacketRoute.transferWindowUpdate;
      case AuthPacketType.transferComplete:
        return TransferControlPacketRoute.transferComplete;
      case AuthPacketType.transferCompleteAck:
        return TransferControlPacketRoute.transferCompleteAck;
      case AuthPacketType.connectRequest:
      case AuthPacketType.authChallenge:
      case AuthPacketType.authToken:
      case AuthPacketType.authTokenAck:
      case AuthPacketType.authAccept:
      case AuthPacketType.authReject:
        return TransferControlPacketRoute.ignored;
    }
  }
}
