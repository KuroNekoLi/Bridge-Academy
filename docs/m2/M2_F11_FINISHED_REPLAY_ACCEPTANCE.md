# M2-F11 — Terminal Deal History and Rule-Checked Playback

**Engineering status 2026-10-15: M2-F11 CORE + FLUTTER WEB + REAL CHROME REPLAY GO.** Actual native Android emulator replay-touch QA remains separately PENDING.

## Scope
A player can review the **current finished deal** from event zero through all auction calls and public card actions, and inspect per-step trick progress, contract, last trick winner and final NS score. Buttons: First, Previous, Next and Last; zh-TW/en copy.

Persistent history, export, full-hand reveal, DDS, BEN re-evaluation and undo are out of scope.

## Trust boundary
- SinglePlayerCoordinator.completedReplay is null until the deal is terminal. While auctioning or playing, not even an event prefix is exported.
- For a terminal deal, reconstruct original event actions from GameState.start using the exact same authority BridgeGame.apply. Verify canonical event versions, historyFingerprint and score before publishing.
- Publish only an immutable CompletedReplay of ReplayFrame objects containing PlayerView.forSeat(history, authorizedHumanSeat) plus the **already-played** public action. Never return original Deal, privileged GameState, full PBN or GameTranscript.encode JSON to Flutter.
- Replay Flutter UI is read-only, cannot issue an old action, and resets when starting another game.
- Full-board PBN and hidden opponents' cards do not appear in the UI, even at the result screen. Fingerprint is non-cryptographic regression evidence, not authentication.

## Executable acceptance
1. During incomplete auction or ongoing play: completedReplay is null.
2. A genuine four-call Pass Out: five frames (start plus four chronological Pass calls); final score zero; no tricks.
3. A full game: four auction calls + 52 card actions + initial frame = 57 frames; every action version is preserved; exactly 13 completed tricks and matching score. North declarer / South Dummy retains actor-versus-hand-owner identity.
4. Independent BridgeGame.replay using the exact internal known fixture events produces the same history fingerprint and NS score.
5. Each snapshot is a filtered PlayerView: Dummy not visible until opening lead; original private four-hand map not serialized.
6. Flutter stepper: First/Previous/Next/Last labels and progress correct, Pass Out UI; reset to no replay on newGame; zh-TW/en.
7. CI for Core, Flutter tests/build, browser, BEN and Android remain separate; only directly executed checks may be called PASS.

## Reproduction
    cd packages/bridge_core
    dart analyze
    dart test test/completed_replay_test.dart
    cd ../../apps/bridge_academy_flutter
    flutter create --platforms=web --project-name=bridge_academy_flutter .
    flutter pub get
    flutter analyze
    flutter test test/completed_replay_test.dart
    flutter build web --release

## Evidence
Actual executed evidence:
- [Bridge Core CI #38692682476](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38692682476) PASS (44/44 tests including post-terminal Pass Out and full 52-card replay, version/fingerprint, Dummy privacy).
- [Flutter CI #38692937055](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38692937055) PASS: flutter analyze clean, 19/19 Flutter session/Widget tests including M2-F11, Web Release Build, previous Demo Chrome interaction regression. Tested source SHA ed856602ad6ea5a72121bbd1b2c853ed4afc3967.
- Initial Flutter CI #38692682306 FAILED analyzer/compiler because Flutter onPressed expects a void callback, not a returned Future<void>; source fix ed856602 removed the invalid return and Flutter CI went green. Initial separate Learning Gate #38692937032 flagged a source-only fix commit lacking matching lesson/index update; this evidence update is committed with the new browser/Android replay checks and the lesson/index in the same change set.
- **New replay browser click acceptance PASS:** [Flutter CI #38693616403](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38693616403), source SHA b380ba231b599b8ef0d6d2cf732499a2c8fb2d9b. 19/19 Flutter tests, analyze clean, Web Release Build PASS; genuine Chrome/ChromeDriver integration test explicitly clicked replay First → Next → Last after Pass Out, verified event steps and removal after restart.
- **Real BEN regression PASS:** [CI #38692937041](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38692937041), source SHA ed856602ad6ea5a72121bbd1b2c853ed4afc3967. Both real-BEN Chrome full-deal variants passed; not proof of replay clicks or AI strategy quality.
- **Android replay touch pending:** [Emulator CI #38693616421](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38693616421) still in progress when this report was written. Initial native run #38692682504 failed on the now-fixed Flutter callback compile error; no native replay pass can be claimed from that run.


## Limitations
Only the currently completed deal is kept in memory. The local single-player authority still holds all hands internally; this filtering is a client interface guarantee, not competitive server-side anti-cheat. Playing replay does not call BEN again or run new AI decisions.
