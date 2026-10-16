# M2-F39｜B1：四副牌練習賽與場次總結

- Feature ID：M2-F39
- Milestone：B1 四副牌練習賽（第一個可操作切片）
- 類型：Flutter 玩家功能、Bridge Core 場次協調、加密存檔
- 工程狀態：SCOPED ENGINEERING VERIFIED（Flutter 109/109、Web Build、Chrome Demo PASS）
- 學習狀態：DELIVERED（非 PRACTICED／MASTERED）
- 程式：`apps/bridge_academy_flutter/lib/src/four_board_practice.dart`、`bridge_session.dart`、`bridge_app.dart`
- 驗收與測試：`apps/bridge_academy_flutter/test/b1_four_board_practice_test.dart`，CI 執行後再補證據；[B1 驗收](../../product/B1_FOUR_BOARD_PRACTICE_ACCEPTANCE.md)

## 功能目的與實際情境

玩家完成一副牌後，往往還想練一組牌而不是一直手動設定。B1 在既有單人牌桌上新增「開始四副牌練習賽」；每完成一副，列出定約、得分與進度，讓玩家按「進入下一副練習牌」。四副完成後，在牌桌看見結算，也可到先前的歷史牌局逐副複盤。固定使用新隨機 52 張牌、板號連續遞增，以 Bridge Core 正式計分；不可混為線上 Duplicate 比賽或 MP／IMP 排名。

## 主要程式碼導讀

`FourBoardPractice` 是四副練習的 value object。僅包含起始牌號、玩家座位與「已完成的 boardNumber、唯一 attemptId、定約、NS 得分」，不包含任何暗牌或 PBN。

```dart
int get completed => results.length;
bool get isComplete => completed == 4;
int get nextBoardNumber => startBoard + completed;
int get humanNetScore => results.fold(0, (sum, result) =>
    sum + (humanSeat.isNS ? result.nsScore : -result.nsScore));
```

`BridgeSession.startFourBoardPractice` 建立四副練習並使用 `BoardDefinition.forNumber` 選出正確發牌者／局況，仍交由既有 `SinglePlayerCoordinator` 執行每次 `submitCall`／`submitCard`。只有合法完成牌局且被分配 `_historyId` 後，`_recordFourBoardFinish` 才加入一筆結果，並再次寫入既有加密 Checkpoint。此紀錄在 `restoreSavedGame` 恢復，避免應用程式重新啟動後，玩家已完成的板次消失或計分兩次。

`BridgeTable` 則增加可見的開始／下一副按鈕、四副逐局分數列表、總分與完成訊息。使用者介面文案全部透過 `AppCopy` 提供 zh-TW/en，不製造新的 API 或傳送牌局給 BEN。

## 為什麼這樣設計

對 Kotlin／Android 開發者而言，`FourBoardPractice` 類似不可變 `data class`，`BridgeSession` 類似 ViewModel，`BridgeTable` 類似 Compose 畫面觀察 StateFlow。這裡選擇「單一加密 Checkpoint 同步儲存場次摘要」，而不是額外開一個沒有交易關聯的 SharedPreferences 計分 key，因為在牌局結束時可能被 OS 中斷；兩個分離 key 容易造成已經結算但進度還沒增加的混亂。

可替代方案是從最近 12 筆歷史即時計算四副成績，但 A5 歷史可刪除／匯入／有限保留，不能作為權威場次進度。因此 B1 另存場次摘要；每副仍獨立歸檔，玩家可以自行複盤。

**注意：** 四份不同局況的 NS Duplicate 得分直接相加只是私人練習數字，**沒有相同牌組的比較基準就不是 MP／IMP**。

## 驗證與實際證據

```bash
cd apps/bridge_academy_flutter
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build web --release
```

新增的 `b1_four_board_practice_test.dart` 對四家 Pass Out 模擬 Bot 進行四副連續的合法 Bridge Core 事件，檢查板次 1～4、重送不會重複計入、加密存檔模型復原、禁止中途跳板與 zh-TW/en 畫面。**[Flutter CI #38880212042](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38880212042) SUCCESS**：`flutter analyze --no-pub` 無問題、`flutter test --no-pub --reporter expanded` **109/109 PASS**（原 105 項＋B1 四項）、`flutter build web --release` 成功，Chrome Demo 回歸成功。首輪 [#38879969927](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38879969927) 遇到 `curly_braces_in_flow_control_structures` lint，隨後在 [56162ba](https://github.com/KuroNekoLi/Bridge-Academy/commit/56162ba7d5d727ceca2aadc6b8eb84e73a1e2e92) 修復；lint-only commit 當次 Learning Gate 失敗，改由本次驗收文件＋教學索引一同提交重新通過。真 BEN 四副連打、裝置 QA、多人或公開部署還沒有驗證。 真 BEN 四副連打、裝置 QA、多人或公開部署也還沒有驗證。

## 練習與自我檢驗

**思考題：** 為什麼玩家坐 East/West 時，場次摘要要把 Bridge Core 儲存的 NS Score 取負號？即使算出四副加總，為什麼還不能叫它 IMP？

**5–15 分鐘小練習：** 在 `b1_four_board_practice_test.dart` 修改起始牌號為 15，檢查第 15～18 副是否依 WBF 的 16 板局況／發牌順序循環，而不修改 Core 規則。

**完成標準：** 能描述 Bridge Core 單副合法性、B1 Value Object 場次聚合、使用者視角得分，並指出哪個跨重啟狀態由 Checkpoint 保存。

## 下一步

B1 的本機四副練習完成後，再做 B2 Just Declare；A4.5 正式服務、A3.5 UI release gate 與 Android／iOS 裝置測試仍在原定阻擋／延期狀態。
