# Task 015. Legacy incoming complete failure mapping 일관화

## 1. Task Purpose

- [x] 이 태스크의 목적은 legacy Control `TRANSFER_COMPLETE` finalize 실패도 `TransferIncomingFinalizeFailureMapper`를 사용하게 만드는 것이다.
- [x] 이 태스크는 Data channel 완료 실패와 legacy Control 완료 실패의 사용자 메시지 정책을 일치시킨다.
- [x] 완료 후 incoming finalize 실패 message/code 판단은 mapper 한 곳에서 수행된다.

## 2. Scope

### Included

- [x] controller source guard로 Data/Control finalize catch가 mapper를 모두 사용하는지 고정한다.
- [x] `_onTransferComplete`의 AppException catch와 generic catch가 mapper 결과를 사용하도록 변경한다.
- [x] 기존 controller 회귀 테스트를 실행한다.

### Excluded

- [x] legacy Control chunk 전송 경로 자체는 변경하지 않는다.
- [x] digest, file finalize, ACK 전송 방식은 변경하지 않는다.
- [x] logger category 변경은 하지 않는다.

## 3. TDD Plan

- [x] 실패하는 source guard 테스트를 먼저 작성한다.
- [x] mapper 호출이 Data/Control finalize catch 양쪽에 존재하는지 검증한다.
- [x] 최소 구현으로 테스트를 통과시킨다.
- [x] 기존 transfer controller 회귀 테스트를 실행한다.

## 4. Validation Checklist

- [x] 테스트가 모두 통과한다.
- [x] 실패 테스트가 먼저 작성되었다.
- [x] 외부 환경 값이 런타임 중간에 재조회되지 않는다.
- [x] 로그 정책 위반이 없다.
- [x] Data/Control incoming finalize failure mapping이 일관화되었다.

## 5. Completion Report

- [x] 수행한 변경 사항을 요약한다.
  - legacy Control `_onTransferComplete`의 AppException/generic catch에도 `TransferIncomingFinalizeFailureMapper`를 적용했다.
  - source guard로 mapper 호출이 Data/Control finalize catch 양쪽에 존재하도록 고정했다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 수정: `lib/application/transfer/transfer_controller.dart`
  - 수정: `test/application/transfer/transfer_incoming_finalize_failure_mapper_test.dart`
  - 수정: `.tasks/task015.md`
- [x] 실행한 테스트 명령과 결과를 기록한다.
  - `flutter test test/application/transfer/transfer_incoming_finalize_failure_mapper_test.dart --reporter expanded`: 최초 mapper 호출 2회로 실패해 red phase 확인, 구현 후 4개 테스트 통과.
  - `dart format lib/application/transfer/transfer_controller.dart test/application/transfer/transfer_incoming_finalize_failure_mapper_test.dart`: 통과.
  - `flutter analyze`: No issues found.
  - `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`: 30개 테스트 통과. Drift test warning은 기존 테스트 DB 생성 경고이며 실패는 아니다.
- [x] 검증한 항목을 기록한다.
  - Data/Control incoming finalize failure mapping이 같은 mapper를 사용한다.
  - 직접 hard-coded generic finalize 실패 메시지가 controller에서 제거됐다.
- [x] 남은 위험 요소를 기록한다.
  - legacy Control complete readiness 조건은 아직 controller에 직접 남아 있다.
  - finalize 성공 경로 자체는 아직 controller 내부에 남아 있다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - 다음 태스크는 legacy Control complete readiness도 `TransferIncomingDataFinishCommand`를 재사용하도록 변경한다.

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

결정: `task016.md`를 생성한다. 범위는 legacy Control complete readiness가 `TransferIncomingDataFinishCommand`를 재사용하도록 변경하는 것으로 제한한다.
