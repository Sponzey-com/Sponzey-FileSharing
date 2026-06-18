# Task 008 - 연결 UI, diagnostics, 실제 연결 검증

## 목표

연결 우선 목표의 사용자 확인 지점을 완성한다.

UI는 최소한의 연결 상태를 안정적으로 보여주고, Debug diagnostics는 route candidate와 active path 선택 이유를 설명해야 한다. 실제 macOS/Windows/Linux 및 멀티 NIC 환경에서 연결되는지 수동 검증 절차도 고정한다.

## 연관 문서

- [plan.md - 5.7 연결 UI와 diagnostics 정리](plan.md#57-연결-ui와-diagnostics-정리)
- [plan.md - 5.8 수동 연결 검증](plan.md#58-수동-연결-검증)
- [plan.md - 7. 완료 기준](plan.md#7-완료-기준)
- [task007.md](task007.md)

## 선행 조건

- [task004.md](task004.md)의 runtime candidate projection이 UI provider로 연결되어 있어야 한다.
- [task007.md](task007.md)의 active path 상태 전이가 완료되어 있어야 한다.
- 기존 peer list UI와 diagnostics UI의 overflow 이력을 확인해야 한다.

## 포함 기능

### 기능 1. Product UI 연결 상태 정리

- peer list/card에는 최소 연결 상태만 표시한다.
- 후보 탐색 중, 인증 중, 연결됨, 실패, offline/stale 상태를 구분한다.
- raw local address 목록이나 긴 interface 세부 정보는 Product UI에 과도하게 노출하지 않는다.
- 창 크기를 줄여도 overflow가 나지 않도록 layout을 고정한다.

### 기능 2. Debug diagnostics 강화

- candidate count, active interface, local address, remote endpoint, last failure reason을 표시한다.
- path selection reason과 candidate score/status/RTT/failure count를 확인할 수 있게 한다.
- discovery/security/control/auth reason code를 구분한다.
- password, token, verifier, group tag 전체값, session key, 파일 경로는 표시하지 않는다.

### 기능 3. 플랫폼 수동 검증 게이트

- macOS 동일 장비 2개 인스턴스 loopback/local registry 검증을 정의한다.
- macOS 장비 2대 같은 Ethernet subnet 검증을 정의한다.
- macOS + Windows Parallels bridged network 검증을 정의한다.
- Ethernet NIC 2개 또는 bridge network candidate 다중 표시 검증을 정의한다.
- peer 종료 후 stale/offline 정리 검증을 정의한다.

## 구현 체크리스트

- [x] peer card에 연결 상태 요약을 추가하거나 기존 표시를 정리했다.
- [x] candidate만 있고 active path가 없을 때 “연결 확인 중” 상태를 표시한다.
- [x] authenticated + active path가 있으면 “연결됨” 상태를 표시한다.
- [x] 모든 candidate 실패 시 간단한 실패 메시지를 표시한다.
- [x] Debug diagnostics에 active path 요약을 표시한다.
- [x] Debug diagnostics에 candidate rows를 표시한다.
- [x] Debug diagnostics에 last failure reason을 표시한다.
- [x] 긴 interface 이름과 host name을 줄바꿈/ellipsis/constraints로 처리했다.
- [x] stale/offline peer가 UI에서 연결됨으로 남지 않게 했다.
- [x] `.tasks/multi_interface_beta_checklist.md` 또는 동등한 수동 검증 문서를 현재 계획에 맞게 갱신했다.

## 테스트

- [x] active path가 있으면 연결됨 상태가 표시되는 widget/provider 테스트를 작성했다.
- [x] candidate만 있으면 연결 확인 중 상태가 표시되는 테스트를 작성했다.
- [x] 모든 candidate 실패 시 실패 메시지가 표시되는 테스트를 작성했다.
- [x] stale/offline peer가 연결됨으로 표시되지 않는 테스트를 작성했다.
- [x] Debug diagnostics에 candidate count와 active path가 표시되는 테스트를 작성했다.
- [x] Product UI에 raw network detail이 과도하게 노출되지 않는 테스트를 작성했다.
- [x] 긴 interface 이름과 긴 host name에서 overflow가 발생하지 않는 widget smoke 테스트를 작성했다.
- [x] PeersScreen peer card 전체에서 긴 이름과 Product UI 정보 노출 제한을 검증하는 widget smoke 테스트를 작성했다.
- [x] 민감 정보가 diagnostics snapshot에 없는지 테스트했다.

## 수동 검증 체크리스트

- [ ] macOS 동일 장비 앱 2개를 같은 ID/PW로 로그인하고 자동 연결을 확인했다.
- [ ] macOS 장비 2대를 같은 Ethernet subnet에 연결하고 자동 연결을 확인했다.
- [ ] macOS host와 Windows Parallels bridged guest 사이 자동 연결을 확인했다.
- [ ] Windows firewall 허용 전후 실패 원인이 구분되는지 확인했다.
- [ ] Ethernet NIC 2개 장비에서 candidate 2개 이상 표시되는지 확인했다.
- [ ] 내부 Ethernet bridge 또는 VM bridge 후보가 보존되는지 확인했다.
- [ ] 한 NIC 연결 차단 후 다른 candidate 재시도 또는 명확한 실패 표시를 확인했다.
- [ ] 앱 하나 종료 후 stale/offline으로 정리되는지 확인했다.

## 검증

- [x] `flutter analyze`가 통과한다.
- [x] 관련 provider/widget 테스트가 통과한다.
- [x] 일반 사용자는 연결 여부를 간단히 이해할 수 있다.
- [x] 개발자는 candidate 선택과 실패 원인을 diagnostics에서 확인할 수 있다.
- [ ] macOS/Windows/Linux 수동 검증 결과가 체크리스트에 남는다.

## 구현 결과

- `PeerConnectionSummary`를 추가해 Product UI가 `발견됨`, `연결 확인 중`, `인증 중`, `연결됨`, `연결 실패`, `응답 대기`, `오프라인`, `버전 다름`을 짧은 문구로 표시한다.
- `PeersScreen`의 peer card는 raw `Route ip:port` 표시를 제거하고, summary label/description과 `NetworkPathSummary`의 product summary만 사용한다.
- peer card grid는 `childAspectRatio` 대신 `mainAxisExtent`를 사용해 창 크기 축소와 긴 host/interface 이름에서 overflow 가능성을 낮췄다.
- `PeerPathDiagnostics`는 candidate count, active interface, active endpoint, path selection reason, last failure reason, candidate row를 제공한다.
- `NetworkPathSummary(debug: true)`는 debug summary와 candidate rows를 렌더링하고, product mode는 짧은 product summary만 표시한다.
- `.tasks/multi_interface_beta_checklist.md`에 task008 연결 우선 수동 검증 gate를 추가했다.

## 실행 결과

- `flutter test test/application/network/peer_connection_summary_provider_test.dart test/application/network/network_diagnostics_provider_test.dart test/presentation/peers/network_path_summary_test.dart test/presentation/peers/peers_screen_test.dart` 통과
- `flutter analyze` 통과
- `flutter test` 통과, 193 tests
- 전체 테스트 중 Drift multiple database 경고가 출력되었으나 테스트 실패는 아니다.
- 실제 macOS/Windows/Linux 장비 수동 검증은 이 작업에서 실행하지 않았고 체크리스트만 갱신했다.

## 완료 기준

- 연결 1차 목표를 UI와 diagnostics에서 확인할 수 있다.
- 실제 플랫폼 검증 절차가 문서화되어 있다.
- 제품 UI와 Debug diagnostics의 정보 노출 수준이 분리되어 있다.
- 멀티 Ethernet 연결 실패를 재현하고 설명할 수 있다.
