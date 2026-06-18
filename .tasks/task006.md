# Task 006. Transfer Route Lease 실패 사유 분리

## 1. Task Purpose

- [x] 이 태스크의 목적은 route lease 실패가 만료/비활성 때문인지, 다른 remote route로 변경되었기 때문인지 구분하는 것이다.
- [x] 이 태스크는 `.tasks/plan.md`의 diagnostics와 사용자 오류 표시 정리 목표에 기여한다.
- [x] 이 태스크 완료 후 route switch 실패는 `연결 경로가 변경` 메시지로, route inactive 실패는 `연결 경로가 만료` 메시지로 구분되어야 한다.

## 2. Current Context

- [x] task005에서 active route가 다른 remote로 바뀌면 data chunk 전 실패한다는 테스트를 추가했다.
- [x] 현재 controller 메시지는 route 변경도 `연결 경로가 만료`로 표시한다.
- [x] `TransferOutgoingRouteLeaseDecision`은 boolean만 반환해 실패 사유를 표현하지 못한다.

## 3. Scope

### Included

- [x] route lease decision에 실패 사유와 메시지를 추가한다.
- [x] inactive/missing route와 changed route를 구분한다.
- [x] transfer controller가 decision message를 사용하도록 변경한다.

### Excluded

- [x] UI 레이아웃 변경은 이번 태스크에서 다루지 않는다.
- [x] 로그 레벨 변경은 이번 태스크에서 다루지 않는다.
- [x] 데이터 전송 알고리즘 변경은 이번 태스크에서 다루지 않는다.

## 4. Functional Units

### Functional Unit 1

- [x] 구현할 기능은 route lease decision 사유 추가다.
- [x] 입력은 expected route snapshot과 current route 상태다.
- [x] 출력은 `isValid`, `reasonCode`, `message`를 가진 decision이다.
- [x] 성공 조건은 valid decision에는 사유가 없고 invalid decision에는 사유와 메시지가 있다.
- [x] 실패 조건은 boolean만 반환해 controller가 실패 원인을 추정하는 것이다.

### Functional Unit 2

- [x] 구현할 기능은 route inactive와 route changed 메시지 분기다.
- [x] 입력은 inactive current status 또는 remote address mismatch다.
- [x] 출력은 서로 다른 사용자 메시지다.
- [x] 성공 조건은 inactive는 만료 메시지, changed는 변경 메시지를 반환하는 것이다.
- [x] 실패 조건은 두 실패가 같은 메시지로 표시되는 것이다.

### Functional Unit 3

- [x] 구현할 기능은 transfer controller 회귀 테스트다.
- [x] 입력은 route expired 테스트와 route switched 테스트다.
- [x] 출력은 각 테스트의 예상 메시지와 no data chunk 검증이다.
- [x] 성공 조건은 두 테스트가 서로 다른 메시지로 통과하는 것이다.
- [x] 실패 조건은 메시지 분리를 테스트하지 않는 것이다.

## 5. Architecture Notes

- [x] 실패 사유 판단은 `application/transfer` command에 둔다.
- [x] controller는 command decision을 소비하고 판단 규칙을 중복하지 않는다.
- [x] domain transfer snapshot 값 객체는 변경하지 않는다.
- [x] infrastructure data transport는 실패 사유 판단을 소유하지 않는다.

## 6. Configuration Rules

- [x] 외부 설정 파일을 추가하지 않는다.
- [x] 환경 변수나 런타임 설정 값을 새로 읽지 않는다.
- [x] 테스트는 명시적 입력값만 사용한다.
- [x] 프로세스 중간 환경 설정 삽입 또는 변경을 사용하지 않는다.

## 7. Logging Requirements

### Product Log

- [x] 새 Product log를 추가하지 않는다.

### Field Debug Log

- [x] 새 Field Debug log를 추가하지 않는다.

### Development Log

- [x] 임시 개발 로그를 추가하지 않는다.

## 8. State Machine Requirements

- [x] 새 상태머신을 추가하지 않는다.
- [x] route lease failure reason은 현재 validation decision의 출력으로만 표현한다.
- [x] transfer job은 기존 failed 상태를 사용한다.

## 9. TDD Plan

- [x] 먼저 route lease command 테스트에 reason/message 기대값을 추가한다.
- [x] 테스트 실패를 확인한다.
- [x] decision에 reason/message를 추가한다.
- [x] controller가 decision message를 사용하도록 변경한다.
- [x] transfer controller route switched 테스트의 메시지 기대값을 변경한다.
- [x] 관련 테스트와 `flutter analyze`를 실행한다.

## 10. Implementation Checklist

