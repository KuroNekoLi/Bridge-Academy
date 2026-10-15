# M2-F08｜Flutter Android 模擬器操作驗收

- Feature ID：M2-F08
- 工程狀態：IMPLEMENTED（正式 Android CI 尚未驗收）
- 學習狀態：DELIVERED
- 程式：apps/bridge_academy_flutter/integration_test/android_table_test.dart
- CI：.github/workflows/flutter-android-emulator.yml
- 驗收：docs/m2/M2_F08_ANDROID_EMULATOR_ACCEPTANCE.md

## 功能目的與實際情境

本功能以真正測試執行記錄判定，而非僅以測試檔存在判定。

## 主要程式碼導讀
先前的 Chrome 成功無法證明 Android 原生安裝、觸控和畫面更新。此功能使用 API 35 x86_64 Android 模擬器，以真實 Flutter Android App 操作中英切換、Pass Out、重新開局、叫牌與明手出牌。

測試透過 WidgetTester.ensureVisible → tap → pumpAndSettle 驅動按鈕，卻是在 Android Emulator 上執行，和只有宿主記憶體的 Widget Test 不同。和 Android Espresso／instrumentation tests 的目標相似，但 Flutter integration_test 共用測試 API。

## 為什麼這樣設計
Android Emulator 可固定 API 與裝置外形並納入 CI，缺點是啟動、Gradle 編譯成本較高，也不能取代實體手機。測試刻意使用固定 Demo Bot：Android 平台相容性不應與 BEN 神經網路／CORS 問題混成同一個失敗原因。Domain 規則仍由 Bridge Core 權威管理。

## 驗證與實際證據
啟動 Android Emulator 後，在 Flutter App 目錄執行：

    flutter create --platforms=android --project-name=bridge_academy_flutter .
    flutter drive --driver=test_driver/integration_test.dart --target=integration_test/android_table_test.dart -d emulator-5554

實際 CI：初版 #38685813955、第二輪 #38687000645 均因 Runner 磁碟不足而無法開機；第三輪 [#38689252806](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38689252806) 清理不用的工具後剩餘 23 GiB，模擬器成功開機，但 flutter drive 因 reactivecircus 每行獨立執行 shell 而找不到 pubspec.yaml。現已將 cd、flutter devices、flutter drive 合併成單一命令，修正後的 [#38689747773](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38689747773) 正在驗收。這些都是環境／測試腳本故障，不是 Bridge Core 域規則失敗；Android APK／UI PASS 尚未取得。不含 iOS、實機、TalkBack 或 Android BEN 網路驗收。

## 練習與自我檢驗
**問題：** Chrome 整合測試 PASS，但 Android 模擬器在 APK 安裝時失敗，為何這不是 Bridge Core 違反跟牌規則的證據？

**小練習：** 在測試中加入一次預期明手首攻前尚未公開的斷言，解釋 PlayerView 為何隱藏它。

**完成標準：** 能區分 Domain／Widget／真 Chrome／原生 Android Emulator 各層驗收的意義。
