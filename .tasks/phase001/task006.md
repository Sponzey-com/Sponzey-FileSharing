# Task 006 - UDP 신뢰성 보강, 재전송, 성능 측정

## 목표

UDP 기반 전송 위에 ACK/NACK, 재전송, sliding window, 진행률 계산을 얹어 손실 환경에서도 안정적으로 동작하게 만든다.

## 연관 문서

- [plan.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/plan.md)

## 선행 조건

- [task004.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/tasks/task004.md)
- [task005.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/tasks/task005.md)

## 포함 기능

### 기능 1. ACK/NACK와 Selective Repeat ARQ

- `CHUNK_ACK`, `CHUNK_NACK`, `WINDOW_UPDATE` 구현
- 누락 chunk만 재전송하는 selective repeat 방식 도입
- 중복 패킷과 out-of-order 패킷 처리

### 기능 2. Sliding window 및 timeout 동적 조정

- 송신 window 크기 제어
- RTT 측정 기반 timeout 계산
- 재전송 횟수 초과, 세션 실패, window 축소 정책 구현

### 기능 3. 전송 진행률/속도/오류 관측성

- 전송 속도, 진행률, 예상 남은 시간 계산
- 재전송 횟수와 손실률 표시
- 개발 로그와 디버그 메트릭 수집

## 구현 체크리스트

- [x] ACK/NACK 처리 상태 머신이 전송 엔진에 통합되어 있다.
- [x] out-of-order chunk가 올바르게 버퍼링 또는 폐기된다.
- [x] timeout이 고정값이 아니라 RTT 기반으로 조정된다.
- [x] window 크기 조정 정책이 구현되어 있다.
- [x] UI에 속도, 진행률, 재시도 횟수가 표시된다.
- [x] 손실이 많은 경우 전송 실패 사유가 기록된다.

## 산출물

- 신뢰성 보강 전송 엔진
- retry 정책 구현
- 전송 진행률 추적기
- 디버그 메트릭 로깅

## 테스트

- [x] ACK/NACK 상태 전이 단위 테스트 작성
- [x] out-of-order, duplicate, lost packet 시뮬레이션 테스트 작성
- [x] timeout 재계산 로직 단위 테스트 작성
- [x] 손실 환경에서 대용량 파일 전송 통합 테스트 작성

## 검증

- [x] 10% 패킷 손실 환경에서 전송이 완료되는지 확인한다.
- [x] 20% 손실 환경에서 재전송과 실패 정책이 기대대로 동작하는지 확인한다.
- [x] 진행률 표시가 실제 파일 크기 기준으로 자연스럽게 증가하는지 확인한다.
- [x] 과도한 로그 폭증 없이 진단에 필요한 정보만 남는지 확인한다.

## 완료 기준

- 손실과 순서 뒤바뀜이 있는 환경에서도 단일 파일 전송이 재현 가능하게 안정화된다.
- 성능 관련 UI와 진단 데이터가 확보된다.

## 메모

- 이 태스크 완료 후부터 실제 LAN 환경에서 의미 있는 성능 측정이 가능해진다.