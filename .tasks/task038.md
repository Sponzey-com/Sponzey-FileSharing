# task038 - TCP Transfer Send Use Case for Controller Boundary

## Goal

기존 `TransferController.sendFile`이 UDP 내부 구현을 직접 수행하지 않고 TCP 데이터 채널 전송 경로를 호출할 수 있도록 controller-facing use case를 추가한다.

## Scope

- [x] controller가 전달할 수 있는 peer/auth/session/file 입력 모델을 정의한다.
- [x] connected TCP outbound channel이 있을 때 `TcpPeerFileSendCommand`를 호출한다.
- [x] 전송 성공 시 controller가 job update에 사용할 file metadata와 전송 metric을 반환한다.
- [x] 전송 실패 시 명시 issue code와 사용자 메시지를 반환한다.
- [x] use case는 UI, socket, file system concrete 구현에 직접 의존하지 않는다.

## Architecture Notes

- use case는 `lib/application/transfer`에 둔다.
- 파일 metadata 준비는 기존 `TransferFileService` port를 사용한다.
- TCP 송신은 `TcpPeerFileSendCommand` port 조립 결과를 사용한다.
- use case는 route lease, UDP control/data send, retry window를 다루지 않는다.
- controller 전환은 다음 task에서 수행한다.

## TDD Checklist

- [x] connected TCP channel이 있으면 파일 metadata를 준비하고 TCP peer send command를 호출하는 테스트를 작성한다.
- [x] TCP channel missing이면 실패 result를 반환하는 테스트를 작성한다.
- [x] metadata 준비 실패가 실패 result로 매핑되는 테스트를 작성한다.

## Implementation Checklist

- [x] `TcpTransferSendUseCaseInput`을 추가한다.
- [x] `TcpTransferSendUseCaseResult`를 추가한다.
- [x] `TcpTransferSendUseCase`를 추가한다.
- [x] use case provider를 TCP pipeline providers에 추가한다.

## Validation

- [x] `flutter test test/application/transfer/tcp_transfer_send_use_case_test.dart test/infrastructure/transfer/tcp_transfer_pipeline_providers_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task038.md lib/application/transfer/tcp_transfer_send_use_case.dart lib/infrastructure/transfer/tcp_transfer_pipeline_providers.dart test/application/transfer/tcp_transfer_send_use_case_test.dart test/infrastructure/transfer/tcp_transfer_pipeline_providers_test.dart`

## Completion Report

- Status: completed
- Notes:
  - Added a controller-facing TCP transfer send use case.
  - Added provider composition for the use case.
  - The use case returns file metadata and TCP send metrics without directly depending on UI, socket, or concrete filesystem code.
