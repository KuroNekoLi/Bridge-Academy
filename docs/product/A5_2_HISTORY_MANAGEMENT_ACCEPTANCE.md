# A5.2 — 搜尋、篩選、分頁與刪除已完成牌局

**2026-10-16 / Status: A5.2 SCOPED ENGINEERING VERIFIED — Flutter 94/94, Web release and Chrome Demo/secure checkpoint PASS.** 范圍僅限本機 `BridgeSession` 的已完成牌局，加密歷史使用 A5.1 的既有儲存格式。**A5.3 遠端 Gateway 牌局歷史、PBN 匯出及更大型歷史庫未完成。**

## 玩家實際可操作的功能

在牌桌選擇「歷史牌局」後：
- 搜尋 **牌號、定約（例如 3NT／PASS OUT）、南北方分數與玩家座位**，並可切換「全部／有定約／Pass Out／練習牌局」篩選。
- 一頁最多 **5 副**，使用上一頁／下一頁查看最多 12 副加密紀錄。篩選或搜尋更新時會回到第一頁；找不到顯示獨立空狀態。
- 每筆紀錄旁的刪除圖示會彈出不可復原警告。選「取消」不動資料；確認後只刪選定的歷史與複盤，不刪正在進行的牌局。
- 選擇未刪除紀錄依然能用既有 Bridge Core `CompletedReplay` 的 First/Previous/Next/Last 逐步回放。
- 全部顯示字串及警告支援繁體中文與英文。

## 安全與狀態一致性

`BridgeHistoryPanel` 僅接受 `HistorySummary` 和已篩選 `CompletedReplay`，**搜尋不會讀到全部四家牌**。原始 `SavedBoardCodec` 包含完整 52 張牌，僅儲存在 AES-256-GCM 加密的 `CompletedHistoryStore`。

刪除採以下順序：從 AES-GCM 加密記錄解密驗證 → 更新歷史列表及刪除 tombstone → 重新加密並提交 → 直到成功才更新畫面。若寫入失敗，原本列表仍保留並提供雙語錯誤。刪除 ID 記錄在相同加密集合中，使**最新牌局仍保存在 checkpoint 的情況下，應用程式重啟也不會重新把刪掉的紀錄插入歷史**。A5.1 的 v1 加密內容允許無 `deleted` 欄位，新資料則新增最多 64 個 tombstone。仍存在單機多標籤頁、容量與非原子複數儲存物件的限制；這不是雲端帳號歷史。

## 本切片驗收

| 驗收 | 要求 |
| --- | --- |
| 搜尋／篩選 | 牌號、定約、分數與座位；有定約／Pass Out／練習皆可選 |
| 分頁 | 7 筆可分成 5＋2，無符合結果時顯示正確提示 |
| 刪除取消 | 確認對話框 Cancel 不變更資料 |
| 刪除成功 | 只有選擇的 ID 被永久刪除，其他紀錄與當前牌局保留 |
| 重啟復活防護 | 最新已完成牌局從歷史刪除後，重新 restore 不會自動補回 |
| 隱私 | 加密原始記錄不包含明文 PBN／transcript；UI 只使用可見 DTO |
| 相容性 | A5.1、A4 Flutter、Web Build 與既有 Chrome 測試繼續通過 |

**原始檔：** `apps/bridge_academy_flutter/lib/src/completed_history_store.dart`、`lib/src/bridge_session.dart`、`lib/src/widgets/bridge_history_panel.dart`、`lib/src/app_copy.dart`。**新增測試：** `apps/bridge_academy_flutter/test/a5_history_management_test.dart`。

## 已執行的 CI 與具體證據

- Feature commit [4f8b9c2](https://github.com/KuroNekoLi/Bridge-Academy/commit/4f8b9c27f61839432769b2e00853dc19293baff0)，lint 修正 [2d51e6f](https://github.com/KuroNekoLi/Bridge-Academy/commit/2d51e6fba45de3fa2bc2148e43f0f30171dd51fe)。
- [Flutter M2 CI #38857429965](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38857429965) **SUCCESS**：`flutter analyze --no-pub` No issues found；`flutter test --no-pub --reporter expanded` **94/94 PASS**（A5.1 91＋A5.2 新增 3 項）；`flutter build web --no-pub --release` **PASS**；既有真 ChromeDriver Demo/secure checkpoint E2E 皆 **PASS**。
- [Feature Learning Gate #38857430064](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38857430064) **FAIL（lint-only 修正提交未同步教學與索引）**，因此在本份驗收與 [M2-F34](../learning/features/M2_F34_HISTORY_MANAGEMENT.md)、[教學索引](../learning/INDEX.md) 補足修正經過；**最新文件提交的 Learning Gate 仍待執行，不提前宣稱 PASS**。
- 第一輪 [Flutter CI #38857189109](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38857189109) 被嚴格 lint 擋下：七項字串插值及一項多餘的 null assertion。保留 lint 並修正後重新執行成功。
- 新增加密儲存重啟測試使用注入的 AES key/record store；**不是**真 Android／iOS 裝置 QA，也不代表已在公開網域或多分頁同步環境驗收。

## 不在此次範圍

PBN 交換檔授權匯出、雲端跨裝置同步、刪除後備份機制、超過 12 筆的長期歷史、可查詢的 Gateway Server 賽事歷史、多人／排名競賽。A4.5 部署、安全與授權仍暫緩。Android／iOS 裝置測試與 A3.5 維持使用者要求的暫停，不可默默啟用。
