# Multi Interface Beta Checklist

## 목적

멀티 Ethernet/Wi-Fi/가상 어댑터 환경에서 Discovery, Control, active path 표시, Data Port, failover가 베타 품질 기준을 만족하는지 검증한다.

자동화 가능한 항목은 release gate로 강제하고, 실제 OS/장비/방화벽 조건이 필요한 항목은 수동 검증 기록으로 분리한다.

## Task 008 연결 우선 수동 검증 Gate

아래 항목은 파일 전송 완성 전이라도 peer 연결 1차 목표를 확인하기 위한 최소 수동 검증이다.

- [ ] macOS 동일 장비에서 앱 인스턴스 2개를 실행하고 같은 ID/PW로 로그인했을 때 loopback/local registry 후보가 생성된다.
- [ ] macOS 동일 장비 2개 인스턴스가 자동 handshake 후 Product UI에서 `연결됨` 또는 명확한 실패 상태로 수렴한다.
- [ ] macOS 장비 2대를 같은 Ethernet subnet에 연결했을 때 candidate가 1개 이상 표시되고, Debug diagnostics에 active interface/local address/remote endpoint가 보인다.
- [ ] macOS host와 Windows Parallels guest를 bridged network로 설정했을 때 서로 candidate를 발견한다.
- [ ] Windows Defender Firewall 차단 상태에서는 Discovery/Control 실패가 `peer 없음` 하나로 뭉개지지 않고 diagnostics reason으로 구분된다.
- [ ] Windows Defender Firewall에서 UDP Discovery `38400`, Control `38401`, Data `38410-38430`을 허용한 뒤 candidate 발견과 handshake가 재시도된다.
- [ ] Ethernet NIC 2개 또는 Ethernet + bridge가 있는 장비에서 같은 peer에 대해 candidate가 2개 이상 보존된다.
- [ ] 한 NIC 또는 bridge 경로를 차단했을 때 Debug diagnostics의 candidate status/failure count/last failure reason이 갱신된다.
- [ ] 앱 인스턴스 하나를 종료하면 상대 UI에서 stale/offline 상태로 바뀌고, Product UI가 `연결됨`으로 남지 않는다.
- [ ] Product UI에는 raw IP 목록, 긴 interface 이름, token/password/verifier/group tag/session key/file path가 노출되지 않는다.
- [ ] Debug diagnostics에는 candidate count, active interface, local address, remote endpoint, selection reason, candidate score/status/RTT/failure count가 보인다.

## 자동 Release Gate

- [ ] `flutter analyze` 통과
- [ ] `flutter test` 전체 통과
- [ ] subnet/broadcast 계산 단위 테스트 통과
- [ ] route candidate projection 단위 테스트 통과
- [ ] peer path selection/state machine 테스트 통과
- [ ] ControlTransport adapter 테스트 통과
- [ ] DataTransport port bind policy 테스트 통과
- [ ] DataPath failover state machine 테스트 통과
- [ ] diagnostics provider/widget smoke 테스트 통과

## 포트와 방화벽 안내

- Discovery Port: UDP `38400`
- Control Port: UDP `38401`
- Data Port Range: UDP `38410-38430`
- 앱은 방화벽 규칙을 자동 변경하지 않는다.
- 방화벽 차단 의심 시 OS 방화벽, 보안 제품, 라우터 AP isolation, VPN split tunnel 설정을 사용자가 직접 확인한다.
- Data Port는 OS 임의 ephemeral fallback을 사용하지 않는다. 지정 range가 막히면 실패로 보고해야 한다.

## macOS 수동 검증

- [ ] Ethernet + Wi-Fi가 동시에 활성화된 상태에서 두 interface 모두 discovery target이 생성되는지 확인
- [ ] Ethernet + Wi-Fi가 서로 다른 subnet일 때 각 subnet directed broadcast가 계산되는지 확인
- [ ] Ethernet + Wi-Fi가 같은 subnet일 때 candidate가 interface별로 보존되는지 확인
- [ ] Thunderbolt Bridge + Ethernet 구성에서 bridge hint가 표시되고 기본 selection penalty가 적용되는지 확인
- [ ] USB LAN adapter hot plug 후 inventory 갱신과 discovery target 재생성이 가능한지 확인
- [ ] macOS 방화벽 활성화 상태에서 Discovery/Control/Data port 허용 안내가 충분한지 확인
- [ ] 전송 중 Wi-Fi 비활성화 시 same interface retry 또는 alternate interface failover가 관찰되는지 확인

## Windows 수동 검증

- [ ] Ethernet + Wi-Fi 동시 활성화 상태에서 discovery target이 interface별로 생성되는지 확인
- [ ] Windows Defender Firewall에서 Discovery/Control/Data port 차단 시 진단 문구가 이해 가능한지 확인
- [ ] Hyper-V/Parallels/VMware adapter가 virtual hint로 분류되고 기본 selection penalty가 적용되는지 확인
- [ ] VPN adapter 활성화 상태에서 VPN candidate가 일반 LAN candidate를 불필요하게 이기지 않는지 확인
- [ ] Data Port range 첫 port가 사용 중일 때 다음 port retry가 동작하는지 확인
- [ ] 전송 중 Ethernet cable 분리 시 해당 peer session만 failover되고 다른 1:N peer session이 유지되는지 확인

## Linux 수동 검증

- [ ] Ethernet + Wi-Fi 동시 활성화 상태에서 discovery target이 interface별로 생성되는지 확인
- [ ] Docker bridge가 bridge/virtual policy로 구분되는지 확인
- [ ] ufw/firewalld/nftables 차단 상태에서 Discovery/Control/Data port 안내가 충분한지 확인
- [ ] 서로 다른 subnet 두 NIC에서 각 subnet candidate가 유지되는지 확인
- [ ] 전송 중 interface down 시 failover state와 diagnostics projection이 갱신되는지 확인

## Known Limitations

- Dart `NetworkInterface`는 prefix/netmask를 일관되게 제공하지 않는다. prefix가 없으면 `/24` fallback으로 directed broadcast를 계산한다.
- Discovery source hint는 후보 추적용이며 인증/보안 판단 근거로 사용하지 않는다.
- 실제 Control socket의 interface-specific receive bind는 후속 hardening에서 OS별로 더 세분화해야 한다.
- 실제 Data chunk 전송의 controller 전면 이관은 adapter 단계 이후 점진적으로 진행한다.
- VPN/virtual/bridge 자동 제외는 기본 정책이 아니라 selection penalty이며, 사용자가 요구하는 환경에서는 후보로 남을 수 있다.

## 수행 기록

| Date | OS | Interfaces | Scenario | Result | Notes |
| ---- | -- | ---------- | -------- | ------ | ----- |
|      |    |            |          |        |       |
