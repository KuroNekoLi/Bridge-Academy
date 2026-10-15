# Bridge Core — M1

A pure Dart 3 library with zero production dependencies. No Flutter, BEN, DDS or network code.

## Getting started

    cd packages/bridge_core
    dart pub get
    dart analyze
    dart test --reporter expanded

## Public API

- GameState.start(deal, dealer, vulnerability)
- BridgeGame.apply(state, action) validates and returns immutable successor or throws RuleViolation.
- GameState.legalCards(owner) / actorToPlay / dummyExposed
- BridgeGame.replay(deal, dealer, vulnerability, actions)
- Deal.fromPbn / toPbn (4 hands, PBN S.H.D.C clockwise)
- DuplicateScore.score(contract, declarerTricks, vulnerability): signed NS perspective
- GameTranscript.encode(state) / decode(archive): versioned full-deal event archive

## Critical security boundary

GameState and GameTranscript contain ALL FOUR hands. Never send either directly to a player, a normal bot, or a public API response. M2 must add seat-specific projections and negative information-leak tests. The event fingerprint is deterministic but noncryptographic.

## What is deliberately not included

No BEN adapter, UI, localization strings, claims, concessions, irregularities, server matchmaking, IMP/MP, or tournament direction. Official WBF tournament-law compliance remains a separate review.

## Test status

GitHub Actions is the intended CI runner. Chat's local container lacks Dart SDK; do not claim static analysis or unit tests have passed until CI reports success on the exact commit.

