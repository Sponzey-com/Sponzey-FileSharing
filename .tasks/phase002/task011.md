# Task 011 - 수신 정책, 이력, 로그/진단 고도화

## 목표

수신 승인 정책, 전송 이력, 로그/진단 이벤트를 실사용 가능한 수준으로 고도화한다. 보안과 운영성을 위해 민감 정보는 저장하거나 기록하지 않는다.

## 연관 문서

- [phase002 plan.md - 수신 정책 계획](plan.md#11-수신-정책-계획)
- [phase002 plan.md - 로그와 진단 계획](plan.md#12-로그와-진단-계획)
- [AGENTS.md - Logging Rules](../../AGENTS.md#logging-rules)

## 선행 조건

- [task008.md](task008.md)의 단일 파일 전송이 있어야 한다.
- [task010.md](task010.md)의 queue/job 모델이 있으면 이력 집계까지 반영한다.

## 포함 기능

### 기능 1. ReceivePolicy 상태 머신

- `autoAcceptAll`, `askEveryTime`, `autoAcceptAllowedPeers`, `rejectUnknownPeers` 정책을 구현한다.
- 인증 세션, allowed peer, file metadata, 저장 경로, 파일명 충돌을 순서대로 판단한다.
- accept, waitForApproval, reject 상태를 명확히 표현한다.

### 기능 2. Transfer history 저장

- 완료, 실패, 취소 전송 이력을 저장한다.
- peer, direction, 파일명, 크기, reason code, 시간, retry count를 기록한다.
- raw token, session key, 파일 원문, 민감 경로는 저장하지 않는다.

### 기능 3. 로그와 진단 event 연결

- Product, Debug, Development 목적 기준으로 로그를 분리한다.
- MessageBus diagnostics event를 logger/history/projection이 관찰한다.
- 민감 정보 로깅 금지 기준을 테스트와 리뷰 체크리스트에 반영한다.

## 구현 체크리스트

- [x] ReceivePolicy 상태와 이벤트를 정의했다.
- [x] allowed peer 기반 자동 승인 정책을 구현했다.
- [x] ask every time 승인 대기 흐름을 구현했다.
- [x] unknown peer reject 정책을 구현했다.
- [x] 저장 경로 허용 범위 검증을 구현했다.
- [x] 파일명 충돌 정책을 구현했다.
- [x] 임시 파일과 최종 파일 경로 정책을 정리했다.
- [ ] transfer history 저장 모델을 구현했다.
- [x] 실패 reason code를 표준화했다.
- [x] MessageBus diagnostics event를 logger와 연결했다.
- [x] Product/Debug/Development 로그 목적을 코드에 반영했다.
- [x] 민감 정보 로깅 금지 기준을 확인했다.

## 테스트

- [x] unknown peer reject 테스트를 작성했다.
- [x] allowed peer auto accept 테스트를 작성했다.
- [x] ask every time user accept/reject 테스트를 작성했다.
- [x] 저장 경로 허용 범위 밖 쓰기 거부 테스트를 작성했다.
- [x] 파일명 충돌 정책 테스트를 작성했다.
- [ ] transfer history persistence 테스트를 작성했다.
- [x] 실패 reason code 저장 테스트를 작성했다.
- [x] Product log 최소화 테스트 또는 검증을 작성했다.
- [x] password/raw token/session key/file payload가 로그에 없는지 테스트 또는 snapshot 검증을 작성했다.

## 검증

- [x] 사용자는 수신 정책을 설정하고 결과를 예측할 수 있다.
- [ ] 전송 완료/실패/취소 이력을 나중에 확인할 수 있다.
- [x] Debug 로그는 현장 문제 분석에 필요한 정보를 포함한다.
- [x] Development 로그는 상태 머신 전이와 packet codec 문제를 추적할 수 있다.
- [x] 민감 정보가 DB와 로그에 남지 않는다.

## 진행 결과

- `lib/domain/receive_policy/receive_policy_state_machine.dart`
- `lib/domain/entities/app_settings.dart`
- `lib/infrastructure/repositories/settings_repository.dart`
- `lib/infrastructure/repositories/allowed_peer_repository.dart`
- `test/domain/receive_policy/receive_policy_state_machine_test.dart`
- `test/application/settings/settings_controller_test.dart`

## 남은 비수동 후속

- 영구 전송 이력 테이블과 persistence 테스트는 아직 별도 구현이 필요하다.

## 완료 기준

- 수신 정책이 상태 머신으로 관리된다.
- 전송 이력과 로그/진단 체계가 운영 목적별로 분리된다.
- 보안 정보 노출 없이 문제 분석이 가능하다.
