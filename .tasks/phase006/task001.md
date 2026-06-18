# task001 - 문서 정렬과 공통 작업 기준 고정

## 상태

- [x] 진행 전
- [x] 진행 중
- [x] 구현 완료
- [x] 테스트 완료
- [x] 수동 검증 완료
- [x] 완료

## 목적

현재 계획의 첫 단계는 코드를 수정하기 전에 제품 방향과 작업 기준을 흔들리지 않게 고정하는 것이다. 이 태스크는 README, README.ko.md, PROJECT.md, AGENTS.md, `.tasks` 문서가 같은 제품 정책을 말하도록 정렬하고, 이후 모든 구현 태스크가 동일한 TDD, 상태 머신, MessageBus, diagnostics 기준을 따르도록 공통 체크리스트를 확정한다.

## 기능 범위

1. 제품 문서 정렬
2. 공통 TDD 및 상태 머신 완료 기준 문서화
3. phase/task 인덱스 정리

## 선행 조건

- [x] `.tasks/plan.md`를 끝까지 읽는다.
- [x] `AGENTS.md`의 Project Direction, Required Engineering Principles, Product-Specific Guardrails를 확인한다.
- [x] `PROJECT.md`, `README.md`, `README.ko.md`, `.tasks/README.md`의 현재 표현을 확인한다.

## 제외 범위

- 런타임 코드 수정은 하지 않는다.
- protocol, route, transfer 로직은 수정하지 않는다.
- 새 설정 파일, dotenv, YAML, JSON을 추가하지 않는다.

## 계층별 변경 위치

- 문서: `README.md`, `README.ko.md`, `PROJECT.md`, `AGENTS.md`, `.tasks/README.md`, `.tasks/task*.md`
- 코드 계층 변경 없음

## 실패 테스트 또는 수동 재현 기준

- [x] README와 PROJECT가 가입/로컬 계정/secure storage를 현재 기본 경로처럼 설명하면 실패다.
- [x] `.tasks/README.md`가 현재 루트 plan과 task 파일을 가리키지 못하면 실패다.
- [x] 새 task 문서에 기능 범위, 테스트, 수동 검증, 완료 기준이 빠지면 실패다.

## diagnostics/log 검토 기준

- 이 태스크는 문서 작업이므로 앱 diagnostics 실행은 요구하지 않는다.
- 단, 네트워크/전송 작업 태스크 템플릿에는 diagnostics/log 검토 항목이 반드시 포함되어야 한다.

## 구현 체크리스트

- [x] README.md가 현재 제품 방향을 영어로 설명하는지 확인한다.
- [x] README.ko.md가 현재 제품 방향을 한국어로 설명하는지 확인한다.
- [x] README와 README.ko.md가 서로 링크되어 있는지 확인한다.
- [x] 가입 없음, 런타임 ID/PW, 메모리 전용 credential, 자동 인증, 자동 수신 정책이 문서에 반영되어 있는지 확인한다.
- [x] 사용 가능한 모든 Ethernet 계열 인터페이스를 활용한다는 설명이 README/README.ko.md에 반영되어 있는지 확인한다.
- [x] PROJECT.md가 현재 기본 경로와 미래 확장 후보를 구분하는지 확인한다.
- [x] AGENTS.md가 hardcoded IP, VM 제품, NIC 이름 기반 로직을 금지하는지 확인한다.
- [x] AGENTS.md가 route lease, self packet suppression, diagnostics 우선 원칙을 포함하는지 확인한다.
- [x] `.tasks/README.md`에 현재 루트 plan과 task001~task011 링크를 추가한다.
- [x] `.tasks/phase005`는 고속 UDP Data Channel 전환 기록으로 유지한다.

## 테스트 체크리스트

- [x] `rg -n "계정 생성|flutter_secure_storage|Keychain|Credential Manager|Secret Service|수신 전 승인|허용 사용자" README.md README.ko.md PROJECT.md AGENTS.md .tasks/plan.md .tasks/task*.md` 결과를 검토한다.
- [x] 위 키워드가 나오더라도 현재 기본 경로가 아니라 향후 확장 후보로 표현되어 있는지 확인한다.
- [x] `.tasks/task001.md`부터 `.tasks/task011.md`까지 파일이 존재하는지 확인한다.
- [x] 각 task 파일에 `기능 범위`, `테스트 체크리스트`, `수동 검증 체크리스트`, `완료 기준`, `회귀 금지 조건`이 있는지 확인한다.

## 수동 검증 체크리스트

- [x] 새 개발자가 README와 `.tasks/plan.md`만 읽어도 현재 1차 목표가 "연결 안정화와 전송 경로 일치성"임을 이해할 수 있다.
- [x] 새 개발자가 AGENTS.md만 읽어도 hardcoded VM IP 방식이 금지임을 이해할 수 있다.
- [x] 새 개발자가 task002 이후 문서를 읽으면 테스트를 먼저 작성해야 함을 이해할 수 있다.

## 완료 기준

- [x] 문서들이 현재 제품 정책과 충돌하지 않는다.
- [x] 루트 `.tasks`의 plan과 task 파일이 다음 작업 순서를 명확히 제시한다.
- [x] 이후 구현 태스크에 공통 완료 기준을 복사해 사용할 수 있다.

## 회귀 금지 조건

- 가입, 로컬 계정 생성, password hash/verifier 영속 저장을 현재 기본 경로로 되돌리지 않는다.
- Keychain/Credential Manager/Secret Service를 현재 credential 저장소로 추가하지 않는다.
- 문서 태스크 완료를 이유로 런타임 테스트가 필요한 코드 변경을 테스트 없이 포함하지 않는다.
