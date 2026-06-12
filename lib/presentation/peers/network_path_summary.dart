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
    if (!debug) {
      return Text(
        diagnostics.productSummary,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    final rows = diagnostics.candidateDebugRows.take(6).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          diagnostics.debugSummary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        for (final row in rows)
          Text(
            row,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (diagnostics.candidateDebugRows.length > rows.length)
          Text(
            '+${diagnostics.candidateDebugRows.length - rows.length} candidates',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}
