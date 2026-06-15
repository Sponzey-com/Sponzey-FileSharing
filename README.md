# Sponzey FileSharing

[English](README.md) | [한국어](README.ko.md)

Sponzey FileSharing is a Flutter Desktop file sharing app designed for devices on the same local network to discover each other without an external server and transfer files quickly to authenticated peers.

This project is not just a simple file copy utility. It is intended to reliably handle repeated internal-network workflows such as device-to-device file distribution, test artifact delivery, log collection, and file sharing between office or lab machines.

The project explicitly targets environments where a single machine can have multiple active network paths at the same time. It should use every available Ethernet interface for peer discovery, connection establishment, and file transfer, including multiple physical NICs, USB Ethernet adapters, internal Ethernet bridge networks, and bridge-based internal networks exposed by virtualization environments.

## Core Goals

- Automatically discover nodes on the same local network.
- Open file transfer sessions only with peers authenticated through ID/password-based credentials.
- Provide a low-latency transfer experience over UDP.
- Add reliability on top of UDP by explicitly handling packet loss, duplication, retransmission, and timeouts.
- Support both 1:1 transfer and 1:N distribution.
- Use all available Ethernet interfaces as discovery, connection, and transfer path candidates.
- Target desktop environments on macOS, Windows, and Linux, with Linux support based on Ubuntu 22.04 LTS or newer.
- Stay focused on internal-network usage without depending on a central web backend or external cloud infrastructure.

## Use Cases

- Quickly sharing files among multiple PCs in the same office, lab, or classroom network.
- Repeatedly delivering build artifacts, logs, or configuration files between development and test machines.
- Sending files only to a specific user or device.
- Distributing the same file to multiple devices at once.
- Moving files only inside an internal network where external cloud upload is difficult or not allowed.
- Exchanging files with devices on different internal segments from a workstation that has two or more Ethernet cards.
- Exchanging files with devices connected through internal Ethernet bridge networks or virtualized bridge networks in addition to physical NICs.

## Main Features

### Node Discovery

Each app instance discovers other running nodes on the same network. The intended discovery result includes information such as user ID, device name, online status, last response timestamp, and protocol version.

Discovery is not designed around a single NIC. The project aims to scan all available Ethernet interfaces and manage discovery, control, and data paths separately per interface IPv4 candidate. That means a machine with two Ethernet cards, a motherboard NIC plus a USB NIC, or a test environment with an internal Ethernet bridge should treat each path as an independent connection candidate.

### Authentication-Based Connection

File transfer is allowed only to authenticated peers. The planned reference authentication model uses ID/password-based login and short-lived mutual authentication built on password-derived JWT tokens.

The authentication flow follows these rules:

- Do not require sign-up or local account creation in the current app scope.
- Keep passwords, password-derived JWTs, and session keys in memory only.
- Never store plaintext passwords.
- Never transmit sensitive data before authentication.
- Use short expiration, nonce, and `jti` in tokens.
- Create transfer jobs only within authenticated sessions.
- Automatically authenticate, connect, and receive between peers using the same ID/password group.
- Treat allowed-user lists, manual receive approval, and persisted credential verifiers as future extensions, not the current default path.

### UDP-Based File Transfer

The transfer transport is UDP. UDP is favorable for low connection latency and fast transfer inside local networks, but reliability has to be reinforced explicitly.

The transfer layer therefore handles:

- Packet loss
- Packet duplication
- Out-of-order delivery
- Retransmission
- Timeout
- Transfer cancellation
- Partial failure and retry

### Multi-Peer Connectivity and Transfer Queue

A single app instance acts as both sender and receiver and serves as a local endpoint capable of communicating with multiple peers at the same time.

Transfer work is managed as independent `transfer job` or session units so that state does not leak across multi-file transfer and 1:N distribution flows.

### Receive Policy and History

Receivers automatically accept files from authenticated peers and save them to the configured default receive directory. There is no pre-receive approval dialog in the current app scope. Transfer results should remain in history so that users can inspect diagnostics such as failure reason, peer node, filename, size, and timestamp.

