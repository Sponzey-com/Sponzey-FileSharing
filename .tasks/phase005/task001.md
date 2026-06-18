# task001 - 현재 Control Chunk 경로 고정과 Legacy 분리 기준

## 목적

현재 파일 전송은 Control/Auth 채널의 JSON/base64 `TRANSFER_CHUNK` 경로로 동작한다. 이 태스크는 현재 동작을 정확히 테스트로 고정하고, 이후 Data Channel 전환이 들어와도 기존 호환 경로와 신규 고속 경로가 섞이지 않도록 경계를 만든다.

## 진행 현황

- [x] 신규 기본 전송 경로에서 file chunk가 Control channel로 흐르지 않도록 테스트로 고정했다.
- [x] legacy Control chunk 관련 테스트는 Data channel 전환 후에도 별도 경계로 유지했다.
- [x] `TRANSFER_INIT`은 파일 chunk 없이 metadata, capability, Data endpoint 협상 정보만 전달하도록 정리했다.
- [x] 관련 검증: `flutter test test/application/transfer`, `flutter analyze`

## 기능 범위

### 1. 현재 Control chunk 경로 특성화

- [x] 송신 `TransferController`가 현재 `AuthPacketType.transferChunk`를 사용하는 경로를 테스트로 고정한다.
- [x] `TRANSFER_INIT`, `TRANSFER_INIT_ACK`, `TRANSFER_CHUNK`, `TRANSFER_CHUNK_ACK`, `TRANSFER_WINDOW_UPDATE`, `TRANSFER_COMPLETE_ACK` 순서를 fixture 또는 fake transport로 표현한다.
- [x] 현재 경로가 JSON/base64 payload를 사용하는 legacy behavior임을 테스트 이름에 명확히 남긴다.
- [x] 현재 동작을 “좋은 설계”로 승인하는 테스트가 아니라 “마이그레이션 전 기준점”으로 분리한다.

### 2. 신규 Data Channel 목표 실패 테스트 작성

- [x] 신규 전송 목표 테스트에서 file chunk가 `ControlTransport`로 흐르면 실패하도록 만든다.
- [x] 신규 목표 테스트에서 `DataTransport` 또는 후속 binary data transport가 chunk 전송 경로가 되어야 함을 표현한다.
- [x] `TRANSFER_INIT`은 metadata와 data capability만 전달해야 하며, file chunk를 포함하면 실패하도록 한다.
- [x] `TRANSFER_CHUNK` legacy path는 protocol mismatch 또는 명시 fallback 상황에서만 허용되도록 테스트 이름을 분리한다.

### 3. 로그와 이벤트 baseline 고정

- [x] per-packet product/info 로그가 발생하지 않아야 하는 기준을 현재 테스트에 반영한다.
- [x] per-packet MessageBus event를 만들지 않는 기준을 문서화하고 가능한 범위에서 테스트한다.
- [x] progress event는 aggregate 기준으로만 발생해야 한다는 기대를 application 테스트에 남긴다.

## 구현 지침

- 변경 전 `.tasks/plan.md`의 1장, 2장, 7.1을 다시 확인한다.
- 런타임 동작을 크게 바꾸지 말고, 먼저 현재 경로와 목표 경로를 테스트로 분리한다.
- 테스트명에는 `legacy`, `data_channel_target`, `control_chunk_not_allowed`처럼 목적이 드러나는 표현을 사용한다.
- 기존 테스트를 삭제하지 않는다. 의미가 바뀐 테스트는 legacy 영역으로 이동하거나 이름을 고친다.
- Product log 기준은 기존 `AppLogger`, `AppLogLevel`, `AppLogCategory`만 사용한다.

## 예상 변경 위치

- [x] `test/application/transfer/transfer_controller_test.dart`
- [x] `test/infrastructure/control/raw_udp_control_transport_test.dart`
- [x] `test/infrastructure/transfer/transfer_file_service_test.dart`
- [x] 필요 시 `lib/application/transfer/transfer_controller.dart`
- [x] 필요 시 `lib/infrastructure/control/control_transport.dart`

## 테스트

- [x] legacy Control chunk 전송 순서가 현재와 동일함을 검증한다.
- [x] 신규 Data Channel 목표 테스트에서 Control chunk 사용 시 실패한다.
- [x] `TRANSFER_INIT`에 file chunk payload가 들어가지 않는 목표 테스트를 작성한다.
- [x] per-packet product/info 로그가 발생하지 않음을 검증한다.
- [x] reader/writer 유지 개선이 깨지지 않았음을 기존 테스트로 확인한다.

## 검증 명령

- [x] `flutter test test/application/transfer/transfer_controller_test.dart`
- [x] `flutter test test/infrastructure/control/raw_udp_control_transport_test.dart`
- [x] `flutter test test/infrastructure/transfer/transfer_file_service_test.dart`
- [x] `flutter analyze`

## 완료 기준

- [x] 현재 Control chunk 경로가 legacy behavior로 명확히 고정되어 있다.
- [x] 신규 Data Channel 전환 목표가 실패 테스트 또는 명확한 테스트 기준으로 표현되어 있다.
- [x] 이후 태스크가 Control 경로와 Data 경로를 혼동하지 않는다.
- [x] 문서나 테스트 이름만 읽어도 “무엇을 유지하고 무엇을 제거할지” 알 수 있다.

## 리스크와 주의사항

- 현재 동작을 고정하는 테스트가 미래의 잘못된 구현을 보호하지 않도록 legacy naming을 명확히 해야 한다.
- 아직 Data Channel 구현을 시작하지 않는다. 이 태스크의 핵심은 기준점과 경계 설정이다.
- unrelated refactor는 하지 않는다.
