# Architecture v0.1 — boundaries first

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
