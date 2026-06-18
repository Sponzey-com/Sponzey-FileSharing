# Task 007. Diagnostics Route Error Code 분리

## 1. Task Purpose

- [x] 이 태스크의 목적은 diagnostics export에서 transfer route 변경/만료 실패를 storage path 실패로 오분류하지 않도록 하는 것이다.
- [x] 이 태스크는 `.tasks/plan.md`의 diagnostics 정확도와 현장 확인성 개선 목표에 기여한다.
- [x] 이 태스크 완료 후 route changed는 `TRANSFER_ROUTE_CHANGED`, route expired는 `TRANSFER_ROUTE_EXPIRED`로 export되어야 한다.

## 2. Current Context

- [x] `DiagnosticsExportBundleBuilder._errorCode(...)`는 실패 메시지에 `path` 또는 `경로`가 포함되면 `STORAGE_PATH_FAILED`로 분류한다.
- [x] task006 이후 route changed와 route expired 메시지에도 `연결 경로`가 포함된다.
- [x] 이 상태에서는 네트워크 route 실패가 storage path 실패로 잘못 export될 수 있다.

## 3. Scope

### Included

- [x] diagnostics error code mapping에 route changed/expired 분기를 추가한다.
- [x] route changed/expired 메시지에 대한 diagnostics 테스트를 추가한다.
- [x] 기존 storage path 분류는 유지한다.

### Excluded

- [x] diagnostics export 파일 저장 방식 변경은 이번 태스크에서 다루지 않는다.
- [x] UI 변경은 이번 태스크에서 다루지 않는다.
- [x] 로그 레벨 변경은 이번 태스크에서 다루지 않는다.
- [x] 네트워크 또는 transfer 로직 변경은 이번 태스크에서 다루지 않는다.

## 4. Functional Units

### Functional Unit 1

- [x] 구현할 기능은 route changed diagnostics 분류다.
- [x] 입력은 `연결 경로가 변경` 메시지를 가진 failed transfer job이다.
- [x] 출력은 `TRANSFER_ROUTE_CHANGED` error code다.
- [x] 성공 조건은 route changed가 storage path failure로 분류되지 않는 것이다.

### Functional Unit 2

- [x] 구현할 기능은 route expired diagnostics 분류다.
- [x] 입력은 `연결 경로가 만료` 메시지를 가진 failed transfer job이다.
- [x] 출력은 `TRANSFER_ROUTE_EXPIRED` error code다.
- [x] 성공 조건은 route expired가 storage path failure로 분류되지 않는 것이다.

### Functional Unit 3

- [x] 구현할 기능은 기존 storage path 분류 유지다.
- [x] 입력은 저장 경로 권한 문제 메시지를 가진 failed transfer job이다.
- [x] 출력은 `STORAGE_PATH_FAILED` error code다.
- [x] 성공 조건은 route 분기 추가 후에도 storage path 분류가 깨지지 않는 것이다.

## 5. Architecture Notes

- [x] diagnostics 분류는 `application/diagnostics`에 둔다.
- [x] transfer controller와 transport 로직은 변경하지 않는다.
- [x] diagnostics는 민감한 전체 경로를 redactor를 통해 처리해야 한다.
- [x] route error code는 field debug 진단용이며 product 동작을 바꾸지 않는다.

## 6. Configuration Rules

- [x] 외부 설정 파일을 추가하지 않는다.
- [x] 환경 변수나 런타임 설정 값을 새로 읽지 않는다.
- [x] 테스트는 명시적 TransferJob 입력만 사용한다.
- [x] 프로세스 중간 환경 설정 삽입 또는 변경을 사용하지 않는다.

## 7. Logging Requirements

### Product Log

- [x] 새 Product log를 추가하지 않는다.

### Field Debug Log

- [x] diagnostics export의 error code 분류만 수정한다.

### Development Log

- [x] 임시 개발 로그를 추가하지 않는다.

## 8. State Machine Requirements

