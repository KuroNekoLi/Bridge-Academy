# M2-F18｜Android 兩次強制關閉後，存檔回退警告仍須保留

- Feature ID：M2-F18
- Milestone：Phase A2.6／P1.2
- 類型：Flutter Android 真正跨程序故障注入／資料恢復驗收
- 工程狀態：IMPLEMENTED（Android 三次啟動 CI 尚未實測）
- 學習狀態：DELIVERED
- 原始碼：apps/bridge_academy_flutter/integration_test/android_rollback_prepare_test.dart、android_rollback_no_consent_test.dart、android_rollback_confirm_test.dart、scripts/android_rollback_consent_e2e.sh
- 驗收：docs/product/P1_A2_6_ANDROID_ROLLBACK_CONSENT_ACCEPTANCE.md

## 功能目的與實際情境

假設玩家剛叫完一個 Pass，App 最新存檔受到破壞，只能還原「玩家叫牌前」的上一次合法存檔。即使 App 再被 Android 強制關閉一次，玩家也必須知道有可能失去剛才的操作，而且在玩家明確同意前，AI 不可自行繼續打牌。

A2.5 已有 Dart/Flutter Widget Tests；本次新增在 Android Emulator **三個獨立 App 程序**的裝置驗收，避免誤把「重新 new 一個物件」當成真正 Process Death 測試。

## 主要程式碼導讀

三個獨立的 \`flutter drive\` 透過 Shell 串接：

~~~bash
flutter drive --target=integration_test/android_rollback_prepare_test.dart \
  --driver=test_driver/integration_test.dart --keep-app-running -d emulator-5554
adb shell am force-stop "$package"
flutter drive --target=integration_test/android_rollback_no_consent_test.dart \
  --driver=test_driver/integration_test.dart --keep-app-running -d emulator-5554
adb shell am force-stop "$package"
flutter drive --target=integration_test/android_rollback_confirm_test.dart \
  --driver=test_driver/integration_test.dart -d emulator-5554
~~~

正式腳本會先使用 \`pm list packages\` 找出 App package，並用 \`pidof\` 確認強制關閉成功。第一個程序寫入兩個經 Domain 驗證的版本，故意破壞活躍版本；第二個程序確認必須回退上一筆、畫面呈現警告且 Pass 無法點；第三個程序證明第二次重開後警告未消失，再透過真實 Flutter Widget 的確認按鈕解鎖一次合法 Pass。

專案原本的 \`PreferencesSessionArchiveStore\` 會把 \`recoveryPending\` 跟隨 Commit Marker 寫入裝置存儲。裝置 QA 透過實際關閉與重啟確認其值沒有被只存在記憶體的布林變數取代。

## 為什麼這樣設計

- **持續警告 = 玩家信任**：自動回復較早存檔，有可能讓玩家失去最近的一步操作；應明確告知並要求決策，而非默默重送 AI 指令。
- **Process Death vs. Object recreation**：Flutter Test 裡 \`BridgeSession()\` 建構兩次只驗證物件狀態；Android/Kotlin 的 \`ActivityScenario.recreate()\` 也不等同 \`adb am force-stop\`。本次是真的切斷整個行程再重新啟動。
- **Fail closed**：在確認前，UI \`pass\` 控制項保持 \`onPressed == null\`，底層 Session 即使被直接呼叫也不能更改版本；確認後才能從還原版本繼續。
- **替代方案與限制**：用全記憶體 Fake Store 測試更快、更穩定，適合日常回歸，但不能代替原生 SharedPreferences 實際寫入測試；本次也沒有證明斷電時 fsync 成功、資料加密、跨分頁互斥或真正 BEN 網路請求去重。

這相當於 Android 以 Room/DataStore 驗證持久化與 Process Death 時，必須有 emulator instrumentation 的 end-to-end 證據，而不只測試 Fake DAO。

## 驗證與實際證據

從 Flutter App 目錄、使用 Android API 35 emulator-5554 執行：

~~~bash
flutter create --platforms=android --project-name=bridge_academy_flutter .
flutter pub get
bash scripts/android_rollback_consent_e2e.sh
~~~

驗收需要三段獨立 process marker 與最後 PASS；**建立教材時 NOT RUN**。實際 CI URL、Commit SHA 與結果將回填正式驗收報告；不可借用 A2.3 已通過的普通還原 CI，宣稱本功能已驗收。

## 練習與自我檢驗

**思考題：** 如果 Process B 恢復了上一版存檔但尚未取得玩家同意，Process C 重啟後為什麼不能只檢查 \`version == 0\`，就讓 BEN 繼續自動叫牌？

**小練習：** 在 \`android_rollback_no_consent_test.dart\` 將 \`recoveryPending\` 預期由 \`true\` 改成 \`false\`，說明為何此測試應失敗，以及失敗對使用者的意義。

**完成標準：** 能解釋版本、合法回放、持久化確認旗標與真實 Process Death 是不同的保證。

## 下一步

A2 尚有正式加密、原子性與併發寫入設計缺口；下一個產品工程決策應選定正式 Native/Web 儲存後端，並規劃 migration 與 power-loss 實測，不能因本次 API 35 模擬器成功就標示 A2 PRODUCT READY。

