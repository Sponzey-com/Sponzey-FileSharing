import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/core/message_bus/app_event.dart';

abstract interface class MessageBus {
  void publish(AppEvent event);

  Stream<TEvent> eventsOfType<TEvent extends AppEvent>();
}

final messageBusProvider = Provider<MessageBus>((ref) {
  final bus = InMemoryMessageBus();
  ref.onDispose(bus.dispose);
  return bus;
});

class InMemoryMessageBus implements MessageBus {
  final StreamController<AppEvent> _controller =
      StreamController<AppEvent>.broadcast(sync: true);

  @override
  void publish(AppEvent event) {
    if (_controller.isClosed) {
      return;
    }
    _controller.add(event);
  }

  @override
  Stream<TEvent> eventsOfType<TEvent extends AppEvent>() {
    return _controller.stream.where((event) => event is TEvent).cast<TEvent>();
  }

  void dispose() {
    unawaited(_controller.close());
  }
}
