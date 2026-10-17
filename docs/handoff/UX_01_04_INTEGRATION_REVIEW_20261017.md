# UX-01 → UX-02 → UX-03 → UX-04 Code Review 與整合驗收

**Date:** 2026-10-17  
**Base master:** `41d0ac604554dc3581cbe59b796b172e81270ee9`  
**Integration:** `integration/ux01-ux04-reviewed-20261017`  
**State:** INTEGRATION TESTING; **master is unchanged until clean integrated CI**.

## Review source and source-level status

| Slice | Source SHA | Evidence | Player experience |
| --- | --- | --- | --- |
| UX-01 | `017033af82f4209c170a6a3b2da52b5efc72e094` | Flutter analyze/test/web code job PASS; [latest browser CI #38990644555](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38990644555) was still in progress on first review | No-account home, Demo first play, localized navigation and protected resume |
| UX-02 | `2140509eca0fd25ad786e8ed1afc6dd5fff06deb` | [Flutter CI #38990365337](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38990365337) 180/180, web build + Chrome Demo PASS on unchanged implementation; latest docs/Learning Gate PASS | Terminal results, signed score from human viewpoint, replay and next deal, no fake MP/IMP |
| UX-03 | `b673eea766c6cd79a97d76a4ef05fcb1edbce546` | [Flutter CI #38990226292](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38990226292) 180/180, Chrome Demo PASS on unchanged implementation; Learning Gate PASS | Terminal review links to only verified teaching fixtures, returns to source frame |
| UX-04 | `3501bc2c2085e0e1430b7ba33107eb139c5e19c8` | [Flutter CI #38990454977](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38990454977) 179/179 + Chrome Demo PASS on unchanged implementation; Learning Gate PASS | UTC daily original practice, 0–4 progress, safe continuation, no ranking |

**Source documents may still show CI PENDING because their final handoff documentation was not synchronized with the later workflow verdict. Source scope is distinct from integrated acceptance.**

**Latest UX-01 source handoff:** the source branch later advanced to `d4e8a8ec9c86db6f5f5e764ac95bf9753dec216b` with documentation, CI-note and temporary task cleanup only; no changes to tested runtime source. This later commit is explicitly included as a second-parent merge, preserving the feature branch's final history.

## Merge order and conflict policy

1. UX-01 app shell → UX-02 terminal results → UX-03 review-to-learn → UX-04 daily return.
2. Merge commits contain the original feature tips as second parents; only the resulting working tree omits transient `AGENT_TASK.md` and source-branch-only CI triggers.
3. Shared `bridge_app.dart` and `app_copy.dart` were integrated using line-level, original-master-anchored patches: preserve UX-01 home, UX-02 results/replay navigation, UX-03 callbacks/deep links and UX-04 daily panel; do not overwrite whole files.
4. Four unique learning IDs retained: UX-01 `M2-F53`, UX-02 `M2-F54`, UX-03 `M2-F55`, UX-04 `M2-F56` in the index. No new lesson IDs needed solely for this integration.
5. New UX-01 browser first-play flow is added to existing Demo Chrome runs, alongside previous table and secure checkpoint flows; actual integrated Flutter/Web/BEN/Chrome regression must run. Explicit Android emulator or Android/iOS devices remain ON HOLD.

## Review focus and risk boundaries

- **Resolved:** while a B6 board has finished, UX-02's terminal result is sole owner of Next; the UX-04 summary still shows progress but hides its secondary next action. A regression test checks exactly one Next and invokes the Core session's existing `nextDailyBoard`. Keep this behavior when adjusting homepage design.
- Navigation from history→academy→same timeline index must never create or mutate a game; opt-out learning attempts remain unrecorded.
- Home's Demo and genuine BEN must not be silently conflated; gateway server session cannot be locally restored as BridgeSession.
- Core owns scoring, pass-out and legal transitions. Finished PBN/hidden hands cannot be leaked via new UI or analytics.
- A4.5 staging static artifacts are unrelated and do **not** mean production hosting is live. Do not enable ranking/IMP, login or notifications.
- User interviews not performed (`USER_STUDY_NOT_RUN`); Android/iOS device gate untouched.

## Integration regression discovered
- [First real BEN integration #38991549552](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38991549552) **FAILED** in legacy `browser_gateway_real_test.dart`: expected `gateway_mode_notice` immediately after `BridgeAcademyApp()`, but UX-01 now legitimately starts on Home. The test (not BEN/Core) was using obsolete table-first navigation. Updated the true BEN E2E to assert Home, the absence of Demo quick-start, then click `ux_home_gateway` before exercising the real 52-card gateway game. Full re-run pending.

## Integrated CI

PENDING. Do not merge to master until mandatory checks are green. Note exact SHA and run URLs with conclusions, including any failures and corrections.

## Rollback

All merges preserve original feature commits. Revert by feature scope after confirming active session and learning storage are unchanged; do not force-push master.
