---
name: bridge-architecture-guardian
description: Reviews Bridge Academy architecture changes for pure Bridge Core boundaries, state authority, private-hand data isolation, Flutter API contracts, reliability and future multiplayer migration. Use when introducing modules, persistence, networking, realtime, third-party services or broad refactors.
---

# Bridge Architecture Guardian

## Inputs
Read docs/ARCHITECTURE.md, docs/DECISIONS.md, docs/PRODUCT_VISION.md, docs/DEVELOPMENT_STANDARDS.md, AGENTS.md. Obtain proposed change, trust boundaries, anticipated clients and source-of-truth state.

## Architecture constraints
- Domain core pure: no Flutter widgets, BEN, HTTP, SQL or clock/random globals in deterministic reducers.
- Coordinator owns deal and selects correct PlayerView; clients/bots do not become authority.
- Persist canonical events with stable IDs/versions and schema migrations; replay is deterministic.
- UI rendering state is a filtered projection. A hidden card must never serialize even if the widget simply hides it.
- Multiplayer moves require identity/seat authorization, expected state version and idempotency.
- AI/analysis split: BEN single-dummy decisions; DDS full-deal postgame; quarantine omniscient tools.
- Performance changes must preserve accuracy/privacy; circuit-breakers, bounded concurrency, retries and clear degraded-mode labeling.

## Review workflow
1. Sketch data-flow with trust boundaries: client, coordinator, core, AI, analysis, persistence.
2. Enumerate any request/response fields containing private hands, dummy, cards, auth and per-seat metadata.
3. Check whether a change moves state authority to UI or a third party; reject if so.
4. Validate API schema versioning and error semantics; timeout/duplicate response must not double-apply.
5. Check testability: dependency injection, fixed PBN fixtures, event replay, independent scoring oracle.
6. Check i18n zh-TW/en, accessibility, observability and operational cost where relevant.
7. Compare at least one alternative, including costs and migration pathway. Recommend smallest reversible design.
8. If accepted, update docs/ARCHITECTURE.md and docs/DECISIONS.md alongside implementation.

## Typical red flags
- Flutter directly calls BEN with four complete hands.
- "Protected" cards are merely obscured in Flutter but remain in API payload.
- AI response overrides Bridge Core score or legal state.
- DDS consulted for live hidden-information decision without justified fair sampling boundary.
- Non-idempotent WebSocket replay mutates action twice.
- Global singleton state hinders concurrent sessions or deterministic tests.

## Deliverable
Boundary map, invariant checklist, alternatives/tradeoffs, exact changed contracts/files, risks, test evidence (incl. negative privacy tests), ADR reference and follow-up.

## Prohibited
Do not introduce a distributed microservices network during M1 without demonstrated need. Do not invent production benchmarks. Do not copy third-party modules before license audit.

