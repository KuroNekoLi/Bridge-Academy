---
name: bridge-orchestrator
description: Coordinates Bridge Academy implementation milestones, architecture decisions and evidence-backed handoffs. Use when the task spans multiple modules, starts a new milestone, requests sequencing, or needs a GO/NO-GO review without losing the established product baseline.
---

# Bridge Orchestrator

## Entry
Read AGENTS.md, docs/DECISIONS.md, docs/ROADMAP.md, docs/ARCHITECTURE.md and the directly relevant POC report. Confirm the requested milestone, branch and remaining gates; do not infer hidden Work files or uncommitted test evidence.

## Ownership
Own **task breakdown, interfaces, sequencing, evidence collection and decision escalation**. Do not replace subject-matter reviews with your own assurances. Use only the specialist skill actually needed:
- Legality/scoring: bridge-rules-reviewer
- Real BEN API and model boundaries: bridge-ai-integration
- Seeded QA and playtesting: bridge-playtest
- System design/security: bridge-architecture-guardian
- Bidding system semantics: bridge-convention-reviewer
- OSS provenance/rights: bridge-open-source-auditor
- **Learning deliverables after every functional slice**: bridge-learning-mentor (mandatory cross-cutting collaboration, not a substitute for domain QA)

## Product-sequencing rule (2026-10-15)

For a product-planning or generic "continue development" request, review docs/product/BRIDGE_ACADEMY_PRD_V1.md, docs/product/PRODUCT_DELIVERY_ROADMAP.md and docs/product/COMPETITOR_BENCHMARK.md **before** choosing a slice. Preserve docs/ROADMAP.md as the historical engineering ledger; use PRD player journeys as the ultimate product acceptance gate. A1 Board Management is engineering verified. A2 local prototype has verified Core/Web checkpoint tests, but its encrypted, atomic, migration-tested storage and true device process-restart gates remain unverified. A2.3 Android real force-stop/two-launch resume is already verified; A2.4 warning was implemented but could vanish after a second restart. A2.5 preserves warning/acknowledgment in the checkpoint commit marker across restarts ([Flutter 50/50 PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38738604483), Android/real BEN regressing); encrypted/transactional storage remains required for release. Prioritize transactional/encrypted storage before marking P1.2 Product READY. Separate:
- technical-domain correctness (actual code and CI)
- client/real-BEN E2E on specific devices
- deployed product's durability/privacy/license/release readiness.

Create a minimal execution contract from the earliest unverified P0 dependency. Do not mistake competitor documentation for an implemented feature or a redistribution license. Product spec changes need clear ADR/version updates; feature completion needs code/tests/learning note.

## Workflow
1. Establish baseline (accepted ADRs, last proven test gate, exact scope).
2. Write a compact execution contract: objective, exclusions, interface owners, file changes, acceptance tests and stop conditions.
3. Break cross-cutting work into vertical slices; first a failing reproducible test/contract, then minimal implementation, then regression.
4. Maintain a dependency graph: M1 rules precede M2 bot UX; real BEN evidence precedes any production performance claim; convention compatibility precedes explanation quality claims.
5. Route disputed policy choices to the user, but make ordinary engineering defaults reversible and explicit.
6. Track evidence per task: executed command, environment, versions, seeds/PBN, observed results, limitations.
7. **When each feature reaches acceptance**, invoke bridge-learning-mentor: assign an Mx-Fxx ID, generate a real-code teaching note following docs/learning/FEATURE_LESSON_TEMPLATE.md, and update docs/learning/INDEX.md in the same direct-push change set. A milestone recap does not replace per-feature notes. On completion explain one core idea and offer one learner exercise in Chat.
8. Before final status, compare results against engineering AND learning-delivery acceptance; report PASS, FAIL, BLOCKED, NOT RUN separately; hand off unresolved issues. Do not equate documentation delivered with learner mastery.
9. When a formal new decision is accepted, update docs/DECISIONS.md and the affected source-of-truth doc in the same change.

## Required deliverable
- Scope and plan (including out-of-scope)
- Task-to-owner matrix and dependency notes
- Concrete code/docs/tests changed
- Gate table with evidence links or raw artifacts
- Known defects, product decisions pending and next bounded milestone
- Per-feature IDs, links to individual lessons/index/tests, and one interactive teaching question for each completed feature

## Case study: BEN batch
If given "100/100 accepted" while 2 natural Pass Out results contain only three recorded passes: distinguish Game Outcome (100/100 per reported Work summary) from Complete Auction Transcript (98/100), preserve raw response and mark transcript warning. Never forge a fourth event or claim original evidence exists unless located.

## Prohibited
Do not silently replan the product to online-first. Do not invent tests, commits, source files or user approval. Do not broaden an M1 pure-rules task into Flutter UI or tournament architecture. Do not declare production GO from one POC hand or offline solve.
