# Sponzey FileSharing

[English](README.md) | [한국어](README.ko.md)

Sponzey FileSharing은 같은 로컬 네트워크에 연결된 장치들이 외부 서버 없이 서로를 발견하고, 인증된 상대에게 파일을 빠르게 전송할 수 있도록 만드는 Flutter Desktop 기반 파일 공유 앱입니다.

이 프로젝트는 단순한 파일 복사 도구가 아니라, 내부망에서 반복적으로 발생하는 장치 간 파일 배포, 테스트 산출물 전달, 로그 수집, 연구실/사무실 PC 간 공유를 안정적으로 처리하는 것을 목표로 합니다.

특히 하나의 장치에 여러 네트워크 경로가 동시에 존재하는 환경을 중요한 대상 시나리오로 봅니다. 사용 가능한 모든 Ethernet 인터페이스를 활용해 peer 발견, 연결, 파일 전송이 가능해야 하며, 단일 유선 랜 카드뿐 아니라 복수의 이더넷 카드, USB Ethernet 어댑터, 내부 Ethernet 브리지 네트워크, 가상화 환경에서 노출되는 브리지형 내부망까지 연결 후보로 다룰 수 있어야 합니다.

## 핵심 목표

- 동일 로컬 네트워크 안에서 자동으로 노드를 탐색합니다.
- 아이디와 패스워드 기반 인증을 거친 상대와만 파일 전송 세션을 엽니다.
- UDP 기반 통신으로 낮은 지연의 전송 경험을 제공합니다.
- 패킷 손실, 중복, 재전송, 타임아웃을 고려해 UDP 위에서 신뢰성을 보강합니다.
- 1:1 전송과 1:N 일괄 전송을 모두 지원하는 구조를 갖춥니다.
- 사용 가능한 모든 Ethernet 인터페이스를 탐색, 연결, 전송 경로 후보로 활용하는 구조를 갖춥니다.
- macOS, Windows, Linux 데스크톱 환경에서 동작하는 앱을 지향하며, Linux는 Ubuntu 22.04 LTS 이상을 최소 기준으로 삼습니다.
- 중앙 웹 백엔드나 외부 클라우드에 의존하지 않는 내부망 중심 제품으로 유지합니다.

## 사용 시나리오

- 같은 사무실, 연구실, 강의실 네트워크 안에서 여러 PC 간 파일을 빠르게 공유해야 하는 경우
- 개발 장비와 테스트 장비 사이에 빌드 결과물, 로그, 설정 파일을 반복 전달해야 하는 경우
- 특정 사용자 또는 특정 장치에만 파일을 보내야 하는 경우
- 여러 장치에 동일 파일을 동시에 배포해야 하는 경우
- 외부 클라우드 업로드가 어렵거나 보안상 내부망 안에서만 파일을 이동해야 하는 경우
- 이더넷 카드가 2개 이상인 워크스테이션에서 서로 다른 내부망 세그먼트의 장치와 각각 파일을 주고받아야 하는 경우
- 물리 NIC 외에 내부 Ethernet 브리지 네트워크나 가상화 브리지 네트워크에 연결된 장치와도 파일을 연동해야 하는 경우

## 주요 기능

### 노드 탐색

앱 인스턴스는 같은 네트워크 안에서 실행 중인 다른 노드를 탐색합니다. 탐색 결과에는 사용자 ID, 장치 이름, 온라인 상태, 마지막 응답 시각, 프로토콜 버전 같은 정보를 표시하는 것을 목표로 합니다.

탐색은 단일 NIC만 전제로 하지 않습니다. 프로젝트는 사용 가능한 모든 Ethernet 인터페이스를 스캔하고, 인터페이스별 IPv4 후보를 기준으로 discovery, control, data 경로를 분리해 관리하는 방향을 기준으로 발전합니다. 따라서 이더넷 카드 2개가 동시에 연결된 장비, 메인보드 NIC와 USB NIC를 함께 사용하는 장비, 내부 Ethernet bridge가 구성된 테스트 환경에서도 각 경로를 독립적인 연결 후보로 취급하는 것이 목표입니다.

