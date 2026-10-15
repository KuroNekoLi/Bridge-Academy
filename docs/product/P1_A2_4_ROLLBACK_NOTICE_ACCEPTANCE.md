# Phase A2.4 — Recovery notice for older checkpoint fallback

**Status 2026-10-15: A2.4 FLUTTER WEB ENGINEERING VERIFIED.** Not encrypted or transactionally durable. Android A2.4 device CI is separate and was still running at this report update.

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

## Executed acceptance evidence

- [Flutter CI #38736272456](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38736272456) **SUCCESS** on SHA `d31ab7c71cfc1f53bbe035b539d036d49200da2d`: `flutter analyze` No issues found; **46/46 widget/session tests PASS**, including all four new A2.4 recovery cases; Web Release Build success and actual Chrome Demo end-to-end test success.
- [Feature Learning Gate #38736272610](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38736272610) SUCCESS.
- [Real BEN fixed-board Chrome regression #38735974943](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38735974943) SUCCESS on feature implementation SHA `47dcd6150afab4db16c3721d2700514fc9097ce6`. Existing real BEN scenarios are fixed-deal regression, not a corrupt-save recovery/in-flight HTTP deduplication test.
- [Android emulator #38735974846](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38735974846) was IN PROGRESS at this documentation update; A2.4's four new adversarial tests currently ran in Flutter CI, not on Android hardware.
- Initial Flutter CI #38735974861 failed one *test scrolling* assumption when the warning card pushed the Pass button offscreen. Fix commit `d31ab7c` uses WidgetTester.ensureVisible before the real Pass tap; rerun fully passed. Game logic was not weakened.
- **Follow-up (A2.5) implemented, CI pending:** [durable rollback consent report](P1_A2_5_DURABLE_RECOVERY_CONSENT_ACCEPTANCE.md) adds a `recoveryPending` marker so a second restart cannot silently clear the warning. Previous A2.4 CI does not prove A2.5. Encrypted/transactional storage and concurrency protections remain separate release blockers.
