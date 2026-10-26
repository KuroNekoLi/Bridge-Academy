# Bridge Academy — Agent Operating Contract

> Canonical project documentation: [docs/README.md](docs/README.md). **Only 7 docs files** in three categories (implementation, future product plan, research). Never auto-create a separate feature note/acceptance report/weekly plan Markdown under docs. Update the existing files.

## Mandatory Codex quota / handoff policy — owner approved 2026-10-26

- At task start, before a substantial new slice, after verification and before commit/push/handoff, use the app `get_usage_limits` tool **if actually available**; during extended tool work repeat at most 15-minute intervals. Check every available numeric primary/secondary quota, prefer `rateLimitsByLimitId`, falling back to `rateLimits` if absent. `remainingPercent = clamp(100-usedPercent,0,100)`; quotas are account-shared. Missing fields = **UNKNOWN**, not zero/unlimited.
- If **any** window is ≤30% remaining, **first update [docs/planning/CURRENT_HANDOFF.md](docs/planning/CURRENT_HANDOFF.md)** with project/ref/SHA, branch, uncommitted changes, real tests, pending work, risk/revert and exact triggering window/time; notify owner, prioritize checkpoint and bounded repairs over another major feature.
- If the quota tool is absent, record **UNKNOWN**, prepare a factual handoff before large new work; do not claim to monitor usage nor attempt to access secrets. Existing scheduled owner reminders are independent; do not create duplicates or assume constant background monitoring.

## Read these before making changes

1. [Implemented features, architecture and Bridge Core invariants](docs/implemented/FEATURES.md).
2. [Next product work, scope, user journeys and release gates](docs/planning/ROADMAP.md).
3. [Binding user decisions](docs/planning/DECISIONS.md).
4. [Research / actual CI evidence](docs/research/RESEARCH_REPORTS.md).
5. [Current handoff](docs/planning/CURRENT_HANDOFF.md), then current GitHub `master` and source/tests.

## Absolute rules

- **Bridge Core is authoritative** for 13 cards per seat, 52 unique cards, auction, Pass Out, Double/Redouble, legal follow-suit, trick winner, contracts and signed NS score. BEN/BBA is an untrusted action proposer; validate before mutating `GameState`.
- **PlayerView and private data**: only seat-permitted hand, dummy after correct reveal, public calls/events and authorized state. DDS can see all four hands **only for finished-board/offline explicitly scoped analysis**. Do not leak private deal in GET URI logs, third-party telemetry, screenshots or errors. Never forge a fourth Pass to reconcile a BEN 3-Pass outcome.
- **System pinning**: `GameSystems` NS/EW identity, revision and fingerprint must be immutable per game. Only explicitly allowed BEN 21GF/SAYC profiles are playable by existing runtime; BBA Meckwell Precision is research-only unless all gates pass, 1NT fixed at 13–15 HCP. Custom draft `ENGINE_UNVERIFIED` cannot register itself as supported AI; no fake model capabilities.
- **No unsupported interpretation**: convention meanings, coaching and suggestions need trustworthy versioned evidence. `UNKNOWN` or `USER_DRAFT` when unverified. No LLM-invented BEN hidden reasoning, no claim of actual competitor strength from a small fixture.
- **No production deployment** until real target-VPS performance, TLS/identity/privacy, licensing/model/asset rights, durability, fairness, human/device QA are formally accepted. Research CI is not release approval. No external source/code/assets without provenance and clear licensed use.
- **Owner QA HOLD**: do not dispatch or enable Android emulator, physical Android/iOS app UI/E2E or A3.5 human UX runs without later explicit owner approval. Dart/Flutter unit, analysis, Web, permitted browser/real BEN CI remain allowed. Do not declare blocked QA as passed.
- **Locale**: zh-TW and en. No hard-coded user-facing strings. Change gameplay only with deterministic tests, view isolation checks and explicit user-facing error handling. Reject illegal AI action with no mutation/fallback.
- **Git**: user wants direct push `master` with no PR; never force-push/rewrite history, never clobber another contributor. Git revert is rollback. No credentials, hidden deals, private tokens, proprietary binaries committed.

## Feature delivery and learning gate

For each independently testable user-facing behavior change: plan a small acceptance boundary; implement + tests; update **both** [docs/implemented/FEATURES.md](docs/implemented/FEATURES.md) and [docs/implemented/ENGINEERING_NOTES.md](docs/implemented/ENGINEERING_NOTES.md) in the same change. Append an `## Mx-Fxx｜...` section explaining actual code/files, why, alternatives, exact executed CI, limitation, 5–15-minute practice. Status must distinguish `ENGINEERING_PASS`, `LESSON_DELIVERED`, `PRACTICED`, `MASTERED` (last two require actual learner participation). Docs-only chores such as this consolidation do not fabricate features. The [CI feature learning gate](scripts/check_feature_lessons.py) checks the retained documents on master.

## How to work

1. Choose one relevant [skill](skills/README.md) and preserve domain/visibility/authority invariants.
2. Verify the latest source and CI, not just old summaries. If unknown or stale, say so; distinguish **EXECUTED / FAILED / BLOCKED / NOT RUN**.
3. Implement bounded code, deterministic tests and migration/rollback considerations. Do not run held device QA.
4. Give an actual evidence-backed completion summary, no implied asynchronous work, and mark product rollout gated if appropriate.
5. Update [docs/planning/DECISIONS.md](docs/planning/DECISIONS.md) only for a meaningful owner-authorized product or architecture decision, otherwise keep docs ≤10 by amending the existing three categories.

## Skill routing

- Broad scope / dependencies: bridge-orchestrator.
- Auction, trick, scoring: bridge-rules-reviewer.
- BEN / AI request and response: bridge-ai-integration.
- Testing / benchmarks / fixtures: bridge-playtest.
- Architecture / transport / security: bridge-architecture-guardian.
- Bid meaning / conventions: bridge-convention-reviewer.
- Third-party rights / native code: bridge-open-source-auditor.
- Any independent feature explanation: bridge-learning-mentor (in parallel with relevant primary skill).

## Task result format

Goal / Feature ID (if applicable) / Changed files / Core boundary / Executed tests and CI URLs / Lesson when relevant / Known limitations / Release gate / Next action. Evidence is scoped; historical acceptance does not imply current master all green.