### 인증 기반 연결

파일 전송은 인증된 상대에게만 허용합니다. 프로젝트 계획의 기준 인증 방식은 ID/PW 기반 로그인과 password-derived JWT 토큰을 이용한 짧은 수명의 상호 인증입니다.

인증 흐름은 다음 원칙을 따릅니다.

- 현재 앱 범위에서는 가입이나 로컬 계정 생성을 요구하지 않습니다.
- 비밀번호, password-derived JWT, session key는 메모리에서만 유지합니다.
- 비밀번호 평문 저장 금지
- 인증 전 민감 데이터 전송 금지
- 짧은 만료 시간, nonce, `jti`를 포함한 토큰 사용
- 인증된 세션에서만 전송 작업 생성
- 같은 ID/PW 그룹의 peer끼리 자동 인증, 자동 연결, 자동 수신
- 허용 사용자 목록, 수신 전 승인, credential verifier 영속 저장은 현재 기본 경로가 아니라 향후 확장 후보로 분리

### UDP 기반 파일 전송

전송 기반은 UDP입니다. UDP는 연결 지연이 낮고 로컬 네트워크에서 빠른 전송에 유리하지만, 신뢰성을 직접 보강해야 합니다.

따라서 전송 계층은 다음 문제를 명시적으로 다룹니다.

- 패킷 손실
- 패킷 중복
- 순서 어긋남
- 재전송
- 타임아웃
- 전송 취소
- 부분 실패와 재시도

### 다중 접속과 전송 큐

하나의 앱 인스턴스는 송신자이자 수신자이며, 동시에 여러 peer와 통신할 수 있는 로컬 엔드포인트 역할을 합니다.

전송 작업은 독립적인 `transfer job` 또는 세션 단위로 관리하며, 다중 파일 전송과 1:N 배포에서 상태가 섞이지 않도록 설계합니다.

### 수신 정책과 이력

수신자는 인증된 피어가 보낸 파일을 별도 승인 창 없이 자동 수신하고, 설정된 기본 수신 경로에 저장합니다. 현재 앱 범위에서는 수신 전 수동 승인 절차를 제공하지 않습니다. 전송 결과는 이력으로 남기며, 실패 원인, 상대 노드, 파일명, 크기, 시간 같은 진단 정보를 확인할 수 있도록 합니다.

## 포함 범위

- Flutter Desktop 앱
- 로컬 네트워크 노드 탐색
- UDP 기반 제어 및 데이터 전송
- 가입 없는 런타임 ID/PW 세션
- 인증된 peer 연결
- 단일 파일 및 다중 파일 전송
- 1:1 및 1:N 전송 구조
- 전송 큐, 진행률, 실패, 취소, 재시도 상태 관리
- 전송 이력과 로그
- macOS, Windows, Linux 지원을 고려한 구조

## 제외 범위

- 웹 애플리케이션
- 모바일 앱
- 중앙 웹 백엔드
- 외부 클라우드 저장소 연동
- 인터넷 원격 전송
- NAT traversal
- 조직 관리자 콘솔
- 실시간 공동 편집
- 파일 버전 관리

## 기술 스택

- Flutter Desktop
- Dart
- Riverpod
- Drift / SQLite
- UDP socket 기반 로컬 네트워크 통신
- 런타임 전용 password-derived JWT 인증
- 메모리 전용 credential 및 session key lifecycle
- 플랫폼 저장 경로와 권한 처리

자세한 의존성은 [pubspec.yaml](pubspec.yaml)을 기준으로 확인합니다.

## 플랫폼 지원 기준

