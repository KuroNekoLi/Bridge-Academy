# M2-F10 — Fixed Training Board or Fresh Shuffled Deal

**Status 2026-10-15: M2-F10 BRIDGE CORE + FLUTTER WEB ENGINEERING GO.** Android/native and shuffled-deal BEN quality testing are separate gates.

## Goal and boundaries
The Flutter app previously reused one synthetic deal for every game. M2-F10 preserves that training fixture and adds an explicit Fresh shuffled deal choice, independent of Demo/Live BEN opponent mode.

Bridge Core factory Deal.shuffled takes optional seed. When absent it uses Random.secure and when supplied it uses Random(seed) for same-toolchain deterministic tests. Builds 52 cards, shuffles, assigns 13 each, then validates all 52 unique with the existing Deal constructor. For exact cross-version replay, save toPbn output because a seed alone is not guaranteed to regenerate the same sequence on every Dart release.

BridgeSession.newGame now selects BoardMode.training (default for M2-F07/F09 real BEN fixture regression) or BoardMode.fresh. Test injection via freshDealFactory allows deterministic session/Flutter testing without a global random override. Flutter UI uses board_mode_selector with zh-TW/en strings. All views remain privacy-filtered PlayerView, not raw hands.

## Gates
- Pure Dart: 100 seeded deals must be unique, each with 52 different cards and 13 per seat, deterministic within runtime, exact PBN round-trip. Unseeded test validates card count.
- Flutter Session: default fixed PBN is unchanged; 2 injected fresh deals can be chosen; switching back to training restores the original hand; no other hands in PlayerView JSON.
- Flutter Widget: select Fresh via dropdown and click New Game; private North hand equals the injected 13 cards, Dummy remains hidden.
- Flutter analyze, widget regression, Web Release and Demo Chrome must remain PASS.
- Android emulator and true BEN are separate gates. No device or real BEN success is implied by shuffled local-game tests.

## Reproduction
From repository:
    cd packages/bridge_core
    dart test test/shuffled_deals_test.dart
    cd ../../apps/bridge_academy_flutter
    flutter create --platforms=web --project-name=bridge_academy_flutter .
    flutter pub get
    flutter analyze
    flutter test test/board_mode_test.dart
    flutter build web --release

## Security and limits
The user-visible Flutter board never exposes opponents' private cards. The local coordinator still internally owns all 52 cards and is not suitable for competitive multiplayer anti-cheat. Do not log or display whole-board PBN before terminal state. Fresh shuffling is a practice capability, not a claim of verifiable online fairness.

## Evidence
INITIAL: NOT RUN. Attach exact GitHub CI SHA and results after actual execution; never substitute existing M2-F07/F09 fixed-board BEN evidence.


## Actual CI evidence and regression fixes

- [Bridge Core CI #38690024308](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38690024308): **42/42 PASS**, includes two M2-F10 shuffled-deal tests (100 distinct deterministic seeds / 52 unique cards / 13 per seat / PBN round trip and unseeded board invariants). Code SHA 7ee9281c34ccfa5e8b1ed5b3f95a21817d8adae3.
- [Flutter CI #38690212528](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38690212528): **16/16 PASS**, flutter analyze no issues, Flutter Web Release Build PASS and actual Chrome Demo UI PASS. Includes two fresh-deal session/widget tests; SHA 0bf05e6861e0fb43e6c03f71f2aa65727e2a91db.
- [Feature Learning Gate #38690212485](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38690212485): PASS.
- Earlier Flutter CI #38690024287 caught an overly broad text matcher: two UI labels contained '不是 BEN' after localization update. Regression assertion was narrowed to the actual demo notice and the full suite passed.
- These successes do **not** demonstrate production anti-cheat, Android native APK, randomized BEN play quality or platform-independent PRNG-seed stability.

- Additional regression: [real BEN Chrome CI #38690024436](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38690024436) **SUCCESS** on the M2-F10 implementation commit. It replays the **fixed training fixture**, not a fresh shuffled board, and must not be cited as BEN-on-random-deal coverage.
