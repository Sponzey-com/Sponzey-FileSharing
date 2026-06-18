# task008 - Transfer UX, retry/cancel, persisted history

## 상태

- [x] 진행 전
- [x] 진행 중
- [x] 구현 완료
- [x] 테스트 완료
- [ ] 수동 검증 완료
- [ ] 완료

## 진행 메모

- `transfer_jobs`, `transfer_files` Drift persistent schema를 추가하고 schemaVersion 4 migration을 구성했다.
- application 계층에 `TransferHistoryRepository` 계약을 추가하고, Drift 구현체에서 완료/실패/취소 terminal job과 file item을 upsert하도록 했다.
- `TransferFailurePolicy`를 추가해 네트워크, 인증, 저장소, 상대 준비 실패, route, 검증, 취소 실패를 사용자 메시지와 diagnostic code로 분리했다.
- `TransferJobStatus.cancelled`와 `TransferJobStateMachine`을 추가해 cancel action이 명시적인 상태 전이를 통과하도록 했다.
- `TransferController`가 terminal job을 자동으로 history repository에 저장하고, cancel 시 reader/writer, 임시 파일, frame key를 정리하도록 했다.
- History 화면은 DB 이력과 현재 메모리 terminal job을 병합해 표시하고, Transfers 화면은 retry 가능 여부, 취소, 파일 열기, 폴더 열기 액션을 제공한다.
- Transfers 좌측 New Transfer 카드를 내부 스크롤로 전환해 좁은 높이에서 overflow가 나지 않게 했고, 여러 파일 드롭 시 `sendFiles`로 순차 전송되도록 했다.
- macOS/Windows/Linux 실제 파일 열기와 폴더 열기 수동 검증은 아직 수행하지 않았다.

## 목적

송신과 수신의 상태 표현을 같은 정책으로 통일하고, 전송 이력과 실패 원인을 재시작 후에도 확인할 수 있게 한다. 사용자는 실패가 네트워크, 인증, 저장 경로, 상대 준비 실패 중 어디에서 났는지 구분할 수 있어야 한다.

## 기능 범위

1. persisted transfer history schema와 repository
2. sender/receiver 상태 용어와 사용자 메시지 통일
3. retry/cancel/open folder UX 정리

## 선행 조건

- [x] task006 storage lifecycle 기준 확인
- [x] task007 transfer correctness 기준 확인
- [x] 현재 Drift schema, history screen, transfer queue UI를 읽는다.

## 제외 범위

- 수신 전 승인 workflow는 현재 범위가 아니다.
- 조직/그룹 관리 UI는 현재 범위가 아니다.
- 대규모 batch 최적화는 현재 범위가 아니다.

## 계층별 변경 위치

- domain/application: transfer status vocabulary, retryability, history entity
- infrastructure: Drift migration, transfer history repository
- presentation: transfer queue, history screen, retry/cancel/open folder actions
- test: DB repository test, application test, widget test

## 실패 테스트 또는 수동 재현 기준

- [x] 앱 재시작 후 완료/실패 이력이 사라지는 실패 테스트를 작성한다.
- [x] sender는 실패, receiver는 완료처럼 보이는 상태 용어 불일치 사례를 실패 기준으로 기록한다.
- [x] retry 불가능 오류에도 재시도 버튼이 표시되는 widget 실패 테스트를 작성한다.

## diagnostics/log 검토 기준

- [x] transfer history에 저장되는 값과 diagnostics export 값이 같은 transfer id로 연결되는지 확인한다.
- [x] 실패 메시지에는 사용자 문구와 개발자 진단 코드가 분리되어 있는지 확인한다.
- [ ] 전체 파일 경로는 UI에는 필요 시 표시하되 로그/export에는 redaction되는지 확인한다.

## 구현 체크리스트

- [x] transfer_jobs persistent schema를 정의한다.
- [x] transfer_files persistent schema를 정의한다.
- [x] 기존 DB migration 전략을 작성한다.
- [x] transfer history repository interface를 application에서 사용할 수 있게 한다.
- [x] 완료/실패/cancelled job을 저장한다.
- [x] sender/receiver status vocabulary를 하나로 통일한다.
- [x] retry 가능한 실패와 retry 불가능 실패를 구분한다.
- [x] cancel action은 state machine 전이를 통해 처리한다.
- [x] 완료 파일 열기와 저장 폴더 열기 action을 제공한다.
- [x] multi-file drop은 batch job과 file item 관계를 명확히 한다.
- [x] 1:N 전송은 대상별 session을 분리해 공유 상태 오염을 막는다.

## 테스트 체크리스트

- [x] 완료 transfer job 저장 테스트
- [x] 실패 transfer job 저장 테스트
- [x] 앱 재시작 후 최근 이력 표시 테스트
- [x] retry 가능한 실패와 불가능 실패 구분 테스트
- [x] sender/receiver 상태 용어 통일 테스트
- [x] cancel state transition 테스트
- [x] multi-file drop 시 batch와 file item 생성 테스트
- [x] 1:N 전송에서 대상별 session이 분리되는 테스트
- [x] history screen widget test

## 수동 검증 체크리스트

- [ ] 단일 파일 송신/수신 완료 이력이 표시된다.
- [ ] 실패 후 재시도 버튼이 올바르게 표시된다.
- [ ] retry 불가능 실패에서는 재시도 대신 원인 설명이 표시된다.
- [ ] 완료 후 저장 폴더 열기가 동작한다.
- [ ] 앱 재시작 후 이력이 유지된다.
- [ ] sender와 receiver UI가 같은 transfer id를 기준으로 대조 가능하다.

## 완료 기준

- [x] 전송 이력과 실패 원인이 재시작 후에도 확인된다.
- [x] 송신/수신 상태 정책이 동일하다.
- [x] 사용자는 실패 원인과 다음 조치를 UI에서 알 수 있다.

## 회귀 금지 조건

- 자동 수신 정책과 충돌하는 승인 대기 UI를 기본 흐름에 넣지 않는다.
- retry/cancel을 UI에서 직접 상태 변경하지 않고 application state machine으로 처리한다.
- transfer history에 비밀번호, JWT, session key를 저장하지 않는다.
