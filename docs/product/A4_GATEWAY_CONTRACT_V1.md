# A4.1 — Secure BEN Gateway Client Contract v1

**2026-10-16 | A4.1 MOCK CONTRACT VERIFIED | NO DEPLOYED GATEWAY**

## Trust boundary

```text
BridgeSession -> SinglePlayerCoordinator -> seat-filtered PlayerView
  -> BenBotPolicy -> BenGatewayTransport
  -> [A4.2 LOCAL DEV] anonymous bearer-capability Gateway on loopback, rate limits, restricted input
  -> [A4.3 FUTURE] private network Python BEN (/bid, /lead, /play)
  -> AI action proposal -> Bridge Core validates and commits action
```

The existing `BenTransport.get(route, input)` interface stays for compatibility; this Gateway implementation **actually makes POST requests**. The current app still uses local-development BEN GET, *not this new class*. No four-hand Deal or nonpublic opponent hands are available to the adapter.

## Proposed version 1 wire envelope (not a deployed API)

POST `https://<approved-origin>/v1/ai/decision`. Headers: `Authorization: Bearer <ephemeral-session-token>`, `Content-Type: application/json`, `Cache-Control: no-store`. Example (synthetic, not private player data):

```json
{"version":1,"route":"bid","input":{"hand":"AKQ.JT9.876.5432","seat":"N","dealer":"E","vul":"NS","ctx":"1N-P"}}
```

Route is one of `bid`, `lead`, `play`. `input` requires `hand`, `seat`, `dealer`, `vul`, `ctx`; `dummy` and `played` permitted only for `play`, and only when public, enforced by BenBotPolicy. Unknown fields and `deal` must fail before network request. Response: `{"version":1,"decision":{"bid":"PASS"}}`, or `decision.card` for lead/play.

Transport refuses non-HTTPS origins, embedded credentials, query/fragment/path, redirects, invalid fields, malformed JSON, unknown schema versions and responses over 32KiB. 401/403 → auth, 429 → rate_limit, other non-200 → sanitized http error, timeout → sanitized timeout. No raw response, bearer token, URL with private hand, or network error body in exceptions. No automatic retries.

## What A4.1 does not solve

- A4.2 provides a **loopback-only** Dart gateway and an anonymous 15-minute capability token; **deployed HTTPS, real identity/game-seat authorization, shared persistent sessions and a genuine BEN worker do not exist yet**. `GatewayAccessTokenProvider` is a dependency-injection seam, not an authentication implementation. Never put a shared secret or long-lived bearer token in Flutter/Dart defines, source or packaged assets.
- Future anonymous access (no required player account) still needs a **server-issued short-lived, scope-limited** credential and anti-abuse/rate limit. Authentication, seat/session authorization and request validation must be server-enforced on each request; UI checks alone do not prove secrecy. See [OWASP API Security](https://api-security.owasp.org/editions/2023/en/0x11-t10/).
- The future Gateway may use BEN's existing GET only **inside a trusted private network**; prevent raw URL/query logging, caching, proxy traces and public ingress. BEN GPL-3.0 / model weights / native binaries require separate documented rights analysis before hosted release.
- A POST transport does not provide exactly-once application. Server must define stable session+event version/request identity and durable deduplication/expected-version conflict semantics before automatic network retries.
- No p50/p95, hosting cost, availability, multiuser throughput or real BEN remote staging acceptance has been measured. Device UX tests and A3.5 remain owner-deferred.

## Executable contract tests

Source: `packages/bridge_ben_adapter/lib/src/ben_gateway_transport.dart`  
Tests: `packages/bridge_ben_adapter/test/ben_gateway_transport_test.dart`  
Run:

```bash
cd packages/bridge_ben_adapter
dart pub get
dart analyze --fatal-infos
dart test --reporter expanded
```

[Adapter CI #38833132162](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38833132162) on commit `11146d6` completed `dart analyze --fatal-infos` with **No issues found** and **23/23 package tests passed**, including the new gateway MockClient tests. These verify no hand/token in URL, private payload in POST body, no redirects, invalid route/field preflight, auth/token failure, 429/503 sanitization, oversize/bad JSON response and timeout. **These are not real BEN tests.** Keep existing pinned true BEN CI as a separate regression; no Flutter app transport switch in A4.1.

## Next delivery slices

**A4.2:** [Loopback gateway](../../services/bridge_gateway/README.md) implemented with token TTL, SHA-256 hashed in-memory sessions, bounded requests/CORS and real localhost HTTP integration tests; server game/seat identity verification, durable auth, public TLS and remote BEN are NOT provided. [A4.2 acceptance](A4_GATEWAY_A4_2_ACCEPTANCE.md).  
**A4.3:** Private BEN mediation, bounded queue, stable request identities, genuine pinned BEN integration and model/weights license review.  
**A4.4:** App uses production Gateway when configured securely; localized errors and recovery.  
**A4.5:** Staging/full product acceptance, latency/resources/cost/privacy checks and four seats/16 boards. A3.5 remains deferred and release-blocking.
