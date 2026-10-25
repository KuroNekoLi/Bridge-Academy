# M5-F01｜AI 教練的第一個原則：叫牌解釋一定要有證據

- Feature ID：M5-F01
- Milestone：M5.1 Public Auction Evidence Coach
- 類型：純 Dart、可信賴教學資料、公開資訊／AI 推理分離
- 工程狀態：SCOPED VERIFIED — [CI #40154923631](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40154923631) Domain 36/36 PASS、analyzer PASS
- 學習狀態：DELIVERED
- 原始碼：[auction_coach.dart](../../../packages/bridge_conventions/lib/src/auction_coach.dart) · [GameSystems](../../../packages/bridge_conventions/lib/src/game_systems.dart)
- 驗收與測試：[Domain tests](../../../packages/bridge_conventions/test/auction_coach_test.dart) · [M5 CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/m5-coach.yml)

## 功能目的與實際情境

玩家看見 N 開叫 1NT、E Pass、S 叫 2♣，希望 AI 解釋 2♣ 是什麼。但 SAYC、2/1 和 BBA Meckwell V1 有不同版本與約定例外，且目前沒有完整經過專家認證的自然／人工叫品 Golden corpus。不能只憑「2♣ 常常是 Stayman」就斷言這次 BEN 一定是這樣思考。

M5.1 先做**公開叫牌證據檢視器**：根據 dealer/連續公開 calls 推導 N/E/S/W 座位，使用受信任 `GameSystems` 分辨南北和東西的版本指紋。若沒有經審核規則，就顯示 `UNKNOWN` 或 `baseNotReviewed`，**不憑空產生「最佳叫品」或私有 AI reasoning**。

## 主要程式碼導讀

```dart
final report = PublicAuctionCoach.review(
  dealer: 'N',
  calls: ['1NT', 'P', '2C'],
  systems: GameSystems(
    northSouth: ConventionCatalog.sayc,
    eastWest: ConventionCatalog.twoOverOne,
  ),
);
assert(report.entries[2].seat == 'S');
assert(report.entries[2].isEngineVerified == false);
assert(report.verifiedCandidateCalls.isEmpty);
```

關鍵資料流是：已知公開 dealer/calls → 限長並檢查 token → 依時間順序輪轉座位 → 對照 immutable `GameSystems.forPartnership` → 每次叫品記錄 `profileFingerprint` 和可解釋來源狀態。模組完全不 import Bridge Core `Deal`、不存 hand/PBN，不接受 `GameState` 的完整內部資訊。

## 為什麼這樣設計

這類型就像 Kotlin backend 的 DTO + sealed evidence status：有來源的資訊才可以往 UI 顯示成已知事實。AI `/bid` 提出 `1NT` 可以證明「它叫了 1NT」，卻不能單靠結果反推出模型內部的全部動機。

另一路線是直接用 LLM 自由生成「為什麼 AI 選這口牌」，內容會自然流暢但容易將推論描述成真實模型內部意圖。現階段保留 `UNKNOWN` 更安全，也可為將來 real-BEN bid diagnostics 增加真正的來源層。

常見錯誤：認為對局系統 `BA-SAYC` 且出牌合法，等於每一口 Stayman/transfer 都被正式專家認證；這兩者驗證標準不同。

## 驗證與實際證據

```bash
cd packages/bridge_conventions
dart pub get && dart analyze --fatal-infos
dart test test/auction_coach_test.dart --reporter expanded
```

測試案例包含 dealer=E 的座位輪轉、SAYC/2/1 兩組不同 fingerprint、1N→1NT canonicalization、X/XX 仍 `UNKNOWN`、65 calls、隱藏手牌文字、非法 dealer 拒絕，以及沒有候選最佳叫品證據。這是**固定假叫牌**的 Domain 測試，非實際 BEN 決策品質測試。CI 具體成功連結請見 [M5 workflow](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/m5-coach.yml) 最新成功執行。

## 練習與自我檢驗

**思考題：** 當 BEN 的 `/bid` 回傳合法的 `2C`，為什麼教練目前只能表示「確實叫了 2♣」，而不能直接說「BEN 因四張高花所以使用 Stayman」？

**5–15 分鐘練習：** 在 `auction_coach_test.dart` 增加 `dealer='W'`、四次 Pass 的測試，確認 W/N/E/S attribution，教練仍不會憑空說明當事人牌型。

**完成標準：** 能區分出價觀測、玩家約定、專家解釋及模型內部決策證據四個不同層次。

## 下一步

M5.2 在 Flutter 提供公開叫牌輸入、兩組制度指定與自訂草稿比對；後續 M5.3 再接真 BEN/BBA provenance、受評估候選叫品與賽後制度差異。
