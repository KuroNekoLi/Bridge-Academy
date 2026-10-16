# A4.3.3 — Pinned BEN Full 52-card Gateway Game

**Date:** 2026-10-16 · **Status:** SCOPED ENGINEERING VERIFIED — pinned genuine BEN complete 52-card / 13-trick authoritative Gateway game.  
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
- **Executed evidence:** [True BEN Full Gateway #38845244764](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38845244764) **SUCCESS** on code commit [`c41cbf5`](https://github.com/KuroNekoLi/Bridge-Academy/commit/c41cbf5fdf7cd27af142c6a5b6f6d07ef1466f56). Original pinned BEN SHA `72653ec1b5c17116faea229e9b975ea5622aa1f7`, Python 3.12, Ubuntu 24.04, BEN dev CI sampling. The same job first printed genuine BEN `{"result":"PASS","realBen":true,...,"routes":{"bid":true,"lead":true,"play":true}}`, then printed the full-game `A4_3_3_REAL_BEN_FULL_52_CARD_GATEWAY_GAME` **PASS**.
- **Actual safe aggregate full-game metrics (one CI sample only):** tested final **6NT**, North declarer, dummy South, **auctionCount=6**, **13 tricks**, **52 unique cards**, **terminalVersion=58**, NS duplicate score **-250**, **28 human actions**, **25 bot advance batches**, **30 successful true BEN requests** (`bid:4`, `lead:1`, `play:25`), real BEN call p95 **996 ms**, max **2,129 ms**, complete game elapsed **10,737 ms**. These are CI-fixture measurements, NOT a stable capacity/SLO, not broad model-quality benchmarks.
- [Gateway CI #38845244822](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38845244822) **SUCCESS**, strict `dart analyze --fatal-infos` clean, **32/32 Dart/localhost tests PASS**; [Feature Learning Gate #38845244725](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38845244725) **SUCCESS**.
- CI fixture permits longer anonymous session TTL and more Gateway calls **only for this test**. The public/default config remains 15 minutes and per-token rate-limited. Real production capacity needs separate quotas, queue, TTL/reconnect and real-world sampling.

**Still OPEN:** Real end-to-end **encrypted persistence + full BEN game together** (A4.3.2b separately proved encrypted restart), partial-BEN mid-request kill, full multi-seed/seat/vulnerability/contract scenarios and pass-out/Double/Redouble, persistent transactional dedup over multiple servers, proper hosted TLS, BEN model-weights and GPL obligations, memory/CPU/RSS/cost/p95 SLO, cross-device UX and owner-deferred A3.5. A green 1-board full game is **SCOPED ENGINEERING VERIFIED**, not A4 Production Ready.

## Safe diagnostics

Failure log may include only which stage failed: bootstrap, initial-view, human-action, real-BEN-batch, end-state-validation or idempotency-replay. Do **NOT** upload BEN raw Python logs or print GET URLs, full four-seat PBN, request bodies or access tokens. Real-BEN CI job is a network call to localhost and a pinned third-party model, not a synthetic mock.

## Next

**Single fixed-board full-game PASS is now recorded.** Next phase is A4.4 Flutter Gateway integration and A4.5 staged security, durability topology and operating cost, after reviewing release blockers and public origin/credential configuration. Expand A4.3.3 coverage to multiple random board seeds, seats, vulnerability, strain, doubled/redoubled and PASS OUT. Android/iOS device QA and A3.5 remain owner-deferred.
