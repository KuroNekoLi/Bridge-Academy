# M2-F43｜每日挑戰：可重現牌局與狀態一致性

- Feature ID：M2-F43
- Milestone：M2／B6.1–B6.3
- 類型：Domain／Flutter UI／本機持久化
- 工程狀態：IMPLEMENTED（CI 待驗證）
- 學習狀態：DELIVERED
- 原始碼：`apps/bridge_academy_flutter/lib/src/daily_practice.dart`、`daily_practice_store.dart`、`bridge_session.dart`、`widgets/daily_practice_panel.dart`
- 驗收與測試：`apps/bridge_academy_flutter/test/b6_daily_practice_test.dart`；目前 NOT RUN

## 功能目的與實際情境
玩家今天想練習四副固定牌。即使重開瀏覽器，也要能找回已完成的副數與分數；同一天不能因為 Random 引擎換版本而發出另一副牌。玩家逐副完成真實 Core 規則下的橋牌，不是把範例數字直接塞到 UI。

## 主要程式碼導讀
`DailyPracticeManifest.forDate(utcDate)` 正規化 UTC 年月日並建立 `daily_YYYY-MM-DD_v1`。`dealAt(index)` 透過 SHA-256 對「日期+版本+牌局 index+牌碼」產生固定 byte 序列，再依 digest 排序 52 張牌，得到不依賴 Dart RNG 的原創 Deal。相同輸入跨重啟應完全一致。

```dart
final deck = cards.map((card) => (card: card, hash: digest(card))).toList()
  ..sort((a, b) {
    for (var i = 0; i < 32; i++) {
      if (a.hash[i] != b.hash[i]) {
        return a.hash[i].compareTo(b.hash[i]);
      }
    }
    return a.card.code.compareTo(b.card.code);
  });
```

`BridgeSession.startDailyPractice()` 首先從加密 `DailyPracticeStore` 載入摘要，再生成下一張固定牌。`submitCall`／`submitCard` 持續使用 Bridge Core，而 `_recordDailyFinish` 將當前玩家視角的結果與 AES-GCM 日誌持久化。 `DailyPracticePanel` 只接收日期、完成數與原始比分，不接觸私有 `Deal`。

## 為什麼這樣設計
相當於 Kotlin Android 的 **StateFlow + Repository + immutable UI state**：Widget 不能自行推進進度；每次真實合法的 domain transition 才能更新受信任的 session。把挑戰日誌放在主 Checkpoint 之外，避免玩家開始另一場牌後直接抹除昨天結果。

替代方案是 `Random(seed)`：同一 SDK 內可能可重現，但不同版本未必保證 shuffle 細節穩定；另一方案是版本化伺服器下發 PBN，適合未來公開競賽，但本版先做免登入、離線練習。

常見錯誤：將 **NS 得分**直接當成玩家分數。如果玩家坐 E/W，應該顯示 NS 得分的相反數。另一個危險錯誤是日誌解密失敗直接覆寫成空陣列：那會抹除玩家所有日期紀錄。

## 驗證與實際證據
```sh
cd apps/bridge_academy_flutter
flutter analyze
flutter test test/b6_daily_practice_test.dart
flutter test
flutter build web --release
```
目前 **NOT RUN**：須等待這個 B6 分支的 GitHub Actions 回報，不能拿 master 或先前 B1 的 PASS 代替。相關測試涵蓋 Golden 牌組、52 張驗證、UTC 邊界、四副 Pass Out 結算、重開恢復、儲存失敗與雙語。尚未測試真正 BEN 或 Android/iOS 裝置。

## 練習與自我檢驗
**思考題（1 題）：** 如果今天改用 `Deal.shuffled(seed: utcDay.hashCode)` 產生每日牌局，看似更短，為何對跨 Dart SDK／跨平台的長期一致性不夠安全？

**5–15 分鐘小練習（可選）：** 在 `b6_daily_practice_test.dart` 加上另一日 golden digest fixture，驗證本地與 GitHub CI 產出的 PBN 完全相同。

**完成標準：** 能說明 UTC 跨日鍵、穩定演算法與 manifest revision 各自負責的相容性問題，且能解釋為何 PlayerView 不能拿整副 Deal。

## 下一步
未來要做多人公平每日賽，需要伺服器權威發牌、進行中不能偷窺的 PBN、賽後公開、MP/IMP 比較與反作弊；B6 目前刻意不實作那些範圍。
