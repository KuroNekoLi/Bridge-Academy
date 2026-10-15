# Development Standards v0.1

## Repository and versioning
- User-approved workflow (2026-10-15): push directly to master without PRs. Preserve atomic commits, CI evidence and revertability; never force-push.
- A behavior-changing rules change must update docs/BRIDGE_RULES_BASELINE.md and docs/DECISIONS.md, plus regression fixtures.
- Vendor changes to BEN require exact upstream version, patch file, regression tests and rollback note.
- Use conventional commit subjects where convenient; avoid committing generated test evidence with private user/deal information unless sanitized.

## Coding principles
- Pure deterministic Bridge Core, immutable typed actions/state, explicit perspective in score return values.
- Strongly type seats, suit, vulnerability, calls and terminal reason. Avoid boolean parameter traps for X/XX and vulnerability.
- Inject clock/RNG/AI provider; fixed seed fixtures do not replace fixed PBN fixtures.
- Prefer composition; reject illegal actions explicitly. Version serialized API/event structures.
- Small stateless adapters with timeouts, structured errors and schema validation.

## Testing quality bar
- Unit tests: card counts, dealer rotation, trump winner, follow-suit, Auction terminal states, Double/Redouble rights, declarer/dummy, all score combinations.
- Properties: 52 unique cards, every action preserves invariants, scoring symmetry NS/EW, replay determinism, valid terminal distribution.
- Golden: exact PBN/history/results; failures retain minimal fixture.
- Integration: mock AI schema tests distinctly labeled; true BEN live tests require real model+version and raw JSON.
- Benchmark: latency p50/p95/max, timeout/error and RSS with sample count, machine, PIMC/sampling settings.
- No "100% PASS" claim without specifying criterion. Outcome vs transcript completeness reported separately.

## Learn While Building — mandatory feature delivery
- Every independently demonstrable behavior feature with acceptance criteria (not every line/class) MUST include its own short Traditional-Chinese Feature Learning Note in docs/learning/features/Mx_Fxx_TOPIC.md, plus an index row in docs/learning/INDEX.md, committed together with source/test changes.
- Use docs/learning/FEATURE_LESSON_TEMPLATE.md and bridge-learning-mentor/SKILL.md. Explain a real scenario, actual code paths/flow, WHY and a rejected alternative, an Android/Kotlin analogy when genuinely helpful, practical tests, one 5–15 minute exercise and its success criteria.
- On reporting each completed feature, provide a brief conceptual lesson and one learner question in Chat; keep engineering progress independent from when the learner replies.
- CI enforces a basic lesson/template presence gate on direct pushes; review one lesson for each independent feature and technical accuracy. Add Feature ID → code → test → lesson mapping in commit/engineering report; never invent evidence.
- Track ENGINEERING_PASS separate from LESSON_DELIVERED; only user participation merits PRACTICED or MASTERED.
- Trivial chores without new behavior need no fabricated lesson; substantive bug fixes should update a relevant lesson if they change a previously taught invariant.

## Language / experience
- Product UI and explanations zh-TW/en, no hard-coded visible strings. Accessibility names, clear suit symbols plus labels, color-independent legal move cues.
- Decimal timeouts/latency units explicit; game score perspective explicit.
- User data and room chat eventually require retention/privacy policy before public launch.

## Evidence template
Feature ID / implementation paths / test command / environment+versions / fixture seed & PBN / expected result / actual result / PASS-FAIL-BLOCKED / lesson path / learner exercise / known gaps. Tests not run must say NOT RUN.

## GitHub automation entry
When actual implementation begins, add CI checks for pure rules, formatting and static checks before publishing a release; do not add a green CI badge or claim working workflows without running them.