- macOS: 현재 Flutter Desktop 빌드가 지원하는 macOS 릴리스 기준으로 검증합니다.
- Windows: Windows 10/11과 Visual Studio 2022 C++ toolchain 기준으로 검증합니다.
- Linux: Ubuntu 22.04 LTS를 최소 지원 기준으로 삼습니다. Linux 빌드와 릴리스 산출물은 Ubuntu 22.04에서 생성해 더 최신 glibc 또는 데스크톱 런타임에 실수로 의존하지 않도록 합니다.

다른 Linux 배포판도 GTK 3, libsecret, glibc, Flutter desktop 런타임 의존성이 동등하게 제공되면 동작할 수 있습니다. 다만 개발, CI, 릴리스 검증, 사용자 지원의 호환성 하한은 Ubuntu 22.04 LTS입니다.

## 프로젝트 구조

```text
lib/
  app/                 앱 구성, 라우터, 테마, AppConfig
  application/         유스케이스, 컨트롤러, 상태 조합
  core/                에러, 로깅 등 공통 기반
  domain/              엔티티, 도메인 서비스, 순수 규칙
  infrastructure/      UDP, 인증, DB, 파일 시스템, 플랫폼 구현
  presentation/        Flutter 화면과 위젯

test/
  application/         애플리케이션 계층 테스트
  infrastructure/      인프라 구현 테스트
```

이 저장소는 Layered Architecture와 Clean Architecture를 기준으로 유지합니다.

의존 방향은 다음과 같습니다.

- `presentation`은 `application`을 사용합니다.
- `application`은 `domain`을 사용합니다.
- `infrastructure`는 외부 시스템과 플랫폼 구현을 담당합니다.
- `domain`은 Flutter, Riverpod, Drift, UDP socket, 파일 시스템에 의존하지 않습니다.

## 상태 관리와 내부 절차

인증, 피어 탐색, 연결, 파일 전송, 재시도, 실패 복구처럼 절차와 상태가 있는 기능은 상태 머신을 기준으로 관리합니다.

상태 머신 적용 기준은 다음과 같습니다.

- 상태는 명시적인 enum, sealed class, 값 객체 등으로 표현합니다.
- 허용 가능한 전이와 불가능한 전이를 코드와 테스트로 고정합니다.
- UI 조건문이나 네트워크 콜백 안에 상태 전이 규칙을 흩어놓지 않습니다.
- 임의 boolean 조합으로 복잡한 절차를 관리하지 않습니다.
- 상태 전이에 따른 부작용은 계층 경계를 지켜 명시적으로 실행합니다.

계층 간 비동기 이벤트 전달이 필요한 경우 MessageBus를 사용합니다. MessageBus는 이미 발생한 사실을 알리는 이벤트 전달 장치이며, 명령 실행 경로를 숨기는 용도로 사용하지 않습니다.

## 설정 원칙

이 프로젝트는 외부 설정 파일에 의존하는 방식을 최소화합니다.

- 새 YAML, JSON, dotenv 파일을 쉽게 추가하지 않습니다.
- 런타임 중간에 환경 설정을 삽입하거나 변경하는 방식은 사용하지 않습니다.
- 외부 환경 상수는 프로세스 최초 부트스트랩 시점에만 받아들입니다.
- 부트스트랩 이후에는 명시적인 인자, 생성자 파라미터, provider override, 유스케이스 입력값으로 값을 전달합니다.
- 현재 앱 구성의 기준점은 `AppConfig`와 `bootstrap(config: ...)`입니다.

## 로그 정책

로그는 세 가지 목적 기준으로 나눕니다.

- Product: 프로덕트용 최소 로그. 사용자 영향이 있는 시작, 실패, 복구, 보안 이벤트 중심입니다.
- Debug: 현장 확인용 디버그 로그. 네트워크, 인증, 전송 상태 확인에 사용합니다.
- Development: 개발 및 테스트 중 상세 확인용 로그. 내부 상태 전이와 테스트 보조 정보에 사용합니다.