## In Scope

- Flutter Desktop app
- Local network node discovery
- UDP-based control and data transfer
- Runtime ID/password session without sign-up
- Authenticated peer connection
- Single-file and multi-file transfer
- 1:1 and 1:N transfer structure
- Transfer queue, progress, failure, cancel, and retry state management
- Transfer history and logs
- A structure that accounts for macOS, Windows, and Linux support

## Out of Scope

- Web application
- Mobile app
- Central web backend
- External cloud storage integration
- Internet remote transfer
- NAT traversal
- Organization admin console
- Real-time collaborative editing
- File version management

## Tech Stack

- Flutter Desktop
- Dart
- Riverpod
- Drift / SQLite
- UDP socket based local network communication
- Runtime-only password-derived JWT authentication
- In-memory credential and session-key lifecycle
- Platform path and permission handling

Check [pubspec.yaml](pubspec.yaml) for exact dependencies.

## Platform Support Baseline

- macOS: desktop Flutter builds on currently supported macOS releases.
- Windows: Windows desktop builds on Windows 10/11 with the Visual Studio 2022 C++ toolchain.
- Linux: Ubuntu 22.04 LTS is the minimum supported baseline. Linux builds and release artifacts should be produced on Ubuntu 22.04 to avoid accidentally depending on newer glibc or desktop runtime versions.

Other Linux distributions may work if they provide equivalent GTK 3, libsecret, glibc, and Flutter desktop runtime dependencies, but Ubuntu 22.04 LTS is the compatibility floor for development, CI, release validation, and user support.

## Project Structure

```text
lib/
  app/                 app composition, router, theme, AppConfig
  application/         use cases, controllers, state composition
  core/                shared foundations such as errors and logging
  domain/              entities, domain services, pure rules
  infrastructure/      UDP, auth, DB, file system, platform implementations
  presentation/        Flutter screens and widgets

test/
  application/         application-layer tests
  infrastructure/      infrastructure implementation tests
```

This repository follows Layered Architecture and Clean Architecture.

Dependency direction:

- `presentation` uses `application`.
- `application` uses `domain`.
- `infrastructure` handles external systems and platform-specific implementations.
- `domain` does not depend on Flutter, Riverpod, Drift, UDP sockets, or the file system.

## State Management and Internal Procedures

Features with explicit procedures and lifecycle, such as authentication, peer discovery, connection, file transfer, retry, and failure recovery, are managed as state machines.

State machine rules:

- Represent state explicitly with enums, sealed classes, or value objects.
- Lock valid and invalid transitions in code and tests.
- Do not scatter transition rules across UI conditionals or network callbacks.
- Do not manage complex procedures with arbitrary boolean combinations.
- Execute side effects from state transitions explicitly while respecting layer boundaries.

When asynchronous cross-component event delivery is needed across layers, use MessageBus. MessageBus is for publishing facts that already happened, not for hiding command execution paths.

## Configuration Principles

This project minimizes dependence on external configuration files.

- Do not casually add YAML, JSON, or dotenv files.
- Do not inject or mutate environment settings in the middle of a running process.
- Accept external environment constants only at the initial bootstrap stage.
- After bootstrap, pass values only through explicit arguments, constructor parameters, provider overrides, or use case inputs.
- The current app composition baseline is `AppConfig` and `bootstrap(config: ...)`.

## Logging Policy

Logs are divided into three operational purposes:

- Product: minimal product logs for user-impacting start, failure, recovery, and security events.
- Debug: field-debug logs for checking network, authentication, and transfer state.
- Development: detailed logs used during development and testing for state transitions and test support.

Implementation should follow existing `AppLogger`, `AppLogLevel`, and `AppLogCategory`. Sensitive values such as passwords, tokens, raw file contents, personal identifiers, and full file paths must not be written to logs.

## Running

Flutter SDK must be installed.

Install dependencies:

```sh
flutter pub get
```

Run on desktop:

```sh
flutter run -d macos
flutter run -d windows
flutter run -d linux
```

