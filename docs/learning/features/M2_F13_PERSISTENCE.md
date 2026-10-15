# M2-F13｜Phase A2：本機牌局保存與回放恢復

- Feature ID：M2-F13
- Milestone：Phase A2 / P1.2
- 類型：Bridge Core + Flutter 本機資料層
- 工程狀態：ENGINEERING_VERIFIED（Core／Flutter Web／Chrome／Android 模擬器存檔恢復；真正強制終止、加密、事務保證另驗）
- 學習狀態：DELIVERED
- 原始碼：packages/bridge_core/lib/src/single_player_coordinator.dart；apps/bridge_academy_flutter/lib/src/session_persistence.dart；apps/bridge_academy_flutter/lib/src/bridge_session.dart
- 驗收：docs/product/P1_A2_PERSISTENCE_ACCEPTANCE.md

## 功能目的與實際情境

玩家在第八墩關閉 App，回來應保留原本的牌、所有合法事件、發牌者與局況，以及當前輪次。不可重複套用玩家動作或提前公開其他三家的暗牌。本輪先完成跨平台本機可恢復原型；是否具備斷電保證、加密與實體裝置測試是不同的驗收。

## 主要程式碼導讀

Bridge Core 原有 GameTranscript.encode / decode；新加 Coordinator 的 snapshotForTrustedStorage、restore，以及 runBots(afterCommittedAction)。動作先經 BridgeGame.apply，再等待 afterCommittedAction 保存該版本，才開始下一個 AI 決策。

Flutter SessionArchiveStore 只抽象 read / write / clear，測試注入 MemoryArchive，正式原型使用 SharedPreferencesAsync。SavedBoardCodec 包含 schemaVersion、Board Number、Human Seat、Demo/BEN 模式、事件版本及完整 Transcript；解碼時重播所有事件並檢查 BoardDefinition、版本、fingerprint。一旦寫入失敗，UI 顯示 Retry Saving，暫停後續 Bot 和玩家行動；儲存成功後才恢復。

**信任界線：** 全四家手牌只在受信任的本機儲存與 Domain；Flutter Widget 始終只讀 PlayerView。不得把序列化內容傳入 BEN HTTP、日誌或事件追蹤。

## 為什麼這樣設計

- Event Sourcing：儲存真正已發生的動作，重新經 BridgeGame.apply 還原，不能直接相信存檔內宣稱的 score 或 turn。對照 Android/Kotlin 的 immutable StateFlow、Reducer 與 Room 的資料還原。
- Dependency Injection：SessionArchiveStore 能替換成 Fake 或未來加密 SQLite，類似 Kotlin Repository 抽象與 Fake DAO。
- 錯誤與代價：目前 shared_preferences 官方明確說明「寫入返回不保證同步到磁碟」，而且儲存內容未加密。因此這版是可恢復的 demo prototype，不是正式 critical-game-save 方案。正式發行前需要交易式持久層、加密、安全刪除與裝置 kill/relaunch QA。
- BEN 請求在回應保存前若發生程序終止，重新連線可能**重送推理請求**；單個 Core GameState 的事件不重複，不代表遠端 BEN HTTP exactly-once。將來需要伺服器 idempotency key。

## 驗證與實際證據

執行 Bridge Core 的 dart analyze --fatal-infos、dart test --reporter expanded；Flutter 端執行 flutter pub get、flutter analyze、flutter test、flutter build web --release。新增測試包含 mid-auction、mid-trick、公開明手、Board Number、Pass Out 後恢復、寫入失敗與重試、版本竄改、全四家暗牌不公開。

**已實際執行：** [Core CI #38723931963](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38723931963) 55/55 PASS、Dart Analyze 無問題；[Flutter CI #38724474420](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38724474420) 28/28 PASS、Flutter Analyze／Web Release Build／真 ChromeDriver SharedPreferencesAsync 存取及還原全部 PASS。[Android 模擬器 #38724474457](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38724474457) API 35 真 APK 及存檔恢復 3/3 PASS。真正 Process Kill／加密／交易 durability 仍未驗收。

## 練習與自我檢驗

思考題：為什麼玩家合法叫牌後應等待本機寫入成功，才能讓下一位 BEN Bot 行動？如果 BEN HTTP 已送出但程式在回應前被關閉，怎樣避免重複套用事件，又有什麼仍可能重試？

小練習：在 persistence_test.dart 將 eventVersion 改為 99，驗證 restore 失敗且 view 保持 null；將資料改回合法版本後應成功恢復。

完成標準：能區分事件版本、防止重複提交、非密碼學 fingerprint、Flutter PlayerView 資料邊界、shared_preferences 與交易資料庫的保證。

## 下一步

A2.2：具原子性交易與適當加密的正式儲存實作、schema migration、實體 Android/iOS 進程終止測試及服務端 AI idempotency；接著再開發 A3 牌桌 UX。
