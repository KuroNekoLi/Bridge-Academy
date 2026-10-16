# C1 — Trusted postgame DDS analysis | Acceptance Report

**2026-10-16 · Feature branch `feature/c1-dds-analysis` · SCOPED VERIFIED (Dart + native Linux DDS3); no master merge.**
No master merge, public UI, Android emulator or mobile device test has been performed.

## Scope and functionality
C1.1 / C1.2 implemented: typed `TrustedCompletedBoard`, `DoubleDummyTable` (declarer × strain = 20 values), `DoubleDummyAnalyzer`, `DdsPythonProcessAnalyzer`, process timeout and sanitized error categories, explicit unsupported adapter and test-only original teaching fixture.

Python ABI correction: first DDS3 wheel built successfully on CI, but loading it with Python 3.12 failed because pinned upstream Bazel targets Python 3.14 (native ABI). The dedicated native job is updated to Python 3.14 and must obtain fresh evidence; no earlier success is claimed.\n\nC1.3 **TRUE DDS3 Golden PASS** on [native run #38919422293](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38919422293) at SHA `709dd10ee`: upstream Bazel wheel was compiled and installed with Python 3.14, `REAL_DDS_IMPORT_OK`, and true DD test passed. It pins an Apache-2.0 DDS3 source SHA, builds upstream Python wheel, then executes 3 original fixed PBN fixtures × 20 cells × 2 runs with suit/NT/direction assertions. The ordinary Dart contract test uses a fake Python worker *only* to verify isolated transport and matrix parsing; it is NOT counted as genuine DDS verification.

C1.4 intentional boundary: no edits to B5 Replay UI, player Gateway, `BotPolicy`, Flutter app, scoring logic or persisted checkpoint. UI integration belongs to later C1.5 after B5 completes.

## Acceptance checklist
| Requirement | Test/evidence | Status |
| --- | --- | --- |
| Reject ongoing game, corrupt/partial archive and Pass Out | `double_dummy_analysis_test.dart` | [Dart CI PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38919732769) |
| Replay a completed 13-trick trusted game | `double_dummy_analysis_test.dart` | [Dart CI PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38919732769) |
| Map S/H/D/C/NT rows to N/E/S/W declarers, reject invalid matrix | Dart contract tests | [Dart CI PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38919732769) |
| Timeout, explicit cancellation, unavailable native worker, opaque failure messages | Dart contract tests | [Dart CI PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38919732769) |
| True DDS3 `calc_dd_table` deterministic original fixtures | `dds3_real_golden_test.dart` with `C1_DDS_REAL=1` after pinned upstream build | [Native PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38919422293) |
| Web / browser | Explicit typed unsupported + `dart compile js tool/web_compile_smoke.dart` | [Dart Web compile PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38919732769) |
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

**Actual remote evidence:** [Dart contract CI #38919732769](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38919732769) at SHA `27177086c`: `dart analyze` No issues found; **6 Dart tests PASS + 1 intentional native golden SKIPPED** (not counted); Python `py_compile` PASS; JS Web compilation PASS. [True DDS CI #38919422293](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38919422293) at SHA `709dd10ee`: exact upstream DDS3 Python 3.14 wheel builds and imports, **3 PBN × 20 DD table cells × duplicate-run assertions PASS**. Those two successes were from different app-side commits; a final same-SHA complete run is requested by the `[dds-golden]` final handoff commit and must be checked separately. The isolated C1 workflow is branch-only to prevent resource cost on every master push. `master` stays unchanged.

## Known limitations / rollback
- No public interactive analysis screen (B5 will own UI after review); cannot claim player-facing complete.
- No persistent DD cache or unauthenticated HTTP interface by design.
- Client authorization before reading the encrypted terminal archive is **caller responsibility**; `TrustedCompletedBoard` is a trust boundary contract, not an authentication mechanism. No service deployment or distribution approval.
- Rollback via reverting C1 branch commits; no data migrations, Bridge Core or BEN changes.
