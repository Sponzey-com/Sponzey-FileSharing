import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/core/message_bus/app_event.dart';
import 'package:sponzey_file_sharing/core/message_bus/message_bus.dart';

void main() {
  DiagnosticsAppEvent event(String id) {
    return DiagnosticsAppEvent(
      eventId: id,
      occurredAt: DateTime(2026),
      correlationId: 'corr-1',
      source: 'test',
      severity: AppEventSeverity.development,
      eventType: 'diagnosticRecorded',
    );
  }

  test('publishes events in order', () async {
    final bus = InMemoryMessageBus();
    addTearDown(bus.dispose);

    final received = <String>[];
    final subscription = bus.eventsOfType<DiagnosticsAppEvent>().listen((
      event,
    ) {
      received.add(event.eventId);
    });
    addTearDown(subscription.cancel);

    bus
      ..publish(event('1'))
      ..publish(event('2'));

    await pumpEventQueue();
    expect(received, ['1', '2']);
  });

  test('subscribes by type', () async {
    final bus = InMemoryMessageBus();
    addTearDown(bus.dispose);

    final received = <DiagnosticsAppEvent>[];
    final subscription = bus.eventsOfType<DiagnosticsAppEvent>().listen(
      received.add,
    );
    addTearDown(subscription.cancel);

    bus
      ..publish(
        UdpPortAppEvent(
          eventId: 'udp',
          occurredAt: DateTime(2026),
          correlationId: 'corr-1',
          source: 'test',
          severity: AppEventSeverity.debug,
          eventType: 'portBound',
          portRole: 'discovery',
          port: 38400,
        ),
      )
      ..publish(event('diagnostics'));

    await pumpEventQueue();
    expect(received.single.eventId, 'diagnostics');
  });

  test('does not deliver after unsubscribe', () async {
    final bus = InMemoryMessageBus();
    addTearDown(bus.dispose);

    final received = <String>[];
    final subscription = bus.eventsOfType<DiagnosticsAppEvent>().listen((
      event,
    ) {
      received.add(event.eventId);
    });

    await subscription.cancel();
    bus.publish(event('after-cancel'));

    await pumpEventQueue();
    expect(received, isEmpty);
  });

  test('keeps correlation ids in event metadata', () {
    final recorded = event('diagnostics');

    expect(recorded.correlationId, 'corr-1');
    expect(recorded.severity, AppEventSeverity.development);
  });
}
