# Architecture v0.1 — boundaries first

## A4.1 optional secure Gateway Client boundary (2026-10-16)

```text
SinglePlayerCoordinator -> filtered PlayerView -> BenBotPolicy
                                  -> Dev BenHttpTransport (BEN GET; dev only)
                                  -> BenGatewayTransport (HTTPS JSON POST v1)
                                     -> [NOT DEPLOYED] Auth/rate-limited Gateway
                                     -> [NOT DEPLOYED] Private BEN Python service
Bridge Core validates all proposed moves before commit.
```

A4.1 is a reversible interface seam, **not wired into the default Flutter app**. The new transport requires HTTPS, no embedded credentials/URL query, injected ephemeral bearer provider, route and field allowlist, sanitized errors, no redirects/automatic retry and capped response. It cannot protect against a compromised server or issue its own credentials. Future A4.2 must issue short-lived anonymous credentials, validate authorization and rate limits server-side; A4.3 isolates BEN's old private-hand GET within the private network and implements stable dedup/version semantics. See [wire contract](product/A4_GATEWAY_CONTRACT_V1.md) and [MockAdapter CI 23/23](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38833132162). **No production hosting or BEN service is now available. A3.5 remains owner-deferred and device QA remains disabled.**

## A4.2 local-only first-party Gateway boundary (2026-10-16)

- Dart `services/bridge_gateway` exposes `GET /healthz`, `POST /v1/sessions/anonymous` and `POST /v1/ai/decision` on **127.0.0.1** by default; non-loopback bind is rejected. Local HTTP is not public TLS; any public reverse proxy needs a separate security decision/implementation.
- Issues 256-bit `Random.secure()` anonymous bearer capabilities; stores SHA-256 hashes in process memory, TTL default 15 minutes, no account requirement. Per-peer issuance rate limit and per-token rate/concurrency caps are in-memory and not cluster-aware.
- Filtered A4.1 v1 request schema is enforced at the boundary; unknown fields, whole `deal`, early Dummy fields and private error echo rejected. Proposals go through an injectable `GatewayDecisionBackend`; the default returns **503 unavailable**, never fabricated BEN strategy. Flutter remains unchanged and is NOT connected to this service.
- A **bearer capability is not a player, seat, or deal authorization proof**. There is no server-owned GameState here; a caller can submit a plausible hand of their choice. For formal fair-play/competitive settings, the server must bind tokens to actual game/seat and derive PlayerView server-side. A4.3 also needs durable action IDs/event-version dedup and real BEN private-network worker.
- Localhost HTTP tests inject a fake backend, not a model. Scoped engineering evidence: [Gateway CI 14/14](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38836219472); [A4.2 acceptance](product/A4_GATEWAY_A4_2_ACCEPTANCE.md). A3.5 and device UI acceptance remain owner-deferred.

## A4.3.1 private BEN-only outbound adapter (2026-10-16)

The optional `BenLoopbackBackend` implements `GatewayDecisionBackend`: it maps Gateway's POST envelope to pinned BEN GET `/bid`, `/lead`, `/play` **only on an IP-literal loopback** (`127.0.0.1` or `::1`), disables redirects and proxy, bounds response size/time, hides errors and returns only `bid`/`card`. `BEN_INTERNAL_ORIGIN` is explicit opt-in in `bin/serve.dart`; unset means unchanged 503. [Acceptance](product/A4_GATEWAY_A4_3_1_ACCEPTANCE.md).

**Important trust blocker:** Anonymous Gateway Session currently carries quota only; requester-supplied `hand/seat` is not verified against a server-owned Deal. No public deployment until server-authoritative game/seat context, stable event-version and request dedup. Localhost HTTP tests are complemented by [genuine pinned BEN bid/lead/play smoke PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38837641285) and [20/20 Gateway HTTP PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38837641317). Neither provides a 13-trick Gateway game or seat-bound authorization. A3.5/device hold unchanged.

