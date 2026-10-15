# M2-F19｜Phase A2.7：AES-GCM 與交易式橋牌存檔

- Feature ID：M2-F19
- Milestone：Phase A2.7
- 類型：Flutter 儲存／安全／依賴注入
- 工程狀態：IMPLEMENTED（CI 尚未驗證）
- 學習狀態：DELIVERED
- 原始碼：apps/bridge_academy_flutter/lib/src/secure_session_persistence.dart、lib/src/bridge_app.dart
- 驗收與測試：apps/bridge_academy_flutter/test/secure_checkpoint_test.dart、docs/product/P1_A2_7_SECURE_TRANSACTIONAL_STORAGE_ACCEPTANCE.md

## 功能目的與實際情境

以前的本機牌局能夠恢復，也能檢查事件是否符合橋牌規則，但四家完整的 52 張牌仍存在明文 SharedPreferences。使用者在第八墩被迫關閉 App，恢復功能雖然存在，隱藏牌卻缺少正式的靜態保密保護。本輪新增 Android/iOS 的加密式交易儲存，保留原本 BridgeSession 外部 API。

## 主要程式碼導讀

資料流程：BridgeSession 呼叫 SessionArchiveStore.write → SavedBoardCodec.decode 重新驗證事件 → AES-GCM 用每次新 nonce 加密 → AtomicArchiveRecordStore.replaceRecord 在 SQLite 交易中提交新密文與舊版備份。

實作節錄：

~~~dart
final box = await _algorithm.encrypt(
  utf8.encode(text),
  secretKey: key,
  aad: _aad,
);
await _records.replaceRecord({
  'version': _version,
  'generation': generation,
  'active': active,
  'previous': existing?['active'],
  'recoveryPending': recoveryPending,
});
~~~

解密成功後仍要 SavedBoardCodec.decode 再用 BridgeGame.apply 驗證：通過密碼學認證並不代表出牌順序合法，兩種驗證各管一件事。

## 為什麼這樣設計

用 Android/Kotlin 比喻：BridgeSession 類似 ViewModel 只知道 Repository 介面；真正的實作才負責 SQLite（相近於 Room）和 Android Keystore。這是 Dependency Inversion 的應用。

加密與原子性是兩種不同保障：AES-GCM 保護資料的機密與完整性，而 SQLite Transaction 保證多個欄位作為同一筆資料提交。使用 SHA-256 checksum、或只將 SharedPreferences 的單獨欄位加密，都無法同時滿足這兩種需求。

替代方案是保留雙槽 SharedPreferences 再逐值加密，但多個 Key 仍缺乏一次原子提交。這次選擇單一資料庫交易，代價是需要管理 Keystore／Keychain 的金鑰生命週期、Android Backup 與版本遷移。

常見陷阱：舊版明文資料應先合法驗證，再完成加密資料庫提交，最後才能刪除。若先刪掉，途中崩潰將失去牌局。

## 驗證與實際證據

重現指令（在 Flutter App 目錄）：flutter pub get、flutter analyze、flutter test test/secure_checkpoint_test.dart、flutter test、flutter build web --release。

第一輪 CI 發現 Dart nullable map indexing 型別與多餘 import 的 analyzer 問題，已修正並重跑；正式成功證據以後續 CI 為準，不能把前一輪失敗冒稱通過。

初稿建立時 CI **NOT RUN**。新的測試使用 Fake SQL Atomic Store 和 Fake Key Provider，檢查密文沒有 PBN、寫入中斷保留舊版、錯誤金鑰拒絕、回退警告跨重啟、舊存檔遷移及事件驗證。不能把 Mock 資料庫測試當成 Android/iOS 安全儲存實測。

依使用者要求，實際 Android／iOS 裝置驗收將在完整大功能完成後集中執行。Web 仍是既有 SharedPreferences，尚不能宣稱具備正式版的隱藏牌保密性。

## 練習與自我檢驗

**思考題：** 牌局雖然已使用 AES-GCM 加密，但程式先更新 active Key、下一秒才更新 generation Key。為什麼裝置崩潰後仍可能讀到不一致的歷史？

**5–15 分鐘小練習：** 查看測試中模擬 SQL commit 故障的 failNextWrite，確認重新開 App 後只會還原最後一份已提交牌局。

**完成標準：** 能清楚區分加密認證、原子提交、事件版本核對以及橋牌規則合法性。

## 下一步

繼續完成安全存檔的大功能整合及 Web 儲存安全策略；實際裝置上的 Keychain/Keystore、資料庫斷電行為與恢復流程依照約定之後集中驗收。
