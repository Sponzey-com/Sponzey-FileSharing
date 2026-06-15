import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/core/diagnostics/diagnostics_redactor.dart';

void main() {
  test('redacts password, jwt and session key values', () {
    final redacted = DiagnosticsRedactor.redactValue({
      'password': 'plain-password',
      'jwt': 'aaaaaaaabbbbbbbb.ccccccccdddddddd.eeeeeeeeffffffff',
      'sessionKey': 'session-key-value',
      'message':
          'password=plain-password token=aaaaaaaabbbbbbbb.ccccccccdddddddd.eeeeeeeeffffffff',
    }).toString();

    expect(redacted, isNot(contains('plain-password')));
    expect(redacted, isNot(contains('aaaaaaaabbbbbbbb.ccccccccdddddddd')));
    expect(redacted, isNot(contains('session-key-value')));
    expect(redacted, contains('[redacted'));
  });

  test('shortens full paths to a safe basename form', () {
    final redacted = DiagnosticsRedactor.redactValue({
      'localFilePath': '/Users/dongwooshin/WorkPlaces/private/report.pdf',
      'destinationPath': r'C:\Users\atom\Downloads\Sponzey\report.pdf',
      'message': 'failed at /Users/dongwooshin/Downloads/secret.zip',
    }).toString();

    expect(redacted, isNot(contains('/Users/dongwooshin')));
    expect(redacted, isNot(contains(r'C:\Users\atom')));
    expect(redacted, contains('.../report.pdf'));
    expect(redacted, contains('.../secret.zip'));
  });
}
