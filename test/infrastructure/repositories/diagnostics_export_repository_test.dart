import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sponzey_file_sharing/application/diagnostics/diagnostics_export_bundle.dart';
import 'package:sponzey_file_sharing/infrastructure/repositories/diagnostics_export_repository.dart';

void main() {
  test('saves redacted diagnostics export under diagnostics directory', () async {
    final tempRoot = await Directory.systemTemp.createTemp(
      'sponzey-diagnostics-export-',
    );
    addTearDown(() async {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });
    final repository = FileDiagnosticsExportRepository(
      supportDirectoryLoader: () async => tempRoot,
    );
    final bundle = DiagnosticsExportBundle(
      generatedAt: DateTime.utc(2026, 6, 15, 1, 2, 3),
      product: const {'status': 'failed'},
      debug: const {
        'message':
            'password=secret token=aaaaaaaabbbbbbbb.ccccccccdddddddd.eeeeeeeeffffffff',
        'localFilePath': '/Users/dongwooshin/Downloads/private.zip',
      },
      environment: const {'logFilePath': '/Users/dongwooshin/logs/app.log'},
      development: const {'packetPayloadExcluded': true},
    );

    final result = await repository.save(bundle);

    expect(result.fileName, 'diagnostics-export-20260615T010203Z.json');
    expect(p.basename(p.dirname(result.filePath)), 'diagnostics');
    final saved = await File(result.filePath).readAsString();
    expect(saved, contains('"product"'));
    expect(saved, contains('"debug"'));
    expect(saved, contains('"environment"'));
    expect(saved, contains('"development"'));
    expect(saved, isNot(contains('secret')));
    expect(saved, isNot(contains('aaaaaaaabbbbbbbb.ccccccccdddddddd')));
    expect(saved, isNot(contains('/Users/dongwooshin')));
    expect(saved, contains('.../private.zip'));
    expect(saved, contains('.../app.log'));
  });
}