## A4.3.2: session-owned authoritative training game (2026-10-16)

The anonymous capability now binds to **one server-random Bridge Core Deal**, with `SinglePlayerCoordinator` owning all four hands and keeping the human seat North. Only `humanView.toJson()` is returned. New authenticated POST routes `/v1/games/view`, `/v1/games/action`, `/v1/games/advance` derive every actor/hand internally; BenBotPolicy reads the acting robot's own `PlayerView`, not the caller's claimed `hand`. Core validates move legality and `expected_version`; the Session remembers bounded same-ID responses to prevent repeat human clicks (in-memory only).

**Security limitations:** The old caller-supplied `/v1/ai/decision` still exists for loopback/development and must be disabled for a public deploy. Memory-only sessions/idempotency, long-running partial Bot commits, anonymous user ownership, durable transaction log and seat authority for multiplayer remain unaddressed. No production promotion until these are resolved. [Scoped Gateway CI 27/27](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38839175287), [Acceptance](product/A4_GATEWAY_A4_3_2_ACCEPTANCE.md); owner-deferred A3.5 and all Android/iOS UI device QA remain open.

## A4.3.2b: opt-in encrypted local authoritative checkpoint

`EncryptedSessionStore` uses AES-256-GCM with an externally supplied 32-byte key and one atomic session file per SHA-256 bearer digest. Encrypted content holds the privileged `GameTranscript` + bounded request ledger and pending request identity. `SinglePlayerCoordinator.restore` replays Bridge Core actions on startup (not a blind deserialize). `AuthoritativeGame` persists pending intent **before** mutating the Core; during `runBots(afterCommittedAction: _persist)` it saves each successfully committed event and finally persists the completed request reply atomically with the latest transcript. Incomplete `advance` can resume on matching ID after restart. Wrong key/tampered checkpoint fails closed, no plaintext hand/token logging.

The opt-in durable mode disables the legacy `/v1/ai/decision` raw caller-hand route; ephemeral dev/test mode retains existing A4.3.1 true BEN smoke. Public release still blocked on multi-worker stores, crash/OS SIGKILL and disk durability evidence, key operations, full real BEN game, budget/rights review and deferred A3.5/device QA. [Acceptance](product/A4_GATEWAY_A4_3_2B_ACCEPTANCE.md).

## Components
~~~text
Flutter Android / iOS / Web (render, input, localization)
    | legal intent (seat + action + turn/version), never master deal
Game Coordinator / API (single-player local coordinator; future server authority)
    | owns full Deal, event log, turn policy; emits filtered PlayerView
    |---- Bridge Core (pure deterministic Dart candidate, decision M1)
    |          legality, auction, contract, trick, Duplicate score, event replay
    |---- AI Adapter (Python service)
    |          BEN /bid /lead /play /autoplay; strict visible-view boundary
    |---- Analysis Adapter (DDS / endplay)
    |          OFFLINE or post-game, full deal access only when authorized
    +---- Persistence (SQLite local → PostgreSQL service when needed)
~~~

## A3 UI decomposition boundary (2026-10-16)

