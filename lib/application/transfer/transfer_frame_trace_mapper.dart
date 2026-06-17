import 'package:sponzey_file_sharing/application/transfer/transfer_diagnostics_ring_buffer.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_frame.dart';

class TransferFrameTraceMapper {
  const TransferFrameTraceMapper._();

  static TransferFrameTrace fromFrame(
    DataFrame frame, {
    required DateTime occurredAt,
    required String direction,
    required String endpoint,
    required int datagramBytes,
    required String decisionCode,
  }) {
    return TransferFrameTrace(
      occurredAt: occurredAt,
      direction: direction,
      frameType: frame.type.name,
      sequence: frame.sequence,
      chunkIndex: frame.chunkIndex,
      ackBase: frame.ackBase,
      datagramBytes: datagramBytes,
      endpoint: endpoint,
      decisionCode: decisionCode,
    );
  }
}
