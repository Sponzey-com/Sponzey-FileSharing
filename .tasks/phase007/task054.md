# Task 054. Transfer Random Hex Formatter

## Goal

`TransferController._randomHex` 안의 byte-to-hex 문자열 변환 규칙을 application 계층 formatter로 분리한다. 난수 생성은 컨트롤러의 `_random` 주입 경로를 유지하고, formatting만 독립 테스트로 고정한다.

## Scope

- [x] byte list를 lowercase hex 문자열로 변환하는 formatter를 추가한다.
- [x] 각 byte는 2자리로 zero-padding한다.
- [x] 난수 생성은 formatter 안으로 옮기지 않는다.

## Functional Requirements

- [x] `[0, 1, 15, 16, 255]`는 `00010f10ff`로 변환된다.
- [x] 빈 byte list는 빈 문자열을 반환한다.
- [x] 컨트롤러 `_randomHex`는 `_random.nextInt(256)`으로 바이트를 만든 뒤 formatter에 위임한다.

## Architecture Requirements

- [x] formatter는 `lib/application/transfer`에 둔다.
- [x] formatter는 Random, Flutter, Riverpod, 파일 시스템, 네트워크에 의존하지 않는다.
- [x] formatter는 입력 검증 외 부작용을 갖지 않는다.

## TDD Requirements

- [x] zero-padding과 lowercase 변환 테스트를 먼저 작성한다.
- [x] 컨트롤러가 직접 `toRadixString(16).padLeft(2, '0')` 규칙을 갖지 않는 구조 테스트를 작성한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_random_hex_formatter_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] `TransferRandomHexFormatter`가 추가되어 있다.
- [x] `_randomHex`가 formatter에 위임한다.
- [x] 변경 범위 테스트와 정적 분석이 통과한다.
