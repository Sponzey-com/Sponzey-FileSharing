import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/core/message_bus/app_event.dart';
import 'package:sponzey_file_sharing/core/message_bus/message_bus.dart';

void main() {
  test('publishes peer route candidate events', () async {
    final bus = InMemoryMessageBus();
    addTearDown(bus.dispose);

    final events = <PeerRouteCandidateAppEvent>[];
    final subscription = bus.eventsOfType<PeerRouteCandidateAppEvent>().listen(
      events.add,
    );
    addTearDown(subscription.cancel);

    bus.publish(
      PeerRouteCandidateAppEvent(
        eventId: 'event-001',
        occurredAt: DateTime.utc(2026),
        correlationId: 'corr-001',
        source: 'test',
        severity: AppEventSeverity.debug,
        eventType: 'PeerRouteCandidateFound',
        peerId: 'user@device',
        candidateId: 'candidate-001',
      ),
    );

    expect(events, hasLength(1));
    expect(events.single.eventType, 'PeerRouteCandidateFound');
  });

  test('publishes selected peer path events', () async {
    final bus = InMemoryMessageBus();
    addTearDown(bus.dispose);

    final events = <PeerPathAppEvent>[];
    final subscription = bus.eventsOfType<PeerPathAppEvent>().listen(
      events.add,
    );
    addTearDown(subscription.cancel);

    bus.publish(
      PeerPathAppEvent(
        eventId: 'event-002',
        occurredAt: DateTime.utc(2026),
        correlationId: 'corr-002',
        source: 'test',
        severity: AppEventSeverity.debug,
        eventType: 'PeerPathSelected',
        peerId: 'user@device',
        pathId: 'path-001',
      ),
    );

    expect(events, hasLength(1));
    expect(events.single.eventType, 'PeerPathSelected');
  });

  test('publishes data path failover events', () async {
    final bus = InMemoryMessageBus();
    addTearDown(bus.dispose);

    final events = <DataPathAppEvent>[];
    final subscription = bus.eventsOfType<DataPathAppEvent>().listen(
      events.add,
    );
    addTearDown(subscription.cancel);

    bus.publish(
      DataPathAppEvent(
        eventId: 'event-003',
        occurredAt: DateTime.utc(2026),
        correlationId: 'transfer-001',
        source: 'test',
        severity: AppEventSeverity.debug,
        eventType: 'dataPathFailoverStarted',
        transferId: 'transfer-001',
        pathId: 'path-001',
      ),
    );

    expect(events, hasLength(1));
    expect(events.single.correlationId, 'transfer-001');
  });
}
