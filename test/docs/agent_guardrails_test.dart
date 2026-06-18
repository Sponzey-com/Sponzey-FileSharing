import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AGENTS guardrails use TCP data session as transfer source of truth', () {
    final agents = File('AGENTS.md').readAsStringSync();

    expect(
      agents,
      contains(
        '전송 가능 여부와 파일 전송 대상 선택은 인증된 TCP data session을 기준으로 안정화한다',
      ),
    );
    expect(
      agents,
      contains('route lease는 TCP connect input과 diagnostics context로 사용한다'),
    );
    expect(
      agents,
      isNot(contains('전송 대상 선택은 검증된 active route lease')),
    );
  });

  test('README files describe TCP Data Channel as the current payload path', () {
    final english = File('README.md').readAsStringSync();
    final korean = File('README.ko.md').readAsStringSync();

    expect(
      english,
      contains(
        'Use UDP for low-latency discovery and control, and use an authenticated TCP Data Channel for file payload transfer.',
      ),
    );
    expect(
      english,
      isNot(contains('File payload transfer is being moved')),
    );
    expect(
      korean,
      contains('UDP는 낮은 지연의 discovery/control에 사용하고, 파일 payload 전송은 인증된 TCP Data Channel을 사용합니다.'),
    );
    expect(korean, isNot(contains('파일 payload 전송은 인증된 TCP Data Channel로 전환합니다')));
  });
}
