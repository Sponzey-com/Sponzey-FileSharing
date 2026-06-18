# Task 009 - 플랫폼 체크리스트와 베타 검증 게이트

## 목표

macOS, Windows, Linux의 실제 multi-NIC 환경에서 Discovery, Control, Data Port, failover가 어떤 제약을 갖는지 검증하고 베타 품질 게이트를 문서화한다.

자동 테스트로 검증 가능한 영역과 실제 장비/방화벽/권한 때문에 수동 확인이 필요한 영역을 분리한다.

## 연관 문서

- [plan.md - 수동 테스트](plan.md#144-수동-테스트)
- [plan.md - 플랫폼 체크리스트와 수동 검증](plan.md#phase-003-009-플랫폼-체크리스트와-수동-검증)
- [phase002 platform checklist](../phase002/platform_beta_checklist.md)

## 선행 조건

- [task006.md](task006.md)의 DataTransport가 있어야 한다.
- [task007.md](task007.md)의 Data path failover가 있어야 한다.
- [task008.md](task008.md)의 diagnostics projection이 있으면 수동 검증이 쉬워진다.

## 포함 기능

### 기능 1. 플랫폼별 multi-NIC 체크리스트

- macOS Ethernet + Wi-Fi를 검증한다.
- macOS Thunderbolt Bridge + Ethernet을 검증한다.
- Windows Ethernet + Wi-Fi를 검증한다.
- Windows Hyper-V/Parallels/VMware adapter 존재 시 정책을 검증한다.
- Linux Ethernet + Wi-Fi + Docker bridge를 검증한다.

### 기능 2. 방화벽/권한/포트 문서화

- Discovery Port, Control Port, Data Port range의 방화벽 안내를 정리한다.
- interface별 bind 실패 시 사용자가 확인할 수 있는 대응 방법을 정리한다.
- OS별 UDP broadcast/multicast 제약을 정리한다.

### 기능 3. 베타 검증 게이트

- 자동 테스트 필수 통과 조건을 정의한다.
- 수동 체크리스트 필수/선택 항목을 나눈다.
- known limitations를 문서화한다.
- 베타 전 release decision 기준을 만든다.

## 구현 체크리스트

- [x] `.tasks/multi_interface_beta_checklist.md`를 작성했다.
- [x] macOS multi-NIC 수동 검증 절차를 작성했다.
- [x] Windows multi-NIC 수동 검증 절차를 작성했다.
- [x] Linux multi-NIC 수동 검증 절차를 작성했다.
- [x] Ethernet + Wi-Fi 검증 케이스를 작성했다.
- [x] Thunderbolt/USB LAN 검증 케이스를 작성했다.
- [x] VPN/virtual adapter 제외/포함 정책 검증 케이스를 작성했다.
- [x] 같은 subnet 두 NIC 검증 케이스를 작성했다.
- [x] 서로 다른 subnet 두 NIC 검증 케이스를 작성했다.
- [x] 한 NIC 방화벽 차단 후 failover 검증 케이스를 작성했다.
- [x] 전송 중 NIC 비활성화 검증 케이스를 작성했다.
- [x] Discovery/Control/Data port 방화벽 안내를 작성했다.
- [x] known limitations를 작성했다.
- [x] 자동 테스트 release gate를 작성했다.
- [x] 수동 테스트 release gate를 작성했다.

## 테스트

- [x] 자동 테스트 전체 `flutter test`를 release gate에 포함했다.
- [x] `flutter analyze`를 release gate에 포함했다.
- [x] subnet/candidate/path/failover 단위 테스트를 release gate에 포함했다.
- [x] DataTransport fake multi-interface 테스트를 release gate에 포함했다.
- [x] UI diagnostics smoke 테스트를 release gate에 포함했다.
- [x] macOS 실제 multi-NIC 검증 항목을 수동 체크로 남겼다.
- [x] Windows 실제 multi-NIC 검증 항목을 수동 체크로 남겼다.
- [x] Linux 실제 multi-NIC 검증 항목을 수동 체크로 남겼다.

## 검증

- [x] 플랫폼별 방화벽/권한 이슈가 사용자에게 설명 가능하다.
- [x] release build에서 Product 로그 정책이 유지된다.
- [x] Debug 로그에서 interface/path/failover 요약을 볼 수 있다.
- [x] 수동 체크리스트가 장비 없이 완료된 것처럼 표시되지 않는다.
- [x] known limitation이 후속 task로 추적 가능하다.

## 완료 기준

- multi-interface 자동 검증과 수동 검증 범위가 명확히 분리되어 있다.
- 베타 전에 확인해야 할 OS별 네트워크 리스크가 문서화되어 있다.
- 실제 multi-NIC 환경에서 수행할 체크리스트가 준비되어 있다.

## 메모

- 수동 테스트는 완료로 체크하지 않는다. 실제 장비와 네트워크 조건에서 확인한 날짜와 환경을 기록한다.
- 방화벽 규칙을 앱이 자동으로 변경하지 않는다.
