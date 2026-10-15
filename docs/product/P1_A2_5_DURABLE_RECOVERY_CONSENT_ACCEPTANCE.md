# Phase A2.5 — Durable rollback-acknowledgment marker

**Verified 2026-10-15: FLUTTER WEB ENGINEERING PASS.** [CI #38738604483](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38738604483) SUCCESS, 50/50 Widget/Session tests, Flutter analyze, Web release and Chrome Demo. Android and real BEN separate; no production durability/encryption claim.

## Problem

A2.2 may recover the immediately previous legally validated checkpoint if the active version is corrupt. A2.4 shows a warning and pauses the game, but **the consent flag only lived in BridgeSession memory**. On the second app launch, the repaired checkpoint looked normal, so the warning vanished and a pending robot turn could silently continue. This is a P0 player-trust and event-loss disclosure defect.

## Change boundary

- Keep the existing two-slot checkpoint design. Extend its **active commit marker** with an optional, boolean `recoveryPending`; legacy marker without the field remains compatible.
- When falling back to previous generation, record `recoveryPending: true` **in the same awaited pointer-repair write**. Subsequent reads of the now-valid older slot return `recoveredOlderCheckpoint = true` until explicit acknowledgment.
- `RecoveryAwareSessionArchiveStore.acknowledgeRecoveredCheckpoint()` rechecks the referenced legal slot and rewrites only the marker to `recoveryPending: false`. If that write fails, the persisted flag remains true and no actions may resume.
- `BridgeSession.acknowledgeRecoveredCheckpoint()` awaits store acknowledgment while the session is busy. Only after the durable-intent marker write succeeds will it clear `recoveryNeedsConfirmation` and resume robots. It catches errors without logging privileged transcript data or calling BEN.
- User explicitly choosing **New Game** is an opt-in abandonment of the recovered board; the new checkpoint commit resets the marker. This is distinct from implicit auto-recovery.
- No new serialization of hidden hands into Flutter, no changes to BridgeGame or AI strategy, no new third-party dependency. A2.5 does not itself provide disk fsync guarantees.

## Acceptance matrix

| Gate | Predicate | Initial |
| --- | --- | --- |
| Old A2.4 read semantics | Corrected test: flag **persists** after repeated read, until acknowledged | NOT RUN |
| Second launch without consent | New store + new BridgeSession instance after rollback still show warning and block calls | NOT RUN |
| Failed acknowledgment | Inject commit marker setString failure: warning and game version preserved across another launch | NOT RUN |
| Invalid marker | Non-boolean recoveryPending rejected; does not bypass safety | NOT RUN |
| Explicit new board | Player chooses restart: new checkpoint supersedes old warning, with correct Board metadata | NOT RUN |
| Regression | Flutter analyze, full tests, Web build and real Chrome Demo | NOT RUN |
| Actual Android process kill | Separate A2.3 verified process boundary **before** this change; no A2.5 kill between warning and consent yet | NOT RUN |

Source: apps/bridge_academy_flutter/lib/src/session_persistence.dart, bridge_session.dart.
Test: apps/bridge_academy_flutter/test/checkpoint_recovery_notice_test.dart.
Reproduce:
~~~bash
cd apps/bridge_academy_flutter
flutter pub get
flutter analyze
flutter test test/checkpoint_recovery_notice_test.dart
flutter test
flutter build web --release
~~~

## Security and limitations

The marker update is awaited and checked for exceptions, but **SharedPreferencesAsync is neither encrypted nor an fsync-committed transactional database**. No crash during marker write, concurrent tabs, malicious local manipulation, iOS hardware restart, or remote BEN HTTP exactly-once has been proven. Existing SHA-256 checksum detects accidental corruption, not forgery.

A2 PRODUCT READY remains **NO**. Next work should choose a properly transactional/encrypted native store (with Web policy) and verify upgrade / migration and kill-during-write behavior before release. Do not hide unfinished save-state issues by claiming this marker provides crash-atomic guarantees.

## Actual CI evidence

[Flutter CI #38738604483](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38738604483) **SUCCESS** on SHA 8de76f78521db8c06dbd574a55798a11b5c8cc8a (original implementation 3456ed5): Flutter Analyze No issues found, **50/50 tests PASS**, Web Release Build PASS, actual Chrome Demo integration PASS. Initial CI #38738342220 failed an analyzer nullable-receiver complaint; fixed using Dart 3 pattern binding. The code-only fix triggered a mandatory lesson/index gate, addressed in this documentation commit. [Android #38738604625](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38738604625) and [real BEN #38738604472](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38738604472) were still running at this documentation update.

## Additional current-commit regression (verified)

- [Real BEN Chrome #38738604472](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38738604472) **SUCCESS**, implementation SHA `8de76f78521db8c06dbd574a55798a11b5c8cc8a`: real pinned Python BEN service started, both existing Flutter Chrome cases passed (full game and BEN declarer controlling Dummy). This is an existing **fixed-board** regression, not actual corrupted-checkpoint recovery against BEN.
- [Feature Learning Gate #38739357350](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38739357350) **SUCCESS**, docs/lesson follow-up SHA `73ae9f8df26eaee30fb6b8de801cd7d7d50f9388`.
- [Android emulator #38738604625](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38738604625) **RUNNING** at this report update; even a successful general Android UI regression does not yet constitute a dedicated two-process rollback-and-consent test.
