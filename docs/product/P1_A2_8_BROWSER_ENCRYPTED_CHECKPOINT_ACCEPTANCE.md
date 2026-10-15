# Phase A2.8 — Browser Encrypted Checkpoint Integration

**Initial status (2026-10-15): IMPLEMENTED / NEW CI NOT RUN.**

## Scope and production boundary

A2.7 introduced native Android/iOS encrypted transactional SQLite, but Flutter Web continued to persist *all four private hands in plaintext* through SharedPreferences. This is a confidentiality regression risk even for ordinary single-player practice.

A2.8 reuses the already validated AES-256-GCM archive encoder/decoder on **Web**, with a WebCrypto-backed 256-bit key stored by `flutter_secure_storage` and a single encrypted SharedPreferencesAsync/LocalStorage **record**. Browser access requires HTTPS or localhost; if secure browser key support is absent, the save/restore operation **fails closed** and cannot silently use plaintext. On the first successful restore it migrates a valid old plaintext two-slot checkpoint to encrypted storage, committing ciphertext before removing legacy data.

Web is **not** SQLite. A single LocalStorage key update reduces inconsistent multi-key commits but does NOT prove fsync, ACID, cross-tab compare-and-swap, confidentiality against arbitrary same-origin JavaScript or compromised extensions. A browser-specific on-screen bilingual warning tells the user this. WebCrypto key material is browser/origin-bound and may become unrecoverable when the browser is reset; this is not portable backup. Official [flutter_secure_storage Web docs](https://pub.dev/documentation/flutter_secure_storage_web/latest/) call its Web implementation experimental and require HTTPS or localhost. [shared_preferences docs](https://pub.dev/packages/shared_preferences) explicitly do not promise crash-durable writes.

**Production release gate remains BLOCKED pending approved deployment security (HTTPS + CSP/HSTS + XSS audit), multi-tab concurrency policy, real device/backup testing and remote BEN idempotency.** Native encrypted SQLite strategy is unchanged, and physical Android/iOS QA remains deferred per owner's earlier decision.

## Implementation

- `apps/bridge_academy_flutter/lib/src/secure_session_persistence.dart`: BrowserSingleRecordArchiveStore with strict JSON/size parsing and a single encrypted record; EncryptedTransactionalSessionArchiveStore.browser() composes existing AEAD, legacy migration, fingerprint/Bridge Core validation and durable recovered-generation consent.
- `apps/bridge_academy_flutter/lib/src/bridge_app.dart`: default platform routing uses native SQLite encrypted storage on Android/iOS and encrypted browser store on Web. Never silently fall back to the old plaintext store in Web mode.
- `apps/bridge_academy_flutter/lib/src/app_copy.dart`: security limitation explained in zh-TW/en.
- `apps/bridge_academy_flutter/test/browser_encrypted_archive_test.dart`: five injectable-key/checkpoint tests for at-rest confidentiality, browser reopen, legacy cleanup, wrong-key refusal, durable rollback acknowledgment and PlayerView privacy.
- `apps/bridge_academy_flutter/integration_test/browser_table_test.dart`: real browser integration uses the **default app** and actual WebCrypto plugin, drives a completed board, verifies the browser persistence key contains no privileged plaintext, remounts a fresh App and checks restored result.

## Acceptance gates

| Evidence | Criterion | Initial status |
| --- | --- | --- |
| Dart / Flutter analyzer | No static or null-safety issues | NOT RUN |
| AEAD unit + browser preference backend | No dealPbn / hand metadata, wrong key refuses, migration and rollback | NOT RUN |
| Real Chrome WebCrypto | Default Flutter App writes ciphertext, new App instance restores; no fake key | NOT RUN |
| Web release | Compiles with federated WebCrypto plugin | NOT RUN |
| Existing BEN / Android regression | No regression to native or fixed-pinned real BEN | NOT RUN |
| Native hardware and SQLite | Actual device secure key, backup/wipe, kill-on-commit | DEFERRED |
| Security audit and multi-tab CAS | Same-origin XSS, malicious scripts, CSP/HSTS, concurrent tabs | NOT IMPLEMENTED |

**Gate transition:** Only mark scoped Web engineering VERIFIED after actual Actions results with SHA, not after tests are merely added.

## Commands

~~~bash
cd apps/bridge_academy_flutter
flutter pub get
flutter analyze
flutter test test/browser_encrypted_archive_test.dart
flutter test
flutter build web --release
# CI browser-chrome job executes integration_test/browser_table_test.dart
~~~

## Rollback

Revert A2.8 code commit (no changes to game rules). Browser encrypted records may then be inaccessible to old plaintext-only clients; do **not** downgrade encryption by exporting private hands into plaintext storage. Provide explicit migration/backward compatibility decisions for any production release.

