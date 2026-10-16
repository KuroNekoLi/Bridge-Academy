# Architecture and Product Decision Log

Each item has status and rationale. Proposed choices are not approved simply because they appear here.

## ADR-025 — Product delivery split and device acceptance freeze (2026-10-15)

**ACCEPTED PRODUCT DIRECTION; NOT RELEASE APPROVAL.** Continue Bridge Academy as one-person + three BEN AI first, with reusable five-entry product information architecture and replay/learning loop. Preserve M1/M2 history. A1 canonical BoardDefinition is already scoped engineering-verified; A2 checkpoint/security work has partial Core/Web evidence and later encrypted backends but remains missing full deployment, native hardware and remote request idempotency acceptance. The next UI feature slice is **A3 Bridge Table UI V2**, componentized around player/seat-filtered presentation rather than augmenting one monolithic `bridge_app.dart`.

**Daily challenge decision:** Early B6/P1 may be a local, reproducible, **unranked original practice** set (with no public comparison, MP/IMP percentages, prize or leaderboard). Authentic ranked daily Duplicate and async friend comparisons remain D/P3, dependent on server-generated immutable board sets, trust boundaries, comparative scoring and fair-play controls. DDS remains post-game analysis, not omniscient in-play AI.

**QA owner hold:** Do **not** auto-trigger, manually dispatch, schedule or re-enable Android emulator/physical Android/iOS UI/E2E tests until the owner explicitly approves a separate test plan. Both existing Android AVD workflows were disabled on master; treat platform acceptance as deferred but mandatory before release. Preserve quick static/unit/Widget/Web build checks and currently permitted Chrome/real BEN regression; do not claim device GO based on them. This is a workflow decision, not cancellation of final mobile validation.

Authoritative product references: [PRD v1](product/BRIDGE_ACADEMY_PRD_V1.md), [delivery roadmap](product/PRODUCT_DELIVERY_ROADMAP.md), [official-source benchmark](product/COMPETITOR_BENCHMARK.md). No application source was modified by this ADR.

## ADR-024 — A2.8 encrypted Web local checkpoints, not a transaction guarantee (2026-10-15)

**ACCEPTED FOR IMPLEMENTATION; CI PENDING.** Web must not continue persisting four private hands in plaintext SharedPreferences. Reuse SavedBoardCodec and AES-256-GCM, browser WebCrypto-backed key via flutter_secure_storage and a **single origin-local record** in SharedPreferencesAsync, with validated-then-committed legacy plaintext migration. On HTTPS/localhost failures **fail closed** and never silently write plaintext. Surface localized browser-security notice. Web key handling is experimental; same-origin XSS/hostile extensions, cross-tab CAS and crash durability remain open. Not SQLite ACID or release approval. [Acceptance](product/P1_A2_8_BROWSER_ENCRYPTED_CHECKPOINT_ACCEPTANCE.md).

## ADR-023 — A2.7 authenticated native transactional checkpoints (2026-10-15)
**ACCEPTED FOR IMPLEMENTATION, CI PENDING.** Use AES-256-GCM with fresh nonce for complete four-hand transcript, 256-bit secret in native secure storage, atomic SQLite row commit containing encrypted active and prior generation with durable recoveryPending, and validated legacy SharedPreferences migration. BridgeSession still depends on SessionArchiveStore and never emits privileged transcripts to UI. Web intentionally retains legacy storage and is **not production confidential**. The owner requested delaying Android/iOS physical-device QA until major product features are complete; fake database/crypto tests cannot prove native power-loss behavior. Key-loss, backup policy, browser threat model, cross-process CAS and BEN network exactly-once remain open. [Report](product/P1_A2_7_SECURE_TRANSACTIONAL_STORAGE_ACCEPTANCE.md).

