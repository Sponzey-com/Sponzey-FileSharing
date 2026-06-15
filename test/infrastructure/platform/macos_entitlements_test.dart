import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('macOS desktop builds do not enable App Sandbox', () async {
    for (final path in const [
      'macos/Runner/DebugProfile.entitlements',
      'macos/Runner/Release.entitlements',
    ]) {
      final content = await File(path).readAsString();

      expect(content, isNot(contains('com.apple.security.app-sandbox')));
      expect(content, contains('com.apple.security.network.client'));
      expect(content, contains('com.apple.security.network.server'));
    }
  });
}
