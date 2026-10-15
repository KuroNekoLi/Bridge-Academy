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

## Workflow
1. Establish baseline (accepted ADRs, last proven test gate, exact scope).
2. Write a compact execution contract: objective, exclusions, interface owners, file changes, acceptance tests and stop conditions.
3. Break cross-cutting work into vertical slices; first a failing reproducible test/contract, then minimal implementation, then regression.
4. Maintain a dependency graph: M1 rules precede M2 bot UX; real BEN evidence precedes any production performance claim; convention compatibility precedes explanation quality claims.
5. Route disputed policy choices to the user, but make ordinary engineering defaults reversible and explicit.
6. Track evidence per task: executed command, environment, versions, seeds/PBN, observed results, limitations.
7. Before final status, compare results against every acceptance criterion; report PASS, FAIL, BLOCKED, NOT RUN separately; hand off unresolved issues.
8. When a formal new decision is accepted, update docs/DECISIONS.md and the affected source-of-truth doc in the same change.

## Required deliverable
- Scope and plan (including out-of-scope)
- Task-to-owner matrix and dependency notes
- Concrete code/docs/tests changed
- Gate table with evidence links or raw artifacts
- Known defects, product decisions pending and next bounded milestone

## Case study: BEN batch
If given "100/100 accepted" while 2 natural Pass Out results contain only three recorded passes: distinguish Game Outcome (100/100 per reported Work summary) from Complete Auction Transcript (98/100), preserve raw response and mark transcript warning. Never forge a fourth event or claim original evidence exists unless located.

## Prohibited
Do not silently replan the product to online-first. Do not invent tests, commits, source files or user approval. Do not broaden an M1 pure-rules task into Flutter UI or tournament architecture. Do not declare production GO from one POC hand or offline solve.

