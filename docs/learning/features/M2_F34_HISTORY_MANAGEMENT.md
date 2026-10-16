# M2-F34｜A5.2 可搜尋歷史與安全刪除

- Feature ID：M2-F34
- Milestone：A5.2
- 類型：Flutter UI／本機加密儲存／使用者資料控制
- 工程狀態：ENGINEERING_VERIFIED（Flutter 94/94 + Web Release + Chrome Demo CI PASS；僅本機加密歷史）
- 學習狀態：DELIVERED（不代表 PRACTICED 或 MASTERED）
- 程式：[歷史清單 UI](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_history_panel.dart) · [加密 Repository](../../apps/bridge_academy_flutter/lib/src/completed_history_store.dart) · [Session](../../apps/bridge_academy_flutter/lib/src/bridge_session.dart)
- 驗收：[A5.2](../product/A5_2_HISTORY_MANAGEMENT_ACCEPTANCE.md) · [Flutter tests](../../apps/bridge_academy_flutter/test/a5_history_management_test.dart)

## 功能目的與實際情境

玩家完成多副橋牌後，只能照時間逐筆翻，不方便找出「某次 3NT」或「牌號 7」。A5.2 讓歷史變得可以搜尋、篩選及分頁，還能明確確認後刪掉不需要的複盤紀錄。**不只是新增數個 repository method，而是實際可從牌桌操作。**

## 主要程式碼導讀

`BridgeHistoryPanel` 是 StatefulWidget：`_query`、`_filter`、`_page` 都是 UI 暫態；每次建置時，先在公開 `HistorySummary` 上篩選，再每頁取 5 筆。搜尋和篩選變更後重設 `_page=0`，避免玩家停在已不存在的最後一頁。

確認刪除後 `BridgeSession.deleteHistory(id)` 才呼叫 `CompletedHistoryStore.delete(id)`。加密 Repository 的 `delete()` **先更新持久資料、後更新顯示列表**，並寫入同一加密檔的 tombstone。

```dart
final state = await _load();
if (state.deleted.contains(id)) return;
final tombstones = [id, ...state.deleted].take(_maxDeletedIds).toList();
await _save(
  state.items.where((item) => item.id != id).toList(), tombstones,
);
```

它的目的不是傳統資料庫的「軟刪除」：這個小型本機集合實際移除該副存檔，tombstone 只記住已刪的 ID，避免當前牌局的自動封存把它重新建立。

## 為什麼這樣設計

對 Kotlin/Android 開發者而言，`BridgeSession` 類似 ViewModel，`CompletedHistoryStore` 類似 Repository，`HistorySummary` 則是暴露給 Compose/Flutter 的有限 DTO。**不能將完整牌局 PBN 傳到 Widget 再用隱藏欄位或排序解決**；因為 UI 層就不應持有別人的私人牌張。

權衡：目前最多 12 副、每頁 5 筆，直接在記憶體的 DTO 做查詢比引入 FTS／SQLite 多表索引更符合成本。加密資料仍是單筆集合，尚無多瀏覽器分頁／多裝置衝突處理。另一個常見錯誤是刪除後只 `setState` 隱藏：再次載入儲存紀錄還會看到同一副牌。

## 驗證與實際證據

```bash
cd apps/bridge_academy_flutter
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build web --no-pub --release
```

新增測試檢查搜尋、合約篩選、5＋2 分頁、刪除取消、永久刪除與加密歷史在 checkpoint restore 後**不重新出現**。實際 [Flutter CI #38857429965](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38857429965) **SUCCESS**：`flutter analyze --no-pub` 無問題、**94/94**（先前 91＋本次 3）、`flutter build web --no-pub --release` PASS、Chrome Demo/secure checkpoint 回歸 PASS。初版 CI 發現 8 個 lint，修正 `String interpolation` 與多餘的 `!` 後未停用分析檢查。單獨 lint 修復 commit 的 [Learning Gate #38857430064](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38857430064) 因缺同步更新教材與索引而 **FAIL**，已在後續文件 commit 補述，本次 gate 尚待結果。測試使用注入的加密 record/key 和 Flutter Widget，仍未進行 Android/iOS 實機、公開 HTTPS 或 Gateway 雲端歷史驗收。使用 Fake Records/Keys 的 AES 測試不代表已通過實機安全稽核。

## 練習與自我檢驗

**思考題（1 題）：** 如果刪除最新一筆歷史後，只將它從畫面 List 刪掉，卻沒有把 Tombstone 寫到加密儲存，為什麼重開 App 可能會再次看到這副牌？

**5–15 分鐘小練習：** 閱讀 `deleteHistory`，找到保證「先加密儲存成功，後更新畫面」的 `await`，再指出測試如何驗證重啟後沒有復活。

**完成標準：** 能區分畫面清單、加密持久資料、仍存在的當前遊戲 checkpoint，以及它們之間的恢復順序。

## 下一步

A5.3 會針對 Gateway Server-owned 模式設計有授權的歷史存取、留存政策及已完成牌局 Replay；單純本機加密記錄不等於跨裝置帳戶歷史。PBN 匯出／匯入應另行經過隱私許可及格式審查。
