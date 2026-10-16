# M2-F29｜A4.3.2b：AES-GCM 加密 Checkpoint 與 Bot 中斷接續

- Feature ID：M2-F29
- Milestone：A4.3.2b
- 類型：Dart Backend／資料持久化／一致性
- 工程狀態：SCOPED ENGINEERING VERIFIED（Gateway CI 32/32，含 OS SIGKILL 重啟，非正式部署）
- 學習狀態：DELIVERED（不代表 PRACTICED 或 MASTERED）
- 原始碼：`services/bridge_gateway/lib/src/encrypted_session_store.dart`、`authoritative_game.dart`、`gateway_service.dart`
- 驗收與測試：`services/bridge_gateway/test/encrypted_restart_test.dart`、`docs/product/A4_GATEWAY_A4_3_2B_ACCEPTANCE.md`

## 功能目的與實際情境

玩家按下 1NT，或輪到 BEN 連續行動時，Gateway 如果突然中斷，下一次呼叫不該從新牌局開始，或將已經完成的出牌再提交一次。過去匿名 Token／Bridge Core／去重表都只在記憶體中；這輪把**權威的四家發牌、事件紀錄、已成功的 Request ID 回應**一起保存。由於完整 PBN 很敏感，儲存檔必須加密。

## 主要程式碼導讀

`EncryptedSessionStore` 用 `AesGcm.with256bits()` 和外部 32-byte Key，加密 `GameTranscript` + request ledger，寫入 tmp 檔並 flush 後 rename。Gateway 啟動時先載入檔案，利用 `SinglePlayerCoordinator.restore` 重演全部動作；任何壞檔／錯誤金鑰都拒絕啟動，不會悄悄另起新局。

`AuthoritativeGame.execute` 保存 pending request，再真正執行命令：

```dart
_pending = {'request_id': requestId, 'fingerprint': fingerprint};
await _persist(); // Before the first real action.
await coordinator.runBots(afterCommittedAction: _persist);
_replies[requestId] = (fingerprint, reply);
_pending = null;
await _persist(); // Event + reply in the same checkpoint.
```

在 Android/Kotlin 世界，這相當於一個小型、僅單機的 Room Transaction + Event Replay，但**不能**因此宣稱等同 SQLite WAL、分散式交易或永久 exactly-once。每次 Bot 確認一個動作就寫入檢查點，重啟時接續目前版本，不是重新交給 BEN 決定前面的動作。

## 為什麼這樣設計

不能只在 Bot 執行完 4 步後儲存：如果第 3 步成功時突然斷線，硬把整個批次重新執行將可能重複出牌。反過來，每一步檢查點提供了**已驗證事件的可恢復邊界**。

也不能把 Token 與四家手牌放進 log 或可讀的明文 JSON。Token 只留 SHA-256 Digest；四手牌局狀態用 AES-256-GCM 加密。和完整資料庫系統相比，單一檔案 rename 更容易驗證，但不能解決跨多程序鎖、備援儲存與供應商磁碟斷電耐久性。

## 驗證與實際證據

```bash
cd services/bridge_gateway
dart pub get
dart analyze --fatal-infos
dart test --reporter expanded
```

新增測試：同一 bearer 重啟後恢復同一 version、同一 Request ID 返回原結果；中途有 BEN 出錯時，只保存已提交的 Bot Event，再重啟補完而不重複；加密檔不可包含明文完整 PBN、Token、Request ID；錯誤金鑰拒絕啟動；持久模式拒絕用客戶端提供的手牌呼叫舊 Raw API。[Gateway CI #38841623172](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38841623172) 在提交 `f1dbf74` 上 **Dart analyze 無問題、32/32 測試 PASS**；[前一版 CI #38841447564](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38841447564) 31/31 PASS。新增 [process_restart_test.dart](../../services/bridge_gateway/test/process_restart_test.dart) 使用獨立 Dart 子程序，執行牌局、以 `SIGKILL` 強制結束進程、重啟後用原 Token/Request ID 驗證版本 1 及回應完全相同；並確認舊版提交手牌 API 被 404 阻止。[Learning Gate #38841447645](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38841447645) PASS。仍沒有證明斷電、寫檔中 SIGKILL、跨程序競爭與分散式 Exactly Once。

## 練習與自我檢驗

**思考題（1 題）：** 為什麼必須把「最後一次提交的 Bridge Core 事件」和「同一個 Request ID 的成功回應」一起放入同一個原子 Checkpoint？如果只保存事件，遺失回應紀錄會造成什麼問題？

**5–15 分鐘小練習：** 在 `encrypted_restart_test.dart` 增加一個「同 ID、不同 payload」的重啟後案例，應得到 HTTP 409 且版本不變。

**完成標準：** 能解釋 `request_id`、`expected_version`、event replay、AES-GCM 保密及原子寫入之間的關係，並說出分散式 exactly-once 尚缺哪些條件。

## 下一步

A4.3.2c：寫檔中強制終止、磁碟斷電／fsync、儲存金鑰輪替、跨節點交易式去重；A4.3.3：實際 PINNED BEN Gateway 完整 13 墩測試。A3.5 和 Android/iOS UI 裝置測試仍為延期狀態。
