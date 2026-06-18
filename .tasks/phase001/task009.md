# Task 009 - 플랫폼 안정화, 패키징, 베타 검증

## 목표

macOS, Windows, Linux에서 배포 가능한 품질로 다듬고, 실제 네트워크 환경에서 베타 검증을 수행한다.

## 연관 문서

- [plan.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/plan.md)

## 선행 조건

- [task006.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/tasks/task006.md)
- [task007.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/tasks/task007.md)
- [task008.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/tasks/task008.md)

## 포함 기능

### 기능 1. 플랫폼별 권한/경로/방화벽 대응

- macOS 네트워크 접근, 디렉터리 접근 흐름 점검
- Windows Defender Firewall 대응 및 파일 경로 검증
- Linux keyring, 파일 경로, 배포판 차이 대응

### 기능 2. 설치/배포 패키징 준비

- 플랫폼별 빌드 스크립트 정리
- 설치 산출물 구조 정리
- 버전 표기, 릴리스 노트, 기본 운영 가이드 초안 작성

### 기능 3. 베타 테스트와 네트워크 검증

- 실제 LAN에서 대형 파일, 다중 대상, 손실 환경 테스트
- UI 병목, 메모리 사용량, 로그 품질 검토
- 치명 버그/사용성 문제 수집과 수정 목록 작성

## 구현 체크리스트

- [ ] macOS, Windows, Linux에서 기본 설치 또는 실행 방법이 정리되어 있다.
- [ ] 각 OS별 권한/방화벽 이슈에 대한 사용자 안내가 있다.
- [ ] 릴리스 빌드 산출물과 버전 전략이 정리되어 있다.
- [ ] 교차 플랫폼 전송 테스트 결과가 문서화되어 있다.
- [ ] 알려진 이슈 목록과 베타 피드백 반영 목록이 정리되어 있다.
- [ ] 최종 배포 전 체크리스트가 준비되어 있다.

## 산출물

- 플랫폼별 빌드/배포 스크립트
- 베타 테스트 리포트
- 알려진 이슈 문서
- 릴리스 체크리스트

## 테스트

- [ ] macOS <-> Windows 교차 전송 테스트 수행
- [ ] Windows <-> Linux 교차 전송 테스트 수행
- [ ] macOS <-> Linux 교차 전송 테스트 수행
- [ ] 대형 파일, 다중 파일, 1:N 전송 실환경 테스트 수행
- [ ] 패킷 손실/혼잡 네트워크 시뮬레이션 테스트 수행

## 검증

- [ ] 각 플랫폼에서 한글 파일명과 긴 경로 파일이 정상 처리되는지 확인한다.
- [ ] 방화벽 차단 상태에서 사용자 안내가 충분한지 확인한다.
- [ ] 앱 재시작 후 이력과 설정이 유지되는지 최종 확인한다.
- [ ] 릴리스 후보 빌드에서 치명 크래시 없이 주요 시나리오가 재현되는지 확인한다.

## 완료 기준

- 3개 데스크톱 플랫폼에서 배포 가능한 수준의 안정성과 운영 문서가 확보된다.
- README와 plan에 정의된 핵심 시나리오가 실환경에서 재현된다.

## 메모

- 이 태스크는 구현보다 마감 품질을 다루는 성격이 강하다.
- 기능 추가보다 크로스 플랫폼 불일치와 배포 문제 제거에 집중해야 한다.