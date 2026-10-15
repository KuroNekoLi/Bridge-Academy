# Bridge Academy — Agent Operating Contract

This file is the entry point for Codex, Work and other coding agents. The repository docs, not old chats or model memory, are the working source of truth. User-approved product decisions outrank agent assumptions. In a contradiction, report it and request a decision before silently changing the baseline.

## On every task
1. Read README.md, docs/DECISIONS.md, docs/ARCHITECTURE.md, docs/BRIDGE_RULES_BASELINE.md and the relevant milestone in docs/ROADMAP.md.
2. Select the smallest applicable skill in skills/README.md; do not activate unrelated skills for decoration.
3. State which invariant you will preserve, the scope, measurable acceptance criteria and files affected.
4. Implement the smallest safe change and add deterministic tests at the boundary.
5. Run relevant checks if the environment permits. Clearly distinguish EXECUTED / BLOCKED / NOT RUN; retain exact commands, environment, versions and result excerpts.
6. Summarize changes, residual risks, test evidence, and next decision; update the applicable docs/DECISIONS.md or POC record if a decision changes.

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

## Git policy
Use topic branches and reviewable PRs; do not force-push master or rewrite history. Keep third-party modifications as explicit upstream patches with their own tests. Commit source and documentation, not generated secrets or unverifiable "passed" screenshots. If commands or repository operations are unavailable, report the blocker without claiming the commit exists.

## Task output format
Goal / Changed files / Design decision / Executed tests + command / Evidence / Known limitations / Next step. A partial test does not imply complete acceptance.

