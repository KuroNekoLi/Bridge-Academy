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

[Gateway CI #38836219472](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38836219472) **SUCCESS**: Dart analyze clean, 14/14 true localhost HTTP integration tests on code SHA `20630994482b684452a2fdf355c62efef1d20f35`. This is not remote HTTPS or real BEN acceptance.

The test suite binds a REAL `HttpServer` on ephemeral 127.0.0.1 ports and issues REAL localhost `HttpClient` HTTP requests. It injects a **stub backend** to check auth, expired tokens, CORS, rate limits, request allowlists, response shaping, concurrency and non-leaking failures. These are **not BEN model or Internet HTTPS tests**.

Workflow: [Bridge Gateway A4.2 CI](../../.github/workflows/bridge-gateway.yml). No Android emulator or physical Android/iOS UI/E2E. [A4.2 acceptance](../../docs/product/A4_GATEWAY_A4_2_ACCEPTANCE.md) and [M2-F26 teaching lesson](../../docs/learning/features/M2_F26_ANONYMOUS_GATEWAY.md).

## Next

A4.3: internal BEN adapter, request ID + event-version deduplication, real pinned BEN tests, deployment/weights rights and safe upstream timeout/cost controls. Do not wire these development tokens into a deployed Flutter app.


## A4.3.1 private BEN loopback worker (explicit local opt-in)

Run the pinned BEN Python API on the SAME machine bound to `127.0.0.1:8085`, then opt in:

```bash
cd services/bridge_gateway
BEN_INTERNAL_ORIGIN=http://127.0.0.1:8085 dart run bin/serve.dart
```

The new `BenLoopbackBackend` performs GET `/bid`, `/lead`, `/play` **only over IP-literal loopback**, after the first-party Gateway has authenticated and allowlisted the POST envelope. It rejects DNS hostnames (even `localhost`), remote IPs, credentials, redirects, errors and oversize bodies; errors are sanitized. Unset `BEN_INTERNAL_ORIGIN` to retain the prior default 503. The Worker makes proposals, never commits a Bridge Core action.

The working model is **local development only**, NOT an Internet-enabled BEN service. The caller currently supplies a hand without a game/seat binding; anonymous credentials are not full player authorization. Server-owned Bridge Core game state, expected event version, request deduplication, public HTTPS deployment and BEN license/cost reviews remain required.

See [A4.3.1 acceptance](../../docs/product/A4_GATEWAY_A4_3_1_ACCEPTANCE.md) and [M2-F27 lesson](../../docs/learning/features/M2_F27_BEN_LOOPBACK_WORKER.md).

### Genuine pinned BEN Gateway smoke (separate from stub tests)

[Workflow](../../.github/workflows/ben-gateway-real.yml) checks out `lorserker/ben@72653ec1` with Python 3.12, starts its genuine gameapi.py on loopback, then runs [live_gateway_ben_smoke.dart](bin/live_gateway_ben_smoke.dart) against the **actual BEN model**. The smoke obtains an anonymous Gateway token and executes one bid, one opening lead and one exposed-dummy play; it logs only success flags, never request URLs, hands or raw BEN output. This is not a complete 13-trick test, seat authorization or hosted HTTPS validation. The existing separate live BEN full-game tests remain the longer regression gate. [Real BEN Gateway CI #38837641285](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38837641285) **SUCCESS**: pinned genuine BEN bid, lead and play via Gateway POST / internal loopback GET; [localhost CI #38837641317](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38837641317) 20/20 PASS. Neither is a complete game or public service.

## A4.3.2 authoritative single-player HTTP slice

Anonymous credentials now own one server-random Bridge Core `SinglePlayerCoordinator`; no client-provided Deal, seat or hand is accepted at `POST /v1/games/view`, `/v1/games/action`, or `/v1/games/advance`. The human seat is server-selected North for this slice. The view endpoint returns only `humanView.toJson`. Human actions carry `expected_version`, an 8–64 character `request_id`, and only an auction call or played card. Identical successful requests are cached; conflicting IDs or stale versions fail with HTTP 409. Bot advancement is server-controlled and derives the acting seat PlayerView, not a browser-supplied hand.

[A4.3.2 Gateway CI #38839175287](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38839175287) passed 27/27 localhost HTTP tests and strict analyzer; [Feature Learning Gate #38839175164](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38839175164) passed. Still no durable replay, public hosting or full real BEN Gateway game.

**No production claim:** in-memory token/game lifecycle (15 min), 128-entry response ledger, no crash-durable exactly-once, no server-side resume, no multiuser seat ownership and no public deployment. The legacy raw `/v1/ai/decision` remains **development-only** and must be disabled for any Internet deployment. [Acceptance](../../docs/product/A4_GATEWAY_A4_3_2_ACCEPTANCE.md), [M2-F28 lesson](../../docs/learning/features/M2_F28_SERVER_GAME_AUTHORITY.md).

## A4.3.2b encrypted durable restart (explicit local opt-in)

Enable checkpoints **only on a trusted local machine**, with an external 32-byte random key that is never printed or committed:

```bash
export GATEWAY_CHECKPOINT_DIR="/path/outside/repository/private-gateway-sessions"
export GATEWAY_CHECKPOINT_KEY_B64="$(openssl rand -base64 32)"
dart run bin/serve.dart
```

**Keep the same key across restarts**. Store the key separately from ciphertext using a proper secret manager in any future deployment; resetting the key intentionally makes previously saved sessions unreadable and the Gateway refuses startup rather than silently creating new games. Local HTTP is loopback only, with no production TLS. This is not an instruction to expose the process to the Internet.

The state is AES-256-GCM encrypted per token-digest checkpoint, flushed to a temporary file before a same-directory rename. Token hashes, expiry, Bridge Core event archive and bounded successful request ledger are restored on startup; the client must still possess the unexpired bearer token. Each Bot action is saved before the next, allowing an interrupted advance request to be resumed with **the same original request ID and payload** rather than repeating already committed events. In durable mode the legacy raw `POST /v1/ai/decision` is disabled (404), unlike the existing ephemeral-mode development API.

Known limits: single-process local lock, no cross-machine replicated store, no power-loss directory fsync certification, no crash-durable peer-IP bootstrap quota, no key rotation or backups, and no 13-trick real BEN Gateway acceptance yet. [A4.3.2b acceptance](../../docs/product/A4_GATEWAY_A4_3_2B_ACCEPTANCE.md), [M2-F29 learning note](../../docs/learning/features/M2_F29_ENCRYPTED_GATEWAY_RESTART.md).
