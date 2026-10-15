# M2-F08 — Android emulator QA

**Status 2026-10-15: Android emulator QA RUNNING / NOT YET VERIFIED.** [GitHub Actions #38685813955](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38685813955) started on implementation SHA 12ea0b1486ee0c0917757f7ae5f0fe6cf366fbea. At the latest inspection, checkout, Flutter setup, native Android platform generation, dependency resolution and KVM setup had succeeded; the emulator-runner/UI execution step was still in progress. **No Android device test PASS is claimed** until the job finishes successfully.

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

