# A4.3.3 — Pinned BEN Full 52-card Gateway Game

**Date:** 2026-10-16 · **Status:** IMPLEMENTED / REAL BEN CI PENDING.  
**Acceptance target:** One fixed, deterministic, *genuine BEN neural-model* deal reaches 52 unique played cards, 13 completed tricks and an authoritative Bridge Core score through the **authenticated Gateway game API**. No mocks, Demo, arbitrary client-provided hands or Android/iOS device CI.

## Integration diagram

```text
Dart HTTP client (only public game actions, never a full Deal)
  -> POST /v1/sessions/anonymous -> short-lived, server-issued capability
  -> POST /v1/games/view -> filtered human PlayerView
  -> POST /v1/games/action -> 3NT opening / human PASS / legal card
  -> POST /v1/games/advance -> server-owned SinglePlayerCoordinator
    -> BenBotPolicy filtered for each acting seat
    -> BenLoopbackBackend GET on 127.0.0.1:8085 only
    -> pinned REAL lorserker/ben Python model
    -> returned proposal -> Bridge Core authoritative apply
  -> filtered human view, never privileged transcript or PBN
```

BEN uses pinned `lorserker/ben@72653ec1b5c17116faea229e9b975ea5622aa1f7`, Python 3.12, CI sample configuration. The fixed non-secret fixture `N-BRIDGEACADEMY-20261015` is the **same one already accepted by the native true BEN full-game regression**, but is injected into the trusted test Gateway using a `dealFactory`; clients are not permitted to specify `Deal`. North opens a synthetic 3NT for repeatability; all other seats' auctions, opening lead and legal play are genuinely decided by BEN, and the test client's North always chooses a legal card, not a trained agent. This verifies engineering integration, **not** bidding optimality or a competitive AI rating.

## Scope and asserted invariants

1. The first server view has `version=0`, human seat North, 13 own cards and **no exposed dummy**. No `deal`, `hands`, `dealPbn`, `transcript` or authorization token in any returned PlayerView.
2. Human auction and play POST with `expected_version` and unique `request_id`. BEN advances with its *own* server-side seat-filtered PlayerView; a batch must advance the authoritative version, not produce Demo moves.
3. Terminal `phase=finished`, contract present and `nsScore` populated. Exactly **13 completed tricks × 4 distinct hand owners**, exactly **52 distinct valid card codes**, four public hand counts all zero, no unfinished current trick, and `terminalVersion = auctionCount + 52`.
4. Genuine BEN has at least one successful request on each `bid`, `lead` and `play` route. Count/latency statistics summarize model calls but NEVER output raw BEN URL, hand, token, per-card sequence or original server exception.
5. Replaying the very first successful human `request_id` after game completion returns the identical recorded response **without incrementing the event version**; this is bounded in-memory repeat protection, not distributed exactly-once.
6. Error handling: any non-200 Gateway HTTP, timeout, illegal BEN card, incomplete/truncated board, missing score or invalid event projection fails the job. The runner reports only a safe stage name and HTTP status, not response or query secrets.

## Real CI and non-goals

- Main acceptance: `services/bridge_gateway/bin/live_gateway_ben_full_game.dart`.
- Runner: [ben-gateway-real.yml](../../.github/workflows/ben-gateway-real.yml). It reuses the already-installed pinned BEN dependencies and service within the same workflow job as the A4.3.1 three-route real-model smoke, avoiding a second lengthy BEN installation.
- CI command: `cd services/bridge_gateway && dart pub get && dart run bin/live_gateway_ben_full_game.dart`, with pinned local genuine Python BEN listening on `127.0.0.1:8085`.
- Independent Dart suite: `dart analyze --fatal-infos && dart test --reporter expanded`.
- **At document creation:** CI NOT RUN for this complete Gateway game. It must not be described as passed until the actual job finishes.
- CI fixture permits longer anonymous session TTL and more Gateway calls **only for this test**. The public/default config remains 15 minutes and per-token rate-limited. Real production capacity needs separate quotas, queue, TTL/reconnect and real-world sampling.

**Still OPEN:** Real end-to-end **encrypted persistence + full BEN game together** (A4.3.2b separately proved encrypted restart), partial-BEN mid-request kill, full multi-seed/seat/vulnerability/contract scenarios and pass-out/Double/Redouble, persistent transactional dedup over multiple servers, proper hosted TLS, BEN model-weights and GPL obligations, memory/CPU/RSS/cost/p95 SLO, cross-device UX and owner-deferred A3.5. A green 1-board full game is **SCOPED ENGINEERING VERIFIED**, not A4 Production Ready.

## Safe diagnostics

Failure log may include only which stage failed: bootstrap, initial-view, human-action, real-BEN-batch, end-state-validation or idempotency-replay. Do **NOT** upload BEN raw Python logs or print GET URLs, full four-seat PBN, request bodies or access tokens. Real-BEN CI job is a network call to localhost and a pinned third-party model, not a synthetic mock.

## Next

If the real full game passes, update the Roadmap and M2-F30 lesson with precise run ID, code SHA, deal/trick counts and non-sensitive request-count/latency metrics. Then tackle A4.4 Flutter integration and A4.5 staging security, durable topology and infrastructure cost only after reviewing unresolved release blockers; no Android/iOS device QA without explicit owner authorization.
