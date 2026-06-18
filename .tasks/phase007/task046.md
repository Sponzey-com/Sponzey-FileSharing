# Task 046. Transfer Job Terminal Status Command

## Goal

`TransferController` 안에 남아 있는 전송 작업 실패/거절 상태 전이 규칙을 application 계층의 순수 명령 객체로 분리한다. 컨트롤러는 상태 저장과 UI 에러 반영만 담당하고, `TransferJob`을 어떤 terminal 상태로 바꿀지는 테스트 가능한 명령 객체가 결정한다.

## Scope

- [x] `TransferJob`의 rejected/failed 상태 전이를 순수 명령 객체로 분리한다.
- [x] 상태 변경 시각은 명령 객체 내부에서 조회하지 않고 호출자가 명시적으로 전달한다.
- [x] 컨트롤러의 `_markRejected`, `_markFailed`는 상태 저장 orchestration만 수행한다.

## Functional Requirements

- [x] rejected 전이는 기존 job의 식별자, peer, 파일, 진행률, 경로 정보를 보존한다.
- [x] rejected 전이는 `status`를 `TransferJobStatus.rejected`로 변경한다.
- [x] rejected 전이는 `updatedAt`과 `message`만 호출 입력값으로 갱신한다.
- [x] failed 전이는 기존 job의 식별자, peer, 파일, 진행률, 경로 정보를 보존한다.
- [x] failed 전이는 `status`를 `TransferJobStatus.failed`로 변경한다.
- [x] failed 전이는 `updatedAt`과 `message`만 호출 입력값으로 갱신한다.

## Architecture Requirements

- [x] 명령 객체는 `lib/application/transfer`에 둔다.
- [x] 명령 객체는 Flutter, Riverpod, 파일 시스템, 네트워크, 타이머에 의존하지 않는다.
- [x] 명령 객체는 외부 환경 값이나 전역 시간을 조회하지 않는다.
- [x] 컨트롤러는 명령 결과를 `_updateJob`에 넘기는 adapter 역할만 수행한다.

## TDD Requirements

- [x] rejected 전이가 terminal 상태와 메시지를 정확히 만드는 테스트를 먼저 작성한다.
- [x] failed 전이가 terminal 상태와 메시지를 정확히 만드는 테스트를 작성한다.
- [x] 컨트롤러가 직접 `TransferJobStatus.rejected`/`failed` copyWith 규칙을 들고 있지 않고 명령 객체를 사용하는 구조 테스트를 작성한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_job_terminal_status_command_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] `TransferJobTerminalStatusCommand`가 추가되어 있다.
- [x] `_markRejected`와 `_markFailed`가 명령 객체에 위임한다.
- [x] 변경 범위 테스트와 정적 분석이 통과한다.
