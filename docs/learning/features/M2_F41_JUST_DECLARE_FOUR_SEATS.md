# M2-F41｜B2.2 四座位莊家練習、進度與結果回饋

- Feature ID：M2-F41
- Milestone：B2.2 — Just Declare player-visible extension
- 類型：Flutter 牌桌／Bridge Core 既有規則重用／本機存檔
- 工程狀態：IMPLEMENTED / CI NOT RUN（GitHub Actions Runner 尚未成功分配）
- 學習狀態：DELIVERED（非 PRACTICED／MASTERED）
- 原始碼：[BridgeSession](../../apps/bridge_academy_flutter/lib/src/bridge_session.dart)、[BridgeTable](../../apps/bridge_academy_flutter/lib/src/bridge_app.dart)、[雙語文案](../../apps/bridge_academy_flutter/lib/src/app_copy.dart)
- 測試：[四個莊家座位與回復測試](../../apps/bridge_academy_flutter/test/b2_2_declarer_seats_test.dart)、[既有 Just Declare 驗收](../../apps/bridge_academy_flutter/test/b2_just_declare_test.dart)

## 功能目的與實際情境

玩家想專門練 4♥ 莊家，不想進行叫牌。現在可以從牌桌現有的**玩家座位 N/E/S/W** 選擇莊家，調整 **1–7 線、C/D/H/S/NT**，然後按「只練莊家」。東、南、西、北皆能操作自己的 13 張牌與自己的搭檔明手，正常接受開攻與跟牌規則。練習途中顯示「莊家方已贏墩數／定約目標」，完成後顯示成約或宕約的明確結果。仍是 Demo 規則示範 Bot，**不是 BEN 模型**。

本輪也修復 B2.1 合併時的實際功能斷線：Flutter UI 呼叫了 \`session.startJustDeclare()\` 和 \`session.isJustDeclare\`，但 \`BridgeSession\` 並未定義，導致應用程式不能完成此功能的編譯。功能先補齊，不能把「既有 B2.1 已提交」當成「已驗證可玩」。

## 主要程式碼導讀

\`BridgeTable._justDeclareLauncher\` 取得現有座位選擇 \`_selectedSeat\`、定約等級與花色：

\`\`\`dart
session.startJustDeclare(
  level: _justDeclareLevel,
  strain: _justDeclareStrain,
  humanSeat: _selectedSeat,
);
\`\`\`

\`BridgeSession.startJustDeclare\` 首先拒絕不在 1–7 的線位、進行中的牌局或未完成的四副牌練習，接著使用新發 52 張牌與 \`Contract(declarer: humanSeat)\`，呼叫原本的 \`_beginBoard(... justDeclareContract: ...)\`。Coordinator 接受明確的 \`GameState.justDeclareStart\`，從 \`Phase.play\` 與合法開攻開始，而不是自動插入假的叫品。練習時所有 \`submitCard\` 仍走 Bridge Core \`BridgeGame.apply\`。

牌桌勝負進度從 **PlayerView** 計算：「莊家方累積贏得的已完成墩數」對比 \`contract.targetTricks\`（線位＋6）。玩家選 E/W 也使用莊家同一方的墩數，不能把南北方得分符號直接當作所有玩家的練習成敗。

\`replaySameBoard()\` 現在把舊 \`initialTrainingContract\` 再傳回新的 Coordinator，避免同牌重練時退回普通 Auction。既有 \`SavedBoardCodec\`／GameTranscript v2 記錄定約，因此跨重啟一樣能找回正確莊家／Dummy，不會憑空生成叫牌紀錄。

## 為什麼這樣設計

這對 Android/Kotlin 開發相當於**同一個 Domain Reducer 提供兩種有型別的合法初始狀態**：正常叫牌與「直接進入出牌」教學；Flutter 只用 ViewModel/PlayerView 表示進度。替代方案是在 UI 硬塞「3NT、Pass、Pass、Pass」假紀錄，雖然可以複用舊流程，卻會污染賽事紀錄、複盤與 PBN。另一替代方案是讓任意 BEN 處理沒有 Auction 的出牌，但原 BEN 路由需要有效叫牌上下文，這輪不應冒充它已支援。

常見錯誤：把 target \`3NT = 9\` 拿去比「北家自己贏得的墩數」，忽略南家的搭檔明手其實與北家屬於同一方；莊家可能在 E/W，因此應先比較勝方 \`isNS\` 與莊家方再加總。

## 驗證與實際證據

重現指令：

\`\`\`bash
cd packages/bridge_core
dart pub get && dart analyze --fatal-infos && dart test
cd ../../apps/bridge_academy_flutter
flutter pub get && flutter analyze && flutter test && flutter build web --release
\`\`\`

新測試覆蓋 N/E/S/W 各自的合法開攻、明手公開、無虛假叫牌、提交一張後加密 Session 邏輯的跨程序重建、終局儲存及重玩同牌同定約。另確認 B2 不能中斷一般牌局、拒絕 0/8 線，並檢查繁中／英文的目標提示。

**重要：本輪 GitHub Actions Runner 是否分配成功，必須在實際新 Workflow Run 產生後記錄，不可用舊 B1 109/109 通過證據冒充 B2.2 已通過。** 目前程式已提交候選，測試結果尚未驗證。Android/iOS 模擬器及實機 QA 依使用者指示持續停用。

## 練習與自我檢驗

**思考題：** 為什麼玩家選擇西家莊家時，成約判斷必須統計「東西方」取得的墩數，而不能直接比較 NS Score 是不是正數？

**5–15 分鐘小練習：** 追蹤 \`Seat.west.partner\` 與 \`Contract.openingLeader\`，找出西家莊家時，誰先開攻、誰是明手、第一張牌之後哪些牌是玩家可以控制的。

**完成標準：** 能區分 \`Contract.declarer\`、\`Contract.dummy\`、\`PlayerView.actorToPlay\` 與 \`Trick.winner\`。

## 下一步

B2.3 有授權的原創教材牌例與勝負講評，或 B3.1 純叫牌練習（ConventionProfile 未審核時僅提供合法性與規則回饋，不冒充 BEN/SAYC/2/1 的策略解釋）。A4.5 公開服務、A3.5 與 Android/iOS 裝置 QA 仍待另行決策。
