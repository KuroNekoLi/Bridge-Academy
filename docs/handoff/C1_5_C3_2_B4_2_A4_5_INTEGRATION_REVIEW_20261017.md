# C1.5 + C3.2 + B4.2 + A4.5 — Integration Code Review

**Date:** 2026-10-17  
**Base:** master 6b93bfcfb7f852c1521a29f164694ae4f6779921  
**Integration branch:** `integration/c1-5-c3-2-b4-2-a4-5-reviewed-20261017`  
**Status:** APPROVED FOR SCOPED MASTER MERGE, NOT release/production approval.

## Reviewed sources and boundaries
- C1.5 `feature/c1-5-dds-review-integration` @ `c5c24d5e7fd954aa45c6fde1c074fd3b13b905ea`: terminal-only trusted transcript -> typed 5×4 DDS table; Flutter/Web mock adapter tests passed; **native DDS worker was not executed in this feature's CI**. Browser unsupported, no real per-move SolveBoard, not a live cheat surface. Source CI Flutter 161/161 and Learning Gate PASS.
- C3.2 `feature/c3-2-personalized-recommendations` @ `fd262ba07c7f5c0504ceead50698dac74fbf6664`: opt-in local pure deterministic learning recommendations, invalid/obsolete attempts ignored. Source CI Flutter 165/165 and Learning Gate PASS.
- B4.2 `feature/b4-2-advanced-lessons` @ `86503cfd6e1d546143d16fd5de63472eb4aec889`: 3 additional lessons/12 new questions; 6/21 total; unreviewed convention previews labeled as such; original question IDs preserved. Source CI Flutter 164/164 and Learning Gate PASS.
- A4.5 `feature/a4-5-deployment-readiness` @ `90b5654c51d919671abafb3d7042c94e7fdc6da4`: staging-only Zeabur prototype, static fail-closed checks, no deployed host or license approval. Source static CI PASS. Do not claim production readiness or deploy without owner authorization.

## Integration resolutions
1. Retained C3.2's `academy_page.dart` behavior and B4.2's bilingual page title, rather than overwriting the opt-in recommendation UI.
2. Extended C3.2's new-user recommendations test from 3 fixed lessons to `lessons.length` (=6 after B4.2) and used B4.2's updated B4/C3 scrolling tests.
3. Assigned distinct IDs **M2-F50 C1.5**, **M2-F51 C3.2**, **M2-F52 B4.2**; kept the original English/Chinese lesson content and corrected the index links, while retaining all source commit histories using genuine two-parent merge commits.
4. Kept B4.2's advanced-course roadmap entry and A4.5's static-preflight deployment gate; recorded C1.5/C3.2 bounds.
5. Fixed A4.5 staging auth/config mismatch: runtime now demands exactly `/run/secrets/staging_htpasswd` (the path Nginx uses) and readability by worker `www-data`; exactly one strict HTTPS browser origin is accepted. This is a preventive static improvement, **not proof staging Docker runs**.
6. Integration-only CI branch filter temporarily enables Flutter/Chrome, Learning Gate, genuine BEN Browser, and A4.5 static checks. Restore ordinary master-only triggers before master promotion.

## Review limitations and release gates
- DDS native-runtime E2E and a production-distributable DDS worker remain unverified for the C1.5 Flutter UI.
- C3.2 suggestions are transparent heuristics, not expert bridge judgment; six-course expanded catalog cannot be treated as evidence of learner mastery.
- A4.5 source CI and prototype Docker are **NOT** actual TLS, hosted staging, authoritative multi-user identity, production licensing, production latency/cost benchmarks, or public launch approval.
- Android/iOS emulator and physical device UI/E2E stay **on user hold**. No PR; after merged CI succeeds, fast-forward master only with non-forced expected-SHA lease.

## Integration CI regression and correction
The first combined Flutter run [#38985456049](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38985456049) **FAILED 4 widget tests** while the independent Chrome Demo job passed. Review traced the failures to a missing B4.2 course-list bilingual welcome copy and to C3/C3.2 widget tests assuming lazily-created controls were already mounted after B4.2 expanded to six lessons. Restored B4.2's zh-TW/en welcome; used bounded scrollUntilVisible for the two genuinely offscreen controls. A second full combined test is mandatory. The next branch push also corrects the Feature Learning Gate failure on that code-only fix: the lesson and index now document the integration-regression knowledge and the six-lesson catalog.

## CI evidence

- [Flutter CI #38985726254](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38985726254) @ `a5d5f361e3bf5f8f4e8bf116ff3cd625adea54ee`: `flutter analyze` **No issues**, **174/174 Flutter PASS**, `flutter build web --release` **PASS**, ChromeDriver Demo browser E2E **PASS**.
- [Learning Gate #38985807858](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38985807858) @ `964294c6fca99d83a23f98d8ab7ada14c3a85e5f`: **PASS**. The earlier code-only fix at `a5d5f36` briefly failed the learning gate, resolved by updating both lessons and the index. The verified source tree is unchanged by the subsequent documentation-only commit.
- [A4.5 staging static preflight #38985456108](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38985456108) @ `2ebbe2da7fbb759857dc039911521d00e40f6013`: **PASS**, includes staging auth guard source, no Docker build or hosted deployment.
- [True BEN Chrome E2E #38985456098](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38985456098) @ `2ebbe2da7fbb759857dc039911521d00e40f6013`: **PASS**. The newer [true BEN CI #38985726283](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38985726283) on the Flutter-tested commit was still **IN PROGRESS at review finalization**. Code changes after `2ebbe2da` only repaired Academy copy/test scrolling; no Gateway/Bridge Core/BEN domain changes.
- Initial combined Flutter #38985456049 failed four integration-specific UI tests; this is recorded rather than hidden. All four succeeded within final 174/174 and no new player feature was dropped.
- Workflow branch filters are restored by the final integration commit; master push triggers normal master CI again. Full native DDS3 runtime E2E on C1.5 and actual HTTPS staging deployment have **NOT RUN** and are separate release gates.


## Rollback
Revert by merge boundaries after reviewing the stored C3 schema (no migration introduced), never force-push master. Feature branch source histories remain retained.
