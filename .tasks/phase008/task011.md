# Task 011. Route 환경 의존 금지 패턴 감사

## 1. Task Purpose

- [x] 이 태스크의 목적은 구현 코드가 특정 IP 대역, VM 제품, NIC 이름, 개발자 장비 환경을 전제로 route를 선택하지 않는지 검증하는 것이다.
- [x] 이 태스크는 `.tasks/plan.md`의 “특정 환경에 종속되지 않는 모든 Ethernet 계열 인터페이스 활용” 목표와 AGENTS.md guardrail을 검증한다.
- [x] 이 태스크 완료 후 runtime code에는 Parallels, vmenet, bridge100, 10.211.x.x, 192.168.x.x 같은 특정 환경 조건으로 route를 선택하는 코드가 없어야 한다.

## 2. Current Context

- [x] 사용자 문제는 host/VM 사이에서 경로가 흔들리고 특정 IP로 잘못 전송되는 것이었다.
- [x] 계획은 관찰된 interface, packet, route probe 결과를 기준으로 route를 선택해야 한다고 정의한다.
- [x] AGENTS.md는 특정 IP 대역, VM 제품, NIC 이름, 개발자 장비 환경을 전제로 한 discovery/connect/transfer 로직을 금지한다.

## 3. Scope

### Included

- [x] `lib` runtime code에서 VM/IP/NIC 하드코딩 패턴을 검색한다.
- [x] 검색 결과가 정당한 일반 처리인지, 금지된 route selection 조건인지 구분한다.
- [x] 문제가 있으면 이번 태스크 범위에서 최소 수정하거나 후속 태스크로 분리한다.
  - 금지 패턴이 발견되지 않아 runtime 수정은 수행하지 않았다.
- [x] `flutter analyze`와 관련 테스트 또는 검색 검증을 실행한다.

### Excluded

- [x] 테스트 fixture, 문서, task history의 예시 IP는 runtime route selection 코드가 아니므로 금지 대상으로 보지 않는다.
- [x] loopback/local registry를 위한 일반 `localhost` 또는 `127.0.0.1` 처리 전체를 금지하지 않는다.
- [x] 실제 host/VM 수동 네트워크 검증은 이번 태스크에서 수행하지 않는다.

## 4. Functional Units

### Functional Unit 1

- [x] 구현할 기능은 runtime route environment pattern scan이다.
- [x] 입력은 `lib` 아래 Dart runtime code다.
- [x] 출력은 특정 VM/IP/NIC 이름 또는 IP 대역 literal 사용 목록이다.
- [x] 성공 조건은 route selection, discovery target, transfer endpoint 결정에 특정 환경 literal이 사용되지 않는 것이다.

### Functional Unit 2

- [x] 구현할 기능은 legitimate literal classification이다.
- [x] 입력은 검색된 `localhost`, `127.0.0.1`, `0.0.0.0`, `255.255.255.255` 같은 일반 네트워크 literal이다.
- [x] 출력은 허용 사유 또는 수정 필요 판정이다.
- [x] 성공 조건은 일반 wildcard/broadcast/loopback 처리와 특정 환경 의존 분기가 명확히 구분되는 것이다.

### Functional Unit 3

- [x] 구현할 기능은 audit validation record다.
- [x] 입력은 `rg` 검색 결과, `flutter analyze`, 관련 테스트 결과다.
- [x] 출력은 Completion Report의 검증 기록이다.
- [x] 성공 조건은 감사 근거가 재현 가능한 명령으로 남는 것이다.

## 5. Architecture Notes

- [x] route selection은 관찰된 interface, packet, probe result 기반이어야 한다.
- [x] 특정 VM vendor, IP prefix, NIC name branch는 domain/application/infrastructure 어느 계층에도 넣지 않는다.
- [x] 일반 broadcast, unspecified bind, loopback fallback은 용도와 경계를 확인하고 허용할 수 있다.
- [x] 문제가 발견되면 route policy command 또는 state machine 경계로 이동해 테스트로 고정한다.

## 6. Configuration Rules

- [x] 감사 목적으로 새 설정 파일을 만들지 않는다.
- [x] 환경 변수나 외부 설정 재조회로 route behavior를 바꾸지 않는다.
- [x] 허용/금지 판단은 AGENTS.md와 `.tasks/plan.md` 기준으로 수행한다.

## 7. Logging Requirements

### Product Log

- [x] 새 Product log를 추가하지 않는다.

### Field Debug Log

- [x] 새 Field Debug log를 추가하지 않는다.

### Development Log

- [x] 임시 개발 로그를 추가하지 않는다.

## 8. State Machine Requirements

- [x] 새 상태머신을 추가하지 않는다.
- [x] 특정 환경 literal로 상태 전이를 우회하는 코드는 금지한다.

## 9. TDD Plan

- [x] 먼저 runtime code 검색으로 의심 지점을 확인한다.
- [x] 금지 패턴이 발견되면 실패 기준을 테스트로 추가한다.
  - 금지 패턴이 없어 새 실패 테스트는 추가하지 않았다.
- [x] 테스트를 통과하는 최소 수정만 수행한다.
  - 수정이 필요하지 않았다.
- [x] 금지 패턴이 없으면 검색 명령과 `flutter analyze`로 검증한다.

## 10. Implementation Checklist

- [x] `.tasks/task011.md`를 생성한다.
- [x] `.tasks/task010.md`의 다음 태스크 결정 hook을 완료 처리한다.
- [x] `lib`에서 특정 VM/IP/NIC literal을 검색한다.
- [x] 검색 결과를 허용/수정 필요로 분류한다.
- [x] 수정이 필요하면 테스트 먼저 추가한다.
  - 수정이 필요하지 않았다.
