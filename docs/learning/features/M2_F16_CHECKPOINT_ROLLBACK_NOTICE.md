# M2-F16｜A2.4 雙槽存檔回退時必須告知玩家

- Feature ID：M2-F16
- Milestone：Phase A2.4 / P1.2
- 類型：Checkpoint Store、Flutter Session 與 UI
- 工程狀態：IMPLEMENTED（CI 尚待執行）
- 學習狀態：DELIVERED
- 程式：apps/bridge_academy_flutter/lib/src/session_persistence.dart、bridge_session.dart、bridge_app.dart
- 測試：apps/bridge_academy_flutter/test/checkpoint_recovery_notice_test.dart
- 驗收：docs/product/P1_A2_4_ROLLBACK_NOTICE_ACCEPTANCE.md

## 功能目的與實際情境

玩家在第八墩做完一次合法出牌，最新 Checkpoint 卻損壞。A2.2 原有雙槽回復功能可能退回較早、合法的牌局，但之前沒有告知玩家進度已倒退。這次會在回退時顯示中英雙語警告，直到使用者確認前停用玩家按鈕、禁止 BEN／Demo Bot 自動繼續。

## 主要程式碼導讀

PreferencesSessionArchiveStore.read() 先檢查目前 Commit Marker 指定的 Slot；若已損壞，只有另一個 Slot 的 generation 剛好是上一代，而且通過 SHA-256 與 Bridge Core 重播驗證，才會修正 Marker 後設定 recoveredOlderCheckpoint = true。這個 Getter 僅暴露布林值，不公開完整手牌或 PBN。

BridgeSession.restoreSavedGame() 讀取狀態並設 recoveryNeedsConfirmation；submitCall、submitCard、retryBots 會受到 actionsPaused 保護；acknowledgeRecoveredCheckpoint() 清除暫停後才進行下一個合法 Bot 回合。Flutter 使用 recovery_warning 與 ack_recovered_checkpoint 的穩定 Key，供 Widget Test 和 Android 驗收。

## 為什麼這樣設計

核心 Event Sourcing 可以保證「重播回來的事件合法」，無法保證「存檔最新版本一定沒有丟失」。兩者是不同的性質：規則正確性 vs Durability。這就像 Kotlin Repository 回傳 RecoveryResult.RecoveredPreviousVersion，讓 ViewModel 驅動 Compose 呈現明確的警告，而不是讓 Activity 直接讀取資料庫底層的全部暗牌。

備案是默默回到舊版並繼續出牌（最簡單但容易誤導），或完全拒絕恢復（安全但喪失合法備份的價值）。目前單機原型採「有告知、可檢查、需確認後繼續」；不適用於需要稽核的線上競賽。

## 驗證與實際證據

執行：cd apps/bridge_academy_flutter && flutter pub get && flutter analyze && flutter test test/checkpoint_recovery_notice_test.dart && flutter test

四個案例：正常 Restore 不警告；上一代回退會標記且下次讀取清除標記；真人玩家未確認不能出牌、確認後可以合法 Pass Out；Bot 輪次恢復但未確認時不可偷偷自動推進。Widget Test 同時檢查繁中／英文與不公開暗牌。

文件建立時新 CI：NOT RUN。前一階段真實 Android 兩次啟動與 force-stop [#38731973367](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38731973367) PASS，不是此次警告的驗收。

限制：SharedPreferencesAsync 仍為明文、無 fsync/ACID、不能保證多分頁並行安全，遠端 BEN 請求亦沒有 exactly-once。不能宣稱正式產品 READY。

## 練習與自我檢驗

**思考題：** 為什麼 Bridge Core 已驗證備份狀態完全合法，仍然需要讓玩家知道最新的 Pass 或出牌可能遺失？

**小練習：** 在 checkpoint_recovery_notice_test.dart 補一筆：兩個 Slot 都損壞時必須拒絕還原，而不是任意選最新的 JSON。

**完成標準：** 能區分事件重播合法性、資料耐久性、回退可見性與遠端 Bot 推理去重。

## 下一步

選擇適合 Android／iOS／Web 的交易式與加密持久層、明確安排 schema migration 及裝置生命週期測試。
