# M5-F03｜賽後教練：從可信 Gateway 牌局帶入公開叫牌

- Feature ID：M5-F03
- Milestone：M5.3 Postgame Public Auction Review
- 類型：Flutter 牌局整合、資料最小化、Server-owned GameSystems
- 工程狀態：IMPLEMENTED；正式驗收依最新 M5 與 Flutter CI
- 學習狀態：DELIVERED
- 原始碼：[GatewayTable](../../../apps/bridge_academy_flutter/lib/src/gateway_table.dart) · [AuctionCoachPage](../../../apps/bridge_academy_flutter/lib/src/conventions/auction_coach_page.dart)
- 驗收與測試：[Widget Test](../../../apps/bridge_academy_flutter/test/m5_auction_coach_test.dart) · [M5 CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/m5-coach.yml)

## 功能目的與實際情境

玩家打完一局真 Gateway 對局，最想知道的是：剛才東西與南北分別依哪個制度叫牌？每口叫牌由哪個座位提出？我們是否能解釋它？

M5.3 在**已經結束**、且有受信任 `GameSystems` 的 Gateway 牌局下方新增「檢視本局公開叫牌」。按下後只帶入三組必要資料：`view.dealer.letter`、`view.auction.map((a) => a.call.code)`，以及 `session.gameSystems`（由 Gateway Session 確認與固定）。這些都是公開牌局紀錄或可信版本描述，**不傳 `PlayerView.ownCards`、`dummyCards`、Deck/Deal、access token、完整私密 PBN**。

## 主要程式碼導讀

```dart
final calls = [
  for (final entry in view.auction) entry.call.code,
];
Navigator.of(context).push(MaterialPageRoute<void>(
  builder: (_) => AuctionCoachPage(
    isEnglish: copy.isEnglish,
    initialDealer: view.dealer.letter,
    initialCalls: calls,
    initialSystems: session.gameSystems,
  ),
));
```

`AuctionCoachPage.initState` 只將這些公開輸入預填在唯讀證據教學流程中的表單，使用者還可以用它作離線試算。再次點「檢視」才重新執行 `PublicAuctionCoach.review`，後者永遠只做公開叫牌、source/evidence 分類。任何 `UNKNOWN` 仍明確顯示，沒有暗中呼叫 BEN API 推論對手持牌。

## 為什麼這樣設計

相當於 Kotlin/Compose 將 Domain 的 `publicEventLog` 映射成新的 screen-specific DTO，不是直接把一整個含私有資料的 `GameState` 傳入教學頁。與 Android Intent extra 相同，越少欄位，越容易證明不存在額外私牌外洩路徑。

替代方式是在賽中隨時顯示候選叫品；但尚未有真正的 pinned BEN/BBA expert-signed 候選證據，可能引導玩家誤認教練掌握最佳策略，所以此階段只在結束後提供公開回顧，而且保留「未證實的叫牌含義」標記。

常見錯誤：將 Flutter client 自己選擇的制度欄位 `_ns`、`_ew` 當作歷史真實版本；應使用 server-confirmed `session.gameSystems`，否則使用者在遊戲結束後改了下次的下拉選單，就會篡改上一局的教學來源。

## 驗證與實際證據

```bash
cd apps/bridge_academy_flutter
flutter pub get && flutter analyze --no-pub
flutter test test/m5_auction_coach_test.dart --reporter expanded
```

Widget test 以特定 `dealer=E`、四次公開 `1NT PASS 2C P` 和雙方不同已釘選制度啟動 Coach，確認文字預填、正確 NS/EW、沒有虛假的最佳叫品或草稿背書。常規 Flutter 測試另外須驗證 `GatewayTable` 編譯整合；**真實手機及真 BEN 牌局點擊式 E2E 未執行**，不能據此稱正式發布完工。只有 M5 CI completed/success 才算 scoped 測試成功。

## 練習與自我檢驗

**思考題：** 為什麼教練從已完成 Gateway 對局取得制度時，必須使用 `session.gameSystems`，而不是下次開新牌局前畫面上的 `_ns` 下拉選單？

**5–15 分鐘小練習（可選）：** 在 `m5_auction_coach_test.dart` 變更預填的 dealer 為 W，確認整個公開叫牌座位依序輪轉，不需要任何私有牌張。

**完成標準：** 能清楚說出事件投影（public projection）、server-owned version pins、UI 設定與歷史記錄的不同權威範圍。

## 下一步

M5.4 若要顯示「AI 當時考慮的其他叫品」，必須先記錄真實 BEN/BBA request/response 與可稽核解釋來源，不可用語言模型臆造；評估、專家 Golden 與 4GB VPS/裝置 QA 仍為獨立關卡。
