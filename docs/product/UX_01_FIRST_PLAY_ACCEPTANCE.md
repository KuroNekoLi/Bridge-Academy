# UX-01 First Play Experience — 2026-10-17

**Branch:** `feature/ux-01-first-play-experience`  
**Scope:** Guest Home, bilingual app navigation, local Demo quick play, explicit custom play, Learning entry, History/Review, Daily practice, protected resume.  
**Current status:** SCOPED VERIFIED: Flutter analyzer, 181/181 tests and Web Release; Chrome E2E still running. **USER_STUDY_NOT_RUN**.

## Player-visible operation
- Normal app launch shows a guest Home (no login). Select **quick Demo** to begin the existing fixed teaching board with North as the human seat, using Bridge Core rules; BEN is always explicitly distinguished from Demo.
- The app shell provides usable Home/Play/Review/Me navigation and an Academy entry. No empty competition rankings. The **short practice** entry reuses existing bidding and Just Declare actions at the table. The **daily practice** entry reuses B6's fixed unranked four-board mode.
- Existing uncompleted local practice shows Resume and never automatically re-deals. Recovery-confirmation and save failure are visible warnings; local unfinished deal replacement from the new shell requires confirmation.
- Explicitly configured Gateway stays server-owned, with **no automatic Demo fallback**; connection availability is not asserted. No cross-process Gateway resume is promised. Without trusted BEN configuration, advanced local BEN selection is unavailable on normal home-driven entry.
- Injected test sessions and Gateway mocks default to legacy table unless `showHomeOnLaunch: true`, keeping pre-existing deterministic Widget/browser fixtures unaffected. Normal uninjected app launch always opens Home.

## Acceptance and testing
Commands: `cd apps/bridge_academy_flutter && flutter analyze && flutter test && flutter build web --release`. 
Browser: `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/browser_ux_01_first_play_test.dart -d web-server --browser-name=chrome`. 
Test cases: guest quick Demo -> Core action, resume without replacement, explicit abandonment confirmation, bilingual Academy navigation, 320/375px screens, injected Gateway no fallback.

**CI verified on source commit `017033af`:** [Flutter run #38990644555](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38990644555) confirms `flutter analyze --no-pub` **No issues**, `flutter test --no-pub --reporter expanded` **181/181 PASS**, and `flutter build web --no-pub --release` **PASS**. Its ChromeDriver job was still **IN PROGRESS** at handoff; no browser E2E PASS is claimed. [Feature Learning Gate #38990644630](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38990644630) **PASS**. No SDK is installed in the local working container; testing was executed by GitHub Actions. 

**Earlier regression evidence:** Initial CI [#38990276470](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38990276470) failed Flutter analysis (corrected) and previous default table-first WebCrypto browser assumption (test adapted to Home → Table). Full verification remains pending. NOT RUN locally (this workspace does not include Dart/Flutter). CI run URL and verdict pending. Device emulator and Android/iOS physical E2E remain on explicit owner hold.

## Lightweight manual user-study script (not executed)
Recruit 5 beginners and 5 experienced bridge players for independent Web walkthroughs: open the app, identify Demo vs real BEN, start a legal move, leave and resume, open a lesson and answer the first question. Record whether each step succeeds unaided, time to first valid action, visible confusion and any request for help. Redact names and never log hands/PBN/tokens. All observed outcomes and rates remain NOT RUN.

## User study
**USER_STUDY_NOT_RUN.** Recruiting 5 beginners + 5 experienced players, observing the time to first legal action, successful return from Learning and perceived Demo/BEN distinction remain pending. No retention, task-success, or satisfaction numbers are invented.

## Risks / rollback
- No published BEN HTTPS availability is claimed; a developer-configured local BEN is a separate option.
- No app-account storage, leaderboard, telemetry or clipboard collection was added.
- Revert the UX-01 commits to restore legacy table-first shell; no Bridge Core schema or durable session format changed.
