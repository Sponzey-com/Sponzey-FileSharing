import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/application/network/network_diagnostics_provider.dart';

class NetworkPathSummary extends ConsumerWidget {
  const NetworkPathSummary({
    super.key,
    required this.peerId,
    this.debug = false,
  });

  final String peerId;
  final bool debug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnostics = ref.watch(peerPathDiagnosticsProvider(peerId));
    return Text(
      debug ? diagnostics.debugSummary : diagnostics.productSummary,
      maxLines: debug ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
