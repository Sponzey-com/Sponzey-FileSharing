import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release run README keeps TCP data channel smoke record fields', () {
    final doc = File('.tasks/release_runs/README.md').readAsStringSync();

    expect(doc, contains('macOS host -> Parallels Windows VM'));
    expect(doc, contains('Parallels Windows VM -> macOS host'));
    expect(doc, contains('TCP data session id'));
    expect(doc, contains('TCP data session state'));
    expect(doc, contains('TCP data session direction'));
    expect(doc, contains('TCP data session stable during transfer'));
    expect(doc, contains('TCP data session restart count'));
    expect(doc, contains('last close reason'));
    expect(doc, contains('receiver digest result'));
    expect(doc, contains('diagnostics export filename'));
    expect(doc, contains('Do not record passwords, JWTs, session keys'));
  });
}
