# A4.3.2b — Encrypted checkpoint, token recovery and replay

**Status:** IMPLEMENTED, CI PENDING (2026-10-16). The storage mechanism is opt-in **localhost single-process development**, not a distributed Event Store or a production release.

## What is persisted

When configured with `GATEWAY_CHECKPOINT_DIR` and `GATEWAY_CHECKPOINT_KEY_B64`, an `EncryptedSessionStore` saves an authenticated AES-256-GCM checkpoint per anonymous token digest, written using a flushed temporary file followed by atomic rename on the same filesystem. The checkpoint includes the SHA-256 digest of the session token *only as its filename*, original expiry and limited quota counters, a privileged `GameTranscript` archive with a four-hand PBN and replayable validated Bridge Core events, and bounded request ID → payload fingerprint → previous successful filtered reply mapping. Raw bearer tokens are **never persisted**; clients must retain the original bearer until it expires. The key is supplied externally, not committed.

This store contains **highly sensitive PBN and hand state, encrypted at rest**. Backups, deployment key protection and proper filesystem permissions are not provided in this slice. Missing/incorrect keys, unsupported format or corrupt ciphertext abort startup (no silent empty-state fallback). All HTTP responses remain seat-filtered. `/v1/ai/decision` (the legacy route that trusts caller-submitted hands) responds 404 in durable mode; old in-memory loopback smoke remains backward compatible.

## Resume protocol and invariants

1. The service writes a new game checkpoint **before** issuing a fresh anonymous bearer token.
2. For a new action, save `pending={request_id, payload fingerprint}` before running the Bridge Core command.
3. `submitHuman` validates an expected event version and card/bid legality; save its result together with the completed response ledger in **one atomic encrypted checkpoint** before sending HTTP 200.
4. The bot runner uses `SinglePlayerCoordinator.runBots(afterCommittedAction: ...)`; checkpoint **after each validated bot event**, with pending request retained until all robot moves for that batch are finished.
5. If the worker stops or the connection breaks, the same `request_id` and original payload can resume an incomplete batch, based on its *restored event version*. It never replays a bot event already committed in the encrypted checkpoint. A completed request instead returns the exact cached reply.
6. Different ID while one request remains pending → 409 `pending_request`; changed payload for the same completed ID → 409 `request_id_conflict`; expired/wrong bearer → 401.

A storage error **fails closed** (503 `storage_unavailable`) and blocks further game actions in that instance instead of acknowledging an unpersisted committed action. Sessions are restored and their historical actions replayed via `GameTranscript.decode` and Bridge Core validation, rather than trusting arbitrary deserialized game state.

## Tests / evidence

- `services/bridge_gateway/lib/src/encrypted_session_store.dart`
- `services/bridge_gateway/lib/src/authoritative_game.dart`
- `services/bridge_gateway/test/encrypted_restart_test.dart`
- `cd services/bridge_gateway && dart pub get && dart analyze --fatal-infos && dart test --reporter expanded`
- Checks: ciphertext excludes four-hand PBN and bearer, same bearer/session/game version restored, successful ID reply exact match after restart, stale/conflicting IDs rejected, interrupted Bot after one committed event resumed without repeating it, wrong-key startup rejected, legacy caller-hand route disabled.

**Current test status: NOT RUN at document creation**. Test harness restarts a fresh Gateway service instance with a fresh store on the same localhost. Separately killing an OS process, fsync guarantees across storage drivers/power loss, multiple worker processes, token revocation, distributed locks, and transactionally durable quotas have not yet been verified.

## Boundaries and next gates

The previous 15-minute default token expiry still applies across restarts. In-memory rate-limit state for some endpoints and peer-IP issue windows are **not cluster-durable**. The store is per session and protected with a single-process lock; no replicated snapshots or stable shared-node persistence. The saved successful response cache is bounded at 128 IDs per session; eviction means old IDs are no longer replayable indefinitely. Thus this is **crash-recoverable local checkpointing**, not global exactly-once semantics.

Before public release: durable multi-process transaction coordinator, hardened storage/backup and key rotation, full 52-card true BEN Gateway game, licensed weights/cost/latency/operations, production HTTPS and device UX acceptance. User-deferred A3.5 and Android/iOS device UI QA stay on hold.
