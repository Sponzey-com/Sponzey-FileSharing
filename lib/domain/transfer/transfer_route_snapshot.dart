class TransferRouteSnapshot {
  const TransferRouteSnapshot({
    required this.routeLeaseId,
    required this.peerId,
    required this.controlLocalAddress,
    required this.controlRemoteAddress,
    required this.controlRemotePort,
    this.localInterfaceId,
    this.dataLocalAddress,
    this.dataRemoteAddress,
    this.dataRemotePort,
  });

  final String routeLeaseId;
  final String peerId;
  final String controlLocalAddress;
  final String controlRemoteAddress;
  final int controlRemotePort;
  final String? localInterfaceId;
  final String? dataLocalAddress;
  final String? dataRemoteAddress;
  final int? dataRemotePort;

  TransferRouteSnapshot copyWith({
    String? routeLeaseId,
    String? peerId,
    String? controlLocalAddress,
    String? controlRemoteAddress,
    int? controlRemotePort,
    String? localInterfaceId,
    String? dataLocalAddress,
    String? dataRemoteAddress,
    int? dataRemotePort,
  }) {
    return TransferRouteSnapshot(
      routeLeaseId: routeLeaseId ?? this.routeLeaseId,
      peerId: peerId ?? this.peerId,
      controlLocalAddress: controlLocalAddress ?? this.controlLocalAddress,
      controlRemoteAddress: controlRemoteAddress ?? this.controlRemoteAddress,
      controlRemotePort: controlRemotePort ?? this.controlRemotePort,
      localInterfaceId: localInterfaceId ?? this.localInterfaceId,
      dataLocalAddress: dataLocalAddress ?? this.dataLocalAddress,
      dataRemoteAddress: dataRemoteAddress ?? this.dataRemoteAddress,
      dataRemotePort: dataRemotePort ?? this.dataRemotePort,
    );
  }
}
