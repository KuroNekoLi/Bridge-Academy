# A4.3.1 — Private BEN Worker Boundary: Acceptance

**Date:** 2026-10-16 · **Status:** SCOPED HTTP + PINNED REAL BEN SMOKE VERIFIED · **no public deployment, game-seat authority or durable deduplication**

## Delivery scope

`BenLoopbackBackend` implements `GatewayDecisionBackend` and maps Gateway's sanitized `bid/lead/play` envelopes into BEN's existing GET endpoints **inside an IP-literal loopback process only**. `bin/serve.dart` requires explicit `BEN_INTERNAL_ORIGIN` opt-in; default remains `upstream_unavailable` 503. Response projection retains only `decision.bid` or `decision.card`, strips model metadata/debug, and delegates action legality to Bridge Core.

## Acceptance gates

| Gate | Required assertion | Evidence |
| --- | --- | --- |
| Outbound SSRF | Reject arbitrary DNS names, non-loopback IPv4/IPv6, credentials, paths/query/fragment, HTTPS scheme mismatch | `test/ben_loopback_backend_test.dart` |
| Privacy | The public Gateway response never echoes private hand, raw BEN URL/query, model internal metadata/errors | Worker real-localhost HTTP tests |
| Trust | The only outbound request is GET to explicit 127.0.0.1/::1; no proxy or redirects; no retry/fallback | Worker validation, mock BEN HTTP |
| Protocol | Gateway POST `bid/lead/play` projects exactly one `bid` or `card`, with early Dummy blocked | HTTP integration |
| Failure | Missing BEN, 302, malformed/oversize/error response, timeout sanitized and fail closed | Negative tests |
| Compatibility | A4.2 14/14 tests continue passing; Flutter and Core unchanged | Gateway CI |
| True model | BEN pinned source / actual model makes at least bid+lead+play proposals | **[Pinned true BEN smoke PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38837641285)**; bid, lead, play on genuine model; full game still open |
| Idempotency | Stable game/event request identity and repeat-safe committed action | **OPEN A4.3.2** |
| Ownership | Server-owned Deal and seat-authorized PlayerView, no trust in caller-supplied hand | **OPEN A4.3.2** |

## Exact executed engineering evidence (code commit 34851d2)

- [Gateway CI #38837641317](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38837641317): **SUCCESS**, Dart analyze no issues, **20/20 localhost Gateway + stub-BEN worker HTTP tests passed**.
- [Pinned true BEN Gateway CI #38837641285](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38837641285): **SUCCESS**; actual output `{"result":"PASS","realBen":true,"gateway":"POST","upstream":"GET_LOOPBACK","routes":{"bid":true,"lead":true,"play":true}}`. Exact BEN SHA `72653ec1b5c17116faea229e9b975ea5622aa1f7`, Python 3.12 on Ubuntu 24.04. No Demo/Mock substitution in this specific workflow.
- [Feature Learning Gate #38837642035](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38837642035): success.
- **This only accepts A4.3.1 as a scoped engineering slice**. Server-owned game/seat authorization, stable action identity and dedup, full 52-card Gateway gameplay, public TLS/hosting and device UX remain unverified.

## Limits and security decision

- The first-party server **still accepts a caller-supplied hand**. A valid anonymous token is a quota capability, **not game authority**. This design MUST NOT be treated as secure for ranked duplicate/multiplayer or exposed publicly until game-seat authorization, server-owned game state, expected event version and replay deduplication exist.
- BEN's upstream GET carries private cards as query parameters; it must stay on a trusted host with URL/request logging disabled. Do not dump the URL, Python BEN exceptions, model training fixtures or live hand payloads to CI logs/analytics.
- No hosting selected and no public TLS/auth/rate-limit cluster infrastructure. BEN license/model weight rights not release-reviewed. A3.5 and hardware device UI QA owner-deferred.
- Allowlist applies to networking, not to convention or bridge legality. BEN output is an **untrusted action proposal**; Bridge Core remains authoritative.

## Reproducible test and notes

```bash
cd services/bridge_gateway
dart pub get
dart analyze --fatal-infos
dart test --reporter expanded
# To opt in locally, start trusted BEN Python on 127.0.0.1:8085 separately:
BEN_INTERNAL_ORIGIN=http://127.0.0.1:8085 dart run bin/serve.dart
```

Tests don't need Python and use actual localhost sockets with a stub BEN. Full real BEN smoke now lives in [bin/live_gateway_ben_smoke.dart](../../services/bridge_gateway/bin/live_gateway_ben_smoke.dart) with a [dedicated CI workflow](../../.github/workflows/ben-gateway-real.yml), pinned `lorserker/ben@72653ec1b5c17116faea229e9b975ea5622aa1f7` and Python 3.12. **Real BEN result: SUCCESS** in [CI #38837641285](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38837641285), with true `bid`, `lead`, `play` responses; this is not a completed 13-trick Gateway game. The script makes independent bid, lead and play proposals through the actual anonymous-credential Gateway. It does not complete 13 tricks; the existing native true BEN regression remains distinct. The gateway never runs fake BEN in the default binary; tests use an explicit fake server.

**Rollback:** Remove `BenLoopbackBackend` export and `BEN_INTERNAL_ORIGIN` opt-in, keep A4.2 default 503. No change to Core/Flutter or device workflows.
