# Release Gate

This document defines the release gate for Sponzey FileSharing. CI artifacts are
not enough to approve a release. A release is eligible only after real
bidirectional desktop transfer scenarios verify discovery, authentication,
TCP data session establishment, data transfer, receiver-side file persistence,
receiver digest, and diagnostics redaction.

## Release Rule

- CI build success only means artifacts were produced.
- GitHub Releases created from tag pushes remain draft until this gate is
  completed.
- Do not publish a final release when only the sender reports success.
- Do not publish a final release without receiver digest verification.
- Do not publish a final release without diagnostics export redaction review.
- Do not publish a final release if the same UID appears as more than one peer
  in the product UI.
- Do not publish a final release if route candidates or discovery refreshes
  replace an active TCP data session during transfer without an explicit
  disconnect, timeout, or socket failure.
- If any required scenario fails, hold the tag and keep the release draft.

## Required Local Commands

Run the local release gate command before tagging when possible:

```sh
scripts/task011_release_gate.sh
```

Minimum command set:

```sh
flutter pub get
flutter analyze
flutter test --concurrency=1 --reporter expanded
```

Platform build smoke:

- macOS host: `flutter build macos --release --dart-define=SPONZEY_APP_VERSION=<tag>`
- Windows host or Windows VM: `scripts\build_windows.ps1 -AppVersion <tag>`
- Linux Ubuntu 22.04: `flutter build linux --release --dart-define=SPONZEY_APP_VERSION=<tag>`

## GitHub Actions Artifact Check

After the desktop release workflow completes, verify these artifacts:

- `macos-release`: contains the macOS `.app` zip.
- `windows-release`: contains the Windows release zip.
- `linux-release`: contains the Linux bundle tarball built on Ubuntu 22.04.

Download each artifact from the workflow run before publishing the release. A
downloaded artifact must launch on the matching operating system before it is
used in manual transfer scenarios.

## Required Manual Scenarios

Each scenario must use the same ID/password group on both peers and must create
a diagnostics export on both ends after the transfer.

Each scenario must also prove the UID and TCP data session model:

- same UID appears as one peer in product UI, even when multiple network paths
  are discovered.
- route candidates remain separate from TCP data sessions in diagnostics.
- TCP data session must remain stable during transfer unless explicit disconnect, timeout, or socket failure occurs.
- port changes or additional discovery packets must not change the selected
  transfer target while the TCP data session is still connected.

| Scenario | Required result |
| --- | --- |
| macOS host to macOS second instance | discovery, auth, TCP data session, transfer, receiver digest |
| macOS second instance to macOS host | discovery, auth, TCP data session, transfer, receiver digest |
| macOS host to Parallels Windows VM | discovery, auth, TCP data session, transfer, receiver digest |
| Parallels Windows VM to macOS host | discovery, auth, TCP data session, transfer, receiver digest |
| macOS host to Ubuntu 22.04 | discovery, auth, TCP data session, transfer, receiver digest |
| Ubuntu 22.04 to macOS host | discovery, auth, TCP data session, transfer, receiver digest |

For VM scenarios, bridged networking is preferred. NAT-only VM networking can
block UDP broadcast discovery and is not a valid pass condition for the product
gate unless a documented route still completes discovery and transfer both ways.

## Diagnostics Export Review

For every scenario, confirm the diagnostics export contains enough context to
match the benchmark record:

- app version or tag
- OS and build mode
- peer id or safe peer label
- TCP data session id or safe session reference
- TCP data session state
- TCP data session direction
- TCP data session safe endpoint summary
- last close reason
- route candidate count
- TCP data session restart count
- selected route address family and route type
- transfer id
- sender final state
- receiver final state
- throughput and elapsed time
- diagnostics timestamp

The export must not contain:

- password
- JWT
- session key
- signing key
- reusable verifier
- file payload
- full sensitive local path

## Benchmark Template

Copy this table into `.tasks/release_runs/<tag>.md` for local records.
`.tasks/release_runs/` is intentionally local and ignored by Git; markdown task
and plan files under `.tasks` remain tracked. If a release is published, attach
or summarize the redacted result in the GitHub Release notes.

| Field | Value |
| --- | --- |
| app version/tag |  |
| source OS |  |
| target OS |  |
| source artifact |  |
| target artifact |  |
| route type | same host / VM bridge / wired LAN / other |
| same UID one peer | pass / fail |
| route candidate count |  |
| TCP data session id |  |
| TCP data session state |  |
| TCP data session direction | outbound / inbound |
| TCP data session stable during transfer | pass / fail |
| TCP data session restart count | 0 required unless explicit disconnect, timeout, or socket failure |
| last close reason | none required for successful transfers |
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

## Release Failure Handling

Hold the tag and keep the GitHub Release draft when:

- host to VM succeeds but VM to host fails
- same UID appears as multiple product peers
- route candidates overwrite an active TCP data session during transfer
- TCP data session changes during transfer without explicit disconnect,
  timeout, or socket failure
- sender completes but receiver digest is missing or failed
- receiver saved file cannot be found in the expected receive directory
- diagnostics export is missing or contains unredacted sensitive values
- only one platform artifact can be launched
- Linux artifact was not built on Ubuntu 22.04

Rollback criteria:

- If a published release is later found to violate this gate, immediately mark
  the release as prerelease or draft if possible, document the failed scenario,
  and create a corrective patch tag.
- Do not reuse or force-move a published tag. Create a new patch tag after the
  failure is fixed.
