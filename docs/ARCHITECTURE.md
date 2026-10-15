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

## Data and failure handling
- Standard PBN and LIN round-trips are candidates, not assumed compatible without fixtures.
- Fixed seed and full PBN may coexist; record both, as RNG versions differ.
- Retry policy must not emit a second irreversible action; timeout logs raw request metadata without revealing other hands.
- Fallback bot play may be deterministic legal-only, clearly marked degraded; never mislabel as BEN output.
- Freeze adapter behavior around Pass Out: preserve BEN returned three-Pass transcript, terminal outcome PASS, set transcriptCompleteness=UNKNOWN; never append synthetic fourth call.

## Security/performance
- BEN runs in isolated service, not in Flutter; limit concurrent expensive requests, redact secrets.
- DO NOT pass hidden completeDeal to ordinary bot calls; separately verify BEN API needs and implement safe information boundary.
- DDS is a double-dummy omniscient oracle, not a fair-play bot.
- In M4, migrate authority to server; do not trust client state/hash/score.
- POC RSS ~2.98 GiB and latency numbers are workload/config-specific (PIMC off/reduced sample).
