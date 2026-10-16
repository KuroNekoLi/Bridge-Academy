# C1 DDS3 third-party source/license/build audit — 2026-10-16

## Upstream provenance (pinned immutable reference)
- Project: https://github.com/dds-bridge/dds
- Exact source revision: [`abb1127ba096676a4849f341f300c9827a732342`](https://github.com/dds-bridge/dds/commit/abb1127ba096676a4849f341f300c9827a732342) (develop snapshot; DDS3 `MODULE.bazel` version reported as 3.1.1 in upstream README at inspection).
- License text verified on that source tree: [LICENSE](https://github.com/dds-bridge/dds/blob/abb1127ba096676a4849f341f300c9827a732342/LICENSE), **Apache License 2.0**, copyright acknowledgments for Bo Haglund and Søren Hein. The LICENSE gives a standard Apache-2.0 redistribution notice, preservation and NOTICE obligations. Do not assume the separate BEN weights or Bridge Academy itself share the same license.
- API source/docs: `python/dds3/__init__.py`, [Python Interface](https://github.com/dds-bridge/dds/blob/abb1127ba096676a4849f341f300c9827a732342/docs/python_interface.md), `python/BUILD.bazel`, `library/src/api/dll.h`. Direct `calc_dd_table` accepts a 4×4 rank-bitmask matrix **[N,E,S,W] × [S,H,D,C]** and emits 5×4 trick counts **[S,H,D,C,NT] × [N,E,S,W]**.
- Integration method: **no DDS code, release binary, Python wheel or upstream NOTICE is vendored into Bridge Academy**. `tool/dds3_worker.py` is our own adapter and calls the upstream DDS Python API in a standalone native subprocess. CI builds an upstream wheel from this SHA using upstream Bazel and installs it on its temporary runner. Pinned upstream `MODULE.bazel` selects hermetic **Python 3.14**; the native wheel must be loaded using Python 3.14, not 3.12. Upstream wheel currently advertises `py3-none-any` despite containing a native extension; packaging/ABI metadata is a distribution blocker until separately audited.
- Supported claim: CI Linux x86_64 process adapter, if the native golden workflow actually succeeds. Python-native DDS3 on macOS/Windows may be possible via upstream builds but has **not** been executed or verified in this branch. Flutter Web remains unsupported for this native process adapter; it must explicitly use `UnsupportedDoubleDummyAnalyzer` and never fake a result.

## License and security gate
Apache-2.0 permits use and modification/distribution when its terms are complied with. **No distribution currently occurs from this feature branch**, so a packaged mobile/native application would require independent review of exact binary/wheel, transitive Bazel/pip dependencies, their NOTICE/attribution, dynamic-linking/redistribution model, export classification as applicable, and security advisories. A pin plus unit tests do NOT complete a future commercial distribution audit. LICENSE remains upstream; do not copy or strip it. Audit status: **SOURCE VERIFIED / DISTRIBUTION NOT APPROVED**.

The process only accepts one private full-deal PBN via capped **stdin**, not argv, URL or environment. Its stdout is a bounded public-after-terminal result matrix; stderr is discarded and never reflected in player errors. Test fixtures are explicitly marked as teaching fixtures. Any production entry point must fetch a terminal event transcript from a trusted encrypted store, confirm current user access to that exact board, reconstruct all actions using `GameTranscript.decode`, and only then create `TrustedCompletedBoard`. This API does not itself authenticate a web requester.

DDS knows all 52 cards: it must **never** be supplied to `BotPolicy.choose`, a live `PlayerView`, or a competition opponent and must not be exposed before a deal finishes. A double-dummy optimum is omniscient and is not evidence that a human should have selected a particular play from limited information.

## Build/reproduction
```sh
git clone https://github.com/dds-bridge/dds.git /tmp/c1-dds-upstream
cd /tmp/c1-dds-upstream
git checkout --detach abb1127ba096676a4849f341f300c9827a732342
bazelisk build -c opt //python:dds3_wheel_dist
find bazel-bin/python -name '*.whl'  # install selected wheel in isolated Python 3.12
```

[Branch-only CI workflow](../../.github/workflows/c1-dds-analysis.yml) drives separate Dart contract/unit checks and **true upstream native DDS** golden tests. Each runtime should have bounded CPU/memory/time. Build must be logged by upstream SHA; full Deal must not appear in CI error logs. Rollback: revert adapter/docs/CI commits only; nothing has modified Bridge Core, Flutter UI, BEN or persisted checkpoint schema.
