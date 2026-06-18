# Task 005 - 단일 파일 전송 MVP와 수신 파이프라인

## 목표

인증된 두 노드 사이에서 단일 파일 하나를 전송하고, 수신 측에서 임시 저장 후 완료 처리까지 할 수 있게 만든다.

## 연관 문서

- [README.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/README.md)
- [plan.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/plan.md)

## 선행 조건

- [task003.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/tasks/task003.md)
- [task004.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/tasks/task004.md)

## 포함 기능

### 기능 1. 전송 초기화와 파일 메타데이터 교환

- `TRANSFER_INIT`, `TRANSFER_INIT_ACK`, `TRANSFER_COMPLETE`, `TRANSFER_COMPLETE_ACK` 패킷 구현
- 파일명, 파일 크기, SHA-256, chunk 수, 저장 정책 협상
- 송신/수신 세션에 `transfer_id` 부여

### 기능 2. 기본 chunk 송수신

- 파일을 고정 크기 chunk로 분할해 송신
- 수신 측에서 임시 파일 또는 임시 버퍼에 순차 저장
- 초기 버전은 단일 대상, 단일 파일, 순차 전송 중심으로 구현

### 기능 3. 수신 완료 처리와 무결성 검증

- 수신 완료 후 SHA-256 검증
- 성공 시 최종 저장 경로로 이동
- 실패 시 임시 파일 정리와 전송 실패 상태 기록

## 구현 체크리스트

- [x] 파일 선택과 대상 선택 후 전송 요청을 생성할 수 있다.
- [x] `TRANSFER_INIT`에서 메타데이터와 저장 정책이 교환된다.
- [x] 송신 측이 파일을 chunk로 분할해 순차 전송한다.
- [x] 수신 측이 임시 경로에 쓰고 완료 시 해시 검증을 수행한다.
- [x] 성공/실패 상태가 UI에 반영된다.
- [x] 전송 완료 후 수신 파일 경로를 확인할 수 있다.

## 산출물

- 단일 파일 전송 UseCase
- 파일 선택 및 전송 시작 UI
- 수신 조립기 초안
- 무결성 검증 로직

## 테스트

- [x] 파일 chunk 분할/조립 단위 테스트 작성
- [x] 파일 해시 검증 단위 테스트 작성
- [x] 송신-수신 단일 파일 통합 테스트 작성
- [x] 손상된 chunk 또는 잘못된 해시 입력에 대한 실패 테스트 작성

## 검증

- [x] 작은 텍스트 파일 전송이 성공하는지 확인한다.
- [ ] 100MB 이상 파일 전송 후 해시가 일치하는지 확인한다.
- [ ] 수신 중 저장 경로 권한 오류가 날 때 실패 처리와 메시지를 확인한다.
- [ ] 실패 후 임시 파일이 남지 않거나 복구 가능한 상태인지 확인한다.

## 완료 기준

- 인증된 두 노드 사이에서 단일 파일 전송이 성공한다.
- 완료/실패 결과를 UI에서 확인할 수 있다.

## 메모

- 이 태스크는 MVP다. 손실 복구와 성능 최적화는 다음 태스크에서 강화한다.