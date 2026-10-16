# M2-F36｜A5.3.2：歷史 PBN 匯出完整出牌紀錄

- Feature ID：M2-F36
- Milestone：A5.3.2（本機已完成牌局）
- 類型：玩家可見的 PBN 匯出、資料互通
- 工程狀態：SCOPED ENGINEERING VERIFIED（Flutter 97/97、Web Release、Chrome Demo CI PASS）
- 學習狀態：DELIVERED（尚未 PRACTICED / MASTERED）
- 程式：`apps/bridge_academy_flutter/lib/src/completed_pbn_export.dart`
- 測試：`apps/bridge_academy_flutter/test/a5_pbn_export_test.dart`

## 功能目的與實際情境

以前玩家打完一副牌，可以從歷史頁面確認並複製 PBN，卻只能分享 52 張初始牌、叫牌與結果，對方無法重建自己如何完成十三墩。現在合約牌局的 PBN 新增 `[Play "E"]`（依實際莊家左手首攻座位而定）和**十三行四張牌**，完整描述每一墩的出牌。四家全 Pass 時沒有出牌，不會憑空寫 `[Play]`。

這仍只適用於本機完成的歷史牌局；沿用 A5.3.1「玩家確認含四家手牌才複製到剪貼簿」的 UI 保護。

## 主要程式碼導讀

`CompletedPbnExport.encode` 僅接受 `SavedBoardCodec.decode` 驗證過且 `isFinished` 的牌局。合約的首攻者是 `contract.openingLeader`，PBN 出牌行的四個**固定座位欄**從首攻者開始，順時針排列；它不是每一墩的實際出牌先後順序。因此必須依 `trick.plays[*].handOwner` 排列，**不能**直接 `trick.plays.map(...)` 輸出。每墩要求四個不同座位恰好各出一張；若不滿 13 墩或座位資料異常，直接拒絕匯出。

```dart
final columns = [
  openingLeader,
  openingLeader.next,
  openingLeader.next.next,
  openingLeader.next.next.next,
];
for (final trick in state.tricks) {
  lines.add(columns.map((seat) {
    final matches = trick.plays
        .where((play) => play.handOwner == seat).toList();
    if (matches.length != 1) {
      throw const FormatException('Invalid seat layout in PBN play');
    }
    return matches.single.card.code;
  }).join(' '));
}
```

## 為什麼這樣設計

這是「**領域事件與交換格式不同**」的典型例子。Kotlin/Android 中常把 Room Entity、Domain Model 與 JSON DTO 分開處理；同理，Bridge Core 的 `Trick.plays` 儲存真實出牌順序，但 PBN 2.1 的四欄座位位置固定。錯把兩者當成相同，第一墩可能看不出錯，到第二墩由另一位玩家領出時就會不相容。

規格參考：Portable Bridge Notation v2.1 §3.6 (https://sackab.fi/data/PBN/PBN21a_1.pdf)。不採用外部套件重寫 Bridge Core；保留小型 serializer，與本機完成牌局的 PlayerView/加密歷史分離。

## 驗證與實際證據

重現：
```bash
cd apps/bridge_academy_flutter
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build web --release
```

測試覆蓋：Pass Out 不產生 `[Play]`；合約牌局產生十三行，每行依首攻固定座位排列四張；所有 52 張出牌不重複且逐張與 Bridge Core 終局 `completedTricks` 一致；A5.3.1 的未完成／已刪除不能匯出與剪貼簿確認仍保留。[Flutter CI #38866531814](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38866531814) 已執行：**flutter analyze 沒有問題、97/97 Unit／Widget PASS、Web Release Build 和 Chrome Demo E2E PASS**。第一次新測試的換行字串寫錯，於 `71364d0` 修正後通過；production serializer 和既有隱私測試均未放寬。真實第三方 PBN 匯入工具相容性仍未驗證。既有 A5.3.1 [Flutter 97/97](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38863038248) 屬於上一版，不能冒稱這一版證據。

## 練習與自我檢驗

**思考題（1 題）：** 第二墩由北家首攻，但 PBN 的 `[Play "E"]` 仍表示最初首攻為東家。第二墩四張牌在 PBN 出牌行應該從哪個座位開始？為什麼？

**5–15 分鐘練習：** 在 `a5_pbn_export_test.dart` 找出 `handOwner` 對照 PBN 欄位的測試，將第二墩的四欄輸出與實際出牌順序比較。

**完成標準：** 能區分 PBN 固定座位欄序與真實出牌時序，並理解出牌資訊僅能在牌局結束、取得明確分享同意後匯出。

## 下一步

A5.3 仍未完成正式 Gateway 歷史存取／匯出、PBN 匯入、跨裝置同步及大量牌例互通驗證；下一個以玩家新玩法為導向的階段可轉向 B1 四副牌練習。A3.5、Android／iOS 裝置測試維持暫停。