Actual platform availability depends on the local Flutter environment and desktop support configuration.

## Platform Operations and Troubleshooting

Sponzey FileSharing uses UDP for discovery, control, and data transfer. Platform issues should be solved at the platform boundary, not by adding OS-specific protocol branches.

Default UDP ports:

- Discovery: `38400/udp`
- Control/auth: `38401/udp`
- Data transfer: `38410-38430/udp`

If these values are changed in `AppConfig`, firewall and smoke-test instructions must be updated at the same time.

### macOS

- Run with `flutter run -d macos` during development.
- The default receive directory is `~/Downloads/Sponzey FileSharing`.
- App support data, logs, and diagnostics export files are stored under `~/Library/Application Support/Sponzey FileSharing`.
- If clicks or keyboard input appear delayed, first check whether another modal, transition overlay, or scroll cue is intercepting input. Primary actions must respond to a single click and keep a desktop hit target of at least 48 logical pixels.

### Windows Runtime

- Allow the app through Windows Defender Firewall for Private networks.
- If discovery or transfer does not work, explicitly allow the configured UDP ports: discovery `38400/udp`, control `38401/udp`, and data `38410-38430/udp`.
- In a Windows VM, use bridged networking when host/guest discovery is required. NAT-only VM networking can block broadcast discovery.
- The default receive directory is `%USERPROFILE%\Downloads\Sponzey FileSharing`.
- App support data, logs, and diagnostics export files are stored under `%APPDATA%\Sponzey FileSharing`.

PowerShell firewall example:

```powershell
New-NetFirewallRule -DisplayName "Sponzey FileSharing UDP" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 38400,38401,38410-38430 -Profile Private
```

### Windows Development Mode and Symlinks

Flutter desktop plugins require symlink support on Windows. Enable Developer Mode before building:

```powershell
start ms-settings:developers
```

Use a local NTFS path such as `C:\Work\SponzeyFileSharing`. Avoid Parallels shared folders, mapped drives, and network drives for builds because plugin symlink creation can fail there even if Flutter itself is installed correctly.

### Linux Ubuntu 22.04 Runtime and Build

Ubuntu 22.04 LTS is the minimum Linux support baseline.

Install build dependencies:

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

Linux receive and app data paths:

- Default receive directory: `$XDG_DOWNLOAD_DIR/Sponzey FileSharing` when `XDG_DOWNLOAD_DIR` is set, otherwise `~/Downloads/Sponzey FileSharing`.
- App support data, logs, and diagnostics export files: `$XDG_DATA_HOME/Sponzey FileSharing` when set, otherwise `~/.local/share/Sponzey FileSharing`.
- If saving fails, confirm directory ownership and write permission before changing app settings.

### Platform Smoke Checklist

Before treating a build as platform-ready:

1. Start the app and sign in with an ID/password.
2. Confirm login fields accept keyboard input and the login button enables immediately after both fields are filled.
3. Confirm primary buttons respond to a single click.
4. Confirm peer discovery on the intended network path.
5. Confirm authenticated connection reaches an active route.
6. Transfer a small file in both directions.
7. Confirm the receiver writes the file under the default receive directory.
8. Create a diagnostics export and confirm it contains route, auth, transfer, and storage state without passwords, JWTs, session keys, file payloads, or full sensitive paths.

## Windows Build

Flutter Windows desktop release builds must be executed on a Windows host. `flutter build windows` is not supported from macOS or Linux hosts.

Run the following on a Windows development machine or Windows VM:

```bat
scripts\build_windows.bat
```

You can also run PowerShell directly:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_windows.ps1
```

To skip tests and only confirm the build:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_windows.ps1 -SkipTests
```