- `BridgeAcademyApp` owns the app theme/locale and `BridgeSession` lifetime; `BridgeTable` is the temporary screen-level controller. The user-facing BoardHeader/TableSurface/SeatPanel/CurrentTrick/PlayerHand and controlled BiddingBox now live in `apps/bridge_academy_flutter/lib/src/widgets/`.
- Widgets receive only the filtered `PlayerView`, board number, locale copy, visible UI state and typed callbacks. `BridgeSeatPanel` only shows Dummy cards after `dummyExposed`. The `BridgeBiddingBox` hoists level/strain selection through callbacks and forwards `Call` intent to BridgeSession; **canSubmit means input allowed, not every bid legal**. A Domain-derived legalCalls projection is needed before call buttons can be selectively disabled.
- `BridgeSession` remains the only UI-side coordinator; it checks current PlayerView, paused/saving state and expected event version. Bridge Core decides legal auction/play actions, actor/hand owner, score, turn order. UI never owns privileged Deal, SessionArchiveStore or BEN transport.
- Scoped evidence: [Flutter CI #38769943196](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38769943196) passed 69 Widget/session tests, analyze, Web build and Chrome Demo on `d4ddfee`; [genuine BEN Chrome regression #38769943206](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38769943206) also succeeded on the same code SHA. Device acceptance is on owner hold; no release GO.
- Current Web persistence after A2.8 uses WebCrypto AES-GCM via an origin-local record, **not** the earlier A2.7 plaintext path. It remains vulnerable to same-origin malicious scripts and lacks SQLite ACID/multi-tab CAS, so deployment threat-model review is pending.

### A3.4 Flutter accessibility UI boundary

- Presentation-only playing-card buttons use minimum 48×48 logical-pixel targets and localized suit/rank semantics; the real disabled state still comes from PlayerView legality and Session busy/rollback gates, not from labels.
- Seat announcements and active-turn text consume only PlayerView metadata. Material Flutter handles default button keyboard behavior; full assistive navigation needs actual keyboard and screen-reader verification before release.
- Scoped evidence on implementation SHA `ea7ca9c`: [Flutter CI 80/80, analyze, Web build, Chrome Demo](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38819474371) and [true BEN Chrome full-game/Dummy E2E](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38819474505). **Android/iOS hardware UI test remains paused until explicit owner approval.**

### A3.3 public history and responsive table

- BridgeTableSurface uses its own LayoutBuilder constraints (breakpoint 560 logical px) to preserve four compass seats while stacking the public current trick below East/West on narrow widths.
- BridgeTableToolbar operates exclusively on PlayerView.auction and PlayerView.completedTricks. Last-trick action remains disabled until Core has completed a trick, and the dialog displays only four publicly played cards and the actual winner.
- BridgeCompletedReplayPanel receives immutable CompletedReplay, an index and an index-change callback; it cannot write BridgeSession/Bridge Core events. The parent owns only ephemeral replay navigation state.
- Scoped tests and live model evidence: [Flutter CI 74/74 and Chrome Demo](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38778610734), [true BEN Chrome](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38778352006). Device testing remains paused by owner.

## A2.7 encrypted native transaction boundary (2026-10-15)
- BridgeSession uses the existing SessionArchiveStore interface; Android/iOS default is EncryptedTransactionalSessionArchiveStore, a full SavedBoard AES-256-GCM ciphertext in a single SQLite row with atomic transaction, and secure-storage-held key. Plaintext migration happens only after authenticated and Bridge Core legal replay verification, encrypted commit, then legacy deletion.
- Atomic row commit and authenticated encryption do NOT guarantee power-loss fsync, malicious process isolation, or cross-process CAS. Physical-device validation deferred by user until complete major features; no security release GO implied.
- Web remains SharedPreferencesAsync plaintext and needs a separate browser threat model; do not silently treat it as secure. Browser frontend still possesses full local privileged Deal for solo play, so a multiplayer fairness model needs server authority.

## A2.5 persistence consent boundary (2026-10-15)
- Checkpoint restoration can fall back to a previous legally verified version. The app must not silently resume if the newest committed generation was lost.
- The local checkpoint commit marker includes an optional boolean recoveryPending that survives separate app launches. BridgeSession awaits clearing the durable-intent marker before unpausing human or AI input; failed acknowledgment stays blocked.
- Marker confirmation and slot content are still SharedPreferencesAsync writes, **not** encrypted, authenticated or fsync/ACID durable. Future transactional storage remains a separate product release requirement.

## Invariants
- One authority executes all state transitions. A BEN call is an **ActionProposal**, not truth.
- Duplicate score returns a documented perspective: NS signed integer, with declarer partnership, vulnerability and X/XX preserved.
- Dealer and vulnerability are explicit; none inferred from PBN string alone without a documented convention.
- Turn and hand privacy enforced at serialization/API boundaries, not solely hidden in Flutter widgets.
- Client action contains event/version or idempotency identifier to reject duplicate or stale actions.
- Every valid transition appends a canonical event; replay reconstructs state from initial deal and actions.
- No direct Flutter dependence in core; no model/Python dependency in scoring.

## Suggested contracts (design proposal, not implemented)
- SubmitAction{gameId, seat, expectedVersion, action} → AppliedEvent/RejectedAction with reason.
- PublicView{dealer, vul, publicAuction, contract, tricks, turn, dummyIfExposed, scoreIfTerminal}.
- PrivateView{publicView, ownCards, permittedPrompt}.
- AIProvider.propose(view, context, timeout) → Proposal + rawResponseId + providerVersion.
- AnalysisProvider.analyze(completeDeal, history) → DoubleDummyAnalysis explicitly tagged.

## M2 local foundation (initial implementation)
- packages/bridge_core/lib/src/player_view.dart builds an explicit per-seat JSON-safe PlayerView; only own hand and exposed dummy cards are included, with public auction/tricks/counts. It is a privileged projector; authorization must be enforced by the coordinator/server.
- packages/bridge_core/lib/src/single_player_coordinator.dart owns private GameState for one local human + three bots, offers humanView (no unrestricted per-seat getter), applies version-checked human actions and validates BotPolicy proposals through BridgeGame.apply.
- DeterministicTrainingBot is intentionally **NOT BEN** and has no strategy-strength claim. BEN production adapter must separately prove API mapping and privacy. This local in-process coordinator is not multiplayer server authority.

## M2-F03 — Seat-limited BEN adapter (contract-level only)
- packages/bridge_ben_adapter accepts only authorized PlayerView and implements BotPolicy; no GameState/Deal access and no use of full-deal /autoplay for seat proposals.
- Maps to BEN /bid, /lead and /play with absolute vulnerability, dash-separated auction, chronological played cards and public dummy after opening lead.
- Reconstructs original 13-card hand from known remaining cards plus each seat's publicly played cards; logs/errors redact query values.
- Uses injected package:http client; automated contract tests are mock-only. The true BEN deployment, dummy actor semantics and end-to-end integration remain separate verification gates.
- PINNED BEN reference revision 72653ec1b5c17116faea229e9b975ea5622aa1f7; details docs/m2/M2_BEN_ADAPTER_REPORT.md.

## M2-F05 — Flutter table (first functional UI slice)
- Flutter app depends on bridge_core and bridge_ben_adapter. BridgeSession (ChangeNotifier) owns SinglePlayerCoordinator; no Widget accesses privileged GameState.
- Widgets render only PlayerView: hidden opponents are counts; exposed dummy and human hand are legal-click controls; all actions use coordinator version checks.
- Demo OpponentMode uses DeterministicTrainingBot, clearly not BEN. Live mode instantiates BenHttpTransport; errors display sanitized status and do not fall back.
- AppCopy centralizes Traditional Chinese and English copy; Material 3 UI and web CI. Native device QA is a separate gate.

## M2-F06 — actual browser automation and adaptive viewports
- Flutter Web browser integration uses official integration_test + Flutter drive + ChromeDriver to test actual rendered Chrome UI (not just simulated Widget Test).
- Responsive controls derive widths from LayoutBuilder parent constraints; phone/tablet Widget Tests run at 320, 375 and 768 logical pixels.
- Current Chrome runner only uses the explicitly labelled deterministic Demo Bot. The separately verified real BEN Dart session must not be cited as proof of Chrome-to-BEN UI operation.

## M2-F07 — True BEN + Chrome full-game boundary
- The independent CI workflow ben-flutter-browser.yml starts real pinned BEN native Python 3.12 then matches ChromeDriver to runner Chrome and drives Flutter UI end-to-end.
- browser_ben_test.dart selects actual BEN mode through the visible dropdown, injects an actual BenBotPolicy backed by BenHttpTransport (route-only counting wrapper), drives a complete 52/13 human-North game and checks non-mock success counts for /bid, /lead, /play.
- Browser network/CORS and genuine asynchronous I/O are additional failure surfaces not proven by native Dart CLI tests or Demo Chrome tests. Do not log BEN private hand query URLs.

## M2-F08/F09 — Android device and robot declarer
- M2-F08 uses reactivecircus Android emulator runner API 35 x86_64 and the native integration_test driver for Flutter Android click-level smoke test; separate from browser and BEN AI inference.
- M2-F09 wraps genuine BenBotPolicy in an audit observer and verifies actual robot declarer acts for public Dummy with 13 CardAction actor/handOwner checks, using real BEN Python + Flutter Chrome.
- Genuine /lead route is not required for the robot in M2-F09: East, a human defender, leads the first trick.

## M2-F10 — training fixtures vs fresh practice deals
- Bridge Core now creates a fresh shuffled Deal from a complete standard 52-card deck; existing Deal constructor guarantees uniqueness / 13 each; optional seed is only for deterministic in-process tests.
- BridgeSession defaults to the historic fixed deal; the explicit BoardMode.fresh opt-in supplies a new shuffled local deal or test-injected deterministic factory; BEN mode remains orthogonal.
- Only PlayerView flows to the UI. Exact cross-runtime replay uses an explicit PBN rather than a seed alone; neither seed nor raw four-hand PBN appears on an active player's screen.

## M2-F11 — finished-game event replay and UI boundary
- SinglePlayerCoordinator only exposes CompletedReplay when terminal; every snapshot is PlayerView.forSeat from a BridgeGame.apply replay, not GameTranscript.encode, and verifies terminal fingerprint/score.
- BridgeSession forwards only filtered completed frames; Flutter read-only navigation steps through actual chronology, public contract/trick/winner/score and own/dummy visible information.
- A new game discards the old in-memory replay. No persistent history, export or full-hand reveal is implied.

## Data and failure handling
- Standard PBN and LIN round-trips are candidates, not assumed compatible without fixtures.
- Fixed seed and full PBN may coexist; record both, as RNG versions differ.
- Retry policy must not emit a second irreversible action; timeout logs raw request metadata without revealing other hands.
- Fallback bot play may be deterministic legal-only, clearly marked degraded; never mislabel as BEN output.
- Freeze adapter behavior around Pass Out: preserve BEN returned three-Pass transcript, terminal outcome PASS, set transcriptCompleteness=UNKNOWN; never append synthetic fourth call.

## Phase A2.2 checkpoint hardening boundary

- SessionArchiveStore retains the same JSON archive supplied by SavedBoardCodec; Bridge Core GameTranscript is the only event replay authority.
- PreferencesSessionArchiveStore v2 uses inactive slot A/B → checksum/read-back + legal replay verification → active marker last. If active is corrupt, the previous valid slot may be recovered. Valid v1 single-key archive migrates after successful commit. Repository tests can inject I/O failures through CheckpointKeyValueStore.
- SHA-256 detects **accidental corruption only**; all four private hands are STILL plaintext in SharedPreferences. Multi-key updates lack an ACID guarantee and untrusted local users may recompute hashes. This must be replaced with a reviewed encrypted transactional store before production public release, alongside true device kill/restart, migration and concurrency tests.
- Do not pass privileged archives/slot payloads to Widgets or BEN or record them in logs.

## Security/performance
- BEN runs in isolated service, not in Flutter; limit concurrent expensive requests, redact secrets.
- DO NOT pass hidden completeDeal to ordinary bot calls; separately verify BEN API needs and implement safe information boundary.
- DDS is a double-dummy omniscient oracle, not a fair-play bot.
- In M4, migrate authority to server; do not trust client state/hash/score.
- POC RSS ~2.98 GiB and latency numbers are workload/config-specific (PIMC off/reduced sample).
