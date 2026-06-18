import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English README documents platform hardening requirements', () {
    final readme = File('README.md').readAsStringSync();

    expect(readme, contains('Windows Defender Firewall'));
    expect(readme, contains('Developer Mode'));
    expect(readme, contains('UDP ports'));
    expect(readme, contains('TCP Data Channel'));
    expect(readme, contains('Ubuntu 22.04'));
    expect(readme, contains('libgtk-3-dev'));
    expect(readme, contains('libsecret-1-dev'));
    expect(readme, contains('Platform Smoke Checklist'));
    expect(readme, contains('diagnostics export'));
  });

  test('Korean README documents platform hardening requirements', () {
    final readme = File('README.ko.md').readAsStringSync();

    expect(readme, contains('Windows Defender Firewall'));
    expect(readme, contains('개발자 모드'));
    expect(readme, contains('UDP 포트'));
    expect(readme, contains('TCP Data Channel'));
    expect(readme, contains('Ubuntu 22.04'));
    expect(readme, contains('libgtk-3-dev'));
    expect(readme, contains('libsecret-1-dev'));
    expect(readme, contains('플랫폼 Smoke 체크리스트'));
    expect(readme, contains('diagnostics export'));
  });
}
