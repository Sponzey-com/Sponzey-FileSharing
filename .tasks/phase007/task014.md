# Task 014. Incoming finalize failure mapping 분리

## 1. Task Purpose

- [x] 이 태스크의 목적은 incoming DATA_FINISH finalize 실패를 사용자 메시지와 reason code로 매핑하는 책임을 controller 밖으로 분리하는 것이다.
- [x] 이 태스크는 digest mismatch 같은 예상 가능한 거절과 일반 finalize 실패를 명시적으로 구분한다.
- [x] 완료 후 `_onDataFinish`의 catch 블록은 mapper 결과를 ACK와 job failure에 사용한다.

## 2. Scope

### Included

- [x] `TransferIncomingFinalizeFailureMapper`를 추가한다.
- [x] `AppException`은 원래 code/message를 유지하는 rejected failure로 매핑한다.
- [x] 일반 예외는 `transfer_finalize_failed`와 기본 사용자 메시지로 매핑한다.
- [x] `_onDataFinish`의 Data channel finalize catch가 mapper 결과를 사용하도록 변경한다.

### Excluded

- [x] legacy Control `TRANSFER_COMPLETE` catch는 변경하지 않는다.
- [x] file finalize, digest 검증, ACK 전송 방식은 변경하지 않는다.
- [x] 로그 레벨 정책은 변경하지 않는다.

## 3. TDD Plan

- [x] 실패하는 테스트를 먼저 작성한다.
- [x] AppException mapping 테스트를 작성한다.
- [x] generic exception mapping 테스트를 작성한다.
- [x] mapper가 framework와 IO에 의존하지 않는 architecture guard를 작성한다.
- [x] 최소 구현으로 mapper 테스트를 통과시킨다.
- [x] 기존 transfer controller 회귀 테스트를 실행한다.

## 4. Validation Checklist

- [x] 테스트가 모두 통과한다.
- [x] 실패 테스트가 먼저 작성되었다.
- [x] mapper 객체가 외부 프레임워크에 의존하지 않는다.
- [x] 외부 환경 값이 런타임 중간에 재조회되지 않는다.
- [x] 로그 정책 위반이 없다.
- [x] controller의 finalize failure message 판단 책임이 줄었다.

## 5. Completion Report

- [x] 수행한 변경 사항을 요약한다.
  - `TransferIncomingFinalizeFailureMapper`를 추가했다.
  - AppException은 원래 code/message로, 일반 예외는 `transfer_finalize_failed`와 기본 메시지로 매핑한다.
  - `_onDataFinish` catch가 mapper 결과를 ACK와 `_failIncomingTransfer`에 사용한다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 추가: `lib/application/transfer/transfer_incoming_finalize_failure_mapper.dart`
  - 추가: `test/application/transfer/transfer_incoming_finalize_failure_mapper_test.dart`
  - 수정: `lib/application/transfer/transfer_controller.dart`
  - 수정: `.tasks/task014.md`
- [x] 실행한 테스트 명령과 결과를 기록한다.
  - `flutter test test/application/transfer/transfer_incoming_finalize_failure_mapper_test.dart --reporter expanded`: 최초 mapper 파일 부재로 실패해 red phase 확인, 구현 후 3개 테스트 통과.
  - `dart format lib/application/transfer/transfer_incoming_finalize_failure_mapper.dart lib/application/transfer/transfer_controller.dart test/application/transfer/transfer_incoming_finalize_failure_mapper_test.dart`: 통과.
  - `flutter analyze`: No issues found.
  - `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`: 30개 테스트 통과. Drift test warning은 기존 테스트 DB 생성 경고이며 실패는 아니다.
- [x] 검증한 항목을 기록한다.
  - mapper 객체는 Flutter, Riverpod, dart:io, transport, file service에 의존하지 않는다.
  - 예상 가능한 AppException과 일반 예외 매핑이 분리됐다.
  - 기존 transfer controller 회귀 테스트가 모두 통과한다.
- [x] 남은 위험 요소를 기록한다.
  - legacy Control `TRANSFER_COMPLETE` catch는 아직 같은 mapper를 사용하지 않는다.
  - finalize 성공 경로 자체는 아직 controller 내부에 남아 있다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - 다음 태스크는 legacy Control complete finalize catch에도 동일 mapper를 적용한다.

## 6. Next Task Decision Hook

- [x] `plan.md`의 최종 목표에 도달했는지 확인한다.
- [x] 도달했다면 추가 태스크를 생성하지 않는다. 최종 목표에는 아직 도달하지 않았다.
- [x] 도달하지 못했다면 남은 목표를 정리한다.
- [x] 남은 목표 중 가장 우선순위가 높은 작업을 선택한다.
- [x] 다음 태스크가 기능 2~3개 단위를 넘지 않도록 범위를 제한한다.
- [x] 다음 태스크가 테스트와 검증을 포함하도록 정의한다.
- [x] 다음 태스크가 `AGENTS.md` 원칙과 충돌하지 않는지 확인한다.
- [x] 다음 태스크 파일명을 결정한다.
- [x] 다음 태스크를 `taskXXX.md`로 생성한다.
- [x] 다음 태스크 생성을 완료한 뒤 즉시 실행을 시작한다.

결정: `task015.md`를 생성한다. 범위는 legacy Control `TRANSFER_COMPLETE` finalize catch가 `TransferIncomingFinalizeFailureMapper`를 재사용하도록 변경하는 것으로 제한한다.
