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
