# M2-F53｜從 App Shell 到第一個合法叫牌

- Feature ID：M2-F53
- Milestone：M2／UX-01
- 類型：Flutter UI／導航與會話生命週期
- 工程狀態：IMPLEMENTED（CI 待驗證）
- 學習狀態：DELIVERED（未要求使用者完成學習練習）
- 原始碼：`apps/bridge_academy_flutter/lib/src/experience/first_play_home.dart`、`bridge_app.dart`、`bridge_session.dart`
- 驗收與測試：`apps/bridge_academy_flutter/test/ux_01_first_play_test.dart`、`integration_test/browser_ux_01_first_play_test.dart`；NOT RUN locally

## 功能目的與實際情境
玩家想進入 Bridge Academy 練第一副牌，不應先理解不同 Bot 的網路與模型設定。UX-01 將首頁顯示為四個實際可用入口，點「快速開始」由原有 `BridgeSession.newGame` 建立 Demo 牌局，再交由原有 Bridge Core 驗證合法叫牌。再次返回首頁時，只要牌局未完成，就能返回同一副，而不是偷偷重洗牌。

## 主要程式碼導讀
`FirstPlayHome` 只讀取狀態旗標、localized copy 和 callback；不接觸 `Deal`、PBN、Bearer token。App Shell 做生命周期決策：
```dart
if (session.started && (!session.finished || seriesPending)) {
  _go(_UxPage.play); // Resume, never replace committed actions.
  return;
}
await session.newGame(
  humanSeat: Seat.north, mode: OpponentMode.demo,
  boardMode: BoardMode.training,
);
```
新首頁看起來只是幾個操作卡，核心卻是兩個安全界線：畫面導航不能重設 Game Session，以及 Gateway/BEN 失敗時不能偷偷改用 Demo。既有牌桌可沿用 Bridge Core 的所有已驗證規則。

## 為什麼這樣設計
Flutter 的 StatefulWidget Shell 相當於 Android Compose 的 Activity-level navigation host；Domain 的 `BridgeSession` 相當於保留狀態的 ViewModel，首頁只用狀態投影。比較另一方案「重做獨立 Quick Play Session」會複製牌局狀態、持久化與動作規則，容易有不同步的 Bug。常見錯誤是切換頁面時呼叫 `newGame()` 或把 Web Gateway 視為可以離線恢復的本機 Snapshot。

## 驗證與實際證據
```bash
cd apps/bridge_academy_flutter
flutter analyze
flutter test
flutter build web --release
```
目前 NOT RUN locally。另有瀏覽器 `browser_ux_01_first_play_test.dart` 可追蹤 Home → Demo → Pass，須等待真正 Chrome 結果才能改 VERIFIED。人工研究狀態：USER_STUDY_NOT_RUN。Android／iOS 裝置測試仍暫停。

## 練習與自我檢驗
**思考題（1 題）：** 如果玩家在 BEN 輪到出牌時點了「首頁」，為什麼返回牌桌時不能重新呼叫 `newGame()`？這跟 Android 的 Activity/Compose 狀態管理有什麼關係？

**5–15 分鐘小練習（可選）：** 在 `ux_01_first_play_test.dart` 補一個測試：持續打了一張合法牌後切換首頁，應保持相同 `PlayerView.version` 與原牌局。

**完成標準：** 能說明 View／Session 的權責、Demo 與 BEN 的可信度差別，以及 resume 不等於 new game。

## 下一步
完成 UX-02 的牌局結果與複盤導引，連成打牌→回顧的真正玩家路徑。
