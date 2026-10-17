# UX-02 — 完整牌局結果與下一步操作

**日期**：2026-10-17  
**分支**：`feature/ux-02-postgame-results`  
**狀態**：IMPLEMENTED / CI PENDING  
**範圍**：Flutter 單人 Demo/既有 B1、B2、B6 終局；不是正式 BEN 部署、裝置 Release 或競賽排名。

## 玩家可以做什麼
1. 牌局完整結束時立即出現結果卡（`final_result`），顯示真實 Board number、發牌者、局況、定約/Pass Out、莊家、莊家方實得/目標墩數、達標/宕牌差距，以及從觀看者 N/S 或 E/W 視角換算的原始 duplicate 分數。所有來源均為當前 `PlayerView`／Bridge Core 終局，**未重新計分**。
2. Pass Out 由 Core 四次真實 Pass 完成，顯示 0 分但**不展示 13 墩／莊家達標**；Just Declare 顯示無競叫的單項莊家練習標籤，不偽造叫牌紀錄。
3. 下一步依模式出現：普通單人下一副＋同副重練、B1 第 1–3 副的下一副、B6 今日第 1–3 副的下一副、B2 同副莊家重練；已完成 B1/B6 系列不提供無意義的「第五副」。B6 原本進度卡上的重複 Next 按鈕於終局隱藏，真正 Next 保留在 UX-02 結果卡。
4. 點「複盤這副牌」以捲動至既有 A5/B5 時間軸；可按「返回本局結果」返回。同樣可展開並捲動至歷史牌局，不重播動作、不修改 reducer 的版本或得分。
5. 保存失敗、歷史/每日記錄寫入失敗、恢復需同意或忙碌時停止下一副／重練按鈕並顯示原因；可讀取回放，不自動跳過損毀 checkpoint。
6. zh-TW/en 文案、Wrap 操作按鈕、320px 兩倍字體靜態 Widget 驗收。

## 程式位置與互通界面
- `apps/bridge_academy_flutter/lib/src/widgets/ux_postgame_result_panel.dart`：`PostgameResult.fromFinishedView` 取得公開、安全且已完成的 DTO；`UxPostgameResultPanel` 只拿 callback。
- `apps/bridge_academy_flutter/lib/src/bridge_app.dart`：僅 BridgeTable 終局區與小範圍 GlobalKey 事件，使用既有 `BridgeSession.nextBoard`、`nextFourBoardPractice`、`nextDailyBoard`、`replaySameBoard` 和 `completedReplay`。外層 `BridgeAcademyApp`／UX-01 首頁沒有修改。
- `apps/bridge_academy_flutter/lib/src/widgets/daily_practice_panel.dart`：增加 `showNextAction`，避免 B6 重複的 next 操作。
- `apps/bridge_academy_flutter/lib/src/app_copy.dart`：雙語文案；保留既有 Widget key `final_result`、`next_board`、`next_practice_board`、`next_daily_board`、`replay_same_board`。

## 驗收與測試證據
- 新測試：`apps/bridge_academy_flutter/test/ux_02_postgame_result_test.dart`。
- 回歸：`bridge_app_test.dart`、`completed_replay_test.dart`、`b1_four_board_practice_test.dart`、`b2_just_declare_test.dart`、`b6_daily_practice_test.dart`，以及所有 Flutter 測試。
- `cd apps/bridge_academy_flutter && flutter analyze && flutter test && flutter build web --release`。
- **目前 NOT RUN**：執行環境沒有 Dart/Flutter SDK，待本分支 GitHub Actions 執行並更新明確 run URL／數量；不把測試檔存在當成 PASS。
- 目前沒有在本輪執行 Android emulator、實體 Android／iOS QA；按產品 Owner 指示持續暫停。

## 待實測使用者研究
**USER_STUDY_NOT_RUN**：安排五位新手和五位有經驗玩家，在 Web Demo 上完成「結束一副牌 → 看懂自己得分 → 複盤 → 返回 → 開下一副」，記錄首次看懂得分所需時間、操作障礙及是否需要協助。未收集前不推定 UX 成功率。無遙測，也不回傳 PBN／四家暗手。

## 已知限制與回退
- 此功能不提供完整 B3 叫牌練習的虛假出牌結算；B3 的 auction-only 完成頁依然保持獨立。
- C1.5 DDS 在不支援的 Web Build 顯示既有不可用狀態，結果卡不宣稱最佳出牌；沒有 MP/IMP 或排名。
- 歷史資料保存遵循既有加密 archive／原先保存策略；UX-02 不建立新 store。
- 如有問題可 revert UX-02 的 feature merge；不清除玩家保存的牌局或原有本機歷史。
