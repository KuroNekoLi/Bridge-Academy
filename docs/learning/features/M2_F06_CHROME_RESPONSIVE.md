# M2-F06｜Flutter 真瀏覽器互動與窄螢幕測試

- Feature ID：M2-F06
- Milestone：M2 單機 UI 驗收
- 類型：Flutter Web Integration Test／Responsive Layout
- 工程狀態：IMPLEMENTED，CI 尚待實際驗證
- 學習狀態：DELIVERED；尚未作答
- 實作：apps/bridge_academy_flutter/lib/src/bridge_app.dart、integration_test/browser_table_test.dart
- 測試：apps/bridge_academy_flutter/test/responsive_layout_test.dart、.github/workflows/flutter-single-player.yml
- 驗收：docs/m2/M2_F06_BROWSER_QA_REPORT.md；此文件初稿時瀏覽器 CI NOT RUN

## 功能目的與實際情境

M2-F05 的 Widget Test 是 Flutter 模擬繪製環境，未真的啟動 Chrome。玩家使用時可能遇到瀏覽器才有的問題，例如路由、焦點、點擊座位、換語系後的版面與 ChromeDriver 啟動環境不相容。M2-F06 新增官方 integration_test + flutter drive，使自動化會啟動真正 Chrome 網頁，再模擬玩家選擇語系、新局、四 Pass Out、重開以及首攻後代明手出牌。

手機 320px、375px 與平板 768px 都應能容納主要控制，不能因為英文標籤較長就 RenderFlex overflow。

## 主要程式碼導讀

在 Flutter 畫面內不再將下拉選單寬度直接寫死，而是讓 LayoutBuilder 提供真實可用寬度：

~~~dart
child: LayoutBuilder(
  builder: (context, constraints) => Wrap(
    spacing: 16,
    runSpacing: 8,
    children: [
      _modeSelector(copy, constraints.maxWidth),
      _seatSelector(copy, constraints.maxWidth),
      // 其他控制項
    ],
  ),
),
~~~

_modeSelector 再將 maxWidth 與理想選單寬 320 作比較，_seatSelector 則與 185 比較；縮小容器時選單會收縮。這相當於 Android Compose 中使用 BoxWithConstraints 感知父容器，而非只按模擬器預設尺寸設計。

瀏覽器測試的入口是 integration_test/browser_table_test.dart。與 flutter test 的假渲染不同，CI 先啟動 ChromeDriver，再透過 flutter drive -d web-server --browser-name=chrome 開啟真正瀏覽器。測試仍使用明確標示的 DeterministicTrainingBot，不應宣稱這是 BEN 真實模型操作。

## 為什麼這樣設計

- 替代方法：只將 Widget Test viewport 設 320px。它能檢查 RenderFlex 但無法偵測真瀏覽器環境差異。
- 選擇方法：快速的 Widget／Responsive 回歸在每次 Flutter CI 執行；額外啟動真正 Chrome 驗證完整點擊流程，兩者互補。
- 與 Android 對照：flutter test 接近 Compose UI testing 的局部語意；瀏覽器 Integration Test 更接近 Espresso/UIAutomator 對實際目標平台的端到端操作，但 Chrome 不等於 Android 真機。
- 安全邊界：Demo Bot 不呼叫 BEN。過去 M2-F04 的 BEN 真實 HTTP CLI 測試不能當成本次 Chrome BEN 測試；Chrome + BEN 同場景需另行驗收。
- 資料邊界：整個 Flutter 畫面仍使用 PlayerView，BridgeGame 是唯一叫牌／出牌權威。

## 驗證與實際證據

在專案根目錄：

~~~bash
cd apps/bridge_academy_flutter
flutter create --platforms=web --project-name=bridge_academy_flutter .
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
# 另行安裝並啟動 ChromeDriver --port=4444
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/browser_table_test.dart -d web-server --browser-name=chrome
~~~

GitHub 會在 .github/workflows/flutter-single-player.yml 中單獨執行 ChromeDriver Job。Web Build 與 Unit/Widget Test 不等於 Browser Test，CI 未通過前不可改寫成驗收 GO。真正手機 Chrome、Android、iOS，以及 Chrome 連到真 BEN API 都尚未由本功能證明。

## 練習與自我檢驗

**思考題：** 為什麼 Widget Test 在 800px 上測試成功，不能證明 320px 手機不會發生 RenderFlex overflow？

**5–15 分鐘小練習：** 將 responsive_layout_test.dart 新增一個 280px 視窗測試，觀察 LayoutBuilder 和下拉選單是否仍在父容器限制內。

**完成標準：** 能說明 LayoutBuilder 的 constraints 來源，並正確區分 Widget Test、真 Chrome Integration Test 與 Android/iOS 裝置測試的證據層級。

## 下一步

以瀏覽器 CI 完成 Demo 版面和點擊驗收後，進一步連接真正 BEN 的 Chrome UI，之後做實機與真實玩家可用性測試。
