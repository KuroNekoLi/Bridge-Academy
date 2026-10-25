# M5-F02｜雙語叫牌教練：只顯示已知公開資訊與作者草稿意圖

- Feature ID：M5-F02
- Milestone：M5.2 Flutter Coach Sandbox
- 類型：Flutter 表單、私有本機 Draft Repository、Domain DTO、UNKNOWN UX
- 工程狀態：IMPLEMENTED；實際 PASS 依最新 M5 CI 紀錄
- 學習狀態：DELIVERED
- 原始碼：[auction_coach_page.dart](../../../apps/bridge_academy_flutter/lib/src/conventions/auction_coach_page.dart) · [App entry](../../../apps/bridge_academy_flutter/lib/src/bridge_app.dart)
- 驗收與測試：[Widget tests](../../../apps/bridge_academy_flutter/test/m5_auction_coach_test.dart) · [Domain tests](../../../packages/bridge_conventions/test/auction_coach_test.dart) · [M5 CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/m5-coach.yml)

## 功能目的與實際情境

Bridge Academy 的首頁新增「叫牌教練」入口，可以先選 NS/EW 的既有制度（也能檢視已釘選的 Precision 研究規格），選 dealer，輸入 `1NT P 2C` 後讓 App 告訴玩家這三口牌分別是誰叫的，相關制度型號是什麼，有什麼證據。

若玩家曾在 M4 建過本機 SAYC/2/1 草稿，可以勾選「對照本機南北方自訂草稿」。只有**明確勾選**才會讀本機已驗證 archive，而且只會把符合公開叫牌位置、**南北方**的自訂規則顯示為 `USER_DRAFT` 的作者意圖。即使兩邊都選 SAYC，也不可偷偷讓南北草稿覆蓋東西的解釋。沒有任何改寫 BEN/BBA 行為的 API。

## 主要程式碼導讀

```dart
final report = PublicAuctionCoach.review(
  dealer: _dealer,
  calls: calls,
  systems: GameSystems(northSouth: _ns, eastWest: _ew),
  draft: draft,
  draftNorthSouth: draft == null ? null : true,
);
```

Flutter 只控制公開文字、operator-known `ConventionCatalog` profile 和本機草稿檢視；Domain 產生的 `CoachAuctionEntry` 包含座位與證據，不會回傳「最佳出價」。畫面根據 `CoachMeaningEvidence.userDraftOnly / baseNotReviewed / unknown` 顯示雙語狀態、制度 id/fingerprint。讀取本機草稿異常時顯示安全錯誤，不洩漏原生例外或自動覆蓋。

## 為什麼這樣設計

類似 Compose / Kotlin 單向資料流：使用者觸發 `_explain()`，UI 收集極少公開欄位 → Domain 驗證 → 新 immutable report → Widget render。不能把 UI `CheckboxListTile` 當引擎授權；本機設定不會改 Gateway 的 server-owned GameSystems。

替代方式是直接在實際進行中的遊戲上提示最佳叫品，但目前 BEN/BBA 沒有提供完整、有憑據的比較候選，因此 UI 寧可顯示「無已驗證建議」。這也防止賽中對 AI 內部思考或隱藏手牌做不實陳述。

常見錯誤：同一叫牌模式 `1NT-P-2C` 不一定出現在同一組 partnership；忽略 dealer／NS-EW 會把別人的草稿套到錯誤方向。

## 驗證與實際證據

```bash
cd apps/bridge_academy_flutter
flutter pub get && flutter analyze --no-pub
flutter test test/m5_auction_coach_test.dart --reporter expanded
```

Widget tests 使用注入的 in-memory archive，檢查叫牌結果、繁中與英文、作者意圖明確警示、無最佳出價假建議、惡意輸入拒絕。**沒有直接串真 BEN，也沒有本機真 Android/iOS 裝置重啟驗收**；這是獨立可互動教學頁，不是競賽中建議功能。

## 練習與自我檢驗

**思考題：** 如果一副牌東西、南北都使用 SAYC，但只有南北在自己的草稿選「2♣ 是自然叫品」，為什麼教練不能把東西的 `2♣` 也顯示成南北的自訂意思？

**5–15 分鐘練習：** 在 `m5_auction_coach_test.dart` 的 in-memory store 寫入反向的已編輯 SAYC 卡，驗證不勾選本機草稿時只能得到 `UNKNOWN / baseNotReviewed`；勾選也永遠不會顯示「引擎已驗證」。

**完成標準：** 可解釋 server-known profile、Local Draft authorship、public auction 與 private-hand 隔離，並知道為什麼無實測最佳出價候選必須是空集合。

## 下一步

M5.3 才考慮真 BEN/BBA action-response evidence 和固定金標語義，不能讓未審核自訂卡或生成式 AI 對模型動機做錯誤保證。