When plugin symlink or cache issues are suspected:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_windows.ps1 -Clean
```

Build output:

```text
build\windows\x64\runner\Release
```

Windows build prerequisites:

- Flutter SDK installed
- Visual Studio 2022 Build Tools or Visual Studio 2022 installed
- `Desktop development with C++` workload installed
- Windows desktop support enabled: `flutter config --enable-windows-desktop`

### Windows Symlink Error

If you see the following error, the project location and the Flutter/Pub cache location are on incompatible drives or file systems:

```text
Creating symlink ... failed with ERROR_INVALID_FUNCTION
```

The most reliable fix is to move the project to a local Windows NTFS drive. Flutter plugin symlink creation may fail on Parallels or VMware shared folders, network drives, or mapped drives such as `X:\`.

Recommended location:

```bat
C:\Work\SponzeyFileSharing
```

Then run again on Windows:

```bat
scripts\build_windows.bat
```

The script uses the project-local `.dart_tool\pub-cache` as `PUB_CACHE` by default to reduce problems caused by splitting `C:\Users\...\Pub\Cache` and the project drive. If the same error still occurs, the current drive likely does not support symlinks and the project should be moved to a local NTFS drive such as `C:\`.

## Tests

Run all tests:

```sh
flutter test
```

Run a specific test:

```sh
flutter test test/application/transfer/transfer_controller_test.dart
```

Feature changes should follow TDD.

1. Express the behavior as a test.
2. Confirm the failure.
3. Pass it with the smallest implementation.
4. Clean up duplication, naming, and layer violations.
5. Re-run the related tests.

## Development Documents

- [AGENTS.md](AGENTS.md): mandatory development principles and agent workflow rules for this repository
- [plan.md](plan.md): product requirements, architecture, protocol, and phased development plan
- [.tasks/plan.md](.tasks/plan.md): current connection-first plan for multi-Ethernet stabilization
- [.tasks/phase001/README.md](.tasks/phase001/README.md): phase001 task index
- [.tasks/phase002/README.md](.tasks/phase002/README.md): phase002 task index for state machines, MessageBus, and UDP port separation
- [.tasks/phase003/README.md](.tasks/phase003/README.md): phase003 task index for full multi-Ethernet interface support
- [.tasks/phase004/plan.md](.tasks/phase004/plan.md): peer connection and active path stabilization plan
- [.tasks/phase005/plan.md](.tasks/phase005/plan.md): high-speed UDP Data channel transition record
- [docs/release_gate.md](docs/release_gate.md): release gate, bidirectional host/VM transfer validation, and benchmark record template

Tasks are organized under `.tasks` and phase archive directories. The current connection-first plan is kept at `.tasks/plan.md`, with current execution tasks at `.tasks/task001.md` through `.tasks/task011.md`.

## Current Development Flow

The current stabilization flow follows `.tasks/plan.md`:

1. Align product documents and task standards.
2. Stabilize peer identity, route candidates, route leases, and self-packet suppression.
3. Verify multi-Ethernet discovery targets and packet receive decisions.
4. Complete automatic authentication and connection state machines.
5. Ensure active route leases and Data transfer paths match.
6. Stabilize receive paths, temp files, and receiver preparation lifecycle.
7. Verify Data channel correctness, digest validation, and throughput benchmarks.
8. Productize transfer UX, retry/cancel, and persisted history.
9. Provide diagnostics export with safe redaction.
10. Harden macOS, Windows, and Linux platform behavior.
11. Enforce release gates with bidirectional host/VM transfer verification.

## Development Standards

When writing new code, follow these standards:

- Do not mix domain rules into UI or infrastructure implementation.
- Keep network, file system, database, and platform APIs in the infrastructure layer.
- Prevent unauthenticated peers from entering transfer flows.
- Express transfer, authentication, and discovery lifecycle as state machines.
- Publish events that multiple components need through MessageBus.
- Prefer explicit injection over external configuration files.
- Separate log purpose and level, and do not record sensitive data.
- Run tests appropriate to the changed scope after implementation.

## Summary

Sponzey FileSharing is a desktop app for fast and secure file exchange inside local networks. It uses UDP for low latency while reinforcing reliability, enforcing authentication boundaries, managing procedures through state machines, delivering events through MessageBus, and preserving a testable layered architecture so it can evolve into a practical internal-network file transfer tool.
