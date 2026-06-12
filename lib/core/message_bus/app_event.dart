enum AppEventSeverity { product, debug, development }

abstract class AppEvent {
  const AppEvent({
    required this.eventId,
    required this.occurredAt,
    required this.correlationId,
    required this.source,
    required this.severity,
  });

  final String eventId;
  final DateTime occurredAt;
  final String correlationId;
  final String source;
  final AppEventSeverity severity;
}

class UdpPortAppEvent extends AppEvent {
  const UdpPortAppEvent({
    required super.eventId,
    required super.occurredAt,
    required super.correlationId,
    required super.source,
    required super.severity,
    required this.eventType,
    required this.portRole,
    required this.port,
    this.reasonCode,
  });

  final String eventType;
  final String portRole;
  final int port;
  final String? reasonCode;
}

class DiscoveryAppEvent extends AppEvent {
  const DiscoveryAppEvent({
    required super.eventId,
    required super.occurredAt,
    required super.correlationId,
    required super.source,
    required super.severity,
    required this.eventType,
    this.peerId,
    this.messageId,
    this.reasonCode,
  });

  final String eventType;
  final String? peerId;
  final String? messageId;
  final String? reasonCode;
}

class PeerLinkAppEvent extends AppEvent {
  const PeerLinkAppEvent({
    required super.eventId,
    required super.occurredAt,
    required super.correlationId,
    required super.source,
    required super.severity,
    required this.eventType,
    required this.peerId,
    this.sessionId,
    this.reasonCode,
  });

  final String eventType;
  final String peerId;
  final String? sessionId;
  final String? reasonCode;
}

class NetworkInterfaceAppEvent extends AppEvent {
  const NetworkInterfaceAppEvent({
    required super.eventId,
    required super.occurredAt,
    required super.correlationId,
    required super.source,
    required super.severity,
    required this.eventType,
    this.interfaceId,
    this.reasonCode,
  });

  final String eventType;
  final String? interfaceId;
  final String? reasonCode;
}

class PeerRouteCandidateAppEvent extends AppEvent {
  const PeerRouteCandidateAppEvent({
    required super.eventId,
    required super.occurredAt,
    required super.correlationId,
    required super.source,
    required super.severity,
    required this.eventType,
    required this.peerId,
    this.candidateId,
    this.reasonCode,
  });

  final String eventType;
  final String peerId;
  final String? candidateId;
  final String? reasonCode;
}

class PeerPathAppEvent extends AppEvent {
  const PeerPathAppEvent({
    required super.eventId,
    required super.occurredAt,
    required super.correlationId,
    required super.source,
    required super.severity,
    required this.eventType,
    required this.peerId,
    this.pathId,
    this.reasonCode,
  });

  final String eventType;
  final String peerId;
  final String? pathId;
  final String? reasonCode;
}

class DataPathAppEvent extends AppEvent {
  const DataPathAppEvent({
    required super.eventId,
    required super.occurredAt,
    required super.correlationId,
    required super.source,
    required super.severity,
    required this.eventType,
    required this.transferId,
    this.pathId,
    this.reasonCode,
  });

  final String eventType;
  final String transferId;
  final String? pathId;
  final String? reasonCode;
}

class SecurityAppEvent extends AppEvent {
  const SecurityAppEvent({
    required super.eventId,
    required super.occurredAt,
    required super.correlationId,
    required super.source,
    required super.severity,
    required this.eventType,
    this.peerId,
    this.sessionId,
    this.reasonCode,
  });

  final String eventType;
  final String? peerId;
  final String? sessionId;
  final String? reasonCode;
}

class TransferQueueAppEvent extends AppEvent {
  const TransferQueueAppEvent({
    required super.eventId,
    required super.occurredAt,
    required super.correlationId,
    required super.source,
    required super.severity,
    required this.eventType,
    required this.queueId,
    this.jobId,
    this.peerId,
    this.reasonCode,
  });

  final String eventType;
  final String queueId;
  final String? jobId;
  final String? peerId;
  final String? reasonCode;
}

class TransferSessionAppEvent extends AppEvent {
  const TransferSessionAppEvent({
    required super.eventId,
    required super.occurredAt,
    required super.correlationId,
    required super.source,
    required super.severity,
    required this.eventType,
    required this.transferId,
    this.jobId,
    this.peerId,
    this.reasonCode,
  });

  final String eventType;
  final String transferId;
  final String? jobId;
  final String? peerId;
  final String? reasonCode;
}

class DiagnosticsAppEvent extends AppEvent {
  const DiagnosticsAppEvent({
    required super.eventId,
    required super.occurredAt,
    required super.correlationId,
    required super.source,
    required super.severity,
    required this.eventType,
    this.reasonCode,
  });

  final String eventType;
  final String? reasonCode;
}