- [x] 새 상태머신을 추가하지 않는다.
- [x] transfer job 상태는 기존 failed 상태를 사용한다.
- [x] diagnostics 분류는 상태 전이를 발생시키지 않는다.

## 9. TDD Plan

- [x] 먼저 diagnostics test에 route changed/expired/storage path 분류 기대값을 추가한다.
- [x] 테스트 실패를 확인한다.
- [x] `_errorCode(...)` mapping을 최소 수정한다.
- [x] diagnostics 테스트와 `flutter analyze`를 실행한다.

## 10. Implementation Checklist

- [x] `.tasks/task007.md`를 생성한다.
- [x] diagnostics export bundle 테스트를 추가한다.
- [x] diagnostics error code mapping을 수정한다.
- [x] 관련 테스트를 실행한다.
- [x] 완료 보고를 업데이트한다.

## 11. Validation Checklist

- [x] route changed는 `TRANSFER_ROUTE_CHANGED`로 export된다.
- [x] route expired는 `TRANSFER_ROUTE_EXPIRED`로 export된다.
- [x] storage path failure는 `STORAGE_PATH_FAILED`로 유지된다.
- [x] 민감한 전체 경로가 export되지 않는다.
- [x] `flutter analyze`가 통과한다.

## 12. Completion Report

- [x] 수행한 변경 사항을 요약한다.
  - diagnostics export error code mapping에서 route changed/expired를 storage path보다 먼저 분류하도록 수정했다.
  - route changed, route expired, storage path failure 분류 테스트를 추가했다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 생성: `.tasks/task007.md`
  - 수정: `.tasks/task006.md`
  - 수정: `lib/application/diagnostics/diagnostics_export_bundle.dart`
  - 수정: `test/application/diagnostics/diagnostics_export_bundle_test.dart`
- [x] 실행한 테스트 명령과 결과를 기록한다.
  - `flutter test test/application/diagnostics/diagnostics_export_bundle_test.dart --plain-name 'transfer error code distinguishes route and storage failures' --reporter compact`: 의도한 최초 실패 확인 후 통과
  - `flutter test test/application/diagnostics/diagnostics_export_bundle_test.dart --reporter compact`: 통과
  - `flutter analyze`: 통과
- [x] 검증한 항목을 기록한다.
  - route changed는 `TRANSFER_ROUTE_CHANGED`로 export된다.
  - route expired는 `TRANSFER_ROUTE_EXPIRED`로 export된다.
  - storage path failure는 `STORAGE_PATH_FAILED`로 유지된다.
- [x] 남은 위험 요소를 기록한다.
  - UI에서 diagnostics error code를 직접 보여주지는 않는다. 사용자가 보는 transfer queue 메시지와 diagnostics code 간 연결은 후속 UI 검토가 필요하다.
  - task 파일들이 ignore 대상이라 커밋 추적 여부를 정리해야 한다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - 다음 태스크는 task tracking ignore 상태를 확인하고 추적 가능한 방식으로 정리해야 한다.

## 13. Next Task Decision Hook

- [x] `plan.md`의 최종 목표에 도달했는지 확인한다.
  - 도달하지 못했다. task tracking 문서 추적성 문제가 남아 있다.
- [x] 도달했다면 추가 태스크를 생성하지 않는다.
  - 해당 없음.
- [x] 도달하지 못했다면 남은 목표를 정리한다.
  - 새 `.tasks/taskXXX.md` 파일이 git ignore에 걸리는 문제가 남아 있다.
- [x] 남은 목표 중 가장 우선순위가 높은 작업을 선택한다.
  - 다음 우선순위는 task tracking markdown 추적성 복구다.
- [x] 다음 태스크가 기능 2~3개 단위를 넘지 않도록 범위를 제한한다.
- [x] 다음 태스크가 테스트와 검증을 포함하도록 정의한다.
- [x] 다음 태스크가 `AGENTS.md` 원칙과 충돌하지 않는지 확인한다.
- [x] 다음 태스크 파일명을 결정한다.
  - 다음 파일명은 `.tasks/task008.md`다.
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
