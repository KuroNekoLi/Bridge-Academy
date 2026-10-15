# Phase A2.6 — Android Three-Process Rollback-Consent Acceptance

**Initial status 2026-10-15: IMPLEMENTED / NATIVE CI NOT RUN.**
**Scope:** verify existing A2.5 durable recovery-consent rules on an actual Android API 35 emulator with app-private disk and real process death, not just in-memory widget tests. This is an acceptance-harness change, not a new storage engine.

## Scenario / invariant
1. **Process A** uses Android's real \`SharedPreferencesAsync\` backend. Write valid generation 1 in slot A (North human to call); write valid generation 2 in slot B (North Pass). Corrupt only active B slot. Leave active marker pointing to B, gen=2; do not call read/recovery before process death.
2. Shell confirms app is actually installed, \`adb shell am force-stop\`, confirms process absent. Keep app data (no \`pm clear\`, \`adb uninstall\` or reinstall wiping data).
3. **Process B** loads the saved game through the real store. It must detect B corruption, validate legal earlier A, repair marker to A/gen=1 with \`recoveryPending:true\`, show localized warning, disable Pass, and reject a programmatic Pass without changing version 0. It intentionally does not acknowledge.
4. Shell performs a **second independent Android force-stop** while preserving app storage.
5. **Process C** restores A/gen=1 again, proves warning still visible, executes actual UI "acknowledge" tap, verifies persistent \`recoveryPending:false\` and unchanged version=0. It then submits exactly one human Pass, waits for Demo's 3 actual bot Pass events, and checks terminal Pass Out at version=4, signed NS score 0 and durable final snapshot.
6. All displayed Flutter content is \`PlayerView\`, not \`GameTranscript\`. Raw checkpoint strings/private PBN are never printed by the test. Printed evidence is synthetic process marker only.

## Files / run
- \`integration_test/android_rollback_prepare_test.dart\` — process A
- \`integration_test/android_rollback_no_consent_test.dart\` — process B
- \`integration_test/android_rollback_confirm_test.dart\` — process C
- \`scripts/android_rollback_consent_e2e.sh\` — two explicit ADB \`am force-stop\` boundaries
- \`.github/workflows/android-rollback-consent.yml\` — isolated API 35 x86_64 KVM CI

From \`apps/bridge_academy_flutter\` with a booted Android emulator-5554:
~~~bash
flutter create --platforms=android --project-name=bridge_academy_flutter .
flutter pub get
bash scripts/android_rollback_consent_e2e.sh
~~~

**Required CI terminal evidence:** \`A2_6_PROCESS_A_COMMITTED_CORRUPTION_PASS\`, \`A2_6_PROCESS_B_UNACKNOWLEDGED_WARNING_PASS\`, \`A2_6_PROCESS_C_EXPLICIT_CONSENT_PASS\`, and \`A2_6_ANDROID_THREE_PROCESS_ROLLBACK_CONSENT_PASS\`. All three separate flutter drive invocations must PASS.

## Negative boundary and residual blockers
- This test deliberately corrupts a committed slot and uses a **legal single-generation fallback**. It does **not** prove hard power loss while active marker is being committed, fsync, malicious modification, filesystem encryption, or concurrent web tabs.
- Backend remains **plaintext SharedPreferencesAsync** with best-effort writes. SHA-256 checks accidental corruption, not authenticates content; production privacy, encryption, transactional store and cross-tab compare-and-swap remain **OPEN**.
- Demo Bot is deterministic; real BEN network retries, server idempotency, HTTP exactly-once and other platforms are outside this test.
- Existing A2.5 Flutter tests already proved logic in-memory, but do **not** substitute for this process-boundary execution. Do not mark success on workflow launch alone.
- **PRODUCT READY remains NO**. Next decision: production storage backend and threat model (native encrypted transactional + Web policy), then A3 UI.

