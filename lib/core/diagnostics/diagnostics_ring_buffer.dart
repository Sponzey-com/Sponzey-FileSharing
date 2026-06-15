import 'dart:collection';

class DiagnosticsRingBuffer<T> {
  DiagnosticsRingBuffer({required this.capacity}) {
    if (capacity <= 0) {
      throw ArgumentError.value(capacity, 'capacity', 'must be positive');
    }
  }

  final int capacity;
  final Queue<T> _items = Queue<T>();

  void add(T item) {
    if (_items.length == capacity) {
      _items.removeFirst();
    }
    _items.addLast(item);
  }

  List<T> snapshot() {
    return List<T>.unmodifiable(_items);
  }
}
