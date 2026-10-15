# M2-F11 — Terminal Deal History and Rule-Checked Playback

**Engineering gate when authored: IMPLEMENTED / CI NOT RUN.** Do not infer success from earlier Bridge Core transcript tests.

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
NOT RUN at creation. Update with actual GitHub Actions links and SHAs after execution.

## Limitations
Only the currently completed deal is kept in memory. The local single-player authority still holds all hands internally; this filtering is a client interface guarantee, not competitive server-side anti-cheat. Playing replay does not call BEN again or run new AI decisions.

