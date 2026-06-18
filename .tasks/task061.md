# Task 061. Hide Legacy Route Snapshot From TCP Transfer Queue

## Goal

TCP Data Channel 전송에서는 legacy UDP route lease가 더 이상 전송 상태의 source of truth가 아니므로 transfer queue 기본 UI에서 `Route:` 줄을 표시하지 않는다.

## Scope

- [x] TCP transfer job에 `routeSnapshot`이 있어도 transfer queue 기본 UI에서는 숨긴다.
- [x] legacy UDP transfer job은 기존처럼 route snapshot을 표시할 수 있게 유지한다.
- [x] TCP route/session 세부 정보는 사용자 기본 UI가 아니라 diagnostics export와 debug view에서 확인하도록 경계를 고정한다.

## Functional Requirements

- [x] TCP job 화면에는 `Route:` 텍스트가 나타나지 않는다.
- [x] UDP/legacy job 화면에는 route snapshot이 있으면 `Route:` 텍스트가 나타난다.
- [x] TCP job의 파일명, 속도, 진행률, 상태 badge는 기존처럼 표시된다.

## Architecture Requirements

- [x] 표시 정책은 presentation helper 수준에서만 처리하고 domain model을 변경하지 않는다.
- [x] TCP session 상세는 diagnostics export에서 담당하며 transfer queue가 route lease를 source of truth처럼 보이게 하지 않는다.

## TDD Requirements

- [x] TCP job route snapshot 숨김 widget test를 먼저 추가하고 실패를 확인한다.
- [x] UDP/legacy job route snapshot 유지 widget test를 먼저 추가하고 실패를 확인한다.
- [x] 최소 UI 조건 변경 후 관련 테스트를 통과시킨다.

## Validation

- [x] `flutter test test/presentation/transfers/transfers_screen_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check`

## Done Criteria

- [x] TCP transfer queue에서 legacy `Route:` 줄이 보이지 않는다.
- [x] legacy UDP transfer queue의 route diagnostics 표시가 회귀하지 않는다.
