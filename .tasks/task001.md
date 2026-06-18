# Task 001. TCP Data Channel 문서 Guardrail 정렬

## 1. Task Purpose

- [x] 이 태스크의 목적은 구현 전에 `.tasks/plan.md`, `AGENTS.md`, README 문서가 `UDP Discovery/Control + TCP Data payload` 방향으로 충돌 없이 정렬되도록 만드는 것이다.
- [x] 이 태스크는 `.tasks/plan.md`의 Phase 0, "문서 Guardrail 정렬과 Baseline 고정" 목표에 기여한다.
- [x] 이 태스크 완료 후 프로젝트 문서는 Discovery와 Control은 UDP를 유지하고, 파일 payload Data channel은 TCP stream 전환을 기본 개발 방향으로 삼는다는 점을 명확히 설명해야 한다.

## 2. Current Context

- [x] 현재 `.tasks/plan.md`는 TCP Data Channel 전환 계획으로 작성되어 있다.
- [x] 이전 루트 `.tasks/task001.md`부터 `.tasks/task011.md`는 phase archive 이동 작업의 영향으로 git 상태상 삭제된 상태이며, 현재 루프는 새 TCP Data Channel 계획 기준으로 `task001.md`부터 다시 시작한다.
- [x] 이번 태스크를 시작해야 하는 이유는 README 문서가 아직 UDP 기반 파일 전송을 기본 경로로 설명하고 있어 `.tasks/plan.md`와 AGENTS.md의 TCP Data 방향과 충돌하기 때문이다.
- [x] 현재 확인된 제약 사항은 런타임 동작을 바꾸지 않고 문서와 문서 테스트만 변경해야 한다는 점이다.

## 3. Scope

### Included

- [x] README.md의 핵심 목표, 전송 설명, 플랫폼 운영 안내를 TCP Data Channel 전환 기준으로 정렬한다.
- [x] README.ko.md의 동일 내용을 한국어 기준으로 정렬한다.
- [x] 문서 테스트가 TCP Data Channel 방향을 검증하도록 갱신한다.

### Excluded

- [x] TCP socket, listener, connector, frame codec 구현은 이번 태스크에서 다루지 않는다.
- [x] 기존 UDP Data runtime code 제거는 이번 태스크에서 다루지 않는다.
- [x] Phase 1의 domain state machine과 DataChannel abstraction은 후속 태스크로 넘긴다.

## 4. Functional Units

이번 태스크는 기능 2~3개 단위로만 구성한다.

### Functional Unit 1

- [x] README.md를 TCP Data Channel 전환 방향으로 갱신한다.
- [x] 입력은 `.tasks/plan.md`와 AGENTS.md의 Discovery, Control, Data 책임 기준이다.
- [x] 출력은 사용자가 영문 README를 읽었을 때 UDP 파일 전송이 현재 기본 개발 방향이라고 오해하지 않는 문서다.
- [x] 성공 조건은 README.md에 UDP Discovery/Control과 TCP Data Channel 책임이 분리되어 설명되는 것이다.
- [x] 실패 조건은 README.md에 "UDP 기반 파일 전송"이 기본 Data payload 경로처럼 남아 있는 것이다.

### Functional Unit 2

- [x] README.ko.md를 TCP Data Channel 전환 방향으로 갱신한다.
- [x] 입력은 영문 README와 동일한 제품 방향이다.
- [x] 출력은 한국어 문서가 영문 문서와 같은 전송 방향을 설명하는 상태다.
- [x] 성공 조건은 README.ko.md에 UDP Discovery/Control과 TCP Data Channel 책임이 분리되어 설명되는 것이다.
- [x] 실패 조건은 한글 문서가 영문 문서와 다른 프로토콜 방향을 설명하는 것이다.

### Functional Unit 3

- [x] 문서 테스트를 TCP Data Channel 기준으로 갱신한다.
- [x] 입력은 `test/docs/platform_guide_test.dart`의 README 문구 검증이다.
- [x] 출력은 README 문서가 UDP 포트와 TCP Data Channel 운영 안내를 모두 포함하는지 확인하는 테스트다.
- [x] 성공 조건은 문서 테스트가 통과하는 것이다.
- [x] 실패 조건은 TCP Data Channel 문구가 빠져도 테스트가 통과하는 것이다.

## 5. Architecture Notes

- [x] 변경되는 계층은 문서와 문서 테스트뿐이다.
- [x] 도메인, 유스케이스, 어댑터, 인프라 런타임 책임은 변경하지 않는다.
- [x] 의존성 방향 변경은 없다.
- [x] 외부 시스템 접근 변경은 없다.
- [x] 이번 태스크에서는 새 인터페이스, 포트, 어댑터를 정의하지 않는다.
- [x] 전역 상태, 숨겨진 I/O, 암묵적 설정 접근을 추가하지 않는다.

