# Bridge DDS Adapter (C1)

This independent pure-Dart API (plus opt-in native Python worker) computes
**postgame** double-dummy tables using an externally installed genuine DDS3
engine. No solver binary is checked into Bridge Academy.

## Local tests
```bash
cd packages/bridge_dds_adapter
dart pub get
dart analyze --fatal-infos
dart test --reporter expanded
python3 -m py_compile tool/dds3_worker.py
dart compile js tool/web_compile_smoke.dart -o /tmp/c1-web-smoke.js
```

Regular tests use fake subprocesses for protocol checks; real DDS is opt-in
and must not be misrepresented by those test results.

## True solver
Use the pinned upstream revision listed in
[license/source audit](../../docs/product/C1_DDS_THIRD_PARTY_AUDIT.md);
build `//python:dds3_wheel_dist` using Bazelisk, install its wheel into
**Python 3.14** (upstream `MODULE.bazel` pins 3.14), and run:

```bash
C1_DDS_REAL=1 C1_DDS_WORKER=tool/dds3_worker.py \
  dart test test/dds3_real_golden_test.dart --reporter expanded
```

The branch CI runs the heavy native job only for `workflow_dispatch`
or an explicitly tagged `[dds-golden]` commit, keeping default dev CI fast.

## Trust / API rules
- Use `TrustedCompletedBoard.fromTrustedTranscript(...)` **only** with
  already authorized, trusted, encrypted and terminal storage archives.
  Bridge Core replays the full action log; incomplete and Pass Out boards
  cannot be analyzed by this slice.
- `explicitTeachingFixture` is for clearly labeled original exercises,
  never for live bots. Never give full Deal/PBN to a player, Web Gateway
  or `BotPolicy`.
- Create `DdsPythonProcessAnalyzer(workerScript: <absolute path>)`;
  it sends PBN via private **stdin**, caps stdout, discards stderr, supports
  `analyzeWithCancellation` and timeout, and returns a validated typed
  5×4 table. UI/BEN cannot call it during live play.
- Browser gets the conditional `unsupportedPlatform` adapter; no
  fabricated solver results. Result is omniscient DD **not** a human
  information-constrained play recommendation.
- C1.5 UI integration belongs to B5 after integration review. No
  production hosting, no packaged native distribution until license/security
  review.
