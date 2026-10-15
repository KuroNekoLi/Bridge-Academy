# M2-F15｜A2.3：Android App 行程重啟後的牌局恢復

- Feature ID：M2-F15
- Milestone：Phase A2.3 / P1.2
- 類型：Android Emulator 整合測試與本機持久化
- 工程狀態：IMPLEMENTED（Android CI 待驗）
- 學習狀態：DELIVERED（尚未進行練習）
- 原始碼：apps/bridge_academy_flutter/integration_test/android_persist_prepare_test.dart、android_persist_restore_test.dart、scripts/android_process_restart_e2e.sh
- 驗收與測試：docs/product/P1_A2_3_ANDROID_PROCESS_RESTART_ACCEPTANCE.md；.github/workflows/flutter-android-emulator.yml

## 功能目的與實際情境

玩家在 1NT 定約的主打階段，明手 South 已經公開，North 也已操作一張牌。App 被關閉後，玩家期待下次啟動時回到相同牌號、叫牌歷史、已出牌與目前回合，而不是再次開一副新牌，更不能重複提交玩家已做過的動作。

前一階段 A2.1 已有 GameTranscript 恢復邏輯；A2.2 有雙槽儲存及故障注入測試。本次不是重寫儲存，而是增加 Android OS 行程的跨啟動驗收。

## 主要程式碼導讀

執行流程（擷取自真實測試腳本）：

    flutter drive --driver=test_driver/integration_test.dart \
      --target=integration_test/android_persist_prepare_test.dart \
      -d emulator-5554

    adb shell am force-stop "$package"

    flutter drive --driver=test_driver/integration_test.dart \
      --target=integration_test/android_persist_restore_test.dart \
      -d emulator-5554

第一個 Android 測試寫入已經提交的 Checkpoint，留下版本與事件指紋（不另外記錄暗牌）。第二個 flutter drive 是新行程，從同一部 Android 模擬器的 SharedPreferences 恢復，檢查 PlayerView 的隱藏牌權限與合法出牌。還會啟動普通 BridgeAcademyApp，確認畫面顯示已恢復牌局，接著完成新動作並核對下一版本存檔。

## 為什麼這樣設計

設計概念是 OS-boundary integration testing。Flutter Widget Test 或 Kotlin 的 Fake DAO 測試，只能證明類別在同一個行程裡被正確使用；Android 的 instrumentation test 加上 adb force-stop，可以再確認安裝、Plugin 初始化、真實本機儲存以及新 App 行程之間的資料流程。

取捨是沿用 SharedPreferencesAsync 的現有 A2.2 實作而不額外引入 SQLite／Keystore 依賴。因此本次能驗證真 Android App 重啟，但**不能聲稱資料已加密、具有資料庫交易或斷電耐久性**。而且 Flutter drive 在 force-stop 之前可能已經結束第一個 App，因此此驗收也不是在寫入指令正好執行時殺死行程。

常見錯誤：在同一個 Dart 行程中依序 new 兩個 BridgeSession 並傳同一個 FakeStore，就說已經完成 Android 強制關閉恢復驗收。那仍是模組測試，沒有涵蓋 Android 原生儲存與行程邊界。

## 驗證與實際證據

    cd apps/bridge_academy_flutter
    flutter pub get
    flutter analyze
    # 已啟動 Android emulator-5554：
    bash scripts/android_process_restart_e2e.sh

初稿 CI 尚未執行，狀態 NOT RUN。必須看到 GitHub Actions 原生 Android 工作成功、兩次真實 flutter drive 的 All tests passed 及 A2_3_ANDROID_REAL_PROCESS_RESTART_PASS，再將此功能標記為 ENGINEERING VERIFIED。

## 練習與自我檢驗

**思考題：** 為什麼同一行程裡連續建立兩個 BridgeSession 並從記憶體 FakeStore 讀取成功，仍不能證明玩家強制關閉 Android App 後能恢復牌局？

**5–15 分鐘練習：** 讀取兩支測試裡 version 的斷言，指出為什麼先要確認恢復版本等於已提交版本，接著又要驗證新增合法動作後版本嚴格增加。

**完成標準：** 能區分記憶體測試、Android 行程重啟驗收與真正寫入中斷／斷電耐久性三種不同層級。

## 下一步

A2 發布前仍須完成加密且交易式的儲存策略、真正進行中 kill/reboot 測試，以及正式 BEN 後端的請求去重。此功能通過只能算原生 Android 工程驗收。
