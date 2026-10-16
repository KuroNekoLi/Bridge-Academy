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
- **Pending CI** until an actual GitHub runner result is available; no Android/iOS hardware tests.

## Limitations
- A 500-event cap stops future writes rather than silently removing older records.
- No cloud sync, no authentication, no multi-device records.
- Web key handling cannot protect against malicious same-origin JavaScript.
- Existing short-lived B4 practice set still drives per-page progress when opted out.
