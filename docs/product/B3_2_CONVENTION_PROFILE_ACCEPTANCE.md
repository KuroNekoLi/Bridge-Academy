# B3.2 / C2 — Versioned Convention Explainer Acceptance

**Branch**: `feature/b3-convention-profile`
**Status**: SCOPED VERIFIED (Flutter unit/widget + Web + Chrome demo; expert review pending)
**Date**: 2026-10-16

## Player-visible slice
- During the existing auction-only B3.1 practice, show `BA-NATURAL-NT r1` profile and explanations traced by stable rule ID, a localized rule description, a public-auction-only assumption, a reference, and a prominent **not expert-reviewed** label.
- Opt into `r2` proposed previews through the "Preview proposed agreements" chip; show only when the public sequence is *uncontested opener 1NT -> partner's 2C/2D/2H response*. The exact examples are Stayman, transfer to hearts and transfer to spades.
- No matching context -> explicit UNKNOWN, including any opposing bid, Double/Redouble, malformed chronology, unsupported replies or profile-version mismatch. Version mismatch is UNSUPPORTED at the domain API.
- The profile toggle is **presentation-only and local ephemeral UI state**. It does not change `BiddingPracticeBot.suggest`, Bridge Core call legality, BEN configuration, persisted checkpoint, scoring or session modes.

## Data and migrations
- B3.1 public API `BiddingPracticeProfile.id == BA-NATURAL-NT` and `revision == 1` retained; legacy `BiddingPracticeProfile.explain(List<AuctionEntry>)` delegates to the new engine while keeping legacy localized keys.
- `ConventionProfiles.basic` uses r1 and its four existing educational meanings.
- `ConventionProfiles.preview` uses r2 (same profile ID, 3 additional preview-only rules). A client must pass an exact expected revision to enable a matching result, not silently treat unknown revisions as compatible.
- `BidContext` takes only dealer, viewer, vulnerability and public chronological auction; no private `Deal` and no other hands.
- Only explicit-context and noncompetitive sequences resolve. All semantics are **educational assumptions, not claims about a bidder's actual HCP/length**.

## External teaching references (not implementation code)
- [ACBL — Stayman lesson 1](https://cdn.acbl.org/assets/documents/teachers/Teacher-Manuals/Commonly-Used-Conventions-Lesson-1.pdf)
- [ACBL — Jacoby Transfers lesson 2](https://cdn.acbl.org/assets/documents/teachers/Teacher-Manuals/Commonly-Used-Conventions-Lesson-2.pdf)
- Existing local [B3.1 teaching baseline](B3_BIDDING_PRACTICE_ACCEPTANCE.md)

These sources guide *proposed* descriptions only; the current profile has **not** been independently reviewed or approved by bridge experts, and no AI strategy/profile compatibility report has been verified.

## Scope tests
- `cd apps/bridge_academy_flutter && flutter analyze --no-pub`
- `cd apps/bridge_academy_flutter && flutter test --no-pub`
- `cd apps/bridge_academy_flutter && flutter build web --no-pub --release`
- **EXECUTED / PASS:** [Flutter branch CI #38909043985](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38909043985)（Commit `38d2e96e2d8ce437d90162d1e3c2de1fd8a172fe`）：`flutter analyze --no-pub` **No issues found**；`flutter test --no-pub` **129/129 passed**；`flutter build web --no-pub --release` **PASS**；ChromeDriver demo browser E2E **PASS**。
- Tests `test/b3_2_convention_profile_test.dart` and `test/b3_2_convention_widget_test.dart`; regression requires B3.1, A5/B1/B2 and ordinary Flutter test suite.

## Remaining gates / limitations
- Expert judgment, partnership agreement conflict detection outside current exact simple sequences, authoritative SAYC/2-over-1 profile, actual BEN loaded-system compatibility and teaching evaluation remain **NOT DONE**.
- Android emulator and physical iOS/Android E2E are **ON HOLD by owner**.
- Rollback: revert this feature branch's code commit before integration; existing B3.1 API, stored sessions and scoring are unchanged.