## ADR-022 — A2.5 consent survives restart (2026-10-15)
**ACCEPTED AND FLUTTER WEB ENGINEERING VERIFIED ([CI #38738604483](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38738604483), 50/50 PASS).** After two-slot checkpoint rollback, requiring explicit acknowledgment only in BridgeSession memory is unsafe: a second application launch makes the previous valid checkpoint appear ordinary. Include optional recoveryPending in the active commit marker; persist it with the marker repair, and clear only after awaited explicit player consent. A write error leaves human/bot actions paused. Existing v2 markers without the field default to false for migration compatibility. This is a best-effort local UI safeguard, **not** encryption/ACID/fsync, anti-cheat or remote BEN exactly-once. Follow-up: evaluate secure transactional storage and physical device failures.

## ADR-001 — Incremental product
**ACCEPTED 2026-10-15**: Single-player three-BEN-bot MVP first; later teaching and multiplayer/duplicate. Reason: isolate AI and correctness risks before spending on real-time infrastructure.

## ADR-002 — Backend AI initially, mobile UI later
**ACCEPTED IN PRINCIPLE**: BEN runs as an isolated Python service for POC/M2. Fully offline AI is deferred; never imply single-player = offline.

## ADR-003 — Independent authoritative rules
**ACCEPTED**: an implementation-independent Bridge Core owns rules, turn, outcome and scoring; BEN suggests actions. For multiplayer, server takes authority.

## ADR-004 — POC-002 Pass Out policy
**ACCEPTED 2026-10-15**: three visible PASS calls plus BEN reported PASS outcome count as outcome-level pass with TRANSCRIPT_WARNING; do not assert the fourth actual call occurred. Full transcript replay requires explicit chronological calls. Do not forge missing PASS.

## ADR-005 — POC status taxonomy
**ACCEPTED**: POC-001 GO (one real deal; evidence cited from user Work summary). POC-002 outcome GO (97 completed deals, 3 PASS outcomes) but full-transcript audit 98/100 and production sign-off CONDITIONAL. All findings bound to measured BEN configuration.

## ADR-006 — Core implementation language
**PROPOSED**: pure Dart bridge_core for initial Flutter compatibility. Reassess before M1 execution; avoid coupling domain core to Flutter widgets.

## ADR-007 — Convention cards
**PROPOSED**: versioned ConventionProfile separate from legality; do not claim BEN obeys arbitrary agreements.

## ADR-008 — Licensing
**OPEN**: first-party project license and commercial mode undecided. BEN GPL obligations and weight licenses must be cleared before publishing or distributing an integrated binary.

## ADR-009 — Learn While Building: feature teaching deliverables
**ACCEPTED 2026-10-15**: Each independently testable, accepted functional feature requires a dedicated Traditional-Chinese Feature Learning Note, an index entry and a short interactive concept/question at completion. Explain actual source and tests, engineering trade-offs and accessible Android/Kotlin parallels; keep engineering approval separate from learner mastery. See docs/learning/README.md and skills/bridge-learning-mentor/SKILL.md. Routine chores without new behavior do not require fabricated lessons.

## ADR-010 — M2 filtered views and local game authority
**ACCEPTED FOR M2 ENGINEERING IMPLEMENTATION 2026-10-15**: Bridge Core maintains full privileged GameState. External player/Bot access must pass through a seat-filtered PlayerView; dummy cards are publicly visible only after opening lead. SinglePlayerCoordinator is private-state local authority, rejects stale human versions and validates BotPolicy proposals. DeterministicTrainingBot is a rules smoke-test substitute, never BEN. True BEN Adapter and Flutter UI are separate future features. See docs/m2/M2_FOUNDATION_REPORT.md.

## ADR-011 — BEN per-seat HTTP adapter, independent live gate
**ACCEPTED FOR M2 IMPLEMENTATION 2026-10-15:** adapter depends on PlayerView only and uses real HTTP transport with mockable client; BEN /bid /lead /play are individual proposals, Bridge Core is authority. Only own/known dummy and public history may be sent. Official dummy seat documentation differs; real BEN smoke replay is mandatory for production acceptance. Prior POC real 100-deal runs do not automatically prove this new adapter works.

## ADR-012 — Direct pushes and native BEN validation
**ACCEPTED 2026-10-15:** User requested no more PRs; push to master directly, preserving CI, learning notes and revertability. M2-F04 uses pinned BEN Python 3.12 native runner and a full-game Dart test; PASS requires a real successful CI run, not Mock or pre-existing POC reports.

## ADR-013 — M2-F05 local Flutter UI shell
**ACCEPTED FOR FIRST UI SLICE 2026-10-15:** A small ChangeNotifier BridgeSession sits on SinglePlayerCoordinator and PlayerView. Never replicate legality inside Widgets; explicitly separate Demo and real BEN modes without silent fallback. Fixed PBN enables deterministic GUI tests; zh-TW/en UI copy is centralized. Web CI and Widget Tests do not replace native/device testing.

## ADR-014 — Browser QA is a distinct integration gate (2026-10-15)
M2-F06 adds browser-level ChromeDriver and responsive Flutter testing, independently of existing Dart Widget Tests. Keep model mode explicit: Demo tests cannot be called BEN integration. Device/browser target acceptance and real BEN UI interaction must use evidence from the matching executable, not inferred CLI results.

## ADR-015 — Native BEN + Flutter Chrome UI gate (2026-10-15)
M2-F07 must use pinned upstream BEN on localhost with matching actual ChromeDriver and Flutter integration_test. A route-counting transport must delegate to real HTTP; no mock/fallback acceptance. Full 52-card/13-trick and score verification are mandatory. Do not call this gate GO until GitHub Actions truly passes. BEN reduced sampling/PIMC-off remains an integration fixture, not production strategy/latency approval.

## ADR-016 — M2-F10 separate deterministic fixtures from fresh local practice (2026-10-15)
**ACCEPTED FOR SINGLE-PLAYER M2 ENGINEERING:** Keep the original training deal as the default to preserve reproducible benchmarks and true BEN integration tests. Offer explicitly selected fresh local deals via pure-Dart shuffled Deal; test random behavior with injected freshDealFactory and fixed seeds. Exact replay requires PBN, not only a seed. Do not expose raw four-hand deals through Flutter PlayerView or claim client-owned randomness ensures multiplayer fairness.

## ADR-017 — M2-F11 Replay from canonical events, filtered to PlayerView (2026-10-15)
**ACCEPTED FOR M2 IMPLEMENTATION:** No replay access before terminal state; construct historical player snapshots using BridgeGame.apply from the private starting Deal and authoritative GameEvent log, cross-check version/fingerprint/NS score. Return only immutable frames with seat-authorized PlayerView and publicly played action (never GameState, unfiltered GameTranscript, or full PBN). Flutter replay is read-only and limited to the current completed deal, without persistence, undo, DDS, or BEN re-evaluation.

## ADR-018 — Product journey first; official-source benchmark and product gate (2026-10-15)

**ACCEPTED PRODUCT DIRECTION.** The user approved evaluating 新睿橋牌 and Bridge Base Online as product benchmarks and writing docs/product/COMPETITOR_BENCHMARK.md, docs/product/BRIDGE_ACADEMY_PRD_V1.md and docs/product/PRODUCT_DELIVERY_ROADMAP.md before advancing functional implementation.

1. Prioritize a **complete single-player one-human + three real AI experience** (play, durable resume, score, history, next board) before tournaments or human multiplayer. Adopt five delivery phases A Playable → B Training → C Analysis → D Async Duplicate → E Live Multiplayer.
2. Distinguish MODULE ENGINEERING PASS from FEATURE READY and PRODUCT READY; reproducible fixed-board BEN CI is **not** evidence of production AI service or human-usable App.
3. Product scope and sequencing live in docs/product; existing docs/ROADMAP.md remains historical engineering CI evidence. Bridge rules and security boundaries remain owned by docs/BRIDGE_RULES_BASELINE.md and docs/ARCHITECTURE.md.
4. Next prioritized slice A1 is canonical 16-board Board Number/Dealer/Vulnerability plus localized presentation, with all existing replay, privacy and score rules preserved.
5. Competitor functionality informs original design but does **not** authorize source/asset/puzzle/convention copying. BEN GPL, model weights and service privacy remain release blockers until reviewed.
6. Proposed performance targets, revenue/account requirements, tournament method, actual default AI convention compatibility and launch platform eligibility are **NOT YET APPROVED** as technical facts; they need their own review and observed acceptance.

No Bridge Core gameplay implementation was changed in this documentation-only decision commit.

## ADR-019 — Phase A1 board metadata is Domain-owned (2026-10-15)
**ACCEPTED FOR IMPLEMENTATION (Core/Flutter engineering tests verified).** WBF Duplicate Law 2 defines 1-based Board Numbers, dealer order N/E/S/W and the 16-board vulnerability cycle. A pure-Dart BoardDefinition supplies metadata; BridgeSession passes it to the coordinator, so UI, Bridge Core score and BEN protocol all share the same source of truth. Current game re-deal keeps board number, replaySameBoard preserves physical cards, nextBoard is permitted only for terminal boards and advances sequence. The fixed teaching PBN may repeat with new board metadata only when explicitly chosen as a fixture, never marketed as a fair multi-board tournament. Persistence and server-authoritative competition are future separate gates. No existing legality/scoring reducer rule changed.

## ADR-020 — A2 checkpoint prototype: event validation before trusting local saves (2026-10-15)

**ACCEPTED FOR ENGINEERING PROTOTYPE, NOT PRODUCTION DURABILITY (Core+Web CI verified).** Store a versioned event transcript plus board metadata in an injectable local SessionArchiveStore. Validate every restored move with GameTranscript.decode + BridgeGame.apply and compare 1-based BoardDefinition metadata, event version and noncryptographic fingerprint. Commit each player action before bot execution; persist each legal bot event before requesting the next action. If write fails, stop and require explicit retry.

Initial Flutter adapter uses SharedPreferencesAsync only to validate cross-platform restoration. The official library is not for critical data and does not promise fsync/durability, encryption or security against device access. This remains a release blocker until replaced with atomic, encrypted, migration-tested storage and real device kill/relaunch QA. An in-flight BEN HTTP request may be repeated after crash; no remote exactly-once guarantee until backend idempotency exists. Complete four-hand PBN stays in privileged local storage only, never ordinary UI or playing AI.

## ADR-021 — A2.2 two-slot rollback checkpoint before encrypted release store (2026-10-15)

**ACCEPTED FOR ENGINEERING HARDENING; release encryption gate remains OPEN.** Replace the single SharedPreferencesAsync checkpoint key with two independently validated slots plus a last-written active marker. Preserve the last committed checkpoint across a failed pending-slot write or marker write; after corruption, permit rollback to the previous fully validated legal transcript, never fabricate events. Support validation-led v1 migration; do not remove the old key before v2 commits. Use SHA-256 as a non-secret corruption checksum, **never call it encryption/HMAC**. SharedPreferences is not ACID or crash-durable; true encrypted local transactional storage, concurrency protection, truthful recovery warnings, physical-device kill/relaunch and BEN server idempotency remain release blockers. See docs/product/P1_A2_2_CHECKPOINT_HARDENING_ACCEPTANCE.md.

## ADR-021 — Distinguish real Android app process restart from durability under power loss (2026-10-15)

**ACCEPTED FOR ENGINEERING QA; CI PENDING.** Before treating A2 SharedPreferences checkpoints as a viable player-resume feature, test two distinct Android app launches with OS force-stop in between, validate exact event version/fingerprint after restoring an unfinished legal game and submit a new action without duplicate committed events. Keep the A2.2 checkpoint/Bridge Core rules unchanged. This is not proof of fsync, transactional or encrypted disk, process kill during pending writes, concurrent writers, real BEN exactly-once, or app release readiness. These remain separate P0 gates.

## Future ADR required
Persistence event format, AI fallback policy, identity/multiplayer authority hosting, offline model strategy, baseline conventions, PBN serialization, terminal claim/concession rules.

## ADR-020 — Local rollback must be visible to the player (2026-10-15)

**ACCEPTED FOR ENGINEERING; Flutter/Chrome CI VERIFIED.** A2.2 previously recovered an older legal two-slot checkpoint silently when the current committed generation was corrupt. A legally valid earlier snapshot is not proof of full data durability, so the store now reports a nonsecret recovery flag and the Session blocks human/Bot actions until the user acknowledges possible lost actions. Flutter offers localized warning and continuation, not an implicit decision. This is for unranked local training only; preserve A2 product blockers for encrypted/fsync-safe storage, concurrent-writer control, release migration, remote AI request deduplication and device QA. [A2.4 acceptance](product/P1_A2_4_ROLLBACK_NOTICE_ACCEPTANCE.md).

## ADR-026 — Owner-deferred A3.5 and A4 HTTPS gateway-client seam (2026-10-16)

**ACCEPTED FOR DEVELOPMENT, NOT RELEASE.** Owner explicitly postpones A3.5 final UI/physical device/assistive UX acceptance, and authorizes proceeding to A4. A3.1–A3.4 scoped Flutter/Web/true BEN CI remains valid, but A3 product acceptance and all physical Android/iOS or Android emulator UI/E2E are **NOT VERIFIED / HELD** until an explicit later approval.

For A4.1 adopt an optional, reversible `BenGatewayTransport` implementing the existing `BenTransport` interface, but sending **HTTPS POST** with a versioned JSON envelope, allowlisted fields, sanitized errors, no redirects, bounded response, no implicit retry and injected short-lived credential provider. Existing `BenHttpTransport` GET remains for trusted development/native BEN CI only; never make it public. Compiled-in bearer tokens are forbidden. Domain Bridge Core, not a Gateway/BEN response, always commits and validates an action.

Alternatives rejected: direct public BEN GET (private hands exposed in URL and no authorization/quotas), bundling BEN model with mobile application before weights/runtime/license audit, and client-side embedded API secrets. Authentication, anonymous session bootstrap, rate limiting, server-side replay deduplication, hosting and BEN private upstream/service logs belong to A4.2+ and **are not implemented or hosted by A4.1**. BEN GPL-3.0/model weights need formal release review. [A4 contract](product/A4_GATEWAY_CONTRACT_V1.md).
