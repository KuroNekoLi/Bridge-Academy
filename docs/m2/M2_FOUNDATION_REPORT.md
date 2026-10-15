# M2 Foundation — PlayerView and local Coordinator

**Stage:** M2-F01/M2-F02 implementation on feature branch. **Status:** ENGINEERING VALIDATION PENDING until GitHub Actions run. M2 overall is not complete.

## Completed scope proposed in this PR

- M2-F01: seat-filtered PlayerView, no privileged Deal/GameState archive in serialized DTO; each seat sees its own hand and public info, exposed dummy after opening lead. Only actual controlling player gets legalCards.
- M2-F02: local SinglePlayerCoordinator for one human and three BotPolicy seats, strict expectedVersion on human actions, Bot runner with action budget, stale/illegal proposal rejection. Internally the core remains authoritative.
- DeterministicTrainingBot is a legal test placeholder, **NOT BEN**. It opens 1NT when first actor, otherwise Pass and chooses first legal card.
- No Flutter UI, no real BEN adapter, no server authorization, no persisted game sessions in this slice.

## Tests added

- packages/bridge_core/test/player_view_test.dart — initial privacy, unexposed/exposed dummy, actor-specific legalCards, immutable collections.
- packages/bridge_core/test/single_player_coordinator_test.dart — bot/human handoff, all 13 tricks, Pass Out, stale/illegal action refusal, observer BotPolicy sees filtered view.
- Command: cd packages/bridge_core && dart pub get && dart analyze && dart test --reporter expanded
- **CI evidence:** NOT RUN at authoring time; update with actual run URL and result once GitHub Actions completes. Never infer from M1's earlier 30/30 pass.

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
