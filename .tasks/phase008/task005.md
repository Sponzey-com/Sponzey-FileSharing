# Task 005. Transfer Route Snapshot 불변 검증

## 1. Task Purpose

- [x] 이 태스크의 목적은 파일 전송 시작 시점의 route snapshot이 전송 중 active route 변경으로 다른 remote endpoint에 끌려가지 않도록 검증하는 것이다.
- [x] 이 태스크는 `.tasks/plan.md`의 transfer route snapshot 고정 목표에 기여한다.
- [x] 이 태스크 완료 후 outgoing transfer는 시작 후 active path가 다른 remote address로 바뀌면 data chunk 전송 전에 실패해야 한다.

## 2. Current Context

- [x] `TransferRouteSnapshot`은 전송 시작 시 active route에서 생성된다.
- [x] `TransferOutgoingRouteLeaseCommand`는 active route lease와 snapshot을 비교한다.
- [x] 기존 테스트는 route가 failed 상태가 되면 전송을 중단하는 경로를 검증한다.
- [x] 다른 active route로 교체된 경우 data chunk 전송을 막는 end-to-end 검증은 추가로 필요하다.

## 3. Scope

### Included

- [x] outgoing transfer 중 active route가 다른 remote address로 교체되면 실패하는 테스트를 추가한다.
- [x] 실패 시 data chunk가 전송되지 않는지 검증한다.
- [x] 필요한 경우 route lease validation 메시지와 상태를 보강한다.

### Excluded

- [x] 데이터 채널 window/ACK 알고리즘 변경은 이번 태스크에서 다루지 않는다.
- [x] incoming transfer 저장 정책 변경은 이번 태스크에서 다루지 않는다.
- [x] UI 변경은 이번 태스크에서 다루지 않는다.
- [x] 실제 host/VM 네트워크 검증은 이번 태스크에서 다루지 않는다.

## 4. Functional Units

### Functional Unit 1

- [x] 구현할 기능은 outgoing route snapshot mismatch 테스트다.
- [x] 입력은 transfer init ack 수신 직전 다른 remote address로 교체된 active route다.
- [x] 출력은 outgoing transfer failed job이다.
- [x] 성공 조건은 data chunk가 전송되기 전에 route mismatch로 실패하는 것이다.
- [x] 실패 조건은 새 active route remote로 전송이 계속되는 것이다.

### Functional Unit 2

- [x] 구현할 기능은 data chunk non-delivery 검증이다.
- [x] 입력은 fake data network의 sent frame 목록이다.
- [x] 출력은 data chunk frame이 비어 있는 상태다.
- [x] 성공 조건은 mismatch 상황에서 `DataFrameType.dataChunk`가 하나도 전송되지 않는 것이다.
- [x] 실패 조건은 route mismatch 이후에도 file chunk가 전송되는 것이다.

### Functional Unit 3

- [x] 구현할 기능은 관련 회귀 테스트와 분석 검증이다.
- [x] 입력은 transfer controller 테스트, route lease command 테스트, static analysis다.
- [x] 출력은 통과한 검증 명령과 남은 위험 기록이다.
- [x] 성공 조건은 transfer 관련 테스트와 `flutter analyze`가 통과하는 것이다.
- [x] 실패 조건은 route snapshot 변경을 테스트 없이 완료 처리하는 것이다.

## 5. Architecture Notes

- [x] route snapshot은 `domain/transfer` 값 객체로 유지한다.
- [x] route validation은 `application/transfer` command에서 수행한다.
- [x] data transport는 검증 결과를 소비할 뿐 route 정책을 소유하지 않는다.
- [x] UI는 route mismatch 판단 규칙을 직접 알지 않아야 한다.

## 6. Configuration Rules

- [x] 외부 설정 파일을 추가하지 않는다.
- [x] 환경 변수나 런타임 설정 값을 새로 읽지 않는다.
- [x] 테스트는 fake network와 명시적 입력값만 사용한다.
- [x] 프로세스 중간 환경 설정 삽입 또는 변경을 사용하지 않는다.

## 7. Logging Requirements

### Product Log

- [x] 새 Product log를 추가하지 않는다.

### Field Debug Log

- [x] 새 Field Debug log를 추가하지 않는다.
- [x] 기존 route mismatch message가 사용자와 현장 확인에 충분한지 확인한다.

### Development Log

