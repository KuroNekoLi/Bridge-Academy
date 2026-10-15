# M2-F20｜Phase A2.8：Flutter Web 加密牌局存檔與跨重開恢復

- Feature ID：M2-F20
- Milestone：Phase A2.8 / P1.2
- 類型：跨平台儲存安全／Flutter Web／資料遷移
- 工程狀態：IMPLEMENTED（本次新 CI 尚待驗收）
- 學習狀態：DELIVERED
- 原始碼：apps/bridge_academy_flutter/lib/src/secure_session_persistence.dart、bridge_app.dart
- 驗收與測試：apps/bridge_academy_flutter/test/browser_encrypted_archive_test.dart、integration_test/browser_table_test.dart、docs/product/P1_A2_8_BROWSER_ENCRYPTED_CHECKPOINT_ACCEPTANCE.md

## 功能目的與實際情境

玩家在瀏覽器打到第 8 墩時，不應該讓其他三家的未公開手牌以明文留在 LocalStorage。之前 A2.7 已為 Android/iOS 設計原生加密資料庫，但 Web 仍使用原本的明文 SharedPreferences。這次將 Web 接到既有 AES-256-GCM 存檔器，在新開 App 後仍能還原相同版本的已提交牌局，並安全遷移舊明文資料。

## 主要程式碼導讀

新版以 Platform Routing 選擇儲存技術：原生 Android/iOS 使用 SQLite + secure storage；Web 用實際 WebCrypto 儲存金鑰與單一密文記錄。兩者都實作同一個 `SessionArchiveStore` 介面，BridgeSession 不必知道金鑰如何儲存。

```dart
factory EncryptedTransactionalSessionArchiveStore.browser({
  SharedPreferencesAsync? preferences,
  ArchiveEncryptionKeyProvider? keys,
  SessionArchiveStore? legacy,
}) {
  final prefs = preferences ?? SharedPreferencesAsync();
  return EncryptedTransactionalSessionArchiveStore(
    records: BrowserSingleRecordArchiveStore(preferences: prefs),
    keys: keys ?? NativeArchiveEncryptionKeyProvider(),
    legacy: legacy ?? PreferencesSessionArchiveStore(preferences: prefs),
  );
}
```

儲存先驗證事件紀錄，再透過 AES-GCM 認證加密，最後寫入瀏覽器單一記錄。舊明文資料只有在加密資料成功提交後才清除；金鑰無法取得或錯誤時直接停止，不會退回明文。回復記錄仍需經 `SavedBoardCodec.decode` 與 Bridge Core 驗證，而不只是「成功解密」就接受。

## 為什麼這樣設計

這是 **Dependency Inversion + Fail-Closed Security**。類比 Kotlin/Android：ViewModel 只依賴 Repository 介面，Android 交給 Room/Keystore，Web 使用另一個實作，但商業層不必改動。

沒有採用「只把資料 Base64 編碼」：Base64 不是加密；也沒有宣稱 Web LocalStorage 是 SQLite Transaction：它沒有相同的持久化、併發與資料損毀保證。Web Crypto 的安全金鑰無法保護來自相同網域的惡意 JavaScript（XSS），也不是正式多人防作弊機制。

常見錯誤：先清除舊版 SharedPreferences 明文，然後才嘗試寫加密記錄；中途失敗會造成牌局永久遺失。這次採「先驗證、再提交、最後清除」，並且失敗時不繼續 BEN 或玩家操作。

## 驗證與實際證據

重現指令：

```bash
cd apps/bridge_academy_flutter
flutter pub get
flutter analyze
flutter test test/browser_encrypted_archive_test.dart
flutter test
flutter build web --release
```

Chrome Integration 要使用**真正 browser WebCrypto 實作**，不能把 Fake EncryptionKeyProvider 的 unit test 當作瀏覽器實測。建立教材時 CI 尚未執行；CI 回報後才能更新為 ENGINEERING_VERIFIED。實體 Android/iOS KeyStore、斷電寫入、Web 多分頁與網頁安全標頭須在正式發布前另行驗收。

## 練習與自我檢驗

**思考題：** 使用 AES-GCM 將 LocalStorage 內容加密，為什麼仍不能宣稱「即使頁面存在 XSS，其他人也看不到完整 52 張牌」？

**5–15 分鐘小練習：** 查看 `browser_encrypted_archive_test.dart`，把金鑰切換為另一組，確認恢復拒絕而不是退回舊明文。

**完成標準：** 能說明「靜態加密」、「交易／持久化保證」、「相同來源腳本存取權」是三種不同的問題。

## 下一步

後續 A3 橋牌桌 UI 與 A4 正式 BEN 部署前，Web 仍需 CSP/HSTS 與多分頁政策；實機 Android/iOS 的金鑰保護、備份與崩潰測試依先前決定集中驗收。

