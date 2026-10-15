# M2-F10 — Fixed Training Board or Fresh Shuffled Deal

**Status when authored: IMPLEMENTED / CI NOT RUN.**

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

