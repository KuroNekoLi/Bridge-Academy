# M2-F38｜A5.4 歷史牌局統計與玩家視角分數

- Feature ID：M2-F38
- Milestone：A5.4
- 類型：Flutter 使用者功能／橋牌 Domain 聚合
- 工程狀態：ENGINEERING_VERIFIED（Flutter 105/105、Web build、Chrome Demo 回歸）
- 學習狀態：DELIVERED（非 PRACTICED／MASTERED）
- 來源：`apps/bridge_academy_flutter/lib/src/history_statistics.dart`、`bridge_session.dart`、`widgets/bridge_history_panel.dart`
- 驗收：`docs/product/A5_4_HISTORY_STATISTICS_ACCEPTANCE.md`、`apps/bridge_academy_flutter/test/a5_history_statistics_test.dart`

## 功能目的與實際情境

使用者以前可以完成牌局並開啟歷史列表，但看不出最近練習得如何。現在打開歷史，就能看到目前已保留的已完成牌局數、真正達成定約的比例，以及從**自己坐北／南或東／西**的角度換算的得分。搜尋「3NT」或選擇 Pass Out 時，統計會即時跟著資料改變。

## 主要程式碼導讀

從 `BridgeSession._summarize()` 開始，這個函式在加密的已完成歷史經 `SavedBoardCodec.decode()` 通過 Domain 檢查後，才把數值投影為安全 DTO `HistorySummary`。其中最重要的是：

```dart
contractMade: game.contract == null
    ? null
    : game.tricks.where((trick) =>
          trick.winner.isNS == game.contract!.declarer.isNS).length >=
        game.contract!.targetTricks,
```

**莊家方墩數**不一定是南北；當宣告者是 E/W，必須數東西方所贏的墩。與 `targetTricks = 6 + level` 比較，即可判斷成約。沒有定約的 Pass Out 不存在成約／宕約問題，必須保留 `null`，而非 `false`。

`HistoryStatistics.from(records)` 完全不需要讀取私人 `Deal`。累計玩家分數時：

```dart
netHumanScore += record.humanSeat.isNS ? record.score : -record.score;
```

這和 Kotlin Android 的 Clean Architecture 類似：Bridge Core 是 Domain，`HistorySummary` 是安全 DTO，`HistoryStatistics` 是可獨立驗證的純 Use Case，Flutter Widget 只負責展示。Widget 不應拿到 `GameState` 的四家手牌，否則即使不畫出來也存在外洩風險。

## 為什麼這樣設計

直接從終局 `NS score` 判斷每個定約是否達成，看起來更省事，但這會混淆東西方莊家與南北方分數；更不能把 Pass Out 視為失敗。因此統計從 Bridge Core 真正的莊家方墩數計算，而不是嘗試用分數正負來推測。

刻意只統計最多 12 副加密本機歷史，顯示「目前搜尋與篩選」的結果，避免將固定練習、匯入牌局與他人的正式比賽混作相同排名。日後若加入伺服器比賽，MP/IMP 必須使用共同牌例與比較對象另外計算。

## 驗證與實際證據

```bash
cd apps/bridge_academy_flutter
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build web --release
```

新測試涵蓋：E/W 座位得分反轉、真 Core 完整出牌後成約判斷、零筆和未知結果、中文畫面上的搜尋／Pass Out 篩選，以及英文標籤。[Flutter CI #38877191518](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38877191518) **SUCCESS**：Dart／Flutter analyze 無問題、**105/105 Flutter test PASS**（包含新的 4 項統計、畫面與真 Bridge Core 牌局測試）、Web Release Build 與 Chrome Demo／加密存檔 E2E 通過。原始提交：[f05ccf0](https://github.com/KuroNekoLi/Bridge-Academy/commit/f05ccf099d7a365b0044e00acdad9b247a955f7e)；[Feature Learning Gate #38877191369](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38877191369) PASS。這是本機 Flutter/Web 範圍驗收，不是雲端成績、真 BEN 模型品質、手機裝置或公開產品驗收。

## 練習與自我檢驗

**思考題：** 東方玩家在一副牌局獲得 `NS score = +100`，另一副西方玩家獲得 `NS score = -110`，從兩位玩家各自的分數視角，相加應是多少？為什麼不能用這個總和宣稱玩家的 IMP 排名？

**5–15 分鐘小練習：** 在統計單元測試再加入一副 `PASS OUT`，確認完成副數增加 1、成約率分母不變。

**完成標準：** 能分清 Bridge Core 的 signed NS Score、莊家成約率、各人得分方向與有比較基準的 IMP/MP 賽事分數。

## 下一步

B1 四副牌練習場次，真正累積四副彼此獨立的場次結果，不再只停留在單一牌局的搜尋與統計。A4.5 公開 HTTPS、A3.5 高保真 UI 和裝置 QA 保留 release blockers。
