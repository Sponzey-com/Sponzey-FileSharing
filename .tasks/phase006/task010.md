# task010 - macOS, Windows, Linux platform hardening

## 상태

- [x] 진행 전
- [x] 진행 중
- [x] 구현 완료
- [x] 테스트 완료
- [ ] 수동 검증 완료
- [ ] 완료

## 목적

macOS, Windows, Linux에서 클릭/입력, 방화벽, 소켓 권한, 저장 경로, 빌드 의존성 문제를 제품 수준으로 정리한다. 플랫폼별 차이는 코드에 숨기지 말고 테스트와 문서로 고정한다.

## 기능 범위

1. macOS UI 클릭/포커스 반응성 점검
2. Windows firewall, UDP port, 입력/버튼 활성화 안정화
3. Ubuntu 22.04 minimum Linux 빌드/실행 가이드 정리

## 선행 조건

- [x] task006 저장 경로 기준 확인
- [x] task009 diagnostics export 기준 확인
- [x] `.github/workflows`와 platform build scripts를 확인한다.

## 제외 범위

- notarization, code signing 자동화 고도화는 task011 또는 별도 release task에서 처리한다.
- 새 installer 제작은 현재 범위가 아니다.
- OS별 별도 protocol fork는 만들지 않는다.

## 계층별 변경 위치

- presentation: hit target, focus, button enabled state
- infrastructure: platform path, firewall guidance hooks, socket permission handling
- docs: README/README.ko.md platform guide
- workflow/scripts: Linux 22.04 build assumptions 확인
- test: widget test, platform smoke checklist

## 실패 테스트 또는 수동 재현 기준

- [x] macOS에서 버튼을 한 번 눌러도 반응하지 않는 재현 기준을 기록한다.
- [x] Windows에서 로그인 input focus/typing/button enabled가 동작하지 않는 실패 기준을 기록한다.
- [x] Linux 22.04 최소 의존성 없이 build guide가 불완전한 상태를 실패 기준으로 둔다.

## diagnostics/log 검토 기준

- [x] platform startup log에 OS, app version, configured ports, log level이 안전하게 남는지 확인한다.
- [x] firewall 또는 socket permission 문제는 사용자가 조치 가능한 message로 남는지 확인한다.
- [x] 전체 사용자 경로나 개인정보가 불필요하게 로그에 남지 않는지 확인한다.

## 구현 체크리스트

- [x] macOS primary action button hit target과 focus overlay를 점검한다.
- [x] macOS에서 single click으로 버튼이 반응하도록 widget tree gesture conflict를 제거한다.
- [x] Windows login text field focus와 keyboard input을 확인한다.
- [x] Windows button enabled state가 controller state와 즉시 동기화되는지 확인한다.
- [x] Windows Defender Firewall에서 UDP discovery/control/data port 허용 안내를 README에 추가한다.
- [x] Windows symlink/developer mode와 build 위치 관련 주의사항을 정리한다.
- [x] Ubuntu 22.04 minimum build dependency를 README/README.ko.md에 정리한다.
- [x] Linux runtime path와 permission guide를 정리한다.
- [x] platform-specific path permission guide를 작성한다.
- [x] 플랫폼별 smoke checklist를 `.tasks` 또는 docs에 둔다.

## 테스트 체크리스트

- [x] macOS primary action button hit target widget test
- [x] login input focus/typing widget test
- [x] button enabled state widget test
- [x] path resolver platform test가 task006 기준을 유지한다.
- [x] Ubuntu 22.04 GitHub Actions build가 유지된다.
- [x] README/README.ko.md에 platform guide가 반영되어 있는지 문서 검증한다.

## 수동 검증 체크리스트

- [ ] macOS에서 버튼이 단일 클릭으로 반응한다.
- [ ] macOS에서 로그인 입력이 정상 동작한다.
- [ ] Windows에서 로그인 입력과 버튼 활성화가 정상 동작한다.
- [ ] Windows firewall 허용 후 discovery가 정상 동작한다.
- [ ] Linux 22.04에서 build/run이 정상 동작한다.
- [ ] Linux에서 기본 저장 경로와 수신 파일 생성이 정상 동작한다.

## 완료 기준

- [x] 각 OS별 알려진 실행 전제와 문제 해결 절차가 문서화된다.
- [ ] macOS/Windows/Linux에서 최소 실행, 로그인, discovery, 저장 경로가 확인된다.
- [x] 플랫폼 차이가 protocol 로직을 오염시키지 않는다.

## 회귀 금지 조건

- 특정 OS 문제를 해결하기 위해 protocol을 OS별로 분기하지 않는다.
- Windows/Parallels 전용 IP나 NIC 이름을 코드에 넣지 않는다.
- UI focus 문제를 해결하면서 접근성과 keyboard input을 깨지 않는다.
