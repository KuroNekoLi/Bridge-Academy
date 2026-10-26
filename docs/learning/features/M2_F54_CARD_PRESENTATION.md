# M2-F54｜重用撲克牌顯示套件，叫牌時看得到自己的牌

- Feature ID：M2-F54
- Milestone：M2／A3 UI 延伸
- 類型：Flutter UI／第三方 presentation adapter
- 工程狀態：VERIFIED／ENGINEERING_PASS（Windows＋Web/Chrome CI scoped）
- 學習狀態：DELIVERED；尚無 PRACTICED／MASTERED 證據
- 原始碼：[牌面 adapter](../../../apps/bridge_academy_flutter/lib/src/widgets/bridge_card_face.dart)、[手牌／明手／本墩](../../../apps/bridge_academy_flutter/lib/src/widgets/bridge_table_components.dart)、[本機牌桌](../../../apps/bridge_academy_flutter/lib/src/bridge_app.dart)、[Gateway 牌桌](../../../apps/bridge_academy_flutter/lib/src/gateway_table.dart)
- 驗收與測試：[牌面測試](../../../apps/bridge_academy_flutter/test/m2_card_presentation_test.dart)、[既有明手回歸](../../../apps/bridge_academy_flutter/test/a3_table_components_test.dart)、[驗收](../../product/UX_WORKSPACE_ACCEPTANCE.md)

## 功能目的與實際情境

原本手牌主要是短文字按鈕，且叫牌階段沒有顯示自己拿到什麼。現在本機與 Gateway 叫牌時都顯示自己的 13 張牌；只有進入出牌階段且 Core 允許時才啟用。手牌、已公開明手及本墩使用共用的牌面 renderer；對手仍只顯示張數。

採用釘選 `playing_cards 0.4.1+11`。它負責畫牌，本專案仍負責決定哪些牌能顯示／能提交。套件預設牌角在小牌上太小，因此透過公開 style API 放大中央點數並使用花色字形。

## 主要程式碼導讀

資料流：Core／Coordinator → 合法 PlayerView → `BridgePlayerHand`／`BridgeSeatPanel` → `BridgePlayingCardButton` → `BridgeCardFace` → 套件 `PlayingCardView`。按鈕點擊則回到 session 提交 Card，最後仍由 Core 驗證。

```dart
onPressed: legal && !busy ? onTap : null,
```

`displayCard` 只做四種 suit、十三種 rank 的單向型別轉換；沒有建立牌堆、洗牌或合法性檢查。`sortedVisibleCards` 複製已授權的卡片清單，依 ♠♥♦♣／大到小排序，不改 Core 或事件順序：

```dart
List<bridge.Card> sortedVisibleCards(List<bridge.Card> visible) =>
    [...visible]..sort((a, b) {
      const order = [Suit.spades, Suit.hearts, Suit.diamonds, Suit.clubs];
      final suit = order.indexOf(a.suit).compareTo(order.indexOf(b.suit));
      return suit != 0 ? suit : b.rank.index.compareTo(a.rank.index);
    });
```

套件牌面置於 ExcludeSemantics 中；按鈕外層以獨立 semantics container＋onTap action 保留 zh-TW/en 的完整「可出牌／目前不能出牌＋花色＋點數」語意。打勾／鎖定是非顏色提示，點擊區大於等於 48px。

## 為什麼這樣設計

這類似 Android Compose 中把 domain model 映射成 UI model：第三方元件不知道完整手牌，也不能成為遊戲規則的另一個來源。即使 renderer 本身有發牌 helper，本專案不呼叫它。

替代方案是引進 `card_game` 一起管理所有 deck/group/rule。它有拖放與動畫，適合之後研究，但若把四手牌都交給 Flutter 元件，就破壞 PlayerView 邊界；若讓它直接接受移動，又會出現第二份遊戲狀態。因此本輪只整合 presentation，動畫屬後續 U3。

另一個陷阱是把 npm/pub 套件的程式 license 當作每張附圖的個別授權證據。此套件內附 Wikimedia 圖像缺逐圖紀錄，現有樣式完全覆寫 rank/suit，不讀圖像；但 Flutter 仍可能打包未使用資產，所以公開 binary 前還要排除／完成資產稽核。詳見 [OSS audit](../../OPEN_SOURCE_AUDIT.md)。

## 驗證與實際證據

環境：Windows，Flutter 3.47.8／Dart 3.13.7。可重現：

```powershell
flutter test --no-pub test/m2_card_presentation_test.dart test/a3_table_components_test.dart test/a3_accessibility_test.dart --reporter expanded
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build web --no-pub --release
```

新測試逐張核對 52 個 suit/rank、排序不修改輸入、叫牌只 render ownCards 共 13 張、叫牌牌不可點、鍵盤 Enter 與 semantics tap 可各提交合法牌、單張牌語意不與手牌區合併、busy／illegal callback 為 null、不載入 Image 元件。既有明手所有權／13 墩／隱私及放大字體回歸繼續執行。確切最後執行結果與 Chrome 範圍見 [驗收](../../product/UX_WORKSPACE_ACCEPTANCE.md)。

本輪沒有重跑 genuine BEN、native DDS 或裝置 UI/E2E，不能用 Demo 測試冒稱那些通過。

**本輪實際 CI：** [Flutter/Web/Chrome #40255094253](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40255094253)，source SHA `5b72c13241a6f75dafed66b4a20ebe87677098f3`；198/198 Flutter、analyze、Web release、ChromeDriver 155 的新局 52-card/13-trick 與加密 checkpoint targets 全部 PASS。這是 Demo／Mock scope，真 BEN／Precision regression 狀態另記在驗收，仍非裝置或正式部署。

## 練習與自我檢驗

**思考題（1 題）：** 撲克牌套件若有洗牌和拖放驗證 API，為什麼仍不能直接決定本專案的一次出牌成功？

**5–15 分鐘小練習：** 把牌面測試中的 busy 改為 false／legal 改為 false，確認仍無 onPressed，再指出點選合法明手牌時的 handOwner 為什麼和 acting human 可能不同。

**完成標準：** 能指出 PlayerView 決定可見資料、Session 提交意圖、Bridge Core 決定合法性；改外觀不能擴大 AI／Widget 可見手牌。

## 下一步

U3 的選牌／移動動畫需要以已確認的 Core version 為來源，並支援 reduced motion。牌飛到桌面不代表請求成功；失敗仍須保留可重試的真實狀態。
