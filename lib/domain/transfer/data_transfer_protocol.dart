class DataTransferCapability {
  const DataTransferCapability._(this.name);

  static const udpDataBinaryV1 = DataTransferCapability._('udpDataBinaryV1');
  static const tcpDataStreamV1 = DataTransferCapability._('tcpDataStreamV1');

  final String name;

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) {
    return other is DataTransferCapability && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}

class DataTransferCapabilitySet {
  const DataTransferCapabilitySet(this.capabilities);

  final Set<DataTransferCapability> capabilities;

  bool supports(DataTransferCapability capability) {
    return capabilities.contains(capability);
  }

  List<String> toWireList() {
    return capabilities.map((capability) => capability.name).toList()..sort();
  }

  static DataTransferCapabilitySet fromWireList(List<String> names) {
    return DataTransferCapabilitySet({
      for (final name in names)
        if (name == DataTransferCapability.tcpDataStreamV1.name)
          DataTransferCapability.tcpDataStreamV1
        else if (name == DataTransferCapability.udpDataBinaryV1.name)
          DataTransferCapability.udpDataBinaryV1,
    });
  }
}

class DataTransferProtocolVersion {
  const DataTransferProtocolVersion(this.value);

  static const v1 = DataTransferProtocolVersion(1);

  final int value;

  bool get isSupported => value == v1.value;
}
