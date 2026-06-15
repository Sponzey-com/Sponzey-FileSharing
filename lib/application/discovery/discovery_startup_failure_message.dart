import 'dart:io';

import 'package:sponzey_file_sharing/core/diagnostics/diagnostics_redactor.dart';

String discoveryStartupFailureMessage({
  required String stage,
  required Object error,
  required int discoveryPort,
  required int controlPort,
  required int dataPortRangeStart,
  required int dataPortRangeEnd,
}) {
  final redactedError = DiagnosticsRedactor.redactText(error.toString());
  final base =
      '디스커버리 엔진을 시작하지 못했습니다. [$stage] '
      '${error.runtimeType}: $redactedError';
  final diagnosticsHint = '자세한 상태는 diagnostics export로 확인해 주세요.';

  if (error is SocketException) {
    return '$base UDP 소켓을 열지 못했습니다. OS 방화벽 또는 소켓 권한을 '
        '확인하고 discovery $discoveryPort/udp, control $controlPort/udp, '
        'data ${_formatDataPorts(dataPortRangeStart, dataPortRangeEnd)}가 '
        '허용되어 있는지 확인해 주세요. $diagnosticsHint';
  }

  return '$base $diagnosticsHint';
}

String discoveryStartupFailureDecision({
  required String stage,
  required Object error,
}) {
  final redactedError = DiagnosticsRedactor.redactText(error.toString());
  return 'init failed at $stage: ${error.runtimeType}: $redactedError';
}

String _formatDataPorts(int start, int end) {
  if (start == end) {
    return '$start/udp';
  }
  return '$start-$end/udp';
}
