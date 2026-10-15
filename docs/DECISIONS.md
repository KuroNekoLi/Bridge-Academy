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

## Future ADR required
Persistence event format, AI fallback policy, identity/multiplayer authority hosting, offline model strategy, baseline conventions, PBN serialization, terminal claim/concession rules.
