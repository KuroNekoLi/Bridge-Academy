# M2-F54｜UX-02：終局結果與下一步玩家操作

- Feature ID：M2-F54
- Milestone：M2／UX-02 Postgame Results
- 類型：Flutter UI／PlayerView 邊界／結果頁導航
- 工程狀態：SCOPED VERIFIED（Flutter 180/180 + Web + Chrome Demo）
- 學習狀態：DELIVERED（沒有玩家學習證據，非 PRACTICED）
- 原始碼：`apps/bridge_academy_flutter/lib/src/widgets/ux_postgame_result_panel.dart`、`apps/bridge_academy_flutter/lib/src/bridge_app.dart`
- 驗收與測試：`apps/bridge_academy_flutter/test/ux_02_postgame_result_test.dart`；[Flutter 180/180 PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38990365337)

## 功能目的與實際情境

玩家完成一副牌後，不必再從叫牌盒中尋找歷史或下一副的入口。結果卡同時顯示核心裁決和下一步動作。UX-02 的任務是讓玩家看懂並繼續操作，而不是另外建立牌局引擎或結算算法。

## 主要程式碼導讀

`PostgameResult.fromFinishedView` 的輸入是目前玩家有權看到的 `PlayerView`，而不是含四家私牌的 `Deal`。遇未完成的牌局或分數不存在就拒絕製作結果卡。

```dart
if (view.phase != Phase.finished || view.nsScore == null) {
  throw StateError('Postgame summary requires a Core terminal result');
}
final contract = view.contract;
if (contract != null && view.completedTricks.length != 13) {
  throw StateError('Contracted deal must have 13 completed tricks');
}
if (contract == null && view.completedTricks.isNotEmpty) {
  throw StateError('Pass Out cannot have completed tricks');
}
```

人類玩家角度的符號來自 `view.viewer.isNS ? view.nsScore! : -view.nsScore!`。UI 不能把 NS+420 硬當成 East 人類玩家的 +420；對 East 而言是 -420。

`BridgeTable._postgameResultPanel` 根據 `fourBoardPractice`、`dailyPractice`、`isJustDeclare` 只顯示有實際服務函式的下一步。點「複盤」只讓 Widget 捲動到現有 `BridgeCompletedReplayPanel`，`_replayIndex` 與 `GlobalKey` 屬於呈現狀態，不送出 `GameAction`。

## 為什麼這樣設計

**關注點分離（Separation of Concerns）**：Domain Bridge Core 負責合法動作、定約和計分；`BridgeSession` 負責應用狀態與保存；`UxPostgameResultPanel` 只解讀安全的終局 View 並呼叫 Callback。這接近 Android 使用 `StateFlow<UiState>`、Compose 展示只讀狀態、ViewModel 處理事件的設計。

另一個方案是直接把 `BridgeSession` 注入 Result Widget，但會讓 UI 能呼叫任意變更、難以獨立測試，也更容易觸及私有 Deal，所以這裡明確採用小型終局 DTO。

常見陷阱：Pass Out 沒有 13 墩；Just Declare 沒有叫牌歷史；儲存失敗時必須先修復，不能按「下一副」將未保存的紀錄覆蓋。複盤分析不得用雙明手理論值虛構為玩家當時資訊下的最佳決策。

## 驗證與實際證據

```bash
cd apps/bridge_academy_flutter
flutter analyze
flutter test test/ux_02_postgame_result_test.dart
flutter test
flutter build web --release
```

**已由 GitHub Actions 實際執行**：`3608110c` 對應 [Flutter CI #38990365337](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38990365337)：Flutter 3.47.7；Analyze 無問題、180/180 測試通過、Web Release Build 成功、Chrome Demo E2E 通過。

**一次真實重構教訓**：Dart 在 `difference!` 第一個判斷之後已對區域變數執行 flow promotion，第二個 `difference!` 其實多餘；Flutter Analyzer 會回報 `unnecessary_non_null_assertion` 且 CI 以 warning 擋下。移除多餘的 `!` 後重跑才得到真實 PASS；不能用肉眼檢查取代 `flutter analyze`。

涵蓋未終局拒絕、Pass Out（四個真實 Pass、0 分、無 13 墩）、Just Declare 13 墩與 N/E 分數視角、複盤前後 Core 版本不變、下一副、禁用狀態和 320px 大字體。真 BEN staging、Android/iOS 裝置端不在本次 UX02 範圍。

## 練習與自我檢驗

**思考題（1 題）：** 如果 Bridge Core 最後結算 `nsScore = +620`，而人類玩家坐 West，UX02 應顯示多少分？為什麼結果 Widget 不應直接計算 duplicate score？

**5–15 分鐘小練習（可選）：** 在 `ux_02_postgame_result_test.dart` 對 East 加一個負分斷言，再檢查 Pass Out 頁面為何不能顯示「達標 0/7 墩」。

**完成標準：** 說得出 Core、Session 與 UI 的責任，以及「只用 `PlayerView` 投影，不暴露完整 Deal」的資訊安全界線。

## 下一步

UX-03 可以延伸 Result → B5/C1.5 複盤 → B4 對應教材的推薦回路；UX-01 擁有外層導航，UX-02 本身不建立第二套首頁。
