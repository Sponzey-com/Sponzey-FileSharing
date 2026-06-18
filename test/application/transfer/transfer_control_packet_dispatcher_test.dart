import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_control_packet_dispatcher.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_packet.dart';

void main() {
  test('routes transfer control packet types explicitly', () {
    const dispatcher = TransferControlPacketDispatcher();

    expect(
      dispatcher.routeFor(AuthPacketType.transferInit),
      TransferControlPacketRoute.transferInit,
    );
    expect(
      dispatcher.routeFor(AuthPacketType.transferInitAck),
      TransferControlPacketRoute.transferInitAck,
    );
    expect(
      dispatcher.routeFor(AuthPacketType.transferChunk),
      TransferControlPacketRoute.transferChunk,
    );
    expect(
      dispatcher.routeFor(AuthPacketType.transferChunkAck),
      TransferControlPacketRoute.transferChunkAck,
    );
    expect(
      dispatcher.routeFor(AuthPacketType.transferChunkNack),
      TransferControlPacketRoute.transferChunkNack,
    );
    expect(
      dispatcher.routeFor(AuthPacketType.transferWindowUpdate),
      TransferControlPacketRoute.transferWindowUpdate,
    );
    expect(
      dispatcher.routeFor(AuthPacketType.transferComplete),
      TransferControlPacketRoute.transferComplete,
    );
    expect(
      dispatcher.routeFor(AuthPacketType.transferCompleteAck),
      TransferControlPacketRoute.transferCompleteAck,
    );
  });

  test('routes authentication handshake packets to ignored', () {
    const dispatcher = TransferControlPacketDispatcher();

    for (final type in const [
      AuthPacketType.connectRequest,
      AuthPacketType.authChallenge,
      AuthPacketType.authToken,
      AuthPacketType.authTokenAck,
      AuthPacketType.authAccept,
      AuthPacketType.authReject,
    ]) {
      expect(dispatcher.routeFor(type), TransferControlPacketRoute.ignored);
    }
  });

  test('routes TCP data channel negotiation packets to ignored for now', () {
    const dispatcher = TransferControlPacketDispatcher();

    expect(
      dispatcher.routeFor(AuthPacketType.dataChannelOffer),
      TransferControlPacketRoute.dataChannelOffer,
    );
    for (final type in const [
      AuthPacketType.dataChannelConnect,
      AuthPacketType.dataChannelAccept,
      AuthPacketType.dataChannelReject,
    ]) {
      expect(dispatcher.routeFor(type), TransferControlPacketRoute.ignored);
    }
  });

  test('dispatcher stays independent from framework and IO adapters', () async {
    final source = await File(
      'lib/application/transfer/transfer_control_packet_dispatcher.dart',
    ).readAsString();

    expect(source, isNot(contains('flutter')));
    expect(source, isNot(contains('riverpod')));
    expect(source, isNot(contains('dart:io')));
    expect(source, isNot(contains('ControlTransport')));
    expect(source, isNot(contains('DataTransport')));
  });
}
