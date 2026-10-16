# M2-F47｜Bridge Academy B5 教學式複盤

- Feature ID：M2-F47
- Milestone：M2／B5
- 類型：Flutter UI／規則可解釋性
- 工程狀態：IMPLEMENTED（CI 待確認）
- 學習狀態：DELIVERED
- 原始碼：`apps/bridge_academy_flutter/lib/src/review/review_timeline.dart`、`apps/bridge_academy_flutter/lib/src/widgets/bridge_replay_panel.dart`、`bridge_history_panel.dart`
- 驗收與測試：`apps/bridge_academy_flutter/test/b5_teaching_review_test.dart`；本地 NOT RUN（此環境缺 Flutter SDK）

## 功能目的與實際情境
以前玩家只能在一副已結束的牌局中按上一個／下一個事件；B5 增加「跳到事件」、「下一個重點」與回放當下的規則解釋。已封存的歷史牌局仍從 A5 的加密資料取回，先由 Core 重新驗證歷史事件，再投影為玩家可看的 `PlayerView`。遊戲進行中絕不可開啟完成回放。

## 主要程式碼導讀
`ReviewTimeline.fromReplay` 僅接受 Core 的 `CompletedReplay`，其來源是 `SinglePlayerCoordinator.completedReplay`，已經過 `BridgeGame.apply` 的每事件驗證。

```dart
if (frames.isEmpty ||
    frames.first.action != null ||
    frames.last.view.phase != Phase.finished) {
  throw const FormatException('Review requires a completed replay');
}
if (view.viewer != viewer ||
    view.version != index ||
    (index > 0 && action == null)) {
  throw const FormatException('Invalid replay frame order');
}
```

每個 `ReviewStep` 保留原始 `ReplayFrame` 引用、索引與 `ReviewInsight`；規則類提示使用 Core 的 `contract.targetTricks`、`dummyExposed`、`completedTricks` 等公開結果。叫牌約定只使用 `ConventionExplanationEngine.resolve(BidContext.fromView(view))`，解釋所附含義仍屬**未經專家驗證的約定前提**，不是玩家或 BEN 的真正持牌證據。回放介面一律標示策略品質 UNKNOWN，不會為了漂亮的 UI 偽造 DDS 最佳出牌。

本頁 Bookmark 使用 `reviewId + stepIndex` 作為鍵值，只在 Widget state 的 `Set<String>` 保留；沒有本地 database、同步或新一批加密 keys，也不會修改已完成的牌局紀錄。

## 為什麼這樣設計
以 Android/Kotlin Clean Architecture 比較，`ReviewTimeline` 類似只讀 Domain Mapper，`BridgeCompletedReplayPanel` 如 Compose UI，持有目前索引與短暫 UI state。這能避免另建一個打牌引擎，或讓 Flutter 自行判斷勝負。替代方案是把分析狀態寫進存檔，但會引入新 Schema／Migration 與跨 Store 原子性問題；因此 B5 第一輪刻意只做頁面標記。

**常見陷阱：** 某張牌和領出花色不同，不能只看未完整公開的 PlayerView 就宣稱當時此人必然缺門；該證據需來自 Core 合法性而非公開歷史推測。即使有 DDS 結果，也不等於在當時未知其他三手的真人應該找得到那個解法。

## 驗證與實際證據
```bash
cd apps/bridge_academy_flutter
flutter analyze
flutter test
flutter build web --release
```
初始文件建立時為 **NOT RUN**；後續 CI 需對應 Commit SHA。針對 B5 的 tests 覆蓋四 Pass、加倍／再加倍、王牌／無王、開首攻明手曝露、明手由莊家操作、公開跟牌、未知約定、完整 History Replay 與雙語 Widget。尚無 Android／iOS 真機驗收。

## 練習與自我檢驗
**思考題（1 題）：** 為何「這手牌沒有跟出領出花色」不能只看 `PlayerView` 就推斷他當時確定缺門？Core 已驗證的合法性和回放畫面可見證據各有何差異？

**5–15 分鐘小練習（可選）：** 在 `b5_teaching_review_test.dart` 加入「Pass Out 最終得分依 Core 為 0」與 `reviewOfficialScore` 斷言。

**完成標準：** 可以指認 ReplayFrame 與 PlayerView 的隱藏資訊邊界，理解 Evidence 為何分 rule／convention／unknown，以及 Bookmark 為何不持久化。

## 下一步
由 C1 獨立提供終局 DDS adapter 後，以可信輸入／分析輸出 DTO 額外接 B5，並清楚區分 double-dummy 與真人當時不完整資訊的決策。
