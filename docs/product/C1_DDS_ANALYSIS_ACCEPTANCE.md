# C1 — Trusted postgame DDS analysis | Acceptance Report

**2026-10-16 · Feature branch `feature/c1-dds-analysis` · WORK IN PROGRESS / CI PENDING.**
No master merge, public UI, Android emulator or mobile device test has been performed.

## Scope and functionality
C1.1 / C1.2 implemented: typed `TrustedCompletedBoard`, `DoubleDummyTable` (declarer × strain = 20 values), `DoubleDummyAnalyzer`, `DdsPythonProcessAnalyzer`, process timeout and sanitized error categories, explicit unsupported adapter and test-only original teaching fixture.

C1.3 implemented as a runnable **branch CI golden gate** for real DDS3, not yet declared VERIFIED until a successful [C1 Actions run](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/c1-dds-analysis.yml). It pins an Apache-2.0 DDS3 source SHA, builds upstream Python wheel, then executes 3 original fixed PBN fixtures × 20 cells × 2 runs with suit/NT/direction assertions. The ordinary Dart contract test uses a fake Python worker *only* to verify isolated transport and matrix parsing; it is NOT counted as genuine DDS verification.

C1.4 intentional boundary: no edits to B5 Replay UI, player Gateway, `BotPolicy`, Flutter app, scoring logic or persisted checkpoint. UI integration belongs to later C1.5 after B5 completes.

## Acceptance checklist
| Requirement | Test/evidence | Status |
| --- | --- | --- |
| Reject ongoing game, corrupt/partial archive and Pass Out | `double_dummy_analysis_test.dart` | CI PENDING |
| Replay a completed 13-trick trusted game | `double_dummy_analysis_test.dart` | CI PENDING |
| Map S/H/D/C/NT rows to N/E/S/W declarers, reject invalid matrix | Dart contract tests | CI PENDING |
| Timeout, unavailable native worker, opaque failure messages | Dart contract tests | CI PENDING |
| True DDS3 `calc_dd_table` deterministic original fixtures | `dds3_real_golden_test.dart` with `C1_DDS_REAL=1` after pinned upstream build | CI PENDING |
| Web / browser | Explicit typed unsupported; no binary inserted into Flutter | By design |
| Android emulator / iOS / mobile physical UI E2E | Owner held | NOT RUN |
| Expert evaluation and human limited-information play quality | Not a DDS inference | NOT CLAIMED |
| Redistribution/transitive licensing | [source audit](C1_DDS_THIRD_PARTY_AUDIT.md) | DISTRIBUTION NOT APPROVED |

## Commands and evidence
```sh
cd packages/bridge_dds_adapter
dart pub get
dart analyze --fatal-infos
dart test --reporter expanded  # REAL DDS golden test is SKIPPED without env
python3 -m py_compile tool/dds3_worker.py
# With verified pinned DDS3 wheel installed, run:
C1_DDS_REAL=1 C1_DDS_WORKER=tool/dds3_worker.py \
  dart test test/dds3_real_golden_test.dart --reporter expanded
```

At initial submission, the code/runtime tests could not be executed locally: no Dart SDK or dds3 installed in this environment. Use same-SHA GitHub CI only; do not assert test PASS before reading its result. The isolated C1 workflow is branch-only to prevent resource cost on every master push. `master` stays unchanged.

## Known limitations / rollback
- No public interactive analysis screen (B5 will own UI after review); cannot claim player-facing complete.
- No persistent DD cache or unauthenticated HTTP interface by design.
- Client authorization before reading the encrypted terminal archive is **caller responsibility**; `TrustedCompletedBoard` is a trust boundary contract, not an authentication mechanism. No service deployment or distribution approval.
- Rollback via reverting C1 branch commits; no data migrations, Bridge Core or BEN changes.
