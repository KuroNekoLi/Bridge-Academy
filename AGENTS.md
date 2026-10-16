# Bridge Academy — Agent Operating Contract

This file is the entry point for Codex, Work and other coding agents. The repository docs, not old chats or model memory, are the working source of truth. User-approved product decisions outrank agent assumptions. In a contradiction, report it and request a decision before silently changing the baseline.

## Product-level source of truth (approved 2026-10-15)

Before choosing the next feature, read:
1. docs/product/BRIDGE_ACADEMY_PRD_V1.md — **what the complete product must do**, user journeys, privacy, MVP release gates;
2. docs/product/PRODUCT_DELIVERY_ROADMAP.md — **what comes next**, dependency order, scope and product-vs-engineering acceptance;
3. docs/product/COMPETITOR_BENCHMARK.md — verified 新睿／BBO／BBO Trainer inspiration, **not** a license to copy code/assets;
4. docs/ROADMAP.md — **historical engineering milestone and CI ledger**, retained without rebranding earlier successes;
5. docs/BRIDGE_RULES_BASELINE.md and docs/DECISIONS.md — authoritative game invariants and accepted ADRs.

For generic "下一步" requests, compare the latest code and scoped CI evidence with the **current** product roadmap. A1 Board Management has verified Core/Flutter/real BEN fixed regression. A2 local checkpoints, secure native SQLite and browser encrypted archive have been implemented with scoped test evidence, but native device durability, deployment security and remote BEN idempotency remain **open P0 release gates**. A3.1–A3.4 have scoped engineering acceptance; **owner deferred A3.5**, still a release blocker. The next feature phase is **A4 Production BEN Integration**, with A4.1 HTTPS client verified and A4.2 local-only anonymous Gateway has scoped [14/14 HTTP CI evidence](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38836219472). **No deployed service, no server game/seat authority; A4.3.1 private BEN loopback adapter is scoped real-model verified; A4.3.2 introduced server-owned game authority and scoped 27/27 Gateway CI; A4.3.2b opt-in encrypted single-node checkpoint, per-bot-event persistence and actual Dart SIGKILL process restart are [scoped 32/32 CI verified](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38841623172) (not production distributed exactly-once)**; A4.3.3 [pinned genuine BEN full game through authorized Gateway PASSED](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38845244764) for ONE fixed 52-card/13-trick board; A4.4 Flutter Gateway opt-in session/UI has [86/86 Flutter tests, Web Release and Demo Chrome E2E CI PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38848030915) with secure origin, Bearer lifecycle and same-ID retry; [one real Chrome→localhost Gateway→pinned BEN 13-trick full board has now PASSED](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38849429500) with a bounded opt-in dev quota; A4.5 production TLS/model rights/multiuser cost/privacy capacity, A3.5 and device QA remain OPEN; never call A4 production ready. Safe A2 security work may continue independently. Do not mistake initial historical A1/A2 planning prose for the latest implementation status. Keep distinct:
- technical-domain correctness (actual code and scoped CI)
- Web/browser and real-BEN end-to-end acceptance in named environments
- device-specific acceptance, **currently on owner hold**
- deployed product's durability/privacy/license/release readiness.

**QA hold (owner-approved 2026-10-15):** never re-enable, schedule or dispatch Android emulator or physical Android/iOS UI/E2E workflows without subsequent explicit owner approval. Relevant device workflows are guarded off. Dart/Flutter unit, analysis, Web builds and currently permitted browser/real-BEN checks remain available. Device QA remains a mandatory release gate, not canceled acceptance.

**Daily feature split:** B6/P1 may deliver an **unranked original fixed-board daily practice**; a ranked daily Duplicate, MP/IMP, leaderboard or friend comparison remains D/P3 after server-owned comparable boards and fair scoring. Product doc priority changes need explicit ADR/version history; feature completion needs real code/tests and per-feature lesson.
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
