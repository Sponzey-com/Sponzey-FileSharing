# task009 - Receiver Pipeline DataTransport 전환, Backpressure, Streaming Write/Digest

## 목적

수신 경로를 DataTransport binary frame 기반으로 구현한다. receiver는 `DATA_START` 이후에만 chunk를 받고, out-of-order/duplicate/loss를 처리하며, writer append와 동시에 digest를 계산해 안전하게 finalize한다.

## 진행 현황

- [x] receiver는 binary `DATA_CHUNK`를 수신해 contiguous append, out-of-order buffer, duplicate drop을 수행한다.
- [x] `IncomingDigestingTransferWriter`로 append와 동시에 streaming sha256을 계산한다.
- [x] `DATA_FINISH` digest match일 때만 finalize하고 mismatch는 실패 처리한다.
- [x] receiver window는 buffered chunk 수에 따라 축소되며 ACK/NACK에 반영된다.
- [x] 관련 검증: `flutter test test/application/transfer test/infrastructure/transfer`, `flutter analyze`

## 기능 범위

### 1. Receiver session pipeline

- [x] receiver는 `DATA_START` 후에만 `DATA_CHUNK`를 수신 처리한다.
- [x] receiver는 data session writer를 transfer session 동안 열어둔다.
- [x] contiguous chunk는 즉시 writer에 append한다.
- [x] duplicate chunk는 file에 중복 기록하지 않는다.
- [x] invalid transferId/sessionHash/authTag frame은 상태를 변경하지 않는다.

### 2. Out-of-order buffer와 backpressure

- [x] out-of-order chunk는 session buffer budget 안에서만 보관한다.
- [x] gap이 해소되면 buffered chunk를 순서대로 writer에 append한다.
- [x] session별 buffer budget과 process 전체 buffer budget을 모두 적용한다.
- [x] buffer pressure가 증가하면 advertised window를 줄인다.
- [x] buffer budget 초과 시 window 감소 또는 transfer failure 중 명시 정책으로 처리한다.

### 3. Streaming digest와 finalize

- [x] receiver는 writer append와 동시에 streaming digest를 계산한다.
- [x] 모든 chunk 수신 후 writer close를 수행한다.
- [x] `DATA_FINISH` digest와 receiver digest가 일치할 때만 temp file을 finalize한다.
- [x] digest mismatch는 completed가 아니라 failed가 된다.
- [x] 저장 위치는 기존 settings/default path 정책을 따른다.

## 구현 지침

- receiver 절차는 상태 머신 transition을 사용한다.
- writer는 chunk마다 open/flush/close하지 않는다.
- temp file finalize 전에는 원본 경로를 덮어쓰지 않는다.
- 수신 파일 전체 경로는 product log에 남기지 않는다.
- backpressure 상태는 ACK scheduler가 advertised window에 반영할 수 있게 application state로 전달한다.

## 예상 변경 위치

- [x] `lib/application/transfer/transfer_controller.dart`
- [x] `lib/application/transfer/data_receiver_session.dart`
- [x] `lib/domain/transfer/`
- [x] `lib/infrastructure/transfer/transfer_file_service.dart`
- [x] `test/application/transfer/`
- [x] `test/infrastructure/transfer/`

## 테스트

- [x] `DATA_START` 전 chunk 수신은 reject된다.
- [x] out-of-order chunk가 정상 파일로 재조립된다.
- [x] duplicate chunk는 file에 중복 기록되지 않는다.
- [x] invalid transferId/sessionHash frame은 무시된다.
- [x] authTag mismatch frame은 무시되거나 failure policy를 따른다.
- [x] buffer budget 초과 시 window가 줄거나 transfer가 실패한다.
- [x] 여러 transfer가 동시에 있어도 한 transfer가 전체 buffer를 독점하지 못한다.
- [x] finish 후 digest mismatch는 completed가 되지 않는다.
- [x] finish 후 digest match에서만 finalize가 수행된다.
- [x] product log에 full receive path가 남지 않는다.

## 검증 명령

- [x] `flutter test test/application/transfer`
- [x] `flutter test test/infrastructure/transfer`
- [x] `flutter analyze`

## 완료 기준

- [x] receiver pipeline은 DataTransport binary frame을 처리한다.
- [x] out-of-order, duplicate, invalid frame 처리가 테스트로 고정되어 있다.
- [x] backpressure가 advertised window에 반영될 수 있다.
- [x] streaming digest 검증 후에만 finalize한다.

## 리스크와 주의사항

- 큰 out-of-order buffer로 메모리를 무한 사용하지 않는다.
- writer flush를 chunk마다 호출하지 않는다.
- 수신 파일 정책을 임의 경로 쓰기로 바꾸지 않는다.