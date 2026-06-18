# task002 - Data Session 상태 머신과 Window/Retry 도메인 모델

## 목적

고속 UDP 전송은 boolean 조합으로 관리하면 손실, 중복, 재전송, timeout이 빠르게 꼬인다. 이 태스크는 Data Channel 송수신 절차를 도메인 상태 머신과 순수 값 객체로 고정해, 이후 인프라 구현이 상태 규칙을 임의로 흩뜨리지 못하게 한다.

## 진행 현황

- [x] `DataTransferSessionStateMachine`으로 송수신 전이, terminal 상태, forbidden transition을 고정했다.
- [x] `DataWindow`, `SelectiveAckBitmap`, `RetransmissionPlanner`, `ReceiverBufferBudget` 값을 추가했다.
- [x] socket 없이 도메인 테스트로 window, SACK, retry, buffer budget을 검증했다.
- [x] 관련 검증: `flutter test test/domain/transfer`, `flutter analyze`

## 기능 범위

### 1. Data transfer 상태 머신 정의

- [x] 송신 상태를 `idle`, `preparingFile`, `controlNegotiating`, `bindingDataPort`, `dataStarting`, `sending`, `draining`, `finishing`, `completed`, `failed`, `cancelled`로 모델링한다.
- [x] 수신 상태를 `idle`, `controlAccepted`, `bindingDataPort`, `waitingDataStart`, `receiving`, `verifying`, `finalizing`, `completed`, `failed`, `cancelled`로 모델링한다.
- [x] 상태 전이는 명시적 event 또는 command 함수로만 발생하게 한다.
- [x] 허용되지 않는 전이는 silent ignore가 아니라 no-op, warning decision, failure 중 하나로 표현한다.

### 2. Window, ACK, SACK 도메인 값 객체

- [x] `DataWindow`로 congestion window, advertised window, in-flight count를 표현한다.
- [x] `ChunkAckRange` 또는 동등 값 객체로 cumulative ack와 범위 ack를 표현한다.
- [x] `SelectiveAckBitmap`으로 out-of-order 수신 상태를 표현한다.
- [x] `RetransmissionPlan`으로 missing chunk와 retry priority를 계산한다.

### 3. Retry, timeout, buffer budget 정책

- [x] timeout count와 retry count가 상태 전이에 영향을 주는 규칙을 만든다.
- [x] receiver buffer budget이 낮으면 advertised window가 줄어드는 순수 규칙을 만든다.
- [x] repeated loss가 congestion signal로 반영되는 최소 규칙을 만든다.
- [x] 정책 값은 외부 설정 파일이 아니라 생성자 인자 또는 테스트 입력으로 주입 가능하게 한다.

## 구현 지침

- domain 계층은 Flutter, Riverpod, socket, file system, timer에 의존하지 않는다.
- 상태 이름은 UI 문구가 아니라 절차 상태를 기준으로 한다.
- timer 자체는 domain에 두지 않는다. domain은 `now`, `elapsed`, `timeout event` 같은 입력만 받는다.
- MessageBus publish는 이 태스크의 범위가 아니다. 상태 전이 결과로 발생할 domain/application event 후보만 정의한다.
- 불변 값 객체를 우선 사용한다.

## 예상 변경 위치

- [x] `lib/domain/transfer/`
- [x] `test/domain/transfer/`
- [x] 필요 시 `lib/application/transfer/`의 타입 import 조정

## 테스트

- [x] `DATA_START` 전 chunk 수신은 reject 또는 no-op decision으로 처리된다.
- [x] `waitingDataStart` 전 writer append effect가 발생하지 않는다.
- [x] `sending` 상태에서 ACK 수신 시 in-flight chunk가 줄고 window pump 필요 여부가 계산된다.
- [x] cumulative ack와 SACK bitmap이 완료 chunk를 정확히 계산한다.
- [x] duplicate chunk는 완료 상태를 망가뜨리지 않는다.
- [x] out-of-order chunk는 buffer budget 안에서 pending 상태가 된다.
- [x] missing gap은 `RetransmissionPlan`에 들어간다.
- [x] timeout 횟수 초과 시 `failed` 전이가 발생한다.
- [x] `failed` 이후 late ACK/NACK/chunk는 상태를 되살리지 않는다.
- [x] receiver buffer budget이 낮아지면 advertised window가 감소한다.

## 검증 명령

- [x] `flutter test test/domain/transfer`
- [x] `flutter analyze`

## 완료 기준

- [x] 송신과 수신 Data Channel 상태가 명시적 모델로 존재한다.
- [x] window, ACK, SACK, retry 판단이 socket 없이 테스트 가능하다.
- [x] forbidden transition이 테스트로 고정되어 있다.
- [x] 이후 sender/receiver pipeline은 이 상태 머신 규칙을 사용해야 한다.

## 리스크와 주의사항

- 이 태스크에서 실제 UDP 송수신을 구현하지 않는다.
- 너무 복잡한 congestion control을 먼저 만들지 않는다. 최소 동작 규칙과 테스트 가능성이 우선이다.
- domain에 platform-specific 타입을 넣지 않는다.
