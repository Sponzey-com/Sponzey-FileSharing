# Platform Beta Checklist

이 문서는 수동 실기기 확인을 제외하고 자동화 또는 사전 준비가 가능한 플랫폼 안정화 항목을 정리한다.

## UDP Port 안내

Discovery Port:

- 기본값: `38400/udp`
- 역할: Peer 검색, presence broadcast, heartbeat
- 방화벽 안내: 같은 로컬 네트워크에서 UDP broadcast 수신과 송신을 허용해야 한다.

Control Port:

- 기본값: `38401/udp`
- 역할: Peer 연동, 인증, 세션 협상, 전송 제어 메시지
- 방화벽 안내: 같은 로컬 네트워크 peer의 UDP unicast 요청을 허용해야 한다.

Data Port:

- MVP 기본값: `38410/udp`
- 확장 범위: `38410~38430/udp`
- 역할: 파일 chunk 데이터, ACK/NACK, Data Window Update
- 방화벽 안내: 대용량 전송 중 해당 UDP 포트 범위가 차단되면 전송이 실패할 수 있다.

## macOS 확인 절차

- [ ] 최초 실행 시 네트워크 접근 권한 또는 방화벽 확인 안내가 표시되는지 확인한다.
- [ ] 같은 네트워크의 다른 macOS/Windows/Linux 장치와 discovery가 되는지 확인한다.
- [ ] Downloads 또는 사용자가 선택한 수신 폴더에 쓰기 권한이 있는지 확인한다.
- [ ] 앱 종료 시 UDP socket과 임시 파일이 정리되는지 확인한다.

## Windows 확인 절차

- [ ] Windows Defender Firewall에서 앱의 사설 네트워크 UDP 통신 허용이 가능한지 확인한다.
- [ ] 한글, 공백, 긴 경로 파일명이 정상 처리되는지 확인한다.
- [ ] 수신 폴더 권한 오류 발생 시 사용자 메시지가 표시되는지 확인한다.
- [ ] 앱 종료 시 전송 중 작업이 실패 또는 취소로 정리되는지 확인한다.

## Linux 확인 절차

- [ ] UDP broadcast가 배포판과 네트워크 설정에서 허용되는지 확인한다.
- [ ] Secret Service 또는 keyring 미구성 시 오류 메시지가 복구 가능하게 표시되는지 확인한다.
- [ ] 수신 폴더 권한과 파일명 인코딩을 확인한다.
- [ ] AppImage, deb, rpm 중 배포 대상 포맷별 실행 조건을 확인한다.

## 자동화 후보

- [x] `flutter test`로 codec, 상태 머신, MessageBus, transfer reliability 단위 테스트 실행
- [ ] release build smoke 명령 정리
- [ ] loopback discovery/auth/transfer smoke script 추가
- [ ] packet loss fault injection smoke script 추가

## 알려진 제한

- 인터넷 원격 전송과 NAT traversal은 범위에서 제외한다.
- 중앙 서버 기반 계정 동기화는 범위에서 제외한다.
- 실기기 macOS/Windows/Linux 교차 검증은 수동 확인 항목으로 남긴다.

