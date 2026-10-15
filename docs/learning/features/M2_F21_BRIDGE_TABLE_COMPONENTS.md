# M2-F21｜A3.1：橋牌桌拆分為 Presentation Widgets

- Feature ID：M2-F21
- Milestone：A3.1 Bridge Table UI V2
- 類型：Flutter UI／元件設計
- 工程狀態：ENGINEERING_VERIFIED（Flutter/Web scoped；[CI #38768532495](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38768532495) 67/67 Widget PASS，Chrome Demo PASS，true BEN [#38768532549](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38768532549) SUCCESS；device QA deferred）
- 學習狀態：DELIVERED（不代表 PRACTICED／MASTERED）
- 原始碼：`apps/bridge_academy_flutter/lib/src/widgets/bridge_table_components.dart`、`apps/bridge_academy_flutter/lib/src/bridge_app.dart`
- 驗收與測試：`apps/bridge_academy_flutter/test/a3_table_components_test.dart`，CI #38768161432 initial ANALYZE FAIL (lint), fixed CI #38768532495 ALL PASS (67 Widget / build / Chrome Demo)

## 功能目的與實際情境

開發者需要修改牌桌上 North/West/East/South 座位、局況狀態列或明手卡片時，不應再觸碰負責 Session 與 Replay 的大頁面。A3.1 將顯示職責抽成獨立 Widget，維持既有測試按鈕 Key、語系與可見資訊。

## 主要程式碼導讀

`BridgeTable` 使用 `AnimatedBuilder` 觀察 `BridgeSession`，從 `session.view` 取得受限 `PlayerView` 再傳至 `BridgeTableSurface`。下層座位元件只收到 `PlayerView` 和 callback：

```dart
final isDummy = view.contract?.dummy == seat && view.dummyExposed;
final hasDummyCards = isDummy && view.dummyCards != null;
final active = view.turn == seat;
// 只有公開的明手才有卡片元件。
if (hasDummyCards && seat != view.viewer) ...[
  Text(copy.t('dummy'), key: const Key('dummy_revealed')),
  for (final card in view.dummyCards!)
    BridgePlayingCardButton(
      card: card,
      prefix: 'dummy_card_',
      copy: copy,
      legal: view.canAct && active && view.legalCards.contains(card),
      busy: actionsPaused,
      onTap: () => onPlayCard(card),
    ),
]
```

當按下卡片，callback 回到 BridgeSession.submitCard，再由 Bridge Core 執行合法性與 actor/handOwner 驗證。元件不必知道 BEN 如何出牌，也不必知道四家暗牌。

## 為什麼這樣設計

對 Android/Kotlin 開發者而言，`BridgeSession` 類似 ViewModel、`PlayerView` 類似 UI State DTO、這些 StatelessWidget 對應 Compose 的 pure UI composables。UI 只做 Rendering + Intent Callback，不持有完整的 GameState。

替代做法是讓每個 Widget 注入 `BridgeSession` 並自行查詢或出牌，短期簡單卻造成無法獨立測試、規則驗證重複與暗牌外洩風險。因此採明確傳遞受限資料與 callback。另一個常見錯誤：僅將暗牌遮住並不安全，應在資料到達 Widget 前就過濾。

## 驗證與實際證據

```bash
cd apps/bridge_academy_flutter
flutter create --platforms=web --project-name=bridge_academy_flutter .
flutter pub get
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build web --no-pub --release
```

新增 Widget 測試覆蓋 Board 2/英文局況、四方座位、未公開 Dummy 不渲染、Demo 定約後可點擊合法明手牌。**首次 CI #38768161432 的 3 項 lint 已修正；CI #38768532495：analyze PASS、67/67 Widget PASS、Web Build PASS、Chrome Demo PASS；真 BEN #38768532549 SUCCESS（固定牌局），仍非實機驗收。** 安卓模擬器和實機測試依使用者指示暫停。

## 練習與自我檢驗

**思考題（1 題）：** 若已進入出牌階段，現在輪到 Dummy 的 South 出一張牌，而 North 是真正的莊家，畫面為什麼不應自行組出 `CardAction(actor: South, handOwner: South)`？

**5–15 分鐘小練習（可選）：** 閱讀 `BridgeSeatPanel` 和 `BridgeSession.submitCard`，畫出 `onPlayCard` 的資料流，指出合法判斷各在哪一層。

**完成標準：** 能說明顯示牌張、玩家決策權、Bridge Core 的權限驗證是三項不同責任，且能正確區分 Actor / Hand Owner。

## 下一步

A3.2 抽離 BiddingBox，改善合法叫牌狀態與可及性，再逐步重做四方牌桌佈局。