구현은 기존 `AppLogger`, `AppLogLevel`, `AppLogCategory`를 기준으로 합니다. 패스워드, 토큰, 파일 원문, 개인 식별 정보, 전체 경로처럼 민감한 값은 로그에 남기지 않습니다.

## 실행

Flutter SDK가 설치되어 있어야 합니다.

의존성 설치:

```sh
flutter pub get
```

데스크톱 실행:

```sh
flutter run -d macos
flutter run -d windows
flutter run -d linux
```

플랫폼별 실행 가능 여부는 로컬 Flutter 환경과 데스크톱 지원 설정에 따라 달라질 수 있습니다.

## 플랫폼 운영 및 문제 해결

Sponzey FileSharing은 discovery, control, data transfer에 UDP를 사용합니다. 플랫폼 문제는 OS별 프로토콜 분기가 아니라 플랫폼 경계에서 해결해야 합니다.

기본 UDP 포트:

- Discovery: `38400/udp`
- Control/auth: `38401/udp`
- Data transfer: `38410-38430/udp`

이 값이 `AppConfig`에서 변경되면 방화벽 안내와 smoke test 기준도 함께 변경해야 합니다.

### macOS

- 개발 중에는 `flutter run -d macos`로 실행합니다.
- 기본 수신 경로는 `~/Downloads/Sponzey FileSharing`입니다.
- 앱 지원 데이터, 로그, diagnostics export 파일은 `~/Library/Application Support/Sponzey FileSharing` 아래에 저장됩니다.
- 클릭 또는 키보드 입력이 늦게 반응하면 먼저 modal, 화면 전환 overlay, scroll cue가 입력을 가로채는지 확인합니다. 주요 버튼은 단일 클릭에 반응해야 하며 최소 48 logical pixel 이상의 데스크톱 hit target을 유지해야 합니다.

### Windows 런타임

- Windows Defender Firewall에서 Private 네트워크 기준으로 앱을 허용합니다.
- discovery 또는 transfer가 동작하지 않으면 설정된 UDP 포트를 명시적으로 허용합니다. 기본값은 discovery `38400/udp`, control `38401/udp`, data `38410-38430/udp`입니다.
- Windows VM에서 host/guest 간 discovery가 필요하면 bridged networking을 사용합니다. NAT 전용 VM 네트워크는 broadcast discovery를 막을 수 있습니다.
- 기본 수신 경로는 `%USERPROFILE%\Downloads\Sponzey FileSharing`입니다.
- 앱 지원 데이터, 로그, diagnostics export 파일은 `%APPDATA%\Sponzey FileSharing` 아래에 저장됩니다.

PowerShell 방화벽 예시:

```powershell
New-NetFirewallRule -DisplayName "Sponzey FileSharing UDP" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 38400,38401,38410-38430 -Profile Private
```

### Windows 개발자 모드와 symlink

Flutter desktop plugin은 Windows에서 symlink 지원이 필요합니다. 빌드 전에 개발자 모드를 켭니다.

```powershell
start ms-settings:developers
```

빌드는 `C:\Work\SponzeyFileSharing` 같은 로컬 NTFS 경로에서 수행하는 것을 권장합니다. Parallels 공유 폴더, 매핑 드라이브, 네트워크 드라이브에서는 Flutter 설치가 정상이어도 plugin symlink 생성이 실패할 수 있습니다.

### Linux Ubuntu 22.04 런타임과 빌드

Ubuntu 22.04 LTS를 Linux 최소 지원 기준으로 삼습니다.

빌드 의존성 설치:

```sh
sudo apt-get update
sudo apt-get install -y \
  clang \
  cmake \
  ninja-build \
  pkg-config \
  libgtk-3-dev \
  liblzma-dev \
  libsecret-1-dev
flutter config --enable-linux-desktop
flutter pub get
flutter build linux --release
```

Linux 수신 및 앱 데이터 경로:

