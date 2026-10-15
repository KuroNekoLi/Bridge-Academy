# Architecture and Product Decision Log

Each item has status and rationale. Proposed choices are not approved simply because they appear here.

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

## Future ADR required
Persistence event format, AI fallback policy, identity/multiplayer authority hosting, offline model strategy, baseline conventions, PBN serialization, terminal claim/concession rules.
