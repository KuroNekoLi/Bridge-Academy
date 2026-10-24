# M4-F05｜自訂約定版本備份與安全匯入：只能 Fast-forward，不能默默覆蓋歷史

- Feature ID：M4-F05
- Milestone：M4.5（本機備份／可攜移轉部分）
- 類型：Dart append-only history、受限 JSON、Flutter Clipboard、使用者確認
- 工程狀態：**IMPLEMENTED；CI 以最新版成功 run 為準**
- 學習狀態：**DELIVERED**
- 原始碼：[CustomArchiveImport](../../../packages/bridge_conventions/lib/src/custom_convention_archive.dart) · [Flutter Editor](../../../apps/bridge_academy_flutter/lib/src/conventions/custom_draft_page.dart)
- 測試：[Archive merge tests](../../../packages/bridge_conventions/test/custom_convention_archive_test.dart) · [Clipboard widget tests](../../../apps/bridge_academy_flutter/test/m4_custom_convention_draft_test.dart)

## 功能目的與實際情境

你在一台裝置編輯好 SAYC 約定，想備份到另一台裝置。使用者可以在草稿編輯器按「複製草稿備份」，得到有限的 JSON 版本歷史，再到另一裝置使用「從剪貼簿匯入」。這不是跨裝置登入同步，也**沒有任何 AI 出價權限**。

最危險的情況是另一台已經編輯過自己的 v3，卻誤匯入從原始版本分岔的另一個 v3，導致未確認的資料覆寫。這一版的解法是 **Fast-forward only**：只有匯入資料的每個已存在版本與本機 fingerprint 完全相同、且後面接續更多版本，才可匯入。仍需要使用者明確確認。

## 主要程式碼導讀

```dart
final incoming = CustomConventionArchive.fromJson(
    jsonDecode(clipboardText));
final result = CustomArchiveImport.compare(
  local: current,
  incoming: incoming,
  expectedBase: 'BA-SAYC',
);
if (result == CustomArchiveRestore.fastForward) {
  // 先跳確認對話框，使用者按確認之後才儲存
}
```

此流程檢查：只接受 SAYC/21GF base、正確 revision hash chain、完整 schema、剪貼簿大小最多 128 KiB、不能降低 revision、不能分岔、不能錯誤用 SAYC 備份覆蓋 2/1、不能在無確認下寫入。如果兩者相同就顯示不需匯入。資料損壞／碰到不存在的 rule 會拒絕，不重設存檔。

## 為什麼這樣設計

就像 Git 的 fast-forward merge：遠端包含完整本地歷史，才能把 HEAD 前進；若雙邊改過同一舊版本，屬於 diverged branch，應交給使用者合併，不可默默選擇一方。這套 SHA-256 fingerprint 只保護意外損壞，**不是簽名、也不阻止具有本機寫入權的攻擊者重新計算整條鏈**。正式跨裝置同步還需要可信伺服器與身分驗證、原子儲存與衝突解決。

常見錯誤：將匯入的本機 JSON 寫入 `ConventionCatalog` 當作 BEN 可執行的模型設定。這仍然是玩家私有草稿。

## 驗證與實際證據

```bash
cd packages/bridge_conventions
dart test test/custom_convention_archive_test.dart
cd ../../apps/bridge_academy_flutter
flutter test test/m4_custom_convention_draft_test.dart
```

Domain 驗證 identical、fast-forward、divergent、舊備份、錯誤 base、空 archive；Widget Mock Clipboard 驗證匯入前詢問、衝突拒絕、匯出 round-trip。本機真裝置 clipboard 權限、跨設備可靠傳輸 **NOT RUN**，遵守使用者暫停 Android/iOS 裝置 QA 的指示。

## 練習與自我檢驗

**思考題（1 題）：** 你在 A 裝置的 revision=3 修改 Stayman，B 裝置也從 revision=2 改成另一套，為什麼不能直接把 B 的 revision=3 覆蓋到 A？

**5–15 分鐘小練習：** 在 `custom_convention_archive_test.dart` 增加一個倒退匯入（本機 revision=4、備份 revision=2），斷言結果是 `divergent`。

**完成標準：** 能解釋 hash chain、identity/base version、fast-forward、真正的伺服器授權各自解決什麼問題。

## 下一步

正式自訂 AI 約定的最後大門仍是經獨立審核的引擎相容性映射、100+ 叫牌語義金標案例、受控後端可重現模型／約定卡，不能用本機匯出匯入取代這些證據。