- 기본 수신 경로: `XDG_DOWNLOAD_DIR`이 있으면 `$XDG_DOWNLOAD_DIR/Sponzey FileSharing`, 없으면 `~/Downloads/Sponzey FileSharing`
- 앱 지원 데이터, 로그, diagnostics export 파일: `XDG_DATA_HOME`이 있으면 `$XDG_DATA_HOME/Sponzey FileSharing`, 없으면 `~/.local/share/Sponzey FileSharing`
- 저장 실패가 발생하면 앱 설정을 바꾸기 전에 디렉터리 소유권과 쓰기 권한을 먼저 확인합니다.

### 플랫폼 Smoke 체크리스트

빌드를 플랫폼 준비 상태로 보기 전에 다음을 확인합니다.

1. 앱을 시작하고 ID/PW로 로그인합니다.
2. 로그인 입력창에 키보드 입력이 되고, 두 필드가 채워지면 로그인 버튼이 즉시 활성화되는지 확인합니다.
3. 주요 버튼이 단일 클릭에 반응하는지 확인합니다.
4. 의도한 네트워크 경로에서 peer discovery가 되는지 확인합니다.
5. 인증된 연결이 active route까지 도달하는지 확인합니다.
6. 작은 파일을 양방향으로 전송합니다.
7. 수신 파일이 기본 수신 경로 아래에 생성되는지 확인합니다.
8. diagnostics export를 생성해 route, auth, transfer, storage 상태가 포함되고 password, JWT, session key, file payload, 민감한 전체 경로가 포함되지 않는지 확인합니다.

## Windows 빌드

Flutter Windows 데스크톱 릴리스 빌드는 Windows 호스트에서 실행해야 합니다. macOS나 Linux 호스트에서는 `flutter build windows`가 지원되지 않습니다.

Windows 개발 장비 또는 Windows VM에서 다음을 실행합니다.

```bat
scripts\build_windows.bat
```

PowerShell을 직접 사용할 수도 있습니다.

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_windows.ps1
```

테스트를 생략하고 빌드만 확인해야 할 때:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_windows.ps1 -SkipTests
```