## 6. Configuration Rules

- [x] 외부 설정 파일 의존을 추가하지 않는다.
- [x] 환경 값은 프로그램 시작 시 최초 1회만 수신한다는 원칙을 README에 유지한다.
- [x] 최초 수신 이후에는 환경 값을 전역 상수처럼 사용하지 않는다는 원칙을 유지한다.
- [x] 환경 값은 명시적 인자, 생성자 인자, 컨텍스트 객체, 의존성 주입으로 전달한다는 원칙을 유지한다.
- [x] 프로세스 중간에 환경 설정 값을 삽입하거나 변경하지 않는다.
- [x] 런타임 중간 재설정, 동적 환경 변경, 숨겨진 설정 조회를 제안하지 않는다.

## 7. Logging Requirements

### Product Log

- [x] 운영에 필요한 최소 로그 정책은 README와 AGENTS.md의 기존 기준을 유지한다.
- [x] 사용자 영향, 핵심 상태 변화, 장애 원인 추적에 필요한 정보만 포함한다는 원칙을 유지한다.
- [x] 민감 정보와 과도한 내부 상태를 기록하지 않는다는 원칙을 유지한다.

### Field Debug Log

- [x] 현장 확인용 디버그 로그가 TCP Data Channel state와 endpoint summary를 다루어야 함을 계획에 유지한다.
- [x] 필요한 경우 활성화 조건은 후속 구현 태스크에서 정의한다.
- [x] 민감 정보 마스킹 기준은 README와 AGENTS.md의 원칙을 따른다.
- [x] 보존 범위와 사용 범위는 후속 diagnostics 태스크에서 제한한다.

### Development Log

- [x] 개발 및 테스트 중 확인할 로그는 이번 태스크에서 추가하지 않는다.
- [x] 프로덕션 기본 동작에 포함되지 않도록 한다는 원칙을 유지한다.
- [x] 테스트 완료 후 제거 또는 비활성화 기준은 후속 구현 태스크에서 정의한다.

## 8. State Machine Requirements

- [x] 이번 태스크는 문서 정렬이므로 상태머신 구현이 필요하지 않다.
- [x] 복잡한 내부 흐름을 암묵적 플래그 조합으로 관리하는 코드를 추가하지 않는다.
- [x] TCP state 목록은 `.tasks/plan.md`에 정의되어 있다.
- [x] TCP event 목록은 `.tasks/plan.md`에 정의되어 있다.
- [x] 전이 조건은 후속 domain state machine 태스크에서 테스트로 고정한다.
- [x] 실패 상태와 종료 상태는 `.tasks/plan.md`에 정의되어 있다.
- [x] 상태 전이를 테스트 가능하게 만드는 작업은 후속 task002로 넘긴다.

## 9. TDD Plan

- [x] 문서 테스트를 먼저 갱신해 README가 TCP Data Channel 방향을 포함해야 통과하도록 만든다.
- [x] 테스트 대상 유스케이스는 README 플랫폼/프로토콜 안내 문구 검증이다.
- [x] 정상 케이스 테스트는 README 양쪽이 TCP Data Channel 문구를 포함하는지 확인한다.
- [x] 실패 케이스 테스트는 TCP Data Channel 문구가 빠지면 실패하도록 구성한다.
- [x] 경계값 테스트는 문서 작업 범위에 해당하지 않는다.
- [x] 외부 의존성은 없다.
- [x] 설정 값 전달 방식 테스트는 문서 변경 범위에 해당하지 않는다.
- [x] 로그 정책 검증 테스트는 문서에 민감정보 금지 원칙이 남아 있는지 기존 테스트 범위에서 확인한다.
- [x] 상태 전이 테스트는 후속 task002에서 작성한다.
- [x] 테스트를 통과하는 최소 문서 변경만 작성한다.
- [x] 테스트 통과 후 문구 중복과 충돌을 정리한다.

## 10. Implementation Checklist

- [x] 테스트 파일을 먼저 작성한다.
- [x] 실패하는 테스트를 확인한다.
- [x] 최소 문서 구현을 작성한다.
- [x] 계층 간 의존성을 확인한다.
- [x] 외부 의존성이 경계 계층에만 있는지 확인한다.
- [x] 설정 값 전달 방식이 명시적인지 확인한다.
- [x] 필요한 로그 정책 문구를 유지한다.
- [x] 상태 관리가 필요한 경우 명시적 상태 전이로 구현한다.
- [x] 중복과 구조 문제를 정리한다.
- [x] 모든 관련 테스트를 실행한다.

## 11. Validation Checklist

