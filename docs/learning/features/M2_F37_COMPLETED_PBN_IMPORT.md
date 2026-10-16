# M2-F37｜A5.3.3 完成牌局 PBN 匯入與 Bridge Core 驗證

- Feature ID：M2-F37
- Milestone：A5.3.3
- 類型：Flutter UI／Domain validation／本機加密歷史
- 工程狀態：IMPLEMENTED（CI 待驗）
- 學習狀態：DELIVERED（不是 PRACTICED 或 MASTERED）
- 原始碼：`apps/bridge_academy_flutter/lib/src/completed_pbn_import.dart`、`bridge_session.dart`、`widgets/bridge_history_panel.dart`
- 驗收與測試：`apps/bridge_academy_flutter/test/a5_pbn_import_test.dart`、`docs/product/A5_3_3_PBN_IMPORT_ACCEPTANCE.md`

## 功能目的與實際情境

玩家可以從其他地方取得一份已經**完整打完**的橋牌 PBN，貼進「歷史牌局」，立即用 Bridge Academy 的上一個／下一個事件逐步檢視。不能只看到 PBN 寫著「拿了 9 墩」就相信它，否則有人可能匯入不合法的跟牌或竄改得分。A5.3.3 的第一版明確支援 Bridge Academy 自己匯出的單副完整 PBN 子集，未承諾所有外部牌譜格式皆可讀取。

## 主要程式碼導讀

`CompletedPbnImport.toLocalArchive` 先限制輸入長度與已知 Tag，讀取 Board、Dealer、Vulnerability、四家牌、Auction 和固定列方向的 Play。接著由 `BridgeGame.apply` **依實際行動順序重新提交**每一個叫品與 52 張牌，而不是直接建立看似合法的結果物件：

```dart
for (var i = 0; i < 4; i++) {
  if (state.phase != Phase.play || state.turn == null ||
      state.actorToPlay == null) {
    throw const FormatException('Unexpected end of PBN play');
  }
  final handOwner = state.turn!;
  state = BridgeGame.apply(state, CardAction(
    state.actorToPlay!, handOwner, bySeat[handOwner]!,
  ));
}
```

注意 `handOwner` 可能是明手，`actorToPlay` 卻是莊家；在橋牌合法性上，這兩者不可混為一談。完成後還會驗證 13 墩、`Result`、`Score` 與正確 Board metadata，建立可再次由 `SavedBoardCodec.decode` 驗證的歷史封存。

玩家貼上的原始完整牌張，只交給 `BridgeSession.importHistoryPbn` 處理，成功後才寫入與正在遊玩存檔分離的 **AES-GCM 加密歷史庫**；Widget 只讀 `HistorySummary` 與 `CompletedReplay`。

## 為什麼這樣設計

這很像 Kotlin Android 的「外部 JSON／Room 匯入」：**Untrusted DTO → Domain Validator → Encrypted Repository → ViewModel 的安全投影**。不能因為 PBN 文字符合 Regex，就把裡面的 Score 當資料庫最終值。Regex 負責字面格式，Bridge Core 才負責叫牌順序、跟牌與重算得分。

另一個方案是先建立支援所有 PBN 軟體語法的完整 Parser，但目前會讓一項小功能變成很大的解碼專案。因此首輪僅支援本專案可可靠 round-trip 的完整格式；不支援的標註及未完成對局一律拒絕，不偷偷補事件。

## 驗證與實際證據

```bash
cd apps/bridge_academy_flutter
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build web --release
```

新增測試覆蓋：Demo 完整 13 墩匯出→匯入→複盤；Pass Out；錯誤版號／得分／發牌／Play／部分叫牌；相同資料去重；歷史匯入的雙語 UI。**CI 尚未執行，因此不能把新增功能宣告為已通過。**

這是本機歷史匯入，不是 BEN 推理、跨裝置同步、PBN 大規模互通性測試，Android／iOS 裝置 QA 仍依原決定延期。

## 練習與自我檢驗

**思考題（1 題）：** 為什麼 PBN `[Play]` 從第二墩起可能不是按實際的「第一位出牌者」排序，而是固定從第一墩的首攻座位開始？如果直接按照欄位順序呼叫 `BridgeGame.apply`，會導致什麼錯誤？

**5–15 分鐘小練習：** 先匯出一副 1NT 已完成的 PBN，再更改其中一張 `[Play]` 的牌，查看 `a5_pbn_import_test.dart` 如何證明未新增任何歷史牌局。

**完成標準：** 能說明原始資料、Bridge Core Domain 驗證、加密持久化與 PlayerView 之間的責任界線。

## 下一步

A5.3.4 可擴充支援真實外部 PBN 的常見註解、跳行和跨平台格式；或者依產品 Roadmap 先做 B1 四副牌練習與總結。正式 Gateway 牌局歷史及公開服務仍需另行架構與授權決策。
