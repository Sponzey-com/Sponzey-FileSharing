# task003 - Binary DataFrame Codec, MTU Budget, Protocol Capability

## 목적

Control/Auth 채널의 JSON/base64 chunk 전송을 대체할 raw binary frame 계약을 만든다. 이 태스크는 Data Channel에서 사용할 frame 구조, encode/decode, MTU budget, protocol capability를 테스트로 고정한다.

## 진행 현황

- [x] `DataFrame`, `DataFrameType`, `DataFrameCodec` binary protocol을 추가했다.
- [x] raw payload, no JSON, no base64, big-endian field, malformed reject를 테스트로 고정했다.
- [x] safe UDP payload budget과 typed `udpDataBinaryV1` capability를 추가했다.
- [x] 관련 검증: `flutter test test/domain/transfer test/infrastructure/transfer_data`, `flutter analyze`

## 기능 범위

### 1. Binary DataFrame 모델과 codec

- [x] `DataFrame` 또는 `DataPacketCodecV2`를 기존 JSON `DataPacket`과 분리해 추가한다.
- [x] `DATA_START`, `DATA_CHUNK`, `DATA_ACK`, `DATA_NACK`, `DATA_FINISH`, `DATA_ABORT` frame type을 정의한다.
- [x] payload는 `Uint8List` raw bytes로 유지한다.
- [x] base64 encode/decode를 사용하지 않는다.
- [x] JSON encode/decode를 사용하지 않는다.
- [x] 모든 multi-byte numeric field는 big-endian으로 encode/decode한다.

### 2. MTU-safe packet budget 계산

- [x] magic, version, type, flags, header length, payload length, session hash, transfer id, sequence, chunk index, ack fields, auth tag를 포함한 header budget을 계산한다.
- [x] 기본 datagram 크기는 Ethernet MTU 1500 이하를 목표로 한다.
- [x] IPv4 UDP payload 1472 bytes 이하를 안전 기준으로 삼는다.
- [x] 초기 file payload size는 1200~1300 bytes 범위에서 계산되도록 한다.
- [x] `Message too long` 등 후속 send failure에서 payload downgrade가 가능하도록 size helper를 분리한다.

### 3. Protocol version과 capability 값 객체

- [x] binary data protocol version을 명시적 값 객체로 만든다.
- [x] `udpDataBinaryV1` 또는 동등 capability를 정의한다.
- [x] capability mismatch 시 legacy fallback 또는 reject 판단을 application에서 할 수 있게 한다.
- [x] 문자열 분기보다 typed capability set을 우선한다.

## 구현 지침

- codec 구현체는 infrastructure에 둘 수 있지만, frame field 의미와 protocol version 판단은 domain/application 테스트로 고정한다.
- malformed frame은 exception으로 앱을 죽이지 않고 decode failure로 반환한다.
- frame decode failure에는 reason code를 포함하되 payload 원문은 포함하지 않는다.
- `authTag` 필드는 task004에서 본격 검증하더라도 구조상 예약되어 있어야 한다.
- raw file payload 원문, full path, key material은 debug string에 포함하지 않는다.

## 예상 변경 위치

- [x] `lib/domain/transfer/`
- [x] `lib/infrastructure/transfer/`
- [x] `test/domain/transfer/`
- [x] `test/infrastructure/transfer/`

## 테스트

- [x] `DATA_CHUNK` frame encode/decode가 raw bytes를 그대로 보존한다.
- [x] payload에 base64 문자열 변환이 끼어들지 않는다.
- [x] JSON 문자열 frame이 binary decode 경로에서 valid frame이 되지 않는다.
- [x] header length와 payload length mismatch는 reject된다.
- [x] unknown frame type은 reject된다.
- [x] truncated frame은 reject되고 crash하지 않는다.
- [x] little-endian으로 잘못 encode된 fixture는 protocol test에서 실패한다.
- [x] encoded datagram이 기본 safe MTU budget을 넘지 않는다.
- [x] protocol capability set에 `udpDataBinaryV1`이 있을 때만 binary data negotiation이 가능하다.

## 검증 명령

- [x] `flutter test test/domain/transfer`
- [x] `flutter test test/infrastructure/transfer`
- [x] `flutter analyze`

## 완료 기준

- [x] Data Channel용 binary frame codec이 존재한다.
- [x] raw payload, no JSON, no base64 원칙이 테스트로 고정되어 있다.
- [x] MTU-safe payload size 계산이 테스트로 고정되어 있다.
- [x] protocol version과 capability 판단이 명시적 타입으로 표현된다.

## 리스크와 주의사항

- 큰 UDP datagram으로 속도를 해결하려 하지 않는다. fragmentation 회피가 우선이다.
- 이 태스크에서 socket transport를 완성하지 않는다.
- `DataPacket` 기존 JSON 구조를 즉시 삭제하지 않는다. migration 동안 fallback 또는 테스트 자산으로 남긴다.
