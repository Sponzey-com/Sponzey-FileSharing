# task006 - 저장 경로, temp file, 수신 준비 lifecycle 안정화

## 상태

- [x] 진행 전
- [x] 진행 중
- [x] 구현 완료
- [x] 테스트 완료
- [ ] 수동 검증 완료
- [ ] 완료

## 진행 메모

- 플랫폼별 기본 수신 경로 resolver를 순수 함수로 분리해 macOS, Windows, Linux 경로 정책을 테스트로 고정했다.
- macOS 기본 수신 경로는 `~/Downloads/Sponzey FileSharing`, Windows는 사용자 `Downloads\Sponzey FileSharing`, Linux는 `XDG_DOWNLOAD_DIR` 또는 `~/Downloads/Sponzey FileSharing`로 정리했다.
- receiver는 `TRANSFER_INIT` 처리 중 저장 설정, temp draft, writer, Data bind를 모두 준비한 뒤에만 `TRANSFER_INIT_ACK accepted=true`를 반환한다.
- temp draft 준비 실패는 sender가 data frame을 보내기 전에 `TRANSFER_INIT_ACK accepted=false`로 거절되도록 고정했다.
- final 저장 시 같은 파일명이 있으면 overwrite하지 않고 `name (1).ext` suffix로 저장한다.
- final rename 실패는 temp draft directory를 best-effort cleanup하고 `incoming_finalize_failed`로 반환한다.
- 설정 저장 실패는 controller error state로 남기고 앱 lifecycle을 중단하지 않도록 테스트를 추가했다.
- 수신 준비 start/success/failure와 finalize failure 로그를 transfer id 기준으로 남기되, 전체 저장 경로 대신 파일명과 endpoint 중심으로 제한했다.
- macOS/Windows/Linux 실제 앱 실행과 권한 없는 경로 수동 검증은 아직 수행하지 않았다.

## 목적

인증된 peer의 파일은 기본 저장 경로에 자동 수신되어야 한다. 저장 경로 준비 실패, temp file 생성 실패, rename 실패는 앱 종료나 silent timeout이 아니라 명확한 control response와 사용자 메시지로 처리한다.

## 기능 범위

1. 플랫폼별 기본 저장 경로 resolver와 권한 처리
2. receiver temp/final file lifecycle
3. 수신 준비 실패 control response 표준화

## 선행 조건

- [x] task005의 data transfer route preflight 기준 확인
- [x] 현재 SettingsRepository, SettingsController, TransferController receiver path 코드를 읽는다.
- [x] macOS, Windows, Linux 기본 Downloads 경로 정책을 확인한다.

## 제외 범위

- 수신 전 승인 UI는 현재 범위가 아니다.
- persisted transfer history는 task008에서 처리한다.
- OS별 installer 권한 가이드는 task010에서 처리한다.

## 계층별 변경 위치

- domain/application: receive preparation state, storage failure code
- infrastructure: path resolver, temp file writer, rename/cleanup implementation
- presentation: 설정 저장 오류, receiver failure message
- test: `test/application/transfer`, `test/infrastructure/storage`, widget test

## 실패 테스트 또는 수동 재현 기준

- [x] receiver가 temp file을 준비하지 못했는데 sender가 data chunk를 보내는 실패 테스트를 작성한다.
- [x] 설정 저장 실패 후 앱이 종료되는 실패 재현 기준을 기록한다.
- [x] macOS 기본 저장 경로가 예측 불가능한 위치로 계산되는 실패 테스트를 작성한다.

## diagnostics/log 검토 기준

- [x] receive preparation start/success/failure가 transfer id와 함께 로그에 남는지 확인한다.
- [x] 경로 로그는 전체 민감 경로 대신 축약 또는 basename 중심인지 확인한다.
- [x] temp create, write, rename, cleanup failure가 구분되는지 확인한다.

## 구현 체크리스트

- [x] macOS 기본 경로를 `~/Downloads/Sponzey FileSharing` 계열로 고정한다.
- [x] Windows 기본 경로를 사용자 Downloads 하위로 고정한다.
- [x] Linux 기본 경로를 XDG Downloads 또는 home fallback 하위로 고정한다.
- [x] 기본 경로 생성 실패 시 앱 종료 없이 설정/전송 오류로 처리한다.
- [x] receiver는 data channel 시작 전에 temp file 준비를 완료한다.
- [x] temp file 준비 실패 시 sender에 명확한 transfer init failure를 반환한다.
- [x] overwrite 또는 duplicate filename 정책을 정의한다.
- [x] 완료 시 temp file을 final path로 atomic하게 이동한다.
- [x] rename 실패 시 partial cleanup 정책을 실행한다.
- [x] 설정 저장 실패와 전송 수신 실패 메시지를 분리한다.
- [x] 저장 경로 오류 메시지는 사용자가 조치 가능한 문구로 표시한다.

## 테스트 체크리스트

- [x] macOS 기본 경로 resolver 테스트
- [x] Windows 기본 경로 resolver 테스트
- [x] Linux 기본 경로 resolver 테스트
- [x] 저장 경로 권한 실패 시 앱이 종료되지 않는 테스트
- [x] temp file 준비 실패 시 sender에 retry 가능/불가능 사유 전달 테스트
- [x] receiver 준비 실패 시 data chunk를 보내지 않는 테스트
- [x] 완료 파일 rename 실패 시 partial cleanup 테스트
- [x] duplicate filename 정책 테스트

## 수동 검증 체크리스트

- [ ] macOS에서 설정 저장 후 앱이 유지된다.
- [ ] Windows에서 기본 저장 경로가 자동 생성된다.
- [ ] Linux에서 기본 저장 경로가 자동 생성된다.
- [ ] 권한 없는 경로 설정 후 명확한 오류가 표시된다.
- [ ] 수신 실패 시 sender와 receiver 양쪽에 서로 대응되는 오류가 표시된다.

## 완료 기준

- [x] receiver가 준비되지 않은 상태에서 data channel이 시작되지 않는다.
- [x] 저장 경로 실패는 timeout이 아니라 명확한 실패로 전달된다.
- [x] 수신 완료 파일은 예측 가능한 경로에 저장된다.

## 회귀 금지 조건

- 수신 전 승인 UI를 되살리지 않는다.
- 기본 저장 경로를 임의 working directory나 앱 bundle 내부로 잡지 않는다.
- 전체 파일 경로를 product/debug 로그에 무조건 남기지 않는다.
