#!/usr/bin/env bash
set -euo pipefail
# Run from apps/bridge_academy_flutter with emulator-5554 booted.
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/android_persist_prepare_test.dart \
  --keep-app-running \
  -d emulator-5554

package=$(adb shell pm list packages | tr -d '\r' | sed -n \
  's/^package:\(.*bridge_academy_flutter.*\)$/\1/p' | head -n 1)
if [[ -z "$package" ]]; then
  echo "Bridge Academy Android application missing" >&2
  exit 1
fi
echo "Forcing real Android process stop; retaining app private storage."
adb shell am force-stop "$package"
if adb shell pidof "$package" | grep -qE '[0-9]'; then
  echo "Bridge Academy process is unexpectedly still running" >&2
  exit 1
fi

flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/android_persist_restore_test.dart \
  -d emulator-5554

echo "A2_3_ANDROID_REAL_PROCESS_RESTART_PASS"

