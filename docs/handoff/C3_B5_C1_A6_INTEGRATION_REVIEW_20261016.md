# C3 + B5 + C1 + A6 — Integration Review / Merge Acceptance
**Date:** 2026-10-16 · **Source base:** `master@08a7fb5efcebd8538cfb70624c8975bd9b3eff88`  
**Integration branch:** `integration/c3-b5-c1-a6-reviewed-20261016`  
**Shared tested tree:** `4aa6a1e513d5bec68c3b4504b7acbd82018fac58`

## Sources and verdict
| Branch | Source tip (preserved as merge parent) | Review | Primary evidence |
| --- | --- | --- | --- |
| `feature/c3-learning-progress` | `8a83b1b13fd0a96875d287aa25767b4c4005997c` | SCOPED VERIFIED | [C3 151/151](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38919859220) |
| `feature/b5-teaching-review` | `4e6d62e7bf2892f8f4e099e58819c3de10d0dd18` | SCOPED VERIFIED | [B5 152/152](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38919162697) |
| `feature/c1-dds-analysis` | `d7c78130fb145b499b397142724652ede88269e8` | SCOPED VERIFIED — native Linux DDS engine, NO player UI | [real DDS3 native](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38922555537) |
| `test/a6-real-ben-multiboard` | `bf209b0d08e31ddd9345da9c4232101de2513c91` | SCOPED VERIFIED — Gateway tests | [real BEN 4/4](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38922555451) |

## Code review
- **C3:** B4 keeps answer authority in `AcademyPractice`; consent precedes persistence; AES-GCM archive has its own native key, AAD and browser/SQLite store. Per-attempt UUID-equivalent event identifiers, bounded attempts (500) and opt-in pause/resume are independent of completion count. Fail-closed corrupted data and confirmed full deletion tested. No live game Deal enters ledger.
- **B5:** `ReviewTimeline` builds on immutable terminal `CompletedReplay.frames` / viewer-filtered `PlayerView`; does not fetch private Deal, recalculate scores or call DDS. Convention semantics explicitly unreviewed or UNKNOWN; card strategy marked NOT ANALYZED. Ephemeral marks are not saved or synchronized.
- **C1:** `DoubleDummyAnalyzer` is typed and isolated; trusted terminal archive reconstructed by Bridge Core is the only non-fixture entry. PBN enters a bounded native Python subprocess via stdin, no public Gateway/BEN/UI integration. Real pinned upstream DDS3 Python 3.14 wheel built and tested; browser compilation uses an explicit unsupported implementation. Distribution audit **NOT APPROVED**.
- **A6:** Gateway introduces a server-side optional `trainingBoard` only; no player-supplied Deal/PBN API. Runner pins a genuine BEN version (no mock fallback), verifies 13 tricks/52 unique plays/core score, request idempotency and rejection of untrusted/unauthorized payloads. The four training decks are rotated fixtures with forced human bids, not four independent BEN bidding benchmarks.
- Only overlapping edited path across the four source branches was `docs/learning/INDEX.md`; canonical rows `M2-F46/F47/F48/F49` were appended without losing prior index entries. Merge commits have two Git parents and preserve each source branch's full history.
- No Android/iOS emulator or device QA was executed; the existing hold remains in force. No feature claims commercial deploy readiness, multiplayer ranking fairness or expert-certified bridge strategy.

## Same SHA combined CI evidence
- [Flutter M2 CI #38922555442](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38922555442): **Analyze No issues; 158/158 Flutter tests PASS; Flutter Web Release PASS; real ChromeDriver Demo E2E PASS.**
- [Feature Learning Gate #38922555443](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38922555443): **PASS**.
- [C1 DDS #38922555537](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38922555537): **Dart 6/6 + web compile PASS**, separate **genuine DDS3 native golden PASS** (Python 3.14 pinned wheel, 3 rotated suit-per-seat fixtures, 5×4 matrix). Contract job marks native golden skipped because it is deliberately executed only in the real native job; do not double count.
- [A6 genuine BEN #38922555451](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38922555451): **Gateway 34/34 tests PASS; genuine pinned BEN four distinct rotated server-owned board fixtures 4/4 PASS**; 13 tricks/52 cards per board, Core duplicate score verified, no model failures.

## Known, non-blocking limitations and remaining gates
1. C1 is **native Linux engineering integration**, not Flutter Web DDS UI and not a production service. License provenance Apache-2.0 confirmed; transitive packaging/NOTICE/ABI/security review and player authorization checks remain prerequisites of deployment.
2. C1 golden fixtures are controlled suit-per-seat/rotated scenarios, not broad bridge analysis accuracy on diverse realistic mixed-suit hands. This is a bounded adapter smoke, not a clinical/competitive strategy quality claim.
3. B5 player explanations are rule scoped and do not receive C1 recommendations until future `C1.5`; this deliberate separation avoids unsafe hidden-hand exposure.
4. A6 validates **Gateway four-board** operation rather than four-board Flutter Chrome paths; board 3 finished in a different actual strain than its scenario name, already disclosed in A6 acceptance. No formal SLA/production deployment claims.
5. C3 lacks cloud sync/multi-device consistency; 500-event bounded store rejects extra writes rather than dropping old records.
6. On `master`, the existing normal Flutter / Learning / true BEN workflows must be checked again after push. Integration-specific workflow branch filters are temporary and are restored before master merge.

## Merge and rollback
Integrate as fast-forward of this reviewed merge DAG after removing temporary CI filters. Do **not** delete source branches in the same operation; retain for audit/rollback. If rollback is required, plan a revert by merge commit boundaries with history / storage impact assessment; never force-push master.
