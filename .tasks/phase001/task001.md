# Task 001 - Flutter Desktop 골격과 공통 기반 구축

## 목표

Flutter 데스크톱 앱의 실행 가능한 골격을 만들고, 이후 모든 기능이 얹힐 공통 구조를 확정한다.

## 연관 문서

- [README.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/README.md)
- [plan.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/plan.md)

## 선행 조건

- 없음

## 포함 기능

### 기능 1. Flutter 데스크톱 프로젝트 초기화

- macOS, Windows, Linux 타깃이 모두 활성화된 Flutter 프로젝트 생성
- 앱 엔트리포인트, 앱 설정, 실행 환경 분리
- 개발/릴리스 공통 런타임 초기화 구조 마련

### 기능 2. 앱 레이어 구조와 상태관리/라우팅 도입

- `lib/app`, `core`, `domain`, `application`, `infrastructure`, `presentation` 구조 생성
- `Riverpod` 기반 ProviderScope 초기화
- `go_router` 기반 화면 라우팅 골격 구성

### 기능 3. 공통 테마/로깅/에러 처리 기반 도입

- 데스크톱 UI용 기본 테마 및 공통 디자인 토큰 구성
- 로컬 로그 래퍼와 로그 카테고리 뼈대 추가
- 전역 예외 처리, 비동기 에러 캡처, 사용자 친화 오류 매핑 준비

## 구현 체크리스트

- [x] Flutter 프로젝트가 macOS, Windows, Linux 빌드 타깃으로 생성되어 있다.
- [x] 앱 실행 시 로그인, 대시보드, 피어, 전송, 설정 화면 골격이 라우팅된다.
- [x] `Riverpod` 초기화와 공통 Provider 등록 방식이 정리되어 있다.
- [x] 디렉터리 구조가 `plan.md`의 권장 구조를 따르도록 정리되어 있다.
- [x] 전역 로거 인터페이스와 로그 카테고리 enum 또는 상수 정의가 있다.
- [x] 전역 에러 핸들러와 사용자 메시지 변환 지점이 준비되어 있다.

## 산출물

- Flutter 데스크톱 프로젝트 베이스
- 앱 구조 문서 또는 코드 주석
- 기본 화면 스켈레톤
- 공통 로깅/에러 핸들링 코드

## 테스트

- [x] `flutter analyze`가 통과한다.
- [x] 기본 위젯 테스트로 앱 시작과 초기 라우트 렌더링을 검증한다.
- [ ] macOS에서 앱이 실행되고 기본 화면 전환이 동작한다.
- [ ] Windows에서 앱이 실행되고 기본 화면 전환이 동작한다.
- [ ] Linux에서 앱이 실행되고 기본 화면 전환이 동작한다.

## 검증

- [ ] 개발자가 각 플랫폼에서 앱을 직접 실행해 첫 화면 진입을 확인한다.
- [ ] 화면 전환 시 크래시 없이 라우터가 동작하는지 확인한다.
- [ ] 로그 파일 또는 콘솔 로그에 앱 시작 이벤트가 남는지 확인한다.
- [ ] 예외 강제 발생 시 사용자 메시지와 개발 로그가 분리되는지 확인한다.

## 완료 기준

- 후속 태스크가 공통 기반 변경 없이 바로 기능 개발을 시작할 수 있다.
- 3개 데스크톱 플랫폼에서 최소 앱 실행과 화면 골격 확인이 가능하다.

## 메모

- 이 태스크에서 UI 완성도를 높일 필요는 없다.
- 이후 태스크가 흔들리지 않도록 폴더 구조와 공통 의존성만 먼저 고정하는 것이 핵심이다.
- 2026-04-09 기준 이 작업에서는 `flutter analyze`, `flutter test`, `flutter build macos`까지 확인했다.