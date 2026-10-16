# B2.1 — Just Declare 玩家可玩的莊家練習

**2026-10-16；IMPLEMENTED / CI PENDING；本機練習版，非正式多人競賽**

## 可見的玩法
打牌畫面新增 Just Declare 啟動按鈕與 1–7 線、C/D/H/S/NT 選擇。玩家固定北家莊家、南家明手，發一副全新 52 張牌。Bridge Core 直接建立帶指定定約的出牌起點，東家首攻後明手公開；玩家操作自己的牌與明手，計算 13 墩與真正 DuplicateScore，並將結果保存於既有加密本機歷史。

## 不允許偽造叫牌
這不是把假的 1NT、Pass 插入事件紀錄。GameState.justDeclareStart 建立顯式教學起點，GameTranscript v2 保存 trainingContract；普通 v1 對局仍然由正常 auction 開始。兩者共同使用 BridgeGame.apply 唯一合法性判斷。教學紀錄的複盤從起始牌局直接進入出牌，不能匯出成捏造 Auction 欄位的普通 PBN。

## 玩家模式的限制
本切片明確使用 DeterministicTrainingBot（規則示範，不是 BEN）。BEN 現有 /play API 需要真實叫牌上下文，不可捏造一份 Auction 誤導 BEN。B2.2 再研究 contract-aware 真 BEN 路由、作者設計固定牌例、其他莊家座位與難度。B1 四副牌練習與一般叫牌對局未改動；進行中不可強制切換 B2。B2 所得分數是練習而非排名 MP／IMP。

## 驗收檢查
- 指定 3NT 後，第一個階段為 Play，version 0、auction.length 0，首攻者為東家。
- 首攻以前不能看到明手；首攻後可見南家明手，並由北家控制合法出牌。
- 13 墩／52 張的勝負、出牌遵守跟牌，使用 Bridge Core 計分。
- 加密 checkpoint 跨重啟保留教學合約與事件，歷史重播不假造叫牌。
- v1 普通對局相容，v2 不合法線位、花色、加倍與竄改版號拒絕。
- Flutter 中英文字串、操作按鈕及既有 Web／Chrome 相關回歸。

## 實際 CI
本文件提交時尚未執行。執行 packages/bridge_core 的 dart analyze --fatal-infos + dart test，以及 apps/bridge_academy_flutter 的 flutter analyze/test/build web，完成後補正確 GitHub run URL。

## 安全與待辦
所有完整牌張僅寫入既有加密本機 Session/History Store。PlayerView 仍為對外唯一合法視角。這不是伺服器部署、真 BEN AI 教學品質、裝置驗收或比賽公平性通過。A4.5、A3.5、Android/iOS 裝置測試仍維持暫停。