- [x] `.tasks/task006.md`를 생성한다.
- [x] route lease command 테스트를 수정한다.
- [x] route lease decision 구현을 수정한다.
- [x] transfer controller 메시지 사용 방식을 수정한다.
- [x] transfer controller 테스트 기대값을 수정한다.
- [x] 관련 테스트를 실행한다.
- [x] 완료 보고를 업데이트한다.

## 11. Validation Checklist

- [x] inactive route는 만료 메시지를 반환한다.
- [x] changed route는 변경 메시지를 반환한다.
- [x] controller는 command message를 사용한다.
- [x] route switched transfer test는 변경 메시지를 검증한다.
- [x] route expired transfer test는 만료 메시지를 유지한다.
- [x] `flutter analyze`가 통과한다.

## 12. Completion Report

- [x] 수행한 변경 사항을 요약한다.
  - `TransferOutgoingRouteLeaseDecision`에 `reasonCode`와 `message`를 추가했다.
  - inactive/missing route는 `routeInactive`와 만료 메시지로 처리한다.
  - changed route는 `routeChanged`와 변경 메시지로 처리한다.
  - `TransferController`가 decision의 code/message를 사용하도록 변경했다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 생성: `.tasks/task006.md`
  - 수정: `.tasks/task005.md`
  - 수정: `lib/application/transfer/transfer_outgoing_route_lease_command.dart`
  - 수정: `lib/application/transfer/transfer_controller.dart`
  - 수정: `test/application/transfer/transfer_outgoing_route_lease_command_test.dart`
  - 수정: `test/application/transfer/transfer_controller_test.dart`
- [x] 실행한 테스트 명령과 결과를 기록한다.
  - `flutter test test/application/transfer/transfer_outgoing_route_lease_command_test.dart --reporter compact`: 의도한 최초 실패 확인 후 통과
  - `flutter test test/application/transfer/transfer_controller_test.dart --plain-name 'fails before data chunks when active route switches to another remote' --reporter compact`: 통과
  - `flutter test test/application/transfer/transfer_controller_test.dart --plain-name 'fails before data chunks when route lease expires' --reporter compact`: 통과
  - `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`: 통과
  - `flutter analyze`: 통과
- [x] 검증한 항목을 기록한다.
  - route inactive는 `연결 경로가 만료` 메시지를 유지한다.
  - route changed는 `연결 경로가 변경` 메시지를 사용한다.
  - route changed AppException code는 `transfer_route_changed`로 분리되었다.
- [x] 남은 위험 요소를 기록한다.
  - UI에서 `transfer_route_changed`와 `transfer_route_lease_expired`를 별도 안내로 보여주는지는 후속 태스크에서 확인해야 한다.
  - field diagnostics export에 reason code가 충분히 노출되는지는 후속 태스크에서 확인해야 한다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - 다음 태스크는 UI/diagnostics가 route failure reason을 과도한 정보 없이 표시하는지 검증해야 한다.

## 13. Next Task Decision Hook

- [x] `plan.md`의 최종 목표에 도달했는지 확인한다.
  - 도달하지 못했다. diagnostics error code 분류 정리가 남아 있다.
- [x] 도달했다면 추가 태스크를 생성하지 않는다.
  - 해당 없음.
- [x] 도달하지 못했다면 남은 목표를 정리한다.
  - route changed/expired diagnostics 분류가 남아 있다.
  - UI 표시 정리가 남아 있다.
- [x] 남은 목표 중 가장 우선순위가 높은 작업을 선택한다.
  - 다음 우선순위는 diagnostics route error code 분리다.
- [x] 다음 태스크가 기능 2~3개 단위를 넘지 않도록 범위를 제한한다.
- [x] 다음 태스크가 테스트와 검증을 포함하도록 정의한다.
- [x] 다음 태스크가 `AGENTS.md` 원칙과 충돌하지 않는지 확인한다.
- [x] 다음 태스크 파일명을 결정한다.
  - 다음 파일명은 `.tasks/task007.md`다.
- [x] 다음 태스크를 `taskXXX.md`로 생성한다.
- [x] 다음 태스크 생성을 완료한 뒤 즉시 실행을 시작한다.

## 14. Stop Conditions

- [ ] `plan.md`의 최종 목표에 도달했다.
- [ ] 필수 요구사항이 불명확하여 더 이상 안전하게 진행할 수 없다.
- [ ] 외부 정보, 권한, 비밀값, 접근 권한이 없어 진행할 수 없다.
- [ ] `AGENTS.md` 원칙과 충돌하는 요구사항이 발견되었다.
- [ ] 테스트 또는 검증 환경이 없어 완료 여부를 판단할 수 없다.
- [ ] 코드베이스 구조가 계획과 크게 달라 태스크 재설계가 필요하다.
- [ ] 사용자 결정이 필요한 아키텍처 선택지가 발생했다.
