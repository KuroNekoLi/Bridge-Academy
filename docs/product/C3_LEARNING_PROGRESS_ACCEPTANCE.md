# C3 Learning Progress — Branch Acceptance

**Scope:** Consent-based persistence of B4 learning attempts, unique completed question count, per-skill statistics, restart recovery, and confirmed deletion.

## Implemented
- B4 `AcademyPractice` remains sole grader, `LearnerAttempt` stores only answer metadata (no Deal, PBN, or hidden seats).
- Default opt-out: only on explicit activation an AES-GCM ledger is created under a dedicated browser key/native SQLite file and purpose-specific AAD. Existing session/daily stores are untouched.
- Versioned v2 with explicit v1 read-compatibility, capped at 500 attempts and 96 KiB. Unknown version/tampering are rejected instead of silently resetting; user may explicitly clear damaged data.
- Summary of completed question IDs, real attempt-based correct rate, skill-tag rates (including empty data), and recent attempts.
- Opt-in, pause/resume and permanent deletion are distinct actions: pause retains existing encrypted records; resume records new answers; deletion clears them and disables persistence.

## Verification
- `cd apps/bridge_academy_flutter && flutter analyze && flutter test && flutter build web --release`.
- Added `test/c3_learning_progress_test.dart` for domain, authenticated encryption/tampering, Widget flow.
- **SCOPED VERIFIED**: [Flutter CI run #38919859220](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38919859220) on code commit `59faf0297` reports `flutter analyze` (No issues found), **151/151 Flutter tests**, `flutter build web --release` (PASS), and real ChromeDriver demo E2E (PASS). [Feature Learning Gate #38920287566](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38920287566) also PASS after documenting the paused-history change. Android/iOS device tests remain on hold.

## Limitations
- A 500-event cap stops future writes rather than silently removing older records.
- No cloud sync, no authentication, no multi-device records.
- Web key handling cannot protect against malicious same-origin JavaScript.
- Existing short-lived B4 practice set still drives per-page progress when opted out.

## Merge handoff
- Source branch: `feature/c3-learning-progress`; only this branch was updated, not master.
- Shared code changed: `academy_page.dart`, `secure_session_persistence.dart` (optional key name), `docs/learning/INDEX.md`. Integration Agent should resolve with other branches before merging.
- Temporary branch CI workflow triggers should be removed before final handoff; the above immutable run URLs remain valid.
