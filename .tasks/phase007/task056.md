# Task 056. Remaining TransferController Responsibility Audit

## Goal

`TransferController`에서 이미 순수 규칙으로 분리한 부분과 아직 남아 있는 오케스트레이션 책임을 구분한다. 더 이상 작은 helper 추출로 억지 분리하지 않고, 다음 단계는 plan의 목표인 session runner/control-data dispatcher 경계 분리로 이동할 수 있도록 남은 책임 지도를 고정한다.

## Scope

- [x] 남은 private 메서드를 책임 유형별로 분류한다.
- [x] 추가 pure command 분리 후보와 과분리 금지 대상을 구분한다.
- [x] 다음 task에서 다룰 review 가능한 구현 단위를 정의한다.

## Current Extracted Pure/Application Boundaries

- [x] Control packet dispatch: `TransferControlPacketDispatcher`
- [x] Data frame dispatch: `TransferDataFrameDispatcher`
- [x] Direction-aware session registry: `TransferSessionRegistry`
- [x] Incoming chunk, finish, missing chunk, window, ACK retry scheduling decision commands
- [x] Outgoing ACK/NACK/window/retransmission/digest/route/data endpoint decision commands
- [x] Route validation commands for active route, remote data endpoint, local data bind endpoint, incoming route matching
- [x] Job list upsert, lookup update, metrics update, terminal status, event factory commands
- [x] Frame factory, frame trace mapper, endpoint label formatter, event id formatter, random hex formatter, log-safe formatter
- [x] Identity selection command

## Remaining Controller Responsibilities

### Provider, Bootstrap, and Facade Responsibilities

- [x] `build`, `start`, `sendFile`, `sendFiles`, `sendFileToPeers`, `cancel`, `loadHistory`, `frameDiagnosticsFor`
- [x] These methods still belong in the controller/facade layer until a dedicated `TransferFacadeController` is introduced.
- [x] Do not move provider reads into pure command objects.

### Control Packet Orchestration

- [x] `_onTransferInit`, `_onTransferInitAck`, `_onTransferCompleteAck`, legacy control ACK/NACK/window handlers
- [x] These handlers still combine packet parsing, authenticated session lookup, route context, state update, MessageBus event, and transfer context mutation.
- [x] Next split should move these to a `TransferControlPacketHandler` or session runner boundary, not another small static helper.

### Data Frame Orchestration

- [x] `_onDataStart`, `_onDataChunk`, `_onDataAck`, `_onDataNack`, `_onDataFinish`, `_onDataAbort`, `_onDataWindowUpdate`
- [x] These handlers still combine registry lookup, route guard, file writer/reader, ACK/NACK send, state update, and failure mapping.
- [x] Next split should introduce outgoing/incoming session runner classes with injected transports and file adapters.

### Timer and Retry Ownership

- [x] `_scheduleDataAckRetry`, `_scheduleMissingDataNackRetry`, retransmission scan scheduling, backpressure retry scheduling
- [x] Predicate rules are now extracted where safe.
- [x] Timer creation/cancellation must remain with the object that owns session lifecycle until session runners exist.

### File and Socket Boundary Calls

- [x] `_send`, `_sendDataFrame`, `_bindDataTransport`, `_prepareIncoming`, file reader/writer close/finalize paths
- [x] These are boundary calls and must not be moved into domain or pure application commands.
- [x] Next split should define interfaces for session runners and keep concrete implementations in infrastructure/providers.

### Private Context Classes

- [x] `_OutgoingTransferContext`, `_IncomingTransferContext`
- [x] These still hold mutable session runtime state, timers, file reader/writer, digest context, and route snapshot.
- [x] They should be replaced or wrapped by direction-specific runner state objects in the next phase.

## Additional Pure Extraction Candidates

- [x] No high-value pure extraction remains that can be done without making the design worse.
- [x] Further helper extraction inside packet handlers would mostly move lines without reducing coupling.
- [x] The next productive unit is not another formatter/command, but a runner boundary extraction with tests.

## Next Implementation Unit

- [x] Create `Task 057. Outgoing Transfer Session Runner Boundary`.
- [x] Scope should include only outgoing runtime state and outgoing Data frame send/retry loop.
- [x] It must start with tests around outgoing runner state transitions and injected transport/file reader fakes.
- [x] It must not move incoming writer or receive buffer logic.

## Validation

- [x] Document-only task. Runtime tests are not required by AGENTS.md because no production code changed in this task.
- [x] Latest runtime validation before this audit:
  - `flutter test test/application/transfer --reporter compact`
  - `flutter analyze`

## Done Criteria

- [x] Remaining controller responsibilities are classified.
- [x] Over-extraction risk is documented.
- [x] Next implementation task direction is explicit.
