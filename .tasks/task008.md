# Task 008. Task Tracking Markdown 추적성 복구

## 1. Task Purpose

- [x] 이 태스크의 목적은 `.tasks` 아래 계획/태스크 markdown 문서가 git에서 추적 가능하도록 ignore 규칙을 정리하는 것이다.
- [x] 이 태스크는 작업 루프의 산출물과 개발 계획이 커밋 가능한 상태로 남도록 보장한다.
- [x] 이 태스크 완료 후 `.tasks/task001.md` 이후 새 태스크 문서가 `git status`에서 ignored가 아니라 untracked로 표시되어야 한다.

## 2. Current Context

- [x] 현재 `.gitignore`에는 `.tasks/` 전체 ignore 규칙이 있다.
- [x] `.tasks/plan.md`는 이미 추적 중이어서 수정 상태로 보이지만 새 task 파일은 ignored 상태다.
- [x] 사용자 요청은 `.tasks/taskXXX.md` 형태의 태스크 파일을 생성하고 루프 방식으로 진행하는 것이다.

## 3. Scope

### Included

- [x] `.tasks` 전체 ignore를 markdown 문서 추적 가능 규칙으로 변경한다.
- [x] `.tasks` 아래 non-markdown 산출물은 계속 ignore한다.
- [x] `git check-ignore`와 `git status --short --ignored`로 검증한다.

### Excluded

- [x] 기존 phase 문서 내용 변경은 이번 태스크에서 다루지 않는다.
- [x] release artifact 또는 임시 로그 추적은 이번 태스크에서 다루지 않는다.
- [x] 코드 동작 변경은 이번 태스크에서 다루지 않는다.

## 4. Functional Units

### Functional Unit 1

- [x] 구현할 기능은 `.tasks` markdown allowlist다.
- [x] 입력은 `.gitignore`의 `.tasks/` 규칙이다.
- [x] 출력은 `.tasks/*.md`와 `.tasks/phase*/*.md`가 추적 가능한 ignore 규칙이다.
- [x] 성공 조건은 새 root task markdown이 ignored가 아닌 untracked로 보이는 것이다.

### Functional Unit 2

- [x] 구현할 기능은 non-markdown task artifact ignore 유지다.
- [x] 입력은 `.tasks/release_runs` 같은 비문서 산출물이다.
- [x] 출력은 markdown 외 산출물이 계속 ignored 상태인 것이다.
- [x] 성공 조건은 `.tasks/release_runs`가 자동으로 추적 대상으로 풀리지 않는 것이다.

### Functional Unit 3

- [x] 구현할 기능은 검증 기록이다.
- [x] 입력은 `git check-ignore`와 `git status` 결과다.
- [x] 출력은 Completion Report의 검증 결과다.
- [x] 성공 조건은 task markdown 파일이 ignored에서 벗어난 것이 명확히 기록되는 것이다.

## 5. Architecture Notes

- [x] 런타임 코드 계층은 변경하지 않는다.
- [x] 문서 추적성 변경만 수행한다.
- [x] AGENTS.md의 Task Tracking 기준과 일치해야 한다.

## 6. Configuration Rules

- [x] 앱 런타임 설정을 변경하지 않는다.
- [x] 외부 설정 파일을 추가하지 않는다.
- [x] `.gitignore` 변경은 저장소 추적 정책 변경이며 프로세스 런타임 설정 변경이 아니다.

## 7. Logging Requirements

### Product Log

- [x] 해당 없음.

### Field Debug Log

- [x] 해당 없음.

### Development Log

- [x] 해당 없음.

## 8. State Machine Requirements

- [x] 해당 없음.

## 9. TDD Plan

- [x] 런타임 동작 변경이 아니므로 단위 테스트는 추가하지 않는다.
- [x] 대신 `git check-ignore`와 `git status --ignored`를 검증 명령으로 사용한다.

## 10. Implementation Checklist

- [x] `.tasks/task008.md`를 생성한다.
- [x] `.gitignore`의 `.tasks/` 규칙을 좁힌다.
- [x] task markdown 파일이 ignored가 아닌지 확인한다.
- [x] non-markdown task artifact가 계속 ignored인지 확인한다.
- [x] 완료 보고를 업데이트한다.

## 11. Validation Checklist

- [x] `.tasks/task001.md`가 ignored가 아니다.
- [x] `.tasks/task008.md`가 ignored가 아니다.
- [x] `.tasks/release_runs`는 ignored 상태를 유지한다.
- [x] 런타임 코드 변경이 없다.

## 12. Completion Report

- [x] 수행한 변경 사항을 요약한다.
  - `.gitignore`의 `.tasks/` 전체 ignore를 markdown allowlist 방식으로 좁혔다.
  - `.tasks/*.md`와 `.tasks/phase*/*.md`는 추적 가능하게 했다.
  - `.tasks/release_runs/` 같은 non-markdown 산출물은 계속 ignored로 유지했다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 생성: `.tasks/task008.md`
  - 수정: `.tasks/task007.md`
  - 수정: `.gitignore`
- [x] 실행한 검증 명령과 결과를 기록한다.
  - `git check-ignore -v .tasks/task001.md .tasks/task008.md .tasks/release_runs || true`: task markdown은 allowlist 규칙, release_runs는 ignore 규칙 확인
  - `git status --short --ignored .tasks/task001.md .tasks/task008.md .tasks/release_runs`: task markdown은 `??`, release_runs는 `!!`
  - `git status --short .tasks/task001.md .tasks/task008.md .gitignore`: `.gitignore` 수정과 task markdown untracked 확인
- [x] 검증한 항목을 기록한다.
  - `.tasks/task001.md`와 `.tasks/task008.md`가 ignored에서 벗어났다.
  - `.tasks/release_runs/`는 ignored 상태를 유지한다.
- [x] 남은 위험 요소를 기록한다.
  - `.tasks` 아래 markdown이 다수 untracked로 표시될 수 있으므로 커밋 전 포함 범위를 확인해야 한다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - 다음 태스크는 현재 구현 상태 전체 검증과 남은 계획 항목 정리로 이어간다.

## 13. Next Task Decision Hook

- [x] `plan.md`의 최종 목표에 도달했는지 확인한다.
  - 아직 도달하지 못했다. 전체 회귀 검증과 release gate 정리가 남아 있다.
- [x] 도달했다면 추가 태스크를 생성하지 않는다.
  - 해당 없음.
- [x] 도달하지 못했다면 남은 목표를 정리한다.
  - 지금까지 적용한 route identity, active route lease, transfer route snapshot, diagnostics 변경이 전체 테스트 묶음에서 깨지지 않는지 확인해야 한다.
- [x] 남은 목표 중 가장 우선순위가 높은 작업을 선택한다.
  - 다음 우선순위는 현재 변경 세트 전체 회귀 검증과 추적성 gate다.
- [x] 다음 태스크가 기능 2~3개 단위를 넘지 않도록 범위를 제한한다.
- [x] 다음 태스크가 테스트와 검증을 포함하도록 정의한다.
- [x] 다음 태스크가 `AGENTS.md` 원칙과 충돌하지 않는지 확인한다.
- [x] 다음 태스크 파일명을 결정한다.
  - 다음 파일명은 `.tasks/task009.md`다.
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
