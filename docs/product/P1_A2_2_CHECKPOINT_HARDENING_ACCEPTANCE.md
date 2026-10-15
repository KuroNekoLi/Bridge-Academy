# Phase A2.2 — Two-slot checkpoint integrity and migration

**Initial status: IMPLEMENTED / CI NOT RUN (no release-ready durability or encryption claim).**

## Purpose

Existing Phase A2.1 already restores canonical GameTranscript and prevents bot progression after a failed write. The v1 adapter stores a SINGLE PLAINTEXT SharedPreferencesAsync string containing all 52 cards. This slice provides a reversible, failure-injectable two-slot commit protocol without changing BridgeGame, PlayerView, BEN Adapter or source-of-truth event data.

## Dataflow

\`BridgeSession\` → \`SessionArchiveStore.write(SavedBoardCodec.encode(...))\` → validate legal archive → write inactive v2 JSON envelope → SHA-256 check + Bridge Core replay → write \`v2.active\` marker last. The previously committed slot remains untouched. On startup, read active and validate; if corrupt, validate the other slot and repair pointer (may lose the last one committed event); never silently fabricate a legal move. If there is no marker, ignore orphan v2 data and migrate only a valid v1 checkpoint after a successful v2 commit.

Envelope version 2 is a **storage format** version; the canonical SavedBoardCodec and GameTranscript remain schema version 1. SHA-256 is a **checksum**, not authentication or encryption.

## Test matrix

| Gate | Assertions | At authoring |
| --- | --- | --- |
| Slot rotation | first commit A, second B, active marker only after a verified read-back | NOT RUN |
| Failed inactive-slot write | prior active slot and marker survive | NOT RUN |
| Failed marker write | complete pending slot remains uncommitted and ignored | NOT RUN |
| Torn but acknowledged write | read-back rejects before active marker update | NOT RUN |
| Corrupt active slot | fall back to prior legal state and repair marker | NOT RUN |
| Tampered legal metadata with recomputed SHA | SavedBoardCodec rejects invalid version/board and falls back | NOT RUN |
| Both corrupt | explicit FormatException, no restart fabrication | NOT RUN |
| First write interrupted | orphan unreferenced slot ignored | NOT RUN |
| Existing v1 migration | validate/replay, v2 commit, then remove v1 only on success | NOT RUN |
| Faulted migration | original valid v1 remains intact | NOT RUN |
| Clearing | all v1/v2 slots removed | NOT RUN |
| Full session resume | PlayerView/Board Number/expected version/fingerprint consistent and private | NOT RUN |
| Full Flutter analyze/tests, web build, Chrome/Android | no regressions | NOT RUN |

Test source: \`apps/bridge_academy_flutter/test/checkpoint_store_test.dart\`.
Commands: \`cd apps/bridge_academy_flutter && flutter pub get && flutter analyze && flutter test --reporter expanded && flutter build web --release\`.

## Remaining blockers: NOT PRODUCTION READY

- SharedPreferencesAsync is plaintext and not guaranteed fsync/durable on return. **No claim of encryption, crash atomicity, anti-cheat, user privacy against privileged local attackers or power-loss proof.**
- Independent reads/writes are not safe under two concurrent tab/process writers; the active marker is not a compare-and-swap.
- When active is corrupted, fallback may lose the newest event; a player-facing rollback warning is a future design task before release.
- Storage schema v2 adds *backward* migration from the original v1 single key; forward migration to future changes requires an explicit migration registry before launch.
- Fully transactional encrypted Android/iOS storage, secure-delete policy, Web support choice, real kill/relaunch and physical-device QA remain Phase A2 release gates; server-side idempotent AI calls remain Phase A4.
- No raw PBN/full-deck checkpoint is logged or projected to player/bot, but data does remain stored unencrypted on the local device.

## Evidence

Initially NOT RUN. Record new GitHub CI job URL/commit/test totals upon execution. Prior A2.1 Core 55/55, Flutter 28/28, Chrome and Android passes are historical evidence, NOT evidence of this new storage implementation.
