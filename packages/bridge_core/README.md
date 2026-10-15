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

GitHub Actions executed on commit 5833d681442c7dfec4b99c94919875e78ffaaf2d (Dart 3.13.5, dart analyze PASS, dart test 30/30 PASS). One test contains 100 deterministic complete non-AI deals. Evidence: https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38671869760 . The Chat container still lacks Dart SDK; this is an actual CI result, not an in-chat run.

