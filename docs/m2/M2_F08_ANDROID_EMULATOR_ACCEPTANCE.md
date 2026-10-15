# M2-F08 — Android emulator QA

**Status 2026-10-15: Android emulator QA NOT YET VERIFIED; second CI run started after disk fix.** [GitHub Actions #38685813955](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38685813955) started on implementation SHA 12ea0b1486ee0c0917757f7ae5f0fe6cf366fbea. At the latest inspection, checkout, Flutter setup, native Android platform generation, dependency resolution and KVM setup had succeeded; the emulator-runner/UI execution step was still in progress. **No Android device test PASS is claimed** until the job finishes successfully.

## Gate
- GitHub workflow: .github/workflows/flutter-android-emulator.yml
- Test: apps/bridge_academy_flutter/integration_test/android_table_test.dart
- True Flutter Android APK running on API 35 x86_64 Pixel 5 emulator, KVM-enabled Ubuntu runner.
- Native device touches: language change, new game (13 private hand cards, dummy hidden), four chronological passes / 0 NS score, restart, bid 1NT, bot opening lead, exposed Dummy and legal Dummy card click / version increment.
- Uses fixed synthetic deal and deterministic Demo Bot, not actual BEN. Browser M2-F07 separately verifies genuine BEN.
- Test command from Flutter App directory, booted emulator required:

    flutter create --platforms=android --project-name=bridge_academy_flutter .
    flutter pub get
    flutter drive --driver=test_driver/integration_test.dart --target=integration_test/android_table_test.dart -d emulator-5554

Evidence source: [Android Actions #38685813955](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38685813955). The verified outcome must be updated from the terminal run conclusion. Do not mark GO until executed Android emulator CI passes. No real hardware, Android BEN network, iOS, TalkBack or production signing covered.


## Observed failure and remediation

- [Initial Android CI #38685813955](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38685813955) **FAIL before Flutter device testing**: emulator fatal error during AVD boot: available runner disk 5597.93 MB; default userdata partition required 7372.80 MB. ADB subsequently could not find emulator-5554 until boot timeout. **No Android APK/UI tests ran in that job.**
- Fix at commit 8638fbe383d176582bc587f2bac2ab70442417b3: set emulator runner disk-size 2048M, SD card 128M and RAM 2048M, plus disk diagnostics, and shorten boot timeout to 300s.
- [Rerun Android CI #38687000645](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38687000645) — started. Its result is pending; do not mark Android GO before observing the final job conclusion.

## Second actual failure — documented 2026-10-15

[GitHub Actions #38687000645](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38687000645) ended **FAIL** before device UI execution. Despite `disk-size: 2048M` and 128M SD card, Android Emulator logged:
`FATAL | Not enough space to create userdata partition. Available: 5474.33 MB ... need 7372.80 MB.`
The config.ini did contain `disk.dataPartition.size=2048M`, but the emulator's effective userdata image requirement remained ~7.4 GB. Repeated ADB "device not found" entries were consequences of the failed boot, **not** app or bridge domain failures.

### Third attempt — reclaim disk before creating AVD

CI commit `3f5495aa5aefe47df18e8610086654f020d454d2`: prior to Android SDK/AVD creation, remove only unrelated preinstalled .NET, Haskell, PowerShell and CodeQL toolchains; preserve Flutter, Android and Java; require >=12 GiB available on /, print before/after disk snapshots. Also explicitly set Android Emulator `-partition-size 2048` in MB as documented by Android's official command-line interface. This addresses the **observed root cause** rather than assuming AVD config alone reduces disk usage.

Third attempt status: **NOT YET VERIFIED**. The earlier failures remain linked; do not infer emulator GO from CI bootstrap or Web tests.
