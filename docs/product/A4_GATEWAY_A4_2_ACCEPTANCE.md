# A4.2 — Anonymous Session Gateway: Scoped Acceptance

**Date:** 2026-10-16 · **Status:** IMPLEMENTED / CI PENDING · **No deployed service, real BEN connection or production authentication**

## Goal

Provide a reproducible **loopback-only** Dart service compatible with the A4.1 HTTPS Gateway POST JSON envelope. The gateway must issue high-entropy, short-lived anonymous bearer credentials, validate submitted credentials on each decision, impose per-peer and per-session limits, enforce request allowlists, and return only sanitized public proposal fields. **Default AI backend is unavailable (503).** Testing replaces only the backend implementation, not the real HTTP transport.

## Endpoints

| Method/route | Purpose | Behavior |
| --- | --- | --- |
| `GET /healthz` | Loopback process readiness | Nonsecret `{"version":1,"status":"ready"}`; not BEN readiness |
| `POST /v1/sessions/anonymous` | Mint anonymous bounded capability | JSON `{"version":1}`; token random 256-bit, SHA-256 stored in process memory, TTL 15m, no-cache, scope ai:decision |
| `POST /v1/ai/decision` | Authenticate then validate request and proxy proposal | Bearer token, A4.1 envelope; rate limit, one in-flight per token; fake only in tests, default 503 |
| OPTIONS approved API + Origin | Explicit CORS preflight | Allow only configured trusted browser origin, no wildcard; not a security substitute |

## Required engineering checks

1. Loopback-only binding, no accidental public `0.0.0.0` path, not HTTPS in local process; public deployment still BLOCKED.
2. Token distinctness, expiration/invalid token, nonsecret SHA-256 token storage, no credentials in URL/error. Runtime state intentionally volatile.
3. Per-peer bootstrap window (not spoofable via X-Forwarded-For), bounded live session count, per-token decision quota and in-flight guard.
4. No full `Deal` or unexplained opponent-hand field; `dummy` + `played` only on `play`, requiring typed string fields, 13-card PBN-like notation and modest body limits.
5. Backend failures and malformed proposals fail closed, never return private PBN/error detail/headers; no Demo fallback.
6. Real localhost server HTTP integration tests with fake decision backend; they **do not** prove a real BEN model nor legitimate ownership of a player's hand.
7. Dart static analysis and full local suite via [CI](../../.github/workflows/bridge-gateway.yml); no Android or iOS device UI tests.

## Trust limitations (P0 future gates)

Anonymous token presence is not authenticated user or seat/board authorization. No privileged Bridge Core game state resides in this gateway. No payment, account, player binding, persistent session authority, redis-backed quotas, multi-instance fairness, public TLS infrastructure, replay deduplication, remote action identity, upstream BEN worker isolation, model/weights audit, p50/p95 or hosting budget acceptance is provided. The two HTTP endpoints can be reached only via localhost if the development server is running; a remote Flutter App cannot use them through A4.1 until authenticated HTTPS deployment and A4.4 integration.

**A3.5 remains explicitly owner-deferred; Android emulator and Android/iOS physical UI/E2E remain OFF**. A4.2 CI, even green, cannot waive those gates.

## Actual evidence

- Code: `services/bridge_gateway/lib/src/gateway_service.dart`
- Tests: `services/bridge_gateway/test/gateway_service_test.dart`
- Run: `cd services/bridge_gateway && dart pub get && dart analyze --fatal-infos && dart test --reporter expanded`
- CI: PENDING, update after execution with exact commit SHA, test count and failures.
- Old A4.1 [23/23 adapter MockClient PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38833132162) remains separate.

## Rollback

Remove the new `services/bridge_gateway` and its workflow if a new backend design supersedes it. Nothing in Flutter/Bridge Core/BEN adapter or existing device workflows was replaced by this slice.
