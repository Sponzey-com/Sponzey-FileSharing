enum ControlSocketPlatform { windows, macos, linux, other }

class ControlSocketOptions {
  const ControlSocketOptions({
    required this.reuseAddress,
    required this.reusePort,
  });

  final bool reuseAddress;
  final bool reusePort;
}

class ControlSocketBindPolicy {
  const ControlSocketBindPolicy({required this.platform});

  final ControlSocketPlatform platform;

  ControlSocketOptions receiveSocket() {
    return const ControlSocketOptions(reuseAddress: false, reusePort: false);
  }

  ControlSocketOptions senderSocket() {
    return ControlSocketOptions(
      reuseAddress: true,
      reusePort: platform != ControlSocketPlatform.windows,
    );
  }
}
