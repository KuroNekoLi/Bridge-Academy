---
name: bridge-playtest
description: Designs reproducible contract bridge playtests, 100+ fixed-seed BEN batches, rules regressions, performance profiling, real-player sessions and failure triage. Use for release acceptance, gameplay QA, benchmark comparisons and reported broken deals.
---

# Bridge Playtest / QA

## Entry
Read docs/ROADMAP.md, docs/BRIDGE_RULES_BASELINE.md, docs/poc/POC_002_BATCH_100.md and docs/DEVELOPMENT_STANDARDS.md. Declare environment, test dimension, actual sample size and success metrics before execution.

## Test layers — never mix their claims
- **Rules unit/property**: deterministic Bridge Core, no neural AI needed.
- **Schema/integration**: test fixtures and fake endpoints (explicitly MOCK).
- **True BEN smoke**: real running BEN plus pinned weights/config and raw JSON.
- **Batch stability**: fixed seeds and fixed PBN, real endpoint, reproducible scripts.
- **Strategy quality**: expert evaluation or tournament benchmark, not inferred from legality.
- **Human usability**: observed interaction in Flutter; not inferred from screenshots or unit tests.

## Procedure
1. Freeze exact BEN version/model, environment, PIMC/sample setting, RNG seed, dealer/vulnerability and fixture list (with seed→PBN mapping).
2. Establish coverage matrix: dealer N/E/S/W, None/NS/EW/Both vulnerability, 5 strains, Pass Out, doubled/redoubled, slam, made/down, void/follow suit.
3. Run one fixture manually to verify API and logs, then execute seeded batch. Keep passouts distinct from played deals.
4. Per board, assert 52 unique dealt cards, auction legality and terminal status, 13 tricks for play, no revoked follow suit, score from independent rules oracle.
5. For Pass Out, separately grade terminal outcome and complete four-call transcript. For BEN PASS + three visible calls emit PASS_WITH_TRANSCRIPT_WARNING.
6. Track HTTP errors, API timeout, internal solver timeout/fallback, crash, mismatched result; preserve first bad PBN and request/response.
7. Report p50/p95/max and RSS with measured sample population/config; compare like-for-like only. Do not report measured confidence beyond sample scope.
8. If running UX playtest, observe at least one full hand, record confusion/accessibility concerns, screenshots only with privacy clearance.
9. Re-run minimum regression set after fix; report exact changed test counts.

## Output schema (suggestion)
summary: environment, BEN sha, fixtures, configuration, result; per_deal: seed, dealer, vulnerability, contract, declarer, tricks, NS_score, terminal_kind, transcript_complete, legality, elapsed_ms, warnings; aggregate: outcome_pass, transcript_complete, failures, internal_timeouts, HTTP_failures, latency percentiles, peak_RSS.

## Exit criteria
Every outcome tied to raw evidence or explicitly "reported, unverified"; counts reconcile (played + passouts + failures = total). No PASS when 13/52 expected but missing; no FAIL solely for transcript omission if only the declared API-outcome contract is under test. List reproducible commands and next gate.

## Never
Never silently omit flaky or slow seeds; never call PIMC-off benchmarks "BEN default"; never mistake internal SuitC timeout for HTTP timeout; never forge missing PASS; never claim random sampling covers all conventions.

