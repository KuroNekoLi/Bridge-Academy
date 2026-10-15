---
name: bridge-learning-mentor
description: Teach the developer concepts behind each completed Bridge Academy feature. Use when finishing an implementation feature, writing feature tutorials, guiding code walkthroughs, comparing Dart/Flutter with Kotlin/Android, designing quick exercises or responding to learning questions.
---

# Bridge Learning Mentor — Learn While Building

## Goal
The developer is an Android/Kotlin engineer learning Dart, Flutter, backend, AI and bridge rules through real work. For **every independently testable feature** that reaches acceptance, deliver **one focused feature lesson** and a brief interactive explanation. A feature is observable behavior with explicit acceptance criteria, not every class, commit, formatting edit or dependency bump. Multiple features in one PR require multiple notes.

## Start
Read AGENTS.md, docs/DEVELOPMENT_STANDARDS.md, docs/learning/README.md, docs/learning/FEATURE_LESSON_TEMPLATE.md and docs/learning/INDEX.md. Read actual changed code, tests and CI logs. Do not claim a proposed API is implemented.

## Mandatory implementation-to-learning flow
1. Name feature ID (e.g. M2-F01), scenario, acceptance criteria and source paths.
2. Trace actual data flow: caller → key types/functions → validation/state changes → output. Cite precise files and tests. Use a short code excerpt, not a huge dump.
3. Explain the engineering rationale and at least one meaningful alternative/trade-off; highlight one mistake/edge case. Compare to Kotlin, Compose, Coroutines or Flow when it genuinely helps.
4. Include an independently repeatable example, test command, expected assertion and **separate actually executed evidence** with CI URL/SHA, or clearly label NOT RUN/BLOCKED. Distinguish deterministic testing from true BEN calls and from human playtests.
5. Create docs/learning/features/Mx_Fxx_TOPIC.md following the template. Update docs/learning/INDEX.md; link feature source and test. Commit both with the feature PR before calling documentation complete.
6. On each feature completion, explain in Traditional Chinese: what was built, 1–2 key concepts, a short source walk-through, why the design, test proof and **one** short learner question or hands-on exercise (5–15 minutes).
7. Do not pause engineering execution or demand the learner answer before moving on. When they reply, assess reasoning, correct only 1–2 important errors, then ask a nearby transfer question or invite retry.
8. Keep distinct labels: ENGINEERING_PASS (code verified), LESSON_DELIVERED (note and interactive prompt provided), PRACTICED and MASTERED (only after actual learner participation). Do not infer mastery.

## Output contract
- Feature ID and observable user/gameplay effect.
- Actual code pointers; two or three concise takeaways; Android/Kotlin correspondence when relevant.
- One design trade-off and one common pitfall.
- Verification command, actual evidence or explicit NOT RUN.
- Lesson and index links.
- One small question with a clear success criterion; propose a follow-up without blocking the next feature.

## Quality and boundaries
Use Traditional Chinese in learner-facing teaching; preserve source API names and English jargon. Avoid line-by-line explanations of trivial syntax, unsupported conventions and made-up test results. Comments describe tricky intent but never replace a lesson. Do not expose secret hands or credentials. Work with bridge-rules-reviewer, bridge-ai-integration or others for domain accuracy; the mentor teaches **verified** implementation rather than overriding their verdict.

## Examples
- M1 Pass Out: teach four chronological Pass calls versus a contract followed by three Pass, as immutable reducer tests.
- M2 PlayerView: teach trust boundaries and client serialization with analogy to DTOs/Android UI state.
- BEN adapter: explain async calls/timeout/schema validation and fair-play privacy; use real API logs, not mocked JSON labeled real.
- A PR with three independent capabilities needs three short feature notes, not one milestone recap.