- [x] 기능 요구사항이 충족되었다.
- [x] 테스트가 모두 통과한다.
- [x] 실패 테스트가 먼저 작성되었다.
- [x] 도메인 계층이 외부 프레임워크에 의존하지 않는다.
- [x] 유스케이스가 명시적 입력과 출력을 가진다.
- [x] 외부 환경 값이 런타임 중간에 재조회되지 않는다.
- [x] 외부 환경 값이 전역 상수처럼 사용되지 않는다.
- [x] 로그가 Product Log, Field Debug Log, Development Log 기준에 맞게 분리되었다.
- [x] 개발용 로그가 프로덕션 기본 동작에 포함되지 않는다.
- [x] 복잡한 흐름이 플래그 조합이 아니라 명시적 상태로 표현되었다.
- [x] 리팩터링과 기능 변경이 가능한 한 분리되었다.

## 12. Completion Report

태스크 완료 후 다음 내용을 기록한다.

- [x] 수행한 변경 사항을 요약한다.
- [x] 생성하거나 수정한 파일을 기록한다.
- [x] 실행한 테스트 명령과 결과를 기록한다.
- [x] 검증한 항목을 기록한다.
- [x] 남은 위험 요소를 기록한다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.

Completion summary:

- README.md와 README.ko.md를 UDP Discovery/Control, TCP Data Channel 전환 방향으로 갱신한다.
- `test/docs/platform_guide_test.dart`가 TCP Data Channel 문구를 검증하도록 갱신한다.
- 문서 변경이며 런타임 코드는 변경하지 않는다.

Changed files:

- `.tasks/task001.md`
- `README.md`
- `README.ko.md`
- `test/docs/platform_guide_test.dart`

Validation commands:

- `flutter test test/docs/platform_guide_test.dart --reporter compact`
- Result: passed after README.md and README.ko.md were updated to include TCP Data Channel guidance.
- TDD failure check: the same command failed first after the test was updated and before README changes, because README documents did not yet contain `TCP Data Channel`.
- `git diff --check -- README.md README.ko.md test/docs/platform_guide_test.dart .tasks/task001.md`
- Result: passed.
- `rg -n 'UDP-Based File Transfer|UDP 기반 파일 전송|UDP-based control and data|UDP 기반 제어 및 데이터|uses UDP for discovery, control, and data|discovery, control, data transfer에 UDP|current connection-first|task001.md.*task011' README.md README.ko.md`
- Result: no stale default UDP Data path wording found.

Remaining risks:

- 실제 TCP listener, connector, state machine, frame codec은 아직 구현되지 않았다.
- README는 현재 개발 방향과 현재 릴리즈 동작이 다를 수 있음을 명확히 유지해야 한다.

Follow-up:

- task002에서 TCP data peer session state machine을 domain 계층에 TDD로 추가한다.

## 13. Next Task Decision Hook

이 태스크 완료 후 반드시 다음 판단을 수행한다.

- [x] `plan.md`의 최종 목표에 도달했는지 확인한다.
- [x] 도달했다면 추가 태스크를 생성하지 않는다.
- [x] 도달하지 못했다면 남은 목표를 정리한다.
- [x] 남은 목표 중 가장 우선순위가 높은 작업을 선택한다.
- [x] 다음 태스크가 기능 2~3개 단위를 넘지 않도록 범위를 제한한다.
- [x] 다음 태스크가 테스트와 검증을 포함하도록 정의한다.
- [x] 다음 태스크가 `AGENTS.md` 원칙과 충돌하지 않는지 확인한다.
- [x] 다음 태스크 파일명을 결정한다.
- [x] 다음 태스크를 `taskXXX.md`로 생성한다.
- [x] 다음 태스크 생성을 완료한 뒤 즉시 실행을 시작한다.

Decision:

- 최종 목표에는 아직 도달하지 않았다.
- 다음 우선순위는 Phase 1의 시작인 TCP data peer session state machine과 값 객체를 domain 계층에 추가하는 것이다.
- 다음 파일명은 `.tasks/task002.md`다.

## 14. Stop Conditions

다음 조건 중 하나라도 발생하면 루프를 멈추고 사용자에게 보고한다.

- `plan.md`의 최종 목표에 도달했다.
- 필수 요구사항이 불명확하여 더 이상 안전하게 진행할 수 없다.
- 외부 정보, 권한, 비밀값, 접근 권한이 없어 진행할 수 없다.
- `AGENTS.md` 원칙과 충돌하는 요구사항이 발견되었다.
- 테스트 또는 검증 환경이 없어 완료 여부를 판단할 수 없다.
- 코드베이스 구조가 계획과 크게 달라 태스크 재설계가 필요하다.
- 사용자 결정이 필요한 아키텍처 선택지가 발생했다.
