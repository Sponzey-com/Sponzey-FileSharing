# Task 012 - 플랫폼 안정화, 패키징, 베타 검증 게이트

## 목표

macOS, Windows, Linux에서 Discovery/Control/Data UDP 채널, 파일 저장, 권한, 방화벽, 패키징 이슈를 검증하고 베타 배포 가능한 품질 게이트를 만든다.

## 연관 문서

- [phase002 plan.md - 플랫폼 안정화와 패키징](plan.md#phase-011-플랫폼-안정화와-패키징)
- [root plan.md - 플랫폼별 고려사항](../../plan.md#13-플랫폼별-고려사항)

## 선행 조건

- [task006.md](task006.md), [task007.md](task007.md), [task008.md](task008.md)가 완료되어 discovery/auth/transfer 기본 흐름이 있어야 한다.
- 가능하면 [task009.md](task009.md), [task010.md](task010.md), [task011.md](task011.md)가 완료되어 있어야 한다.

## 포함 기능

### 기능 1. 플랫폼별 네트워크/방화벽 검증

- macOS 네트워크 권한과 방화벽 승인 흐름을 확인한다.
- Windows Defender Firewall 예외 또는 사용자 안내를 확인한다.
- Linux UDP broadcast와 keyring/secret service 의존성을 확인한다.

### 기능 2. 파일 시스템/경로 안정화

- 한글, 공백, 긴 경로, 유니코드 파일명을 검증한다.
- 저장 경로 권한, 남은 공간 부족, 디스크 쓰기 실패를 검증한다.
- 앱 종료 시 소켓, 파일 핸들, 임시 파일을 정리한다.

### 기능 3. 릴리스/베타 검증 게이트

- release build smoke test를 만든다.
- 두 장비 간 discovery, auth, single transfer, retry transfer를 검증한다.
- 베타 체크리스트와 알려진 제한사항을 문서화한다.

## 구현 체크리스트

- [ ] macOS 실행 smoke를 준비했다. _(완전 수동 확인 제외)_
- [ ] Windows 실행 smoke를 준비했다. _(완전 수동 확인 제외)_
- [ ] Linux 실행 smoke를 준비했다. _(완전 수동 확인 제외)_
- [x] Discovery Port 방화벽 안내 문구를 정리했다.
- [x] Control Port 방화벽 안내 문구를 정리했다.
- [x] Data Port 또는 Data Port Range 방화벽 안내 문구를 정리했다.
- [x] macOS network permission 확인 절차를 문서화했다.
- [x] Windows firewall 확인 절차를 문서화했다.
- [x] Linux UDP broadcast 확인 절차를 문서화했다.
- [x] 한글/공백/유니코드 파일명 검증 케이스를 만들었다.
- [x] 긴 경로 검증 케이스를 만들었다.
- [x] 저장 공간 부족 또는 쓰기 실패 검증 케이스를 만들었다.
- [x] 앱 종료 시 socket/file handle cleanup을 확인했다.
- [ ] release build smoke test를 준비했다. _(완전 수동 확인 제외)_
- [x] 베타 체크리스트를 작성했다.

## 테스트

- [ ] macOS에서 앱 실행 smoke를 수행했다. _(완전 수동 확인 제외)_
- [ ] Windows에서 앱 실행 smoke를 수행했다. _(완전 수동 확인 제외)_
- [ ] Linux에서 앱 실행 smoke를 수행했다. _(완전 수동 확인 제외)_
- [ ] macOS <-> Windows discovery/auth/transfer를 검증했다. _(완전 수동 확인 제외)_
- [ ] Windows <-> Linux discovery/auth/transfer를 검증했다. _(완전 수동 확인 제외)_
- [ ] macOS <-> Linux discovery/auth/transfer를 검증했다. _(완전 수동 확인 제외)_
- [ ] 동일 OS 간 discovery/auth/transfer를 검증했다. _(완전 수동 확인 제외)_
- [x] packet loss fault injection smoke를 수행했다.
- [ ] 앱 종료 후 재실행 시 history와 설정이 유지되는지 확인했다.

## 검증

- [x] 플랫폼별 방화벽/권한 이슈가 사용자에게 설명 가능하다.
- [x] release build에서 Product 로그 정책이 적용된다.
- [x] Debug 로그를 켰을 때 현장 확인용 네트워크/전송 정보가 나온다.
- [x] 베타 제한사항이 문서화되어 있다.
- [x] 알려진 실패 조건과 사용자 대응 방법이 정리되어 있다.

## 진행 결과

- `.tasks/phase002/platform_beta_checklist.md`
- `test/application/transfer/transfer_controller_test.dart`의 packet loss fault injection 테스트

## 수동 확인 제외

- 실제 macOS/Windows/Linux 앱 실행, 크로스 OS 네트워크 검증, release build smoke는 장비와 권한 상태가 필요하므로 자동 완료 범위에서 제외했다.

## 남은 비수동 후속

- 영구 history가 추가된 뒤 앱 재실행 유지 검증을 연결해야 한다.

## 완료 기준

- 3개 데스크톱 플랫폼에서 최소 실행과 핵심 네트워크 흐름이 검증된다.
- 베타 배포 전에 수행할 체크리스트가 준비되어 있다.
- 플랫폼별 리스크가 문서화되어 후속 릴리스에서 추적 가능하다.