plugin symlink 또는 캐시 문제가 의심될 때:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_windows.ps1 -Clean
```

빌드 산출물은 다음 경로에 생성됩니다.

```text
build\windows\x64\runner\Release
```

Windows 빌드 사전 조건:

- Flutter SDK 설치
- Visual Studio 2022 Build Tools 또는 Visual Studio 2022 설치
- `Desktop development with C++` workload 설치
- Windows desktop support 활성화: `flutter config --enable-windows-desktop`

### Windows symlink 오류

다음 오류가 나면 프로젝트 위치와 Flutter/Pub cache 위치의 드라이브 또는 파일시스템이 맞지 않는 상태다.

```text
Creating symlink ... failed with ERROR_INVALID_FUNCTION
```

가장 안정적인 해결책은 프로젝트를 Windows 로컬 NTFS 드라이브로 옮기는 것이다. Parallels 또는 VMware 공유 폴더, 네트워크 드라이브, `X:\` 같은 매핑 드라이브에서는 Flutter plugin symlink 생성이 실패할 수 있다.

권장 위치 예시:

```bat
C:\Work\SponzeyFileSharing
```

그 뒤 Windows에서 다시 실행한다.

```bat
scripts\build_windows.bat
```

스크립트는 기본적으로 프로젝트 내부 `.dart_tool\pub-cache`를 `PUB_CACHE`로 사용해 `C:\Users\...\Pub\Cache`와 프로젝트 드라이브가 갈라지는 문제를 줄인다. 그래도 같은 오류가 나면 현재 드라이브가 symlink를 지원하지 않는 것이므로 프로젝트를 `C:\` 같은 로컬 NTFS 드라이브로 옮겨야 한다.

## 테스트

전체 테스트:

```sh
flutter test
```

특정 테스트:

```sh
flutter test test/application/transfer/transfer_controller_test.dart
```

기능 변경은 TDD를 기본으로 진행합니다.

1. 변경할 동작을 테스트로 표현합니다.
2. 실패를 확인합니다.
3. 최소 구현으로 통과시킵니다.
4. 중복, 이름, 계층 위반을 정리합니다.
5. 관련 테스트를 다시 실행합니다.

## 개발 문서

- [AGENTS.md](AGENTS.md): 이 저장소에서 반드시 지켜야 하는 개발 원칙과 에이전트 작업 규칙
- [plan.md](plan.md): 제품 요구사항, 아키텍처, 프로토콜, 단계별 개발 계획
- [.tasks/plan.md](.tasks/plan.md): 현재 구현 기준 멀티 Ethernet 연결 우선 안정화 계획
- [.tasks/phase001/README.md](.tasks/phase001/README.md): phase001 태스크 인덱스
- [.tasks/phase002/README.md](.tasks/phase002/README.md): 상태 머신, MessageBus, UDP 포트 분리 기준의 phase002 태스크 인덱스
- [.tasks/phase003/README.md](.tasks/phase003/README.md): 전체 멀티 Ethernet 인터페이스 지원 기준의 phase003 태스크 인덱스
- [.tasks/phase004/plan.md](.tasks/phase004/plan.md): peer 연결과 active path 안정화 계획
- [.tasks/phase005/plan.md](.tasks/phase005/plan.md): 고속 UDP Data channel 전환 기록
- [docs/release_gate.md](docs/release_gate.md): 릴리즈 게이트, 양방향 host/VM 전송 검증, benchmark 기록 양식

작업 태스크는 `.tasks`와 phase archive 디렉터리 아래에 정리되어 있습니다. 현재 연결 우선 계획은 `.tasks/plan.md`에 두고, 현재 실행 태스크는 `.tasks/task001.md`부터 `.tasks/task011.md`까지 사용합니다.

## 현재 개발 흐름

현재 안정화 흐름은 `.tasks/plan.md`를 기준으로 진행됩니다.

1. 제품 문서와 태스크 기준 정렬
2. peer identity, route candidate, route lease, self packet suppression 안정화
3. multi Ethernet discovery target과 packet receive decision 검증
4. 자동 인증과 연결 상태 머신 완성
5. active route lease와 Data transfer path 일치성 보장
6. 수신 경로, temp file, receiver preparation lifecycle 안정화
7. Data channel correctness, digest validation, throughput benchmark 검증
8. transfer UX, retry/cancel, persisted history 제품화
9. 안전한 redaction을 포함한 diagnostics export 제공
10. macOS, Windows, Linux platform behavior hardening
11. 양방향 host/VM 전송 검증을 포함한 release gate 적용

## 개발 기준

새 코드를 작성할 때는 다음 기준을 지킵니다.

- 도메인 규칙을 UI나 인프라 구현에 섞지 않습니다.
- 네트워크, 파일 시스템, 데이터베이스, 플랫폼 API는 인프라 계층에 둡니다.
- 인증되지 않은 peer가 전송 흐름에 진입하지 못하게 합니다.
- 전송, 인증, 탐색 상태는 상태 머신으로 표현합니다.
- 여러 컴포넌트가 알아야 하는 사건은 MessageBus 이벤트로 발행합니다.
- 외부 설정 파일보다 명시적 주입을 우선합니다.
- 로그는 목적과 수준을 구분하고 민감 정보를 기록하지 않습니다.
- 구현 후 변경 범위에 맞는 테스트를 실행합니다.

## 요약

Sponzey FileSharing은 로컬 네트워크 안에서 빠르고 안전하게 파일을 주고받기 위한 데스크톱 앱입니다. UDP의 낮은 지연을 활용하되 신뢰성 보강, 인증 경계, 상태 머신 기반 절차 관리, MessageBus 기반 이벤트 전달, 테스트 가능한 계층 구조를 통해 실사용 가능한 내부망 파일 전송 도구로 발전시키는 것을 목표로 합니다.