- [x] 임시 개발 로그를 추가하지 않는다.

## 8. State Machine Requirements

- [x] 새 상태머신을 추가하지 않는다.
- [x] transfer job은 기존 실패 상태로 종료되어야 한다.
- [x] route mismatch는 data transfer 시작 전 실패 이벤트로 고정한다.

## 9. TDD Plan

- [x] 먼저 transfer controller 실패 테스트를 추가한다.
- [x] 테스트가 실패하면 최소 구현으로 통과시킨다.
- [x] 이미 구현이 충분하면 테스트 통과를 기록한다.
- [x] route lease command 테스트를 실행한다.
- [x] `flutter analyze`를 실행한다.

## 10. Implementation Checklist

- [x] `.tasks/task005.md`를 생성한다.
- [x] transfer controller 테스트를 추가한다.
- [x] 필요한 최소 구현을 적용한다.
- [x] 관련 테스트를 실행한다.
- [x] 완료 보고를 업데이트한다.

## 11. Validation Checklist

- [x] active route가 다른 remote address로 바뀌면 outgoing transfer가 실패한다.
- [x] 실패 전에 data chunk가 전송되지 않는다.
- [x] route snapshot의 original remote address가 검증 기준으로 사용된다.
- [x] 외부 환경 값이 런타임 중간에 재조회되지 않는다.
- [x] 로그 정책 변경이 없다.
- [x] 리팩터링과 기능 변경이 transfer route snapshot 검증에 한정되었다.

## 12. Completion Report

- [x] 수행한 변경 사항을 요약한다.
  - active route가 다른 remote address로 교체되면 outgoing transfer가 data chunk 전에 실패하는 회귀 테스트를 추가했다.
  - 기존 route lease validation 구현이 이미 이 조건을 막고 있어 production 구현 변경은 필요하지 않았다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 생성: `.tasks/task005.md`
  - 수정: `.tasks/task004.md`
  - 수정: `test/application/transfer/transfer_controller_test.dart`
- [x] 실행한 테스트 명령과 결과를 기록한다.
  - `flutter test test/application/transfer/transfer_controller_test.dart --plain-name 'fails before data chunks when active route switches to another remote' --reporter compact`: 통과
  - `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`: 통과
  - `flutter test test/application/transfer/transfer_outgoing_route_lease_command_test.dart --reporter compact`: 통과
  - `flutter analyze`: 통과
- [x] 검증한 항목을 기록한다.
  - transfer init ack 이후 active path가 `10.211.55.3`에서 `192.168.0.236`으로 바뀌면 전송이 실패한다.
  - 실패 전 `DataFrameType.dataChunk`는 전송되지 않는다.
  - job의 route snapshot은 최초 route remote address인 `10.211.55.3`을 유지한다.
- [x] 남은 위험 요소를 기록한다.
  - route mismatch 사용자 메시지는 현재 `연결 경로가 만료`로 넓게 표현된다. 후속 UI/diagnostics 태스크에서 더 정확한 표현을 검토해야 한다.
  - transfer controller test는 기존 drift 다중 database 경고를 출력하지만 테스트 실패는 아니다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - 다음 태스크는 diagnostics와 UI에 표시되는 route/session 정보를 최소화하고 실제 상태와 맞게 정리해야 한다.

## 13. Next Task Decision Hook

- [x] `plan.md`의 최종 목표에 도달했는지 확인한다.
  - 도달하지 못했다. route failure reason과 diagnostics 정리가 남아 있다.
- [x] 도달했다면 추가 태스크를 생성하지 않는다.
  - 해당 없음.
- [x] 도달하지 못했다면 남은 목표를 정리한다.
  - route changed와 route expired 사용자 메시지 분리가 남아 있다.
  - diagnostics와 UI 표시 정리가 남아 있다.
- [x] 남은 목표 중 가장 우선순위가 높은 작업을 선택한다.
  - 다음 우선순위는 transfer route lease 실패 사유 분리다.
- [x] 다음 태스크가 기능 2~3개 단위를 넘지 않도록 범위를 제한한다.
- [x] 다음 태스크가 테스트와 검증을 포함하도록 정의한다.
- [x] 다음 태스크가 `AGENTS.md` 원칙과 충돌하지 않는지 확인한다.
- [x] 다음 태스크 파일명을 결정한다.
  - 다음 파일명은 `.tasks/task006.md`다.
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
