# task030 - TCP Incoming Stream Frame Event Coordinator

## Goal

TCP listener에서 수신한 stream frame과 frame error를 incoming transfer pipeline으로 전달하는 coordinator를 추가한다. accepted/hello handshake coordinator와 파일 stream frame 처리 책임을 분리한다.

## Scope

- [x] stream frame 수신 이벤트를 `TcpIncomingStreamFramePipelineCommand`로 전달한다.
- [x] frame decode error는 runner나 writer session을 건드리지 않고 issue result로 반환한다.
- [x] data channel registry, incoming runner registry, frame context store는 생성자 인자로 명시 주입한다.
- [x] coordinator는 파일 시스템, socket, UI에 의존하지 않는다.

## Architecture Notes

- coordinator는 `lib/application/transfer`에 둔다.
- coordinator는 listener stream subscription 자체를 소유하지 않는다. subscription 생명주기는 이후 orchestration task에서 다룬다.
- coordinator는 MessageBus를 사용하지 않고, 이미 발생한 frame event를 pipeline에 동기적으로 위임한다.
- 상태 전이는 pipeline과 runner state machine 안에서만 발생한다.

## TDD Checklist

- [x] valid chunk frame을 pipeline으로 전달하고 runner effect가 실행되는 테스트를 작성한다.
- [x] frame error가 pipeline/runner를 건드리지 않고 issue code만 반환하는 테스트를 작성한다.
- [x] missing channel context는 pipeline issue를 그대로 반환하는 테스트를 작성한다.

## Implementation Checklist

- [x] `TcpIncomingStreamFrameEventCoordinator`와 result 타입을 추가한다.
- [x] `handleFrame`은 pipeline result를 coordinator result로 매핑한다.
- [x] `handleFrameError`는 `applied=false`, error issue code를 반환한다.
- [x] coordinator는 infrastructure import 없이 application/domain 타입만 사용한다.

## Validation

- [x] `flutter test test/application/transfer/tcp_incoming_stream_frame_event_coordinator_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task030.md lib/application/transfer/tcp_incoming_stream_frame_event_coordinator.dart test/application/transfer/tcp_incoming_stream_frame_event_coordinator_test.dart`

## Completion Report

- Status: completed
- Notes:
  - Added a stream frame event coordinator that delegates valid frames to the incoming pipeline.
  - Frame decode errors now return explicit coordinator results without touching runner or writer state.
  - The coordinator is application-only and depends on injected registries/stores.
