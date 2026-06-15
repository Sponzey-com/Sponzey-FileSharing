class TransferFrameTrace {
  const TransferFrameTrace({
    required this.occurredAt,
    required this.direction,
    required this.frameType,
    required this.sequence,
    required this.chunkIndex,
    required this.ackBase,
    required this.datagramBytes,
    required this.endpoint,
    required this.decisionCode,
  });

  final DateTime occurredAt;
  final String direction;
  final String frameType;
  final int sequence;
  final int chunkIndex;
  final int ackBase;
  final int datagramBytes;
  final String endpoint;
  final String decisionCode;
}

class TransferDiagnosticsRingBuffer {
  TransferDiagnosticsRingBuffer({required this.capacity})
    : assert(capacity > 0);

  final int capacity;
  final List<TransferFrameTrace> _items = <TransferFrameTrace>[];

  int get length => _items.length;

  void add(TransferFrameTrace trace) {
    if (_items.length == capacity) {
      _items.removeAt(0);
    }
    _items.add(trace);
  }

  List<TransferFrameTrace> snapshot() {
    return List<TransferFrameTrace>.unmodifiable(_items);
  }
}
