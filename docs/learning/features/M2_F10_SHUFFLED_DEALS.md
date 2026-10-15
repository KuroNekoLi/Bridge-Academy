# M2-F10｜固定教學牌與隨機練習牌：可重現測試、依賴注入

- Feature ID：M2-F10
- 類型：純 Dart Bridge Core + Flutter Session/UI
- 工程狀態：IMPLEMENTED（CI 尚未驗收）
- 學習狀態：DELIVERED，尚未練習
- 程式：packages/bridge_core/lib/src/model.dart、apps/bridge_academy_flutter/lib/src/bridge_session.dart、bridge_app.dart
- 測試：packages/bridge_core/test/shuffled_deals_test.dart、apps/bridge_academy_flutter/test/board_mode_test.dart
- 驗收：docs/m2/M2_F10_SHUFFLED_DEALS_ACCEPTANCE.md

## 功能目的與實際情境
原本每次按「重新發牌」都會拿到相同的 52 張牌。這對重現 BEN／計分問題很有用，卻讓玩家無法練習不同牌型。新選項「發牌方式」包含固定教學牌例與新隨機牌局。選擇隨機不會改變電腦對手類型；Demo 和 BEN 依然明確區分。

## 主要程式碼導讀
Bridge Core 的 Deal.shuffled 先建立 4 花色 × 13 點數，再混洗並每 13 張分給一位玩家。最終仍由 Deal 建構子驗證 52 張牌都不重複。

BridgeSession 的 newGame 新增 BoardMode.training / BoardMode.fresh（預設 training）。只有 fresh 才用注入的 freshDealFactory 或 Deal.shuffled。這讓既有 M2-F07/F09 的固定真 BEN 回歸不會被隨機牌破壞。

Flutter 新增 board_mode_selector；畫面仍只經 PlayerView 得到玩家有權看到的牌，不能讀取完整四家手牌。

## 為什麼這樣設計
- Dependency Injection：測試注入 freshDealFactory，不必假設 Random.secure 會抽到指定的 North 手牌。這和 Android/Kotlin 為 ViewModel 注入 Fake Repository、Clock 或 Random 的思路相同。
- 隨機與測試可重現：真練習使用 Random.secure，測試可指定 seed；跨 SDK 的精確重播仍應儲存 PBN，而非只留 seed，因為 Dart PRNG 實作可能變更。
- 安全邊界：單機 Session 的內存包含所有牌，因此不可將這種設計直接稱作多人競賽的防作弊解決方案。多人模式應由伺服器發牌並掌握隱藏狀態。
- 替代方案比較：直接將所有固定牌例換成隨機，會使既有牌局 E2E 失去可重現性；保留兩種明確模式更容易分層測試。

## 驗證與實際證據
    cd packages/bridge_core
    dart test test/shuffled_deals_test.dart
    cd ../../apps/bridge_academy_flutter
    flutter test test/board_mode_test.dart
    flutter analyze

建立教材當下 CI NOT RUN。通過後將真實 GitHub Actions、commit 與測試數量補入驗收文件。Flutter Chrome、Android Emulator、真 BEN 是獨立的驗收層級。

## 練習與自我檢驗
**思考題：** 為什麼單元測試要注入固定 freshDealFactory，而不是呼叫 Random.secure 然後期待某張指定的 North 手牌？

**5–15 分鐘小練習：** 將 Deal.shuffled(seed: 42) 輸出為 PBN，透過 Deal.fromPbn 還原，比較 N/E/S/W 的牌集合。

**完成標準：** 能區分新牌隨機來源、固定種子測試、跨版本 PBN 精確重播，以及 PlayerView 的隱藏牌權限。