- [x] `flutter analyze`를 실행한다.
- [x] 관련 테스트 또는 전체 테스트 필요 여부를 판단한다.
  - 일반 네트워크 literal 관련 테스트를 실행했다. 전체 테스트는 task009에서 통과했고 이번 태스크는 runtime code를 변경하지 않았다.
- [x] 완료 보고를 업데이트한다.

## 11. Validation Checklist

- [x] `lib` runtime code에 `Parallels`, `vmenet`, `bridge100`, `bridge101` 기반 route branch가 없다.
- [x] `lib` runtime code에 `10.211.` 또는 `192.168.` 기반 route branch가 없다.
- [x] 허용된 `0.0.0.0`, `255.255.255.255`, `127.0.0.1`, `localhost` 사용은 일반 bind/broadcast/loopback 처리로 설명된다.
- [x] 특정 환경을 전제로 한 route selection 수정이 필요하지 않다.
- [x] `flutter analyze`가 통과한다.

## 12. Completion Report

- [x] 수행한 변경 사항을 요약한다.
  - `lib` runtime code에서 특정 VM 제품, NIC 이름, 개발자 장비명, 특정 IP 대역 literal을 검색했다.
  - 금지 패턴은 발견되지 않았다.
  - 일반 네트워크 literal은 wildcard bind, limited broadcast, loopback/local registry 처리로 분류했다.
  - runtime code 수정은 수행하지 않았다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 생성: `.tasks/task011.md`
  - 수정: `.tasks/task010.md`
- [x] 실행한 검증 명령과 결과를 기록한다.
  - `rg -n "Parallels|VMware|Hyper-V|vmenet|bridge100|bridge101|10\\.211\\.|192\\.168\\.|DONGWOOSHIN|MacBook|Windows VM" lib`: 매칭 없음
  - `rg -n "127\\.0\\.0\\.1|localhost|0\\.0\\.0\\.0|255\\.255\\.255\\.255|InternetAddress\\.anyIPv4|InternetAddress\\.loopbackIPv4" lib`: 일반 wildcard/broadcast/loopback 용도만 확인
  - `flutter analyze`: 통과
  - `flutter test test/domain/network/discovery_target_builder_test.dart test/application/transfer/transfer_active_route_validation_command_test.dart test/application/transfer/transfer_data_bind_endpoint_route_command_test.dart test/application/discovery/peer_route_candidate_projection_test.dart --reporter compact`: 통과
  - `flutter test --reporter compact`: 통과
- [x] 검증한 항목을 기록한다.
  - 특정 VM/IP/NIC 이름 기반 route branch는 없다.
  - `0.0.0.0`은 wildcard bind와 unknown any-bind candidate 용도다.
  - `255.255.255.255`는 limited broadcast 계산과 display 용도다.
  - `127.0.0.1`과 `localhost`는 local registry 또는 loopback mismatch 방지 용도다.
- [x] 남은 위험 요소를 기록한다.
  - 코드 정적 검색은 실제 OS 방화벽, VM 네트워크 모드, NIC down 같은 런타임 조건을 검증하지 못한다.
  - 실제 host/VM 양방향 전송은 release gate 수동 기록으로 보완해야 한다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - 자동화 가능한 계획 항목은 현재 범위에서 완료되었다. 남은 항목은 실제 host/VM/다중 NIC 수동 검증이다.

## 13. Next Task Decision Hook

- [x] `plan.md`의 최종 목표에 도달했는지 확인한다.
  - 자동화 가능한 목표는 도달했다. 실제 host/VM/다중 NIC 수동 전송 검증은 현재 세션에서 수행할 외부 실행 환경이 필요하다.
- [x] 도달했다면 추가 태스크를 생성하지 않는다.
  - 자동화 가능한 후속 태스크는 생성하지 않는다.
- [x] 도달하지 못했다면 남은 목표를 정리한다.
  - 남은 목표는 release gate 수동 실행과 `.tasks/release_runs/<tag>.md` 기록이다.
- [x] 남은 목표 중 가장 우선순위가 높은 작업을 선택한다.
  - 외부 앱 실행과 실제 네트워크 검증이 필요하므로 현재 코드 작업 루프에서는 진행하지 않는다.
- [x] 다음 태스크가 기능 2~3개 단위를 넘지 않도록 범위를 제한한다.
  - 해당 없음.
- [x] 다음 태스크가 테스트와 검증을 포함하도록 정의한다.
  - 해당 없음.
- [x] 다음 태스크가 `AGENTS.md` 원칙과 충돌하지 않는지 확인한다.
  - 해당 없음.
- [x] 다음 태스크 파일명을 결정한다.
  - 추가 태스크 없음.
- [x] 다음 태스크를 `taskXXX.md`로 생성한다.
  - 추가 태스크 없음.
- [x] 다음 태스크 생성을 완료한 뒤 즉시 실행을 시작한다.
  - 추가 태스크 없음.

## 14. Stop Conditions

- [ ] `plan.md`의 최종 목표에 도달했다.
- [ ] 필수 요구사항이 불명확하여 더 이상 안전하게 진행할 수 없다.
- [ ] 외부 정보, 권한, 비밀값, 접근 권한이 없어 진행할 수 없다.
- [ ] `AGENTS.md` 원칙과 충돌하는 요구사항이 발견되었다.
- [ ] 테스트 또는 검증 환경이 없어 완료 여부를 판단할 수 없다.
- [ ] 코드베이스 구조가 계획과 크게 달라 태스크 재설계가 필요하다.
- [ ] 사용자 결정이 필요한 아키텍처 선택지가 발생했다.
