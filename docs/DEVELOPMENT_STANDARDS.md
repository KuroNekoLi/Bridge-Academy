# Development Standards v0.1

## Repository and versioning
- Work on feature branches; PRs with scope, tests, limitations. Preserve a clean, reviewable history.
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

## Language / experience
- Product UI and explanations zh-TW/en, no hard-coded visible strings. Accessibility names, clear suit symbols plus labels, color-independent legal move cues.
- Decimal timeouts/latency units explicit; game score perspective explicit.
- User data and room chat eventually require retention/privacy policy before public launch.

## Evidence template
Change / test command / environment+versions / fixture seed & PBN / expected result / actual result / PASS-FAIL-BLOCKED / known gaps. Tests not run must say NOT RUN.

## GitHub automation entry
When actual implementation begins, add CI checks for pure rules, formatting and static checks before merging; do not add a green CI badge or claim working workflows without running them.

