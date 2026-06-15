import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/application/diagnostics/diagnostics_export_bundle.dart';
import 'package:sponzey_file_sharing/application/diagnostics/diagnostics_export_provider.dart';
import 'package:sponzey_file_sharing/application/diagnostics/diagnostics_export_repository.dart';
import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/infrastructure/repositories/diagnostics_export_repository.dart';
import 'package:sponzey_file_sharing/presentation/diagnostics/diagnostics_export_panel.dart';

void main() {
  testWidgets('shows redacted diagnostics export sections', (tester) async {
    final bundle = DiagnosticsExportBundle(
      generatedAt: DateTime.utc(2026),
      product: const {'authStatus': 'authenticated'},
      debug: const {
        'message':
            'password=secret jwt=aaaaaaaabbbbbbbb.ccccccccdddddddd.eeeeeeeeffffffff',
        'path': '/Users/dongwooshin/Downloads/private.zip',
      },
      environment: const {'operatingSystem': 'macos'},
      development: const {'packetDetailsExcluded': true},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          diagnosticsExportBundleProvider.overrideWithValue(bundle),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DiagnosticsExportPanel()),
        ),
      ),
    );

    expect(find.text('Diagnostics Export'), findsOneWidget);
    expect(find.textContaining('product'), findsWidgets);
    expect(find.textContaining('debug'), findsWidgets);
    expect(find.textContaining('environment'), findsWidgets);
    expect(find.textContaining('development'), findsWidgets);
    expect(find.textContaining('secret'), findsNothing);
    expect(find.textContaining('aaaaaaaabbbbbbbb.ccccccccdddddddd'), findsNothing);
    expect(find.textContaining('/Users/dongwooshin'), findsNothing);
    expect(find.textContaining('.../private.zip'), findsOneWidget);
  });

  testWidgets('saves export file through controller action', (tester) async {
    final bundle = DiagnosticsExportBundle(
      generatedAt: DateTime.utc(2026),
      product: const {'authStatus': 'authenticated'},
      debug: const {},
      environment: const {},
      development: const {'packetDetailsExcluded': true},
    );
    final repository = _FakeDiagnosticsExportRepository(
      result: DiagnosticsExportSaveResult(
        filePath: '/Users/dongwooshin/Library/export.json',
        fileName: 'export.json',
        createdAt: DateTime.utc(2026),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          diagnosticsExportBundleProvider.overrideWithValue(bundle),
          diagnosticsExportRepositoryProvider.overrideWithValue(repository),
          appLoggerProvider.overrideWithValue(_MemoryLogger()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DiagnosticsExportPanel()),
        ),
      ),
    );

    await tester.tap(find.text('Export 파일 저장'));
    await tester.pumpAndSettle();

    expect(repository.savedBundles, [bundle]);
    expect(find.textContaining('저장됨: .../export.json'), findsOneWidget);
    expect(find.textContaining('/Users/dongwooshin'), findsNothing);
  });
}

class _FakeDiagnosticsExportRepository implements DiagnosticsExportRepository {
  _FakeDiagnosticsExportRepository({required this.result});

  final DiagnosticsExportSaveResult result;
  final List<DiagnosticsExportBundle> savedBundles = [];

  @override
  Future<DiagnosticsExportSaveResult> save(
    DiagnosticsExportBundle bundle,
  ) async {
    savedBundles.add(bundle);
    return result;
  }
}

class _MemoryLogger implements AppLogger {
  @override
  AppLogLevel get minimumLevel => AppLogLevel.debug;

  @override
  void debug(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {}

  @override
  void error(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {}

  @override
  void info(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {}

  @override
  void warning(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {}
}
