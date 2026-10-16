# A5.4 — 近期歷史成績統計：玩家可見功能

**Date:** 2026-10-16  
**Status:** IMPLEMENTED / CI PENDING. **Scope:** 本機最近最多 12 副已完成牌局；不代表賽事排名、真 BEN 成績比較或正式裝置驗收。

## 玩家可以做什麼

在已存在的「歷史牌局」頁面新增「近期牌局統計」摘要。顯示完成副數、有定約副數、定約成功副數與成功率、四家 Pass Out 副數、固定練習副數及**由玩家座位視角計算的累積 Duplicate 得分**。

切換歷史搜尋或篩選，摘要即時更新為目前符合條件的紀錄。頁面明確提示統計只包含受本機最多 12 副上限影響的資料，且包含可能重複的練習或匯入牌局。這不是完整生涯數據、IMP、Matchpoints、排名或 AI 戰力評估。

## 正確性與隱私

- `HistorySummary.contractMade` 在 `BridgeSession._summarize` 中由**已完成且合法的 Bridge Core GameState** 產生：數出莊家方所贏得的 13 墩，並和 `contract.targetTricks` 比較。四家 Pass Out 設為 `null`，不納入定約成功率分母。
- `HistoryStatistics` 只聚合 `HistorySummary`，不載入 Deal、PBN、完整 GameState、加密資料或未公開的四家手牌；不會呼叫 BEN 或 DDS。
- 得分保留 Domain 的有號 `NS score`，但是玩家若坐 E 或 W 則取負號。不同局況與定約的得分可加總成私人練習帳面分數，**不表示具有相同 Duplicate 比較基準**。
- 舊測試資料或兼容摘要若沒有經過 Core 驗證的 `contractMade`，就不納入「已知定約結果」分母，不擅自算作失敗。
- 統計會跟著搜尋／篩選更新，刪除歷史後也會同步變更；不新增 storage schema、事件或額外暗牌存取。

## 功能程式碼

- `apps/bridge_academy_flutter/lib/src/history_statistics.dart`（純聚合規則）
- `apps/bridge_academy_flutter/lib/src/bridge_session.dart`（Bridge Core terminal record）
- `apps/bridge_academy_flutter/lib/src/completed_history_store.dart`（安全摘要 DTO）
- `apps/bridge_academy_flutter/lib/src/widgets/bridge_history_panel.dart`（玩家 UI）
- `apps/bridge_academy_flutter/lib/src/app_copy.dart`（zh-TW/en）
- `apps/bridge_academy_flutter/test/a5_history_statistics_test.dart`（統計／真 Core 完整牌局／可見 UI）

## 驗收

```bash
cd apps/bridge_academy_flutter
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build web --release
```

必須包含：E/W 相對 NS 分數反轉、成約率、Pass Out 不計定約、沒有完成牌局時顯示「尚無資料」、從真實 Bridge Core 13 墩完成牌局取得 `contractMade`、搜尋與篩選更新、zh-TW/en 介面，以及先前 A5.1–A5.3.3 的歷史列表、刪除、PBN 輸出入回歸。

**Executed CI:** PENDING — 不能以先前 A5.3.3 的 101/101 代替本項目驗證。A3.5 和 Android/iOS 裝置 UI 測試仍待使用者授權。

## 非目標

不引入無上限的歷史庫、不支援雲端/跨裝置同步、不增加對戰競爭排名，也不擴大 BEN 部署或公開 API。接下來更值得投入 B1 四副牌練習場次，讓玩家獲得真正的多副牌局摘要。
