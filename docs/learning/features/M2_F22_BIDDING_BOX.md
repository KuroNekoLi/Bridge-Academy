# M2-F22｜A3.2：可控制狀態的叫牌盒

- Feature ID：M2-F22
- Milestone：A3.2 Bridge Table UI V2（叫牌盒元件抽離）
- 類型：Flutter UI／單向資料流
- 工程狀態：IMPLEMENTED；CI #38769224189 analyze import conflict 已修正；後續 CI #38769481251 有 68/69 Widget 通過，但 320px Row overflow 39px，已改為 Wrap 直接子元素／Tooltip，待重跑
- 學習狀態：DELIVERED（非 PRACTICED 或 MASTERED）
- 原始碼：`apps/bridge_academy_flutter/lib/src/widgets/bridge_bidding_box.dart`、`apps/bridge_academy_flutter/lib/src/bridge_app.dart`
- 驗收與測試：`apps/bridge_academy_flutter/test/a3_bidding_box_test.dart`（本次 CI 待確認）

## 功能目的與實際情境

玩家在叫牌階段以 1–7 線位、梅花至無王選擇要叫的約定，亦可按 Pass/X/XX。未來高階視覺調整不應必須觸碰存檔或 BEN 回合控制，因此將原本 `_humanControls` 內的叫牌 UI 獨立成元件，保留 `bid_level`、`bid_strain`、`make_bid`、`pass`、`double`、`redouble` 測試 Key。

## 主要程式碼導讀

在 `BridgeTable` 中保留所選線位與花色，透過 callback 將變更傳回父層；叫牌盒不持有 Session，也不直接呼叫 Core：

```dart
return BridgeBiddingBox(
  copy: copy,
  selectedLevel: _bidLevel,
  selectedStrain: _bidStrain,
  canSubmit: view.canAct && !session.actionsPaused,
  onLevelChanged: (level) => setState(() => _bidLevel = level),
  onStrainChanged: (strain) => setState(() => _bidStrain = strain),
  onSubmitCall: session.submitCall,
);
```

只有 BridgeSession 呼叫協調器送出 `CallAction`，Bridge Core 仍是 Bid/X/XX 合法性的最終權威。**目前 `PlayerView` 尚未提供 legalCalls 投影，因此叫牌盒不會聲稱 X/XX 一定合法，也不會自行複製一份競叫規則。** 這是 A3.2 下一個必要驗收項目。

## 為什麼這樣設計

這和 Jetpack Compose 的 State Hoisting 對應：上層管理 state，下層 stateless UI 透過 `onValueChange` 或 typed action callback 表達意圖。比起每一個子 Widget 都直接拿到 ViewModel，這種寫法更適合獨立的 Widget Test。

替代方案是在 Flutter Widget 內根據 `auction` 自算哪些叫品可按，但這會產生第二份橋牌規則實作。應由 Bridge Core 未來增加公開合法叫品投影，讓 UI 依權威集合 disable 按鈕。陷阱是目前 UI 的 canSubmit 只表示**輪到玩家且沒有鎖定操作**，不表示選到的每個叫品合法。

## 驗證與實際證據

```bash
cd apps/bridge_academy_flutter
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build web --no-pub --release
```

新增測試會驗證選擇 2S 可送交 Core，以及開叫時按 X 會被 Core 拒絕、version 仍為 0。CI #38769224189 analyze FAIL（ambiguous_import，已使用 hide Card 修正）。CI #38769481251 analyzer 通過，但 69 筆 Widget 測試中 68 PASS、1 FAIL（320px Row 水平溢出 39px）；已移除 Row 標籤群組，保留 Tooltip 與 Wrap。修復後 CI 待驗；不可當成 PASS。Android 裝置／模擬器仍依使用者核准條件暫停。

## 練習與自我檢驗

**思考題（1 題）：** 既然 `BridgeBiddingBox.canSubmit == true`，為什麼在第一輪尚未有人叫牌時，Double 仍可能違反橋牌規則？

**5–15 分鐘小練習：** 比較 `BridgeBiddingBox` 的 callback 與 `BridgeSession.submitCall`，指出哪裡在處理 UI 選項，哪裡持有目前的事件版本。

**完成標準：** 可以解釋「玩家可以操作」和「某個動作合法」是不同 predicate，且能指出權威應由哪一層提供。

## 下一步

把公開且完整的 `legalCalls` 從 Bridge Core 投影給 PlayerView，才能真正 disable 非法叫品；再進行 A3.3 牌桌佈局與回放工具列。
