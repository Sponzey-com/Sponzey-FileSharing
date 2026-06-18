# Release Run Records

릴리즈별 수동 gate 결과는 이 디렉터리에 `<tag>.md` 형태로 기록한다.

이 디렉터리는 `.gitignore`에 의해 원격 저장소에는 포함되지 않는다. 공개 릴리즈에는 민감 정보가 제거된 요약만 GitHub Release notes 또는 별도 첨부 파일로 남긴다.

기록 기준은 [../../docs/release_gate.md](../../docs/release_gate.md)의 benchmark template을 사용한다.

## 작성 절차

1. 릴리즈 후보 tag 또는 version 이름으로 `<tag>.md` 파일을 만든다.
2. 아래 template을 복사해 macOS host -> Parallels Windows VM, Parallels Windows VM -> macOS host 방향을 각각 기록한다.
3. 각 방향에서 peer discovery, authentication, TCP data session 연결, file transfer, receiver digest, diagnostics export를 확인한다.
4. 실패가 있으면 실패 방향, TCP data session state, last close reason, diagnostics export filename을 남긴다.
5. Do not record passwords, JWTs, session keys, signing keys, reusable verifiers, file payloads, or full sensitive local paths.

## Required Smoke Directions

- macOS host -> Parallels Windows VM
- Parallels Windows VM -> macOS host

## Record Template

| Field | Value |
| --- | --- |
| app version/tag |  |
| smoke direction | macOS host -> Parallels Windows VM / Parallels Windows VM -> macOS host |
| source OS |  |
| target OS |  |
| source artifact |  |
| target artifact |  |
| same UID one peer | pass / fail |
| route candidate count |  |
| TCP data session id |  |
| TCP data session state |  |
| TCP data session direction | outbound / inbound |
| TCP data session stable during transfer | pass / fail |
| TCP data session restart count | 0 required unless explicit disconnect, timeout, or socket failure |
| last close reason | none required for successful transfers |
| file name | redacted basename only if needed |
| file size | 100 MB required for benchmark |
| average speed |  |
| peak speed |  |
| elapsed time |  |
| sender final state |  |
| receiver final state |  |
| receiver digest result | pass / fail |
| diagnostics export filename |  |
| diagnostics timestamp |  |
| notes |  |

## Pass Criteria

- 두 방향 모두 authenticated peer가 하나의 peer로 표시된다.
- TCP data session state가 전송 중 안정적으로 유지된다.
- TCP data session restart count는 성공 전송에서 0이다.
- receiver digest result가 pass다.
- diagnostics export에는 TCP data session state, direction, safe endpoint summary, last close reason이 포함된다.
- diagnostics export에는 password, JWT, session key, file payload, full sensitive path가 포함되지 않는다.
