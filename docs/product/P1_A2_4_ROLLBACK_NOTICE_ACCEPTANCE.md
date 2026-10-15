# Phase A2.4 — Recovery notice for older checkpoint fallback

**Initial status: IMPLEMENTED / CI NOT RUN.** This is a local-prototype safety improvement, not encrypted or transactional persistence.

## Background

A2.2 uses dual slots with generation commit markers. If a committed slot is corrupt, it can recover exactly the immediately preceding committed generation after validating the full saved transcript through Bridge Core. That may lose a player action. Previously restoration was silent and the bot could immediately resume without informed player consent.

## Accepted behavior

- The new RecoveryAwareSessionArchiveStore exposes only a boolean indicating that the *most recent read* recovered an older generation. It contains no card/PBN data; ordinary SessionArchiveStore fakes remain compatible.
- Reset the flag on every read, set it true only **after** successful prior-generation validation and marker repair. Normal current reads and v1 migration never warn.
- BridgeSession does not auto-advance bot turns after rollback; calls to submitCall, submitCard and retryBots are blocked until explicit acknowledgment.
- Flutter renders localized zh-TW/en warning and confirmation button; disables legal actions while player reviews restored board. Player can also restart the board instead of accepting it.
- After acknowledgment, existing Bridge Core and Coordinator resume normal legal action processing. No synthetic event is created.

## Tests

1. Active current slot valid vs active corrupt, fallback exactly one generation with resettable provenance.
2. Human to move: version unchanged if action attempted without consent, pass button disabled, localized warning, legal Pass Out after consent.
3. Bot to move: no automatic actions before consent; afterward bot can progress to completed state.
4. Normal restore: no warning and active actions immediately enabled.
5. Existing complete test suite, analyze, Chrome Web release and Android emulator regression remain separate gates.

Code: apps/bridge_academy_flutter/lib/src/session_persistence.dart, bridge_session.dart, bridge_app.dart, app_copy.dart.
Test: apps/bridge_academy_flutter/test/checkpoint_recovery_notice_test.dart.

**Prior separate evidence:** Android A2.3 two-launch force-stop resume [#38731973367](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38731973367) SUCCESS.

## Remaining release blockers

SharedPreferencesAsync remains plaintext, not guaranteed fsync/durable, not cryptographically authenticated. No multi-process compare-and-swap, secure erase, physical-device power-loss testing or remote BEN HTTP exactly-once deduplication. A2 PRODUCT READY remains false.
