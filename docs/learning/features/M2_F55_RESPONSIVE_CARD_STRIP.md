# M2-F55｜窄螢幕單排手牌與可操作捲軸

- Feature ID：M2-F55
- Milestone：M2／A3，U3 第一個小範圍
- 類型：Flutter UI
- 工程狀態：VERIFIED／本機 ENGINEERING_PASS（200/200＋Web）；新提交 CI 另記於 [驗收](../../product/UX_WORKSPACE_ACCEPTANCE.md)
- 學習狀態：DELIVERED；未有 PRACTICED／MASTERED 證據
- 原始碼：[BridgeCardStrip](../../../apps/bridge_academy_flutter/lib/src/widgets/bridge_card_strip.dart)、[自己／明手接點](../../../apps/bridge_academy_flutter/lib/src/widgets/bridge_table_components.dart)
- 驗收與測試：[card strip tests](../../../apps/bridge_academy_flutter/test/m2_card_strip_test.dart)、[原有明手測試](../../../apps/bridge_academy_flutter/test/a3_table_components_test.dart)、[放大字體測試](../../../apps/bridge_academy_flutter/test/a3_accessibility_test.dart)

## 功能目的與實際情境

在 320–375px 手機寬度，13 張獨立牌面原本會排成多行，公開明手也占去大量高度。現在空間足夠時維持一排展開；放不下時用同一尺寸的牌面＋水平捲動＋可拖曳捲軸，並顯示中英提示。自己的牌和公開明手都重用此元件。

這只是牌列的操作改善，沒有宣稱整張牌桌已完成單屏、橫直屏最佳化或出牌動畫，也沒有把 Chrome viewport 當裝置驗收。

## 主要程式碼導讀

既有 `BridgePlayerHand`／`BridgeSeatPanel` 仍從 PlayerView 取得 ownCards 或已公開 dummyCards，排序副本後建立原有 `BridgePlayingCardButton`；新的 `BridgeCardStrip` 只接收這些 Widget，沒有 Deal、GameState、Session 或 bot。

真正的切換條件：

```dart
final contentWidth = widget.children.length * 68 +
    (widget.children.length - 1).clamp(0, widget.children.length) * 6;
final overflow = constraints.hasBoundedWidth &&
    contentWidth > constraints.maxWidth;
```

寬度夠時使用 Wrap；不夠時改用水平 SingleChildScrollView／Row。每張牌外框固定寬 68，沒有為塞進 13 張而壓縮到小於 48px。`ScrollController` 屬於 `_BridgeCardStripState`，dispose 時釋放；Scrollbar 與 ScrollView 共用它。內層停用自動 scrollbar，避免桌面出現重複捲軸。

卡牌 onTap、legal／busy、語意名稱和獨立 container 仍是 M2-F54 的元件；捲動只改畫面 offset，不提交任何牌局動作。

## 為什麼這樣設計

這近似 Android Compose 把玩家手牌放進可水平捲動 Row，同時讓 ViewModel／Core 保留權威狀態。13 張牌數量很小，維持 eager children 可保留既有 keyboard／semantics／測試 key，不必引入新的牌庫、adapter position 或規則引擎。

替代方案是扇形互相重疊或縮小牌面；雖然能看見所有牌角，狹窄畫面容易使實際可點區小於 48px。這裡選擇捲動，代價是部分牌需要滑動才看見，因此必須有提示、可見捲軸，並測試最後一張仍可正確操作。

常見陷阱：已捲到最後，玩家打出許多牌或改變視窗寬度後，內容變短。切回不需捲動的 layout 時，不能留下失效 controller／負位移／錯誤的牌索引。本輪測試特別將 13 張縮為 2 張再縮為 0 張。

## 驗證與實際證據

本機 Windows，Flutter 3.47.8／Dart 3.13.7：

```powershell
flutter analyze --no-pub
flutter test --no-pub test/m2_card_strip_test.dart test/a3_accessibility_test.dart test/a3_table_components_test.dart --reporter expanded
flutter test --no-pub --reporter expanded
flutter build web --no-pub --release
```

已執行 scoped **10/10 PASS**：320px 牌列高度 <180、最後 CA 初始在畫面外、捲動後 callback 是正確的 CA、按牌區 >=48、提示可切中英、13→2→0 張不出錯；1280px 無提示／不需捲動且所有牌同一列。既有 320/375/768px 放大字體及明手 owner 測試一起通過。全套與 Web／Chrome 最終結果以 [本輪驗收](../../product/UX_WORKSPACE_ACCEPTANCE.md) 的實際 SHA／命令為準；不可將前一批 `5b72c13` 的 CI 當作本批 renderer layout 已通過的證據。

Demo／Mock、genuine BEN、真正裝置仍分開；owner-held Android/iOS UI/E2E 沒有執行。

## 練習與自我檢驗

**思考題（1 題）：** 13 張牌放不下時，為什麼這裡選擇水平捲動，而不是把每張牌寬度直接除以 13？

**5–15 分鐘小練習：** 在 320px 測試改成 375px，捲動到 CA 後只保留兩張牌，再把視窗加寬到 1280px，確認不再顯示捲動提示、沒有 overflow，且沒有觸發任何出牌 callback。

**完成標準：** 能指出「內容尺寸 → 是否 overflow → 呈現方式」，以及捲動位置和 Core 對局版本是不同狀態；尺寸變更不應選錯牌或改規則。

## 下一步

U3 剩餘整張牌桌的單屏／橫直屏布局、選牌偏好、可中止出牌／收墩動畫與 reduced motion；這些需要另外的 feature lesson 和驗收，不能僅由本牌列宣稱完成。
