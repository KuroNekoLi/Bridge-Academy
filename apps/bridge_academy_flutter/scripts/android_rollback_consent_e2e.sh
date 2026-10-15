#!/usr/bin/env bash
set -euo pipefail
# Run from apps/bridge_academy_flutter with Android emulator-5554 running.
# Every flutter drive below launches a separate instrumentation process.
# The first TWO runs must preserve the installed app and private storage.
force_stop_app() {
  local package
  package=$(adb shell pm list packages | tr -d '\r' | sed -n \
    's/^package:\(.*bridge_academy_flutter.*\)$/\1/p' | head -n 1)
  if [[ -z "$package" ]]; then
    echo "Installed Bridge Academy app not found" >&2
    exit 1
  fi
  adb shell am force-stop "$package"
  if adb shell pidof "$package" | grep -qE '[0-9]'; then
    echo "App process did not stop" >&2
    exit 1
  fi
}
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/android_rollback_prepare_test.dart \
  --keep-app-running -d emulator-5554
force_stop_app
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/android_rollback_no_consent_test.dart \
  --keep-app-running -d emulator-5554
force_stop_app
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/android_rollback_confirm_test.dart \
  -d emulator-5554
echo "A2_6_ANDROID_THREE_PROCESS_ROLLBACK_CONSENT_PASS"

