# Phase A2.7 — Encrypted and transactional archive

**Initial status: IMPLEMENTED / CI NOT RUN.** Hardware testing is deferred until the larger product features are complete, as requested.

## Scope and architecture

Prior A2.2–A2.6 checkpoints were event-validated but saved all four hidden hands in plaintext SharedPreferencesAsync. Multi-key writes had no atomic SQL transaction.

A2.7 adds an Android/iOS backend using AES-256-GCM with per-write random nonce (cryptography), 256-bit key in platform secure storage (flutter_secure_storage), and encrypted current/previous generations in one SQLite row (sqflite). This row is replaced in one SQL transaction. The history is decrypted, authenticated and checked through SavedBoardCodec.decode and BridgeGame.apply before any restore.

App default chooses the native encrypted store for Android/iOS; Web retains SharedPreferencesAsync and is **NOT secure for production hidden-hand storage** until an independent browser threat model and storage implementation are approved. BridgeSession and PlayerView APIs stay unchanged.

A valid previous generation can be recovered only when the active authenticated box fails, with a durable player-consent warning that persists until explicit acknowledgment. Legacy plaintext checkpoints are migrated by validating the old archive, committing ciphertext, then clearing plaintext. A failure before commit retains legacy; failed plaintext deletion is not concealed.

## Automated gate matrix (initial NOT RUN)

| Test | Predicate | Status |
| --- | --- | --- |
| Confidentiality | Raw SQLite payload cannot contain dealPbn or user hand metadata | NOT RUN |
| Authenticity | Wrong 256-bit key / corrupt ciphertext cannot produce an accepted transcript | NOT RUN |
| Atomic commit | Simulated SQL replacement failure leaves previous committed game intact | NOT RUN |
| Rollback recovery | Previous valid generation restored; warning survives another restart and failed consent | NOT RUN |
| Legacy migration | Old plaintext only removed after encrypted commit; failed deletion retried | NOT RUN |
| Rule correctness | Fake but syntactically valid illegal transcript cannot enter store | NOT RUN |
| Flutter Web | Analyze, widget, release web and Chrome Demo regressions | NOT RUN |
| Physical Android/iOS | Secure key storage, native SQLite power loss / migrations | DEFERRED at user request |
| Real BEN and Web private-hand security | Production behavior on these platforms | NOT VERIFIED |

## Test command

From apps/bridge_academy_flutter: flutter pub get; flutter analyze; flutter test test/secure_checkpoint_test.dart; flutter test; flutter build web --release.

## Critical limitations

- Atomic SQLite row replacement protects against a **partial row commit**, not a power-failure guarantee measured on hardware, not cross-process CAS and not server-side anti-rollback.
- AES-GCM authenticated encryption prevents reading/tampering with database ciphertext without the key; compromised devices/processes may still inspect local memory.
- Losing Android Keystore/iOS Keychain key renders data undecryptable; restore/auto-backup policies and native release manifest still need final review.
- Browser local storage remains plaintext; Web users should be explicitly notified in a subsequent UI/security release feature.
- This is not a deployed BEN backend, anti-cheat server, multiuser system or consumer release approval.
- Package versions: cryptography ^2.9.0, flutter_secure_storage ^11.2.0, sqflite ^2.4.2. Dependency/OS support and native crypto behavior require later platform verification.

Files: apps/bridge_academy_flutter/lib/src/secure_session_persistence.dart, bridge_app.dart, pubspec.yaml, test/secure_checkpoint_test.dart.

## Evidence

NOT RUN at authoring. Attach exact GitHub Actions job URL, commit SHA, tests and outcomes before marking engineering verification. Do not reuse A2.6 Android CI as proof of the new encrypted storage.
