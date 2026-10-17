# UX-04 — Daily Return Loop Acceptance

**Branch:** `feature/ux-04-daily-return-loop`  
**Base:** master `41d0ac604554dc3581cbe59b796b172e81270ee9`  
**Status:** IMPLEMENTED / CI PENDING

## 玩家交付
- 每次打開牌桌可見今日 UTC 日期、0/4～4/4、非排名 Demo 規則及空狀態。
- 由既有 B6 `startDailyPractice`／`nextDailyBoard` 操作第一副、續玩及下一副，未完成牌局的「回到牌桌」只捲動不重新發牌。
- 4/4 可以依現有確認對話重打同日四副牌，或選擇下一段原創叫牌練習。
- 近期最多三個日期，只列本機已保存、明確由玩家啟動的每日練習紀錄。
- 跨日未完成、其他模式未完成、存檔故障、回退 checkpoint 待確認與忙碌狀態皆防止不安全的重建。

## 資料／隱私
只使用 B6 的加密持久化結果及 PlayerView 支援的公開 Session flags；不載入其它座位手牌、DDS、PBN 或 C3 opt-in 之外的學習資料。無雲端服務、排名、MP/IMP 比較、streak、推播與遙測。每日非競賽。Android/iOS 真機及模擬器 QA 保持停用。

## 驗收與測試
`cd apps/bridge_academy_flutter && flutter analyze && flutter test && flutter build web --release`。
`test/ux_04_daily_return_test.dart` 涵蓋：UTC 換日、0/4、1/4、4/4、舊日未完成、活躍非每日牌局、損毀每日帳本、恢復確認、雙語與真正 Widget 點擊進下一副。**CI PENDING**（未宣稱已通過）。
**USER_STUDY_NOT_RUN**：5 名新手從空白開始每日挑戰、5 名熟手接續完成第 2 副的觀察仍待真人參與，未蒐集未經同意的資料。

## 整合交接
UX-04 獨立模型 `experience/daily/daily_return_summary.dart` 與元件 `widgets/ux_daily_return_panel.dart`；只在 `BridgeTable` Daily Panel 前以一個區塊接入。未引入 UX-01 App Shell／UX-02 結果／UX-03 複盤分支。UX-01 可重用同一 DTO 於首頁；整合時在 `bridge_app.dart`、`app_copy.dart`、`docs/learning/INDEX.md` 以 hunk 解衝突，不覆寫其他分支。回退可移除新 Widget 接線，保留 B6 存檔和牌局。
