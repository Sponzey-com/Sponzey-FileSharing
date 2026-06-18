# task004 - Transfer Auth Context, Key Lifecycle, Streaming Digest 계약

## 목적

Data Channel은 인증된 peer의 transfer session에서만 열려야 한다. 동시에 대용량 파일 전송 시작 전에 전체 파일을 hash 선계산하느라 지연되어서는 안 된다. 이 태스크는 transfer-scoped auth context와 streaming digest 계약을 정의한다.

## 진행 현황

- [x] `TransferDataAuthContext`를 transfer/session/path/nonce 기반으로 파생하고 lifecycle 폐기 테스트를 추가했다.
- [x] `DataFrameCodec`은 HMAC 기반 truncated auth tag encode/decode 계약을 지원한다.
- [x] sender/receiver가 streaming digest를 누적하고 `DATA_FINISH` digest로 최종 검증하도록 연결했다.
- [x] `TRANSFER_INIT`에서 필수 sha256 선계산을 제거하고 metadata 준비 경로를 분리했다.
- [x] 관련 검증: `flutter test test/application/transfer test/infrastructure/transfer`, `flutter analyze`

## 기능 범위

### 1. Transfer-scoped auth context

- [x] Control/Auth 성공 결과를 기반으로 `TransferDataAuthContext` 또는 동등 값을 생성한다.
- [x] context는 transferId, local node id, remote node id, selected path id, transfer nonce를 포함해 transfer마다 다르게 파생한다.
- [x] password 원문, JWT 문자열, long-lived token을 Data frame에 직접 넣지 않는다.
- [x] discovery group tag는 Data frame authentication에 재사용하지 않는다.
- [x] context는 메모리에만 존재하고 완료, 실패, 취소, timeout, peer offline 시 폐기된다.

### 2. Frame integrity tag 계약

- [x] `DataFrameCodec`이 auth tag 필드를 sign/verify할 수 있는 최소 인터페이스를 받는다.
- [x] HMAC-SHA256 truncated tag 또는 동등한 integrity tag 정책을 선택한다.
- [x] tag mismatch frame은 완료 처리되지 않는다.
- [x] tag failure는 drop, NACK, failed 중 명시 정책으로 처리된다.
- [x] key material은 product/debug log와 diagnostics에 남지 않는다.

### 3. Streaming digest 계약

- [x] sender는 파일을 읽으면서 digest를 누적 계산하고 `DATA_FINISH`에 최종 digest를 포함한다.
- [x] receiver는 writer append와 동시에 digest를 누적 계산한다.
- [x] receiver는 `DATA_FINISH` digest와 local digest가 일치할 때만 finalize한다.
- [x] `TRANSFER_INIT`은 필수 sha256 선계산을 요구하지 않는다.
- [x] 빠른 중복 감지용 optional fingerprint는 무결성 필수값으로 취급하지 않는다.

## 구현 지침

- auth context lifecycle 소유권은 application 계층에 둔다.
- infrastructure codec에는 sign/verify에 필요한 최소 인터페이스만 전달한다.
- key derivation 구현은 테스트 가능해야 하며, 전역 singleton 또는 런타임 외부 설정 reload에 의존하지 않는다.
- digest 구현은 file path 전체를 로그에 남기지 않는다.
- payload encryption은 1차 범위가 아니지만 integrity boundary는 제거하지 않는다.

## 예상 변경 위치

- [x] `lib/application/auth/` 또는 `lib/application/transfer/`
- [x] `lib/domain/transfer/`
- [x] `lib/infrastructure/transfer/`
- [x] `test/application/transfer/`
- [x] `test/infrastructure/transfer/`

## 테스트

- [x] 같은 peer라도 transferId가 다르면 auth context가 다르다.
- [x] selected path id가 다르면 auth context가 다르다.
- [x] discovery group tag만으로 valid data auth tag를 만들 수 없다.
- [x] transfer 완료 후 late data frame은 기존 key로 검증되지 않는다.
- [x] key material이 product/debug log에 남지 않는다.
- [x] authTag mismatch frame은 completed state로 이어지지 않는다.
- [x] sender는 transfer 시작 전에 전체 파일을 hash 선계산하지 않는다.
- [x] receiver digest mismatch는 finalize 실패가 된다.
- [x] `DATA_FINISH` digest가 일치하면 temp file finalize가 가능하다.

## 검증 명령

- [x] `flutter test test/application/transfer`
- [x] `flutter test test/infrastructure/transfer`
- [x] `flutter analyze`

## 완료 기준

- [x] transfer-scoped auth context 생성과 폐기가 테스트로 고정되어 있다.
- [x] Data frame integrity tag 검증 계약이 존재한다.
- [x] 대용량 파일 선계산 hash 없이 streaming digest로 최종 검증하는 계약이 존재한다.
- [x] 보안 민감 값이 로그나 diagnostics에 노출되지 않는다.

## 리스크와 주의사항

- JWT나 password-derived reusable verifier를 Data frame에 넣지 않는다.
- 암호화 구현을 억지로 포함해 범위를 키우지 않는다.
- digest 계약 변경은 task007, task008, task009와 연결되므로 문서와 테스트명을 명확히 유지한다.