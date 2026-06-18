# Task 006 - Data Port 전용 transport와 interface bind

## 목표

파일 chunk 전송을 Control/Auth transport에서 분리하고, 선택된 route candidate의 local interface endpoint와 Data Port range를 사용하는 Data Port 전용 transport를 구현한다.

이 태스크는 phase002에서 남은 핵심 후속인 “실제 Data Port transport 분리”를 멀티 인터페이스 기준으로 해결한다.

## 연관 문서

- [plan.md - Data Port 전송 설계](plan.md#10-data-port-전송-설계)
- [phase002 task008](../phase002/task008.md)
- [task004.md](task004.md)
- [task005.md](task005.md)

## 선행 조건

- [task004.md](task004.md)의 selected path가 있어야 한다.
- [task005.md](task005.md)의 Control path local bind가 있어야 한다.
- phase002의 DataPacket codec과 transfer controller 신뢰성 로직이 있어야 한다.

## 포함 기능

### 기능 1. DataTransport interface와 Raw UDP 구현

- `DataTransport` interface를 만든다.
- `DataDatagram` 모델을 만든다.
- `RawUdpDataTransport`를 만든다.
- Data packet codec을 사용한다.

### 기능 2. Data Port range bind

- selected path의 local interface address에 Data Port를 bind한다.
- `AppConfig.dataPortRange` 안에서만 port를 사용한다.
- bind 실패 시 같은 interface의 다음 port를 시도한다.
- range exhausted 시 명확한 failure를 반환한다.
- OS 임의 ephemeral port fallback은 기본 금지한다.

### 기능 3. TransferController 연결

- TransferInit/Accept 이후 chunk 송수신은 DataTransport를 사용한다.
- Control은 offer/accept/complete/cancel 같은 절차 메시지만 담당한다.
- DataStart/DataChunk/DataAck/DataNack/DataFinish 흐름을 DataTransport에 연결한다.

## 구현 체크리스트

- [x] `DataTransport` interface를 정의했다.
- [x] `DataDatagram` 모델을 정의했다.
- [x] `RawUdpDataTransport` 구현을 추가했다.
- [x] DataTransport provider를 추가했다.
- [x] DataPort bind request가 `UdpInterfaceEndpoint`를 받는다.
- [x] dataPortRange 안에서 bind한다.
- [x] 같은 interface에서 다음 data port retry를 구현했다.
- [x] range exhausted failure를 구현했다.
- [x] OS 임의 port fallback을 하지 않도록 했다.
- [ ] TransferController outgoing chunk send가 DataTransport를 사용한다.
- [ ] TransferController incoming chunk receive가 DataTransport를 사용한다.
- [ ] TransferOffer/Accept는 Control path에 남긴다.
- [ ] DataStart/DataChunk/DataAck/DataNack/DataFinish는 Data path에 배치한다.
- [ ] Data path bind 결과를 TransferJob/MessageBus에 반영한다.
- [ ] AEAD metadata 확장을 방해하지 않는 DataPacket 구조를 유지한다.

## 테스트

- [x] DataTransport bind가 range 첫 port를 사용하는 테스트를 작성했다.
- [x] 첫 port bind 실패 시 다음 port를 사용하는 테스트를 작성했다.
- [x] range exhausted 시 failure를 반환하는 테스트를 작성했다.
- [ ] selected local endpoint가 DataTransport에 전달되는 테스트를 작성했다.
- [ ] 단일 파일 전송이 DataTransport fake network로 완료되는 테스트를 작성했다.
- [ ] Control transport에는 chunk packet이 흐르지 않는 테스트를 작성했다.
- [ ] DataTransport에는 auth token/password/session key가 흐르지 않는 테스트를 작성했다.
- [ ] DataStart 전에는 chunk를 보내지 않는 테스트를 작성했다.
- [ ] DataAck/DataNack가 selected data path를 유지하는 테스트를 작성했다.
- [x] 기존 transfer reliability 테스트가 통과한다.

## 검증

- [x] `flutter analyze`가 통과한다.
- [x] 관련 단위/Application 테스트가 통과한다.
- [ ] Control/Auth packet과 Data packet 경로가 분리되어 있다.
- [ ] Data Port range 밖 port를 사용하지 않는다.
- [ ] 전송 성공/실패/진행률 event가 기존 UI projection과 호환된다.

## 완료 기준

- 실제 파일 chunk가 Data Port 전용 transport를 통해 전송된다.
- DataTransport가 선택된 local interface endpoint를 사용한다.
- Control/Data path 분리가 테스트로 고정된다.

## 메모

- 이 태스크는 변경 범위가 크므로 Tidy First 원칙에 따라 adapter와 작은 이행 단계를 둔다.
- 기존 AuthTransport 기반 전송 테스트는 fake DataTransport 기반으로 점진적으로 이전한다.
