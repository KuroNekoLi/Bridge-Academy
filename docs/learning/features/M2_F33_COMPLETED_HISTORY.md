# M2-F33｜A5.1：打完橋牌後保留歷史牌局與跨局複盤

- Feature ID：M2-F33
- Milestone：A5.1 Local Completed History
- 類型：Flutter UI／資料持久化／Bridge Core
- 工程狀態：ENGINEERING_VERIFIED（91/91 Flutter CI、Web Release、Chrome Demo PASS；本機歷史功能範圍）
- 學習狀態：DELIVERED（尚未 PRACTICED／MASTERED）
- 程式：`lib/src/completed_history_store.dart`、`lib/src/bridge_session.dart`、`lib/src/widgets/bridge_history_panel.dart`
- 驗收：`docs/product/A5_1_HISTORY_ACCEPTANCE.md`、`test/a5_history_test.dart`

## 功能目的與實際情境

玩家連續打三副牌，第三副打到一半突然想回顧第一副的叫牌。之前的「複盤」綁在正在玩的那一副，新局開始就無法找到舊局。現在牌桌有「歷史牌局」入口，完成牌局即新增歷史；從列表選取舊局後可逐步回顧，而且不會中斷或改動目前正在進行的牌局。

## 主要程式碼導讀

資料流：

`BridgeSession._submit/_advanceBots` 完成最後事件 → `_archiveCompleted()` 將已完成的 `SavedBoardCodec` 快照寫入加密歷史資料庫 → `BridgeSession.completedHistory` 只給 UI 基本摘要 → 點選 `historyReplay(id)` 在可信任記憶體中重建 `SinglePlayerCoordinator` → `BridgeCompletedReplayPanel` 只取得經過 `PlayerView` 過濾的逐步事件。

重點不是把 `GameState` 傳到畫面，而是讓它在資料層保持特權，畫面只拿被授權的投影。

```dart
final saved = SavedBoardCodec.decode(record.archive);
if (!saved.state.isFinished) {
  throw const FormatException('Unfinished deal in completed history');
}
```

為了讓歷史紀錄跨重啟不重複，每副牌局有獨立且可隨 Checkpoint 保存的 `historyId`。重打一模一樣的 52 張牌也會拿到新的 ID，因為它是不同的練習紀錄。

## 為什麼這樣設計

這很接近 Android/Kotlin 的 Repository + Room + ViewModel：Flutter Widget 只渲染 `HistorySummary`，`BridgeSession` 管理狀態，獨立 Store 儲存加密資料。差別是 Bridge Academy 暫時只需要一個容量有限的歷史集合，不必立刻引入完整 ORM 或搜尋引擎。

有兩個重要取捨。第一，完整回放必須保留足夠多的事件與原始牌張，這些是**私人資訊**，不能為了做列表就存入明文 SharedPreferences；因此借用已驗證的 AES-256-GCM 與各平台安全金鑰管理。第二，歷史只是輔助資料；歷史存檔出錯不應毀掉主要牌局的 Checkpoint，必須提供明確的「重新儲存歷史」操作。

常見錯誤：用 `historyFingerprint` 當唯一的歷史紀錄 ID。它只能辨識一種「原始牌＋事件序列」，同一玩家兩次用相同步驟重玩時，會錯誤合併為一次。真正的歷史 ID 應代表一次獨立完成嘗試。

## 驗證與實際證據

```bash
cd apps/bridge_academy_flutter
flutter pub get
flutter analyze
flutter test test/a5_history_test.dart --reporter expanded
flutter test --reporter expanded
flutter build web --release
```

新增測試包括 Pass Out 自動加入歷史、下一副牌仍可點選舊局、重新開啟後不重複歸檔、相同牌局不同嘗試、AES-GCM 密文不含手牌與惡意竄改拒絕、Widget 點選歷史重播和英文切換。[A5.1 Flutter CI #38852504246](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38852504246) 已 **SUCCESS**（提交 `0a64fe3`），包括 Dart/Flutter analyzer `No issues found`、**91/91** Widget／Session／資料層測試、Web Release Build、Chrome Demo／存檔回歸；[Feature Learning Gate #38852504261](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38852504261) PASS。先前兩輪曾因存檔 Codec 字串替換失誤及嚴格 null-aware lint 失敗；已重新由原檔構建，未降低終局合法性／加密安全驗證。不把 Widget Mock/記憶體儲存當作 Android/iOS 實機驗證。

## 練習與自我檢驗

**思考題：** 為什麼我們可以在一副牌局結束後才保存它到歷史，而不能在第三墩時就把「所有四家完整手牌」交給 Flutter 畫面做複盤？

**5–15 分鐘練習：** 在 `a5_history_test.dart` 觀察「第二次重打同一副牌」的測試，比較兩筆 `historyId` 和 `historyFingerprint` 各自回答的問題。

**完成標準：** 能清楚區分權威牌局資料、完成紀錄的加密存檔、玩家可見的歷史摘要與安全的複盤投影。

## 下一步

A5.2 歷史篩選／搜尋／保留設定，A5.3 Gateway 歷史串接（需有服務端玩家授權）；其後 B1 四副牌練習。A3.5、Android／iOS 裝置 UI/E2E 依原決策暫停。
