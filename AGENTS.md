# Bridge Academy — Agent Operating Contract

This file is the entry point for Codex, Work and other coding agents. The repository docs, not old chats or model memory, are the working source of truth. User-approved product decisions outrank agent assumptions. In a contradiction, report it and request a decision before silently changing the baseline.

## Product-level source of truth (approved 2026-10-15)

Before choosing the next feature, read:
1. docs/product/BRIDGE_ACADEMY_PRD_V1.md — **what the complete product must do**, user journeys, privacy, MVP release gates;
2. docs/product/PRODUCT_DELIVERY_ROADMAP.md — **what comes next**, dependency order, scope and product-vs-engineering acceptance;
3. docs/product/COMPETITOR_BENCHMARK.md — verified 新睿／BBO／BBO Trainer inspiration, **not** a license to copy code/assets;
4. docs/ROADMAP.md — **historical engineering milestone and CI ledger**, retained without rebranding earlier successes;
5. docs/BRIDGE_RULES_BASELINE.md and docs/DECISIONS.md — authoritative game invariants and accepted ADRs.

For generic "下一步" requests choose the earliest **unverified P0 player journey** in the product roadmap (A1 verified; A2 best-effort local checkpoint prototype has Core/Chrome engineering evidence, but its critical storage durability/security and device-process-restart gates remain unverified. A2.3 Android process-restart QA is the next P0 validation slice, followed by transactional/encrypted storage choices), not an arbitrary next M2-Fxx number. A technical test PASS is not consumer Product READY. Never silently rebuild an existing feature just to match a proposed milestone title. Repository source of truth is code + executed evidence.

## On every task
1. Read README.md, docs/DECISIONS.md, docs/ARCHITECTURE.md, docs/BRIDGE_RULES_BASELINE.md and the relevant milestone in docs/ROADMAP.md.
2. Select the smallest applicable skill in skills/README.md; do not activate unrelated skills for decoration.
3. State which invariant you will preserve, the scope, measurable acceptance criteria and files affected.
4. Implement the smallest safe change and add deterministic tests at the boundary.
5. Run relevant checks if the environment permits. Clearly distinguish EXECUTED / BLOCKED / NOT RUN; retain exact commands, environment, versions and result excerpts.
6. **Learn While Building:** after each independently testable functional feature is accepted, assign an Mx-Fxx ID, author a dedicated Traditional-Chinese teaching note at docs/learning/features/Mx_Fxx_TOPIC.md using the template, update docs/learning/INDEX.md, link actual implementation + tests, and include one small interactive question in the completion message. Multiple functional features need separate notes. Do not treat code comments or a milestone summary as sufficient.
7. Summarize changes, residual risks, test evidence, lesson links, one concept taught, one exercise and next decision; update docs/DECISIONS.md or the POC record if a decision changes. Engineering PASS does not imply learner mastery.

## Absolute invariants
- Bridge Core, not BEN, is authoritative for card ownership, auction legality, contracts, trick wins, scores and turn transitions.
- AI models are **untrusted action proposers**. Validate actions before mutating state.
- A player or bot receives only its permissible view: own hand; dummy only when exposed; public auction/play/history; permitted vulnerability and contract. Never feed an unseen deal to normal playing AI.
- DDS may see all four hands ONLY in offline analysis / test fixtures and must never be represented as fair-play single-dummy strategy.
- A natural Pass Out requires four actual passes to prove a complete transcript; a BEN response reporting PASS with three displayed passes is **outcome-accepted with transcript warning**, not independently proven fourth pass.
- Never forge an auction call to hide missing evidence. Keep server, raw AI and normalized event logs distinguishable.
- No hard-coded user-visible strings: Traditional Chinese (zh-TW) and English (en).
- No external code/license imports without recording the exact origin, version, usage boundary and obligations. No secrets, PBN with private account data, credentials or tokens in Git.
- Non-regression: deterministic seed/PBN fixtures; avoid silently changing scoring conventions or visibility rules.

## Authority and skill routing
- Scope/task sequencing → bridge-orchestrator
- Auction/trick/scoring rules → bridge-rules-reviewer
- BEN/API/adapters/evaluation isolation → bridge-ai-integration
- Batch fixtures, QA and regression evidence → bridge-playtest
- Client/server boundaries and multi-platform architecture → bridge-architecture-guardian
- Convention cards, bidding meaning, explanations → bridge-convention-reviewer
- Third-party dependencies/licensing → bridge-open-source-auditor
- **Any completed feature / learner walkthrough** → bridge-learning-mentor (works alongside domain specialist; not a separate approval of rules, AI or licensing)

## Mandatory feature-learning gate
- A feature is user-observable or independently testable behavior with acceptance criteria, **not** each class or commit; routine chores without behavior do not need fabricated lessons.
- For **each** completed feature: implementation + tests + docs/learning/features/Mx_Fxx_TOPIC.md + one row in docs/learning/INDEX.md **in the same direct-push change set**. No PR is required unless the user requests one. Use bridge-learning-mentor and docs/learning/FEATURE_LESSON_TEMPLATE.md.
- Lessons teach the *actual code*, why the design was chosen, an Android/Kotlin analogy when useful, one alternative, pitfalls, accurate executed test evidence and a small learner exercise. Communicate a brief teaching checkpoint after the engineering update, without blocking development on the learner's answer.
- Distinguish status: ENGINEERING_PASS, LESSON_DELIVERED, PRACTICED, MASTERED; last two require genuine learner participation. If lesson is absent, say FEATURE_DONE_LESSON_PENDING rather than DONE.
- Direct-push CI verifies feature lesson presence and template headings on master; domain correctness and one-note-per-feature mapping still require review.

## Git policy
Approved workflow (2026-10-15): commit and push verified work directly to master, without opening PRs. Do not force-push or rewrite history. Record tests, learning notes and rollback guidance in the commit/report. Keep third-party modifications as explicit upstream patches with their own tests. Commit source and documentation, not generated secrets or unverifiable "passed" screenshots. If commands or repository operations are unavailable, report the blocker without claiming the commit exists.

## Task output format
Goal / Feature IDs / Changed files / Design decision / Executed tests + command / Evidence / Lesson links and key idea / One learner question / Known limitations / Next step. A partial test does not imply complete acceptance.
