# Bridge Academy Gateway — A4.2 (local development only)

A runnable Dart HTTP gateway for **anonymous short-lived bearer sessions, HTTP request/response validation, in-memory throttling and safe decision proposals**. This is NOT a production BEN hosting solution.

## Quick start

```bash
cd services/bridge_gateway
dart pub get
dart analyze --fatal-infos
dart test --reporter expanded
dart run bin/serve.dart
```

By default it binds **127.0.0.1:8086 only**. The service refuses non-loopback addresses. Server-to-client requests on this loopback dev path are HTTP; **never expose the endpoint to any public network**. The future public gateway must terminate TLS/HTTPS using an approved reverse proxy and retain strict private upstream ingress. No app token, model or BEN process is bundled.

```bash
curl -i http://127.0.0.1:8086/healthz
curl -i -H "Content-Type: application/json" \
  -d '{"version":1}' http://127.0.0.1:8086/v1/sessions/anonymous
```

The second response issues `access_token` (Bearer), `expires_in:900` seconds and `scope:ai:decision`. Copy it into a development-only runtime variable and send via `Authorization: Bearer <token>` on `POST /v1/ai/decision`, using the [A4.1 v1 JSON envelope](../../docs/product/A4_GATEWAY_CONTRACT_V1.md). **The default backend intentionally returns 503 `upstream_unavailable`**, never a fake or Demo action; only test code injects a fake backend.

## Security model and limits

- Tokens: 256 bits from `Random.secure()`, stored **only as SHA-256 digests** in an in-memory session map. Expire after 15 minutes, and invalidate on process restart. No durable identity or meaningful player/seat ownership yet.
- Abuse throttling: default max 5 anonymous token issuances per real TCP peer IP per minute, max 1024 active sessions, max 30 decision requests per token/minute and one decision in flight per token. Do not trust arbitrary `X-Forwarded-For`.
- Schema: strict top-level keys `version/route/input`; `bid/lead/play` only, all known input fields are strings; only `play` accepts the extra exposed `dummy` and `played`. Hand syntax, card count (13), ranks and public played-card encoding are checked. Only `decision.bid` or `decision.card` can exit the backend.
- Privacy: 8KiB input limit; no-cache JSON; no untrusted browser Origin by default, explicit CORS allowlist for approved origins; only fixed safe error codes, no raw request body, BEN exception, token or private PBN in response/logs.
- Concurrency: current process limits one outstanding proposal per bearer token with 30-second timeout. Timeout does not forcibly cancel a remote BEN worker; A4.3 must implement bounded queues, cancellation/replay policy and durable idempotency.
- **Session credentials are capability quotas, not player/board authorization.** Anonymous callers can request unrelated legal-looking hands; this A4.2 prototype has no authenticated game/seat state to verify ownership. Do not deploy publicly until a server-authoritative session/deal binding is designed and tested, or the accepted anonymous-practice threat model explicitly limits guarantees.
- TLS is intentionally absent **inside loopback**, not optional for public traffic. CORS is not an access-control system. Reverse-proxy trust, public abuse protection, persistent store, signing rotation, coordinated restarts, multi-instance rate limiting and anti-DDoS must be addressed before hosting.
- No automatic retry, no private-hand GET request and no real BEN are implemented in A4.2. The shipped Flutter app still uses its existing path, and only A4.3 may add pinned internal BEN connectivity.

## Tests and rollout

The test suite binds a REAL `HttpServer` on ephemeral 127.0.0.1 ports and issues REAL localhost `HttpClient` HTTP requests. It injects a **stub backend** to check auth, expired tokens, CORS, rate limits, request allowlists, response shaping, concurrency and non-leaking failures. These are **not BEN model or Internet HTTPS tests**.

Workflow: [Bridge Gateway A4.2 CI](../../.github/workflows/bridge-gateway.yml). No Android emulator or physical Android/iOS UI/E2E. [A4.2 acceptance](../../docs/product/A4_GATEWAY_A4_2_ACCEPTANCE.md) and [M2-F26 teaching lesson](../../docs/learning/features/M2_F26_ANONYMOUS_GATEWAY.md).

## Next

A4.3: internal BEN adapter, request ID + event-version deduplication, real pinned BEN tests, deployment/weights rights and safe upstream timeout/cost controls. Do not wire these development tokens into a deployed Flutter app.
