# M2-F14｜A2.2：雙槽 Checkpoint、提交標記與損壞恢復

- Feature ID：M2-F14
- Milestone：Phase A2.2 — Game Persistence hardening
- 類型：Flutter 資料持久層／可靠性
- 工程狀態：ENGINEERING_VERIFIED（Flutter 42/42、Web Build／真 Chrome Demo、Learning Gate PASS；Android／真 BEN 本版回歸待驗，加密與斷電保證尚未完成）
- 學習狀態：DELIVERED
- 原始碼：apps/bridge_academy_flutter/lib/src/session_persistence.dart
- 測試：apps/bridge_academy_flutter/test/checkpoint_store_test.dart
- 驗收：docs/product/P1_A2_2_CHECKPOINT_HARDENING_ACCEPTANCE.md

## 功能目的與實際情境

玩家完成第八墩後，若 App 正好在覆寫存檔時被系統中斷，單一 SharedPreferences 字串可能壞掉。此功能先建立兩個 checkpoint 槽位與一個已提交槽位標記：寫入新的槽位，完整讀回並檢查內容後，最後才更新 active marker。發生寫入錯誤時，先前的合法存檔仍保留。

這並不意味所有裝置已提供斷電後的資料持久性，也不表示 SharedPreferences 會把四家暗牌加密。這次處理的是**常見中斷／資料損壞的復原能力**，不是完整產品發行等級的保證。

## 主要程式碼導讀

```dart
final generation = (active?.generation ?? 0) + 1;
final target = active?.slot == 'a' ? 'b' : 'a';
await _store.setString(_slotKey(target),
    _encodeEnvelope(archive, generation));
final checked = await _readSlot(target);
if (checked == null ||
    checked.archive != archive ||
    checked.generation != generation) {
  throw StateError('Pending checkpoint validation failed');
}
await _store.setString(activeKey, jsonEncode({
  'slot': target,
  'generation': generation,
}));
```

提交順序很重要。先寫入**非目前 active** 的資料槽，驗證完整內容後才切換 activeKey。讀取時優先使用 active，有損壞時僅能回退至已存在、經 `SavedBoardCodec.decode()` 重新逐事件驗證的上一個槽。

`SHA-256` 只檢查意外內容不一致。惡意者能重新計算沒有密鑰的 SHA-256，**這不是 HMAC、AES 或防竄改認證**。Bridge Core 的 `GameTranscript.decode` 會經規則引擎重放叫牌和出牌，拒絕非法時間軸；但本地可信攻擊者仍可建立一個自洽的虛構歷史，因此不適用於有排名的線上競賽。

## 為什麼這樣設計

- **Write-ahead / Commit marker 概念：** 切換包含 slot 與 generation 的 activeKey 是邏輯提交點；generation 區分上一版已提交存檔與尚未提交的新版本，即使 active 槽意外毀損也不得把未提交較新的一槽當成備份。對照 Android Room/SQLite transactions：資料先準備，最後正式提交。但 SharedPreferences 多個 key 的寫入**不是真正的資料庫交易**，斷電/fsync 邊界沒有同等保證。
- **可測試的 I/O 依賴注入：** `CheckpointKeyValueStore` 可用 Fake 依序模擬「槽位寫入失敗」「提交標記寫入失敗」「寫入後讀回出現壞資料」，就像 Kotlin 注入 Fake DAO 或 Faulty FileSystem。
- **舊版資料相容：** `bridge_academy.local_game.v1` 只在經 Bridge Core 驗證、v2 新槽與 activeKey 寫入成功後才刪除。舊版資料無效時必須拒絕，而不是默默重開遊戲。
- **替代方案與成本：** 完全改用 SQLite transaction、OS secure storage 是未來正式方案；本版仍保留 SharedPreferences 以維持 Flutter Web／Android 現有 CI，減小本次變更範圍。
- **常見陷阱：** 看見 SHA-256 就稱作「已加密」；或者先覆寫 active 再寫備份。前者誤導安全性，後者在部分寫入後可能連舊紀錄都找不到。

## 驗證與實際證據

```bash
cd apps/bridge_academy_flutter
flutter pub get
flutter analyze
flutter test test/checkpoint_store_test.dart
flutter test
flutter build web --release
```

共新增 14 個隔離測試：雙槽輪替、四種寫入／損壞故障、未提交的新一代不得成為恢復來源、外層 checksum 已重算但內層非法事件、雙槽全毀、尚未提交的孤兒槽、v1 讀取遷移及失敗保留、刪除、跨 BridgeSession 重新開啟與隱藏手牌邊界。

**實際驗收：** [Flutter CI #38727920768](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38727920768)，SHA 456aa326，**42/42 PASS、Analyze 無問題、Web Release Build PASS、真 Chrome Demo PASS**。新增加 14 個故障注入案例。[Learning Gate #38727920737](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38727920737) PASS。 真正 Chrome／Android／iOS 實際強制關閉進程、設備斷電、多分頁並發、OS 保護的加密儲存，以及 BEN 網路 exactly-once 仍要另行驗證。

## 練習與自我檢驗

**思考題：** 如果第二個槽位已寫入第 10 墩，但更新 activeKey 前發生例外，下次恢復應使用第 9 墩還是第 10 墩？為什麼？

**小練習（5–15 分鐘）：** 在 Fake KeyValueStore 模擬 activeKey 更新失敗，驗證 `read()` 仍只傳回上一個已提交合法事件版本。

**完成標準：** 能區分待提交資料、已提交資料、CRC/SHA 校驗、Domain replay 合法性、真正 ACID transactions 與靜態資料加密。
