# A4.3.2 — Server-owned training game, versioned actions and in-memory dedup

**Status:** SCOPED ENGINEERING VERIFIED — 27/27 Gateway tests (2026-10-16)  
**Scope:** local-only anonymous-session game authority on Bridge Core. **Not** a public service, not crash-durable exactly-once, and not a multiplayer or ranked duplicate server.

## Trust boundary and endpoints

Unlike the old development-only POST `/v1/ai/decision`, these game-scoped endpoints do **not** accept a `hand`, `deal`, or `seat` from the caller. The authenticated session owns one server-generated `Deal.shuffled()`, fixed for the lifetime of the 15-minute anonymous token. Bridge Core's `SinglePlayerCoordinator` is the source of truth. Human seat is fixed North for the first slice; the other three seats use `BenBotPolicy` fed with a filtered server-side `PlayerView`.

| POST endpoint | Request | Response |
| --- | --- | --- |
| `/v1/games/view` | `{"version":1}` with Bearer | `{"version":1,"view":<PlayerView.toJson>}` |
| `/v1/games/action` | `{"version":1,"expected_version":0,"request_id":"action_001","action":{"kind":"bid","call":"1NT"}}` (or `{"kind":"play","card":"S2"}`) | `{"version":1,"request_id":"...","view":<filtered PlayerView>}` |
| `/v1/games/advance` | `{"version":1,"expected_version":1,"request_id":"bot_step_001"}` | Same filtered result, after coordinator has processed bot turns until the human can act |

The API **does not expose the full four-hand Deal, GameState, event transcript or arbitrary other-seat views**. The `action` object forbids seat/hand overrides; Bridge Core rejects illegal or out-of-turn cards and invalid auction calls. The BEN worker uses only the current acting seat's filtered `PlayerView`, not the caller's invented hand.

## Replay and failure behavior

- `expected_version` is enforced before applying new actions. Stale versions: 409. A `request_id` is 8–64 characters of `[A-Za-z0-9_-]`. Repetition of the **same ID, version and canonical payload** returns the successful cached result without executing again; reused ID with changed payload returns 409.
- A per-session busy guard rejects concurrent requests. Only 128 successful responses per game are cached, in memory. Anonymous sessions expire after 15 minutes and restart loses both game and response ledger. **This is not durable exactly-once**, multi-instance request coordination or end-to-end delivery confirmation.
- `advance` can commit multiple bot actions in a long-running call. On an interrupted/timeout process, call `/v1/games/view` to discover the actual server version; do not automatically blindly retry. Durable event persistence, cancellation and response recovery remain prerequisites for production.
- Existing raw `/v1/ai/decision` stays available only in the **local development gateway** for A4.1 compatibility. Since it accepts caller-supplied `hand`, it must be disabled/removed from any future production deployment. Its presence means A4 overall is still NOT production-ready.
- The game routes are still loopback HTTP. TLS/hosting, token abuse protection beyond in-memory quotas, account identity and authorized competition remain separate future work. A3.5 and Android/iOS device UI tests stay paused.

## Test boundaries

- `services/bridge_gateway/lib/src/authoritative_game.dart`
- `services/bridge_gateway/test/authoritative_game_http_test.dart`
- Execute `cd services/bridge_gateway && dart pub get && dart analyze --fatal-infos && dart test --reporter expanded`

HTTP tests assert no four-hand leak, other-seat injection fails, another token sees a different/version-0 game, idempotent bid, stale/conflicting replay ID, server-only BEN fields, exposed Dummy after opening lead, and unavailable upstream yields 503 without inventing moves. The suite uses a test-injected deterministic server Deal and fake BEN; **neither test data nor client API can set the live Deal**. The previously verified pinned BEN Gateway smoke remains [separate evidence](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38837641285).

## Executed engineering evidence

- Code commit: [5078599](https://github.com/KuroNekoLi/Bridge-Academy/commit/507859946d6e56c272b50d09568fbb61418c6975), test/lesson corrections [1de6bb5](https://github.com/KuroNekoLi/Bridge-Academy/commit/1de6bb5d706415d8e1563645ba0921c714f933d6).
- [Gateway CI #38839175287](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38839175287): **SUCCESS**, `dart analyze --fatal-infos` with **No issues found**, `dart test --reporter expanded` **27/27 PASS**. These consist of 14 prior A4.2 HTTP cases, six A4.3.1 private-loopback cases, and seven A4.3.2 server-authority/idempotency cases.
- [Feature Learning Gate #38839175164](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38839175164): **SUCCESS**; lesson delivered, not learner-mastered. Initial CI #38838997977 had one incorrect test assertion matching public seat-count text `N: 13` as if it were a four-hand PBN. Assertion now verifies that `deal` and privileged `hands` keys are absent, without weakening private-card checks.
- The previous independent [genuine pinned BEN Gateway #38837641285](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38837641285) verified bid/lead/play through A4.3.1. This latest A4.3.2 test suite uses a stub backend for its server-owned game-flow assertions. A combined complete 13-trick Gateway+real BEN game is **not yet verified**.

## A4.3.2b encrypted local recovery slice

Implementation is now in [A4.3.2b acceptance](A4_GATEWAY_A4_3_2B_ACCEPTANCE.md). The optional AES-256-GCM checkpoint (external 32-byte secret, atomic flush+rename) restores token digests/expiry, authority-owned full game transcript and request reply ledger. `afterCommittedAction` persists each Bot action; incomplete matching request ID resumes the remaining Bot batch, while a successful repeated ID uses the previously saved response. The legacy hand-submitting route returns HTTP 404 **only when encrypted persistent mode is enabled**, and is still accessible in old ephemeral loopback development smoke. Single-process local tests are pending; distributed exactly-once and cross-device acceptance remain blocked.

## Remaining requirements

A4.3.2b: durable session store and event/request replay, timeout recovery across restarts, explicit board identity and seat binding for future tables, production removal of the raw caller-supplied hand endpoint. A4.3.3: full 52-card Gateway play with pinned real BEN, backend memory/latency/cost and logging review. No public deployment before both, TLS authorization review and licensing of BEN/models.
