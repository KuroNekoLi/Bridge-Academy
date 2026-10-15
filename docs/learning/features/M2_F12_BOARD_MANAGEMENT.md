# M2-F12｜Phase A1：牌號、發牌者、局況與正確的下一副牌

- Feature ID：M2-F12
- Milestone：Phase A1 / P1.1
- 類型：Bridge Core Domain + Flutter UI + BEN 協議
- 工程狀態：IMPLEMENTED（正式 CI 尚待執行）
- 學習狀態：DELIVERED
- 原始碼：packages/bridge_core/lib/src/board_definition.dart；apps/bridge_academy_flutter/lib/src/bridge_session.dart；apps/bridge_academy_flutter/lib/src/bridge_app.dart
- 驗收與測試：packages/bridge_core/test/board_definition_test.dart；apps/bridge_academy_flutter/test/board_management_test.dart；packages/bridge_ben_adapter/test/board_metadata_wire_test.dart；docs/product/P1_A1_BOARD_MANAGEMENT_ACCEPTANCE.md

## 功能目的與實際情境

玩家在一副牌結束後按「下一副牌」，應由第 1 副進入第 2 副：第 1 副北家發牌、雙方無局；第 2 副東家發牌、南北有局。局況會實際影響計分，不能只修改畫面文字。當玩家按「重打同一副牌」時，則要重用完全相同的 52 張牌和原本的發牌者、局況，不能暗中重新洗牌。

這次採用世界橋牌總會 2017 Duplicate Bridge Laws, Law 2 標準 16 副循環；不是由 AI 隨機選擇局況。來源：https://www.worldbridge.org/wp-content/uploads/2017/03/2017LawsofDuplicateBridge-paginated.pdf

## 主要程式碼導讀

`BoardDefinition.forNumber(number)` 只負責牌號所對應的 immutable metadata：

```dart
factory BoardDefinition.forNumber(int number) {
  if (number < 1) {
    throw RangeError.value(number, 'number', 'Board numbers start at 1');
  }
  return BoardDefinition._(
    number: number,
    dealer: Seat.values[(number - 1) % Seat.values.length],
    vulnerability: _vulnerabilityCycle[(number - 1) % 16],
  );
}
```

牌號從 1 起算，因此必須先 `number - 1` 才能對應零起算陣列。Flutter 的 BridgeSession 在開局時將 `board.dealer`、`board.vulnerability` 實際傳入 `SinglePlayerCoordinator`；後者再交給 Bridge Core，透過 PlayerView 讓 UI 與 BEN 讀取正確值。

`replaySameBoard()` 沿用 `_activeDeal` 與 `_board`，不重新抽牌；`nextBoard()` 只在這副牌完成後才能開下一個 BoardDefinition，並清空前一副的回放 UI。此功能和「直接重新發牌」是不同操作。

## 為什麼這樣設計

這是 **Domain Single Source of Truth**：規則定義在純 Dart Core，Flutter 不另造一張表，BEN 也不自己猜局況。就像 Android 專案將商業規則置於 Kotlin domain/use case，ViewModel 只消費結果，Compose 或 Activity 不應重新計算。

合理替代方案是把 dealer／vulnerability 直接放在 Flutter Widget 裡計算；這樣最快，但 Domain、UI、BEN 可能在第 17 副之後顯示不同值，且單元測試難獨立驗證。

常見錯誤：使用 `board % 16` 會讓 Board 1 指向第 2 組索引；以及「重打」若調用隨機發牌，玩家其實會拿到另一副牌，即使牌號沒變。

## 驗證與實際證據

```bash
cd packages/bridge_core && dart pub get && dart analyze --fatal-infos && dart test --reporter expanded
cd ../bridge_ben_adapter && dart pub get && dart analyze --fatal-infos && dart test --reporter expanded
cd ../../apps/bridge_academy_flutter && flutter pub get && flutter analyze && flutter test
```

實際斷言：Board 1–32 的發牌者與局況、Board 17 週期、非法 0/負牌號、3NT NS 計分敏感度、BEN 傳輸的 `dealer/vul`、不同玩家座位與隱藏手牌、完成 Pass Out 後下一副、完全相同 PBN 的重打與中英翻譯。

**初稿撰寫時 CI NOT RUN。** 最新實際 CI URL／SHA／結果必須寫回驗收文件，不能把舊版 47/47 Core 或固定 BEN Chrome 成功當成本次新增測試證據。真 BEN 變動牌號與實體裝置矩陣仍另行驗收。

## 練習與自我檢驗

**思考題：** 為什麼 Board 17 的 Dealer／Vulnerability 應與 Board 1 相同，卻不能因此把 Board 17 的牌直接視為 Board 1 的同一副牌？

**5–15 分鐘小練習：** 在 `board_definition_test.dart` 加入 Board 33 應與 Board 1 有相同 Dealer／Vulnerability 的斷言，再驗證 `BoardDefinition.forNumber(33).number == 33`。

**完成標準：** 說出牌號、發牌者與局況是獨立於實際 Deal 內容的 metadata，並能解釋 Domain/UI/AI 如何共享同一個 BoardDefinition。

## 下一步

Phase A2 將透過 versioned event transcript 實作中斷恢復；目前回放仍是單一開局記憶體，不代表可以在 App 被關閉後還原。
