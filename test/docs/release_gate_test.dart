import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release gate documents bidirectional transfer and digest criteria', () {
    final doc = File('docs/release_gate.md').readAsStringSync();

    expect(doc, contains('CI build success only means artifacts were produced'));
    expect(doc, contains('GitHub Releases created from tag pushes remain draft'));
    expect(doc, contains('receiver digest'));
    expect(doc, contains('diagnostics export'));
    expect(doc, contains('macOS host to Parallels Windows VM'));
    expect(doc, contains('Parallels Windows VM to macOS host'));
    expect(doc, contains('Ubuntu 22.04'));
    expect(doc, contains('100 MB'));
    expect(doc, contains('same UID appears as one peer'));
    expect(
      doc,
      contains('route candidates remain separate from the active route lease'),
    );
    expect(
      doc,
      contains(
        'active route lease must not change during transfer unless explicit disconnect, timeout, or socket failure occurs',
      ),
    );
    expect(doc, contains('route switch count'));
    expect(doc, contains('.tasks/release_runs/<tag>.md'));
    expect(doc, contains('Do not reuse or force-move a published tag'));
  });

  test('release gate helper runs required local commands and build defines', () {
    final script = File('scripts/task011_release_gate.sh').readAsStringSync();

    expect(script, contains('flutter analyze'));
    expect(script, contains('flutter test --concurrency=1 --reporter expanded'));
    expect(script, contains('--dart-define=SPONZEY_APP_VERSION'));
    expect(script, contains('flutter build macos --release'));
    expect(script, contains('flutter build linux --release'));
    expect(script, contains('scripts\\\\build_windows.ps1 -AppVersion'));
    expect(script, contains('Manual release gate still required'));
    expect(script, contains('same UID one peer'));
    expect(script, contains('active route lease stability'));
  });
}
