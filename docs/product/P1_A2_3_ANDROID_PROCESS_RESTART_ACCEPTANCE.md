# Phase A2.3 — Android process-restart checkpoint acceptance

**Initial status: IMPLEMENTED / ANDROID CI NOT RUN.** This is a real Android process-boundary QA step for already-existing A2.1/A2.2 checkpoint persistence. It does not add encryption, ACID/fsync durability, or real BEN request idempotency.

## Background

A2.1 verified SharedPreferencesAsync Android read/write in the same Flutter test process (CI #38724474457). A2.2 verified dual-slot checksums, generation commit markers and torn-write faults with an injected fake (Flutter CI #38727920768). Neither demonstrates actual restored state after a separate Android app launch.

## Test procedure

Workflow: .github/workflows/flutter-android-emulator.yml. Script: apps/bridge_academy_flutter/scripts/android_process_restart_e2e.sh.

1. Boot real Android 15 API35 x86_64 Emulator, build/install Flutter Android debug APK, execute existing Android table smoke test.
2. Separate first flutter drive: android_persist_prepare_test.dart clears test keys, starts Board 1 / North in Demo mode, bids 1NT, waits for robots to reveal South Dummy, plays a legal dummy card and asserts the saved event version matches the current unfinished game. Saves only expected version and nonsecret regression fingerprint in test-specific preferences.
3. Locate installed app package; run adb shell am force-stop (preserves app data) and verify no package process remains.
4. Separate second flutter drive: android_persist_restore_test.dart reads saved real Android SharedPreferences, validates the full GameTranscript through SavedBoardCodec/Bridge Core, restores a new BridgeSession, checks Board Number, version, fingerprint, public dummy, own hand and legal card. Launches the ordinary BridgeAcademyApp entry and checks automatic restored-game UI.
5. Plays the next legal card and verifies version strictly increases and the next checkpoint matches. Removes private checkpoint and test keys.

Expected CI marker: A2_3_ANDROID_REAL_PROCESS_RESTART_PASS.

## Acceptance matrix (all NOT RUN at initial publication)

| Gate | Predicate |
| --- | --- |
| Emulator | Real Android 15/ API35 and installed Flutter debug APK |
| Process boundary | Two independent flutter drive invocations, explicit Android force-stop |
| Initial commit | SavedBoardCodec event version = live PlayerView after dummy card |
| Restore | Same board/version/fingerprint, phase play, dummy and legal card restored |
| Privacy | PlayerView has no PBN/full hand; unfinished replay remains unavailable |
| UI | Normal BridgeAcademyApp boot displays restored board |
| Resume | Next card is legal; updated checkpoint version strictly increases |
| Regression | Existing device test, Flutter static analysis, and Web CI remain green |

## Reproduction

With Android emulator-5554 booted, from app directory:

    flutter create --platforms=android --project-name=bridge_academy_flutter .
    flutter pub get
    bash scripts/android_process_restart_e2e.sh

## Scope boundaries

The first flutter drive can exit the app before force-stop is issued. This exercise verifies retained data across **separate launches plus an explicit Android force-stop**, not killing an arbitrary Dart instruction during a pending fsync. No device shutdown, Android upgrade, app data purge, concurrent writer, iOS restart, physical device, or BEN HTTP exactly-once is proven.

The checkpoint currently stores all four hands in **plaintext** within Android application-private preferences: sandboxing is NOT encryption. Do not print raw PBN, HTTP URLs, private hands or transcript payloads. Test metadata contains only version and unsigned regression fingerprint.

Next release blockers: secure transactional storage choices per Android/iOS/Web, real kill-during-write lifecycle fault injection, rollback warning when old generation is recovered, mobile hardware QA and backend-mediated idempotent BEN requests. Treat this feature as engineering validation only until actual CI finishes.

## Verified non-device regression — latest implementation

- [Flutter M2 Single Player #38730229223](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38730229223): SUCCESS, SHA `824cc114a40759558340f9aecdacd2215271a3f5`. `flutter analyze` no issues; **42/42 widget and session tests PASS**; Flutter Web Release Build PASS; real ChromeDriver Demo E2E success.
- [Feature Learning Gate #38730229181](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38730229181): SUCCESS, same code SHA.
- [Android emulator cross-process #38730229216](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38730229216): RUNNING at this report update. Flutter's 42 tests do **not** prove real OS force-stop/restore; see final Android job result before marking A2.3 VERIFIED.
