# M2 Foundation — PlayerView and local Coordinator

**Stage:** M2-F01/M2-F02 implemented and tested on feature PR #4. **Status:** FOUNDATION TEST GATE GO; overall M2 MVP IN PROGRESS (BEN and Flutter not yet integrated).

## Completed scope proposed in this PR

- M2-F01: seat-filtered PlayerView, no privileged Deal/GameState archive in serialized DTO; each seat sees its own hand and public info, exposed dummy after opening lead. Only actual controlling player gets legalCards.
- M2-F02: local SinglePlayerCoordinator for one human and three BotPolicy seats, strict expectedVersion on human actions, Bot runner with action budget, stale/illegal proposal rejection. Internally the core remains authoritative.
- DeterministicTrainingBot is a legal test placeholder, **NOT BEN**. It opens 1NT when first actor, otherwise Pass and chooses first legal card.
- No Flutter UI, no real BEN adapter, no server authorization, no persisted game sessions in this slice.

## Tests added

- packages/bridge_core/test/player_view_test.dart — initial privacy, unexposed/exposed dummy, actor-specific legalCards, immutable collections.
- packages/bridge_core/test/single_player_coordinator_test.dart — bot/human handoff, all 13 tricks, Pass Out, stale/illegal action refusal, observer BotPolicy sees filtered view.
- Command: cd packages/bridge_core && dart pub get && dart analyze && dart test --reporter expanded
- **CI evidence:** [Bridge Core CI #38673888504](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38673888504) executed on commit cb2d42687649ddea2d677739659a09a01ccb3972; Dart analyze step passed and **dart test 40/40 PASS** (10 new M2 test cases plus original 30). Original 100 seeded non-AI deal loop remains covered by M1 suite. [Feature Learning Gate #38673888302](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38673888302) PASS. Test run does not include real BEN or Flutter.

## Reliability of evidence
A follow-up code-style cleanup removed inherited M1 string-interpolation lint infos and tightened CI to `dart analyze --fatal-infos`. [Strict CI #38674228138](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38674228138) on commit 72733a63ded60b1fc3f4e7e3daa25a704d97bdf8 reports **No issues found!**, followed by **40/40 tests PASS**. This is a verified Dart rules/Coordinator result, not BEN AI or Flutter validation.

## Security limitations and next gates

1. A PlayerView contains per-seat secret cards by design; **a future HTTP/WebSocket handler must authenticate and authorize viewer seat**. Projector alone does not authenticate callers.
2. Bridge Core remains privileged; do not directly send GameState, GameTranscript or full PBN to a player or regular AI.
3. BotPolicy only sees PlayerView. The true BEN API might require additional context; resolve without sending unseen hands to an information-constrained Bot. Model API signature and correct information sampling need a separate BEN Adapter acceptance.
4. Local in-process state is not server-authoritative multiplayer infrastructure; no idempotency-key history or persistence exists yet.
5. Negative privacy tests in this PR prove DTO serialization for selected known deals; broader fuzzing, network proxy tests and logging redaction are later requirements.
6. A full Flutter single-player UI, bilingual i18n, accessibility, BEN runtime integration and target-device validation are still outstanding for M2.

## Feature learning evidence

- [M2-F01 teaching note](../learning/features/M2_F01_PLAYER_VIEW.md)
- [M2-F02 teaching note](../learning/features/M2_F02_LOCAL_COORDINATOR.md)
- [Feature Learning Index](../learning/INDEX.md)

Do not claim M2 MVP GO from this foundation slice.
