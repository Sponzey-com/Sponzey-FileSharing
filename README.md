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
- Target desktop environments on macOS, Windows, and Linux.
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

- Never store plaintext passwords.
- Never transmit sensitive data before authentication.
- Use short expiration, nonce, and `jti` in tokens.
- Create transfer jobs only within authenticated sessions.
- Apply access control based on allowed users and device policies.

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

Receivers can automatically accept files or require approval depending on policy. Transfer results should remain in history so that users can inspect diagnostics such as failure reason, peer node, filename, size, and timestamp.

## In Scope

- Flutter Desktop app
- Local network node discovery
- UDP-based control and data transfer
- Local account creation and login
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
- Local secure storage
- Argon2id based password hashing
- JWT based authentication tokens

Check [pubspec.yaml](pubspec.yaml) for exact dependencies.

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

Tasks are organized under `.tasks/phase001`, `.tasks/phase002`, and `.tasks/phase003`. The current cross-phase connection-first plan is kept at `.tasks/plan.md`.

## Current Development Flow

phase001 follows this sequence:

1. Build the Flutter Desktop skeleton and shared foundations.
2. Build local account, settings storage, and secure storage.
3. Implement UDP node discovery and the peer list UI.
4. Implement password-derived JWT mutual authentication and allowed user policy.
5. Implement the single-file transfer MVP and receive pipeline.
6. Reinforce UDP reliability, retransmission, and performance measurement.
7. Implement multi-file transfer, 1:N transfer, and queue management.
8. Improve receive policy, history/logging, and settings screens.
9. Stabilize platforms, packaging, and beta verification.

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
