import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('desktop release workflow keeps Ubuntu 22.04 Linux baseline', () {
    final workflow = File(
      '.github/workflows/desktop-release.yml',
    ).readAsStringSync();

    expect(workflow, contains('Build Linux Ubuntu 22.04 minimum'));
    expect(workflow, contains('runs-on: ubuntu-22.04'));
    expect(workflow, contains('libgtk-3-dev'));
    expect(workflow, contains('libsecret-1-dev'));
    expect(
      workflow,
      contains(
        'flutter build linux --release --dart-define=SPONZEY_APP_VERSION',
      ),
    );
  });

  test('desktop release workflow keeps releases draft until manual gate', () {
    final workflow = File(
      '.github/workflows/desktop-release.yml',
    ).readAsStringSync();

    expect(workflow, contains('SPONZEY_APP_VERSION'));
    expect(workflow, contains('--dart-define=SPONZEY_APP_VERSION'));
    expect(workflow, contains('scripts\\build_windows.ps1 -AppVersion'));
    expect(
      workflow,
      contains(
        "draft: \${{ github.event_name != 'workflow_dispatch' || github.event.inputs.draft == 'true' }}",
      ),
    );
  });
}
