# M2-F02｜SinglePlayerCoordinator：人類與 Bot 的權威回合

- Feature ID：M2-F02
- Milestone：M2
- 類型：Game Coordinator / 非同步流程
- 工程狀態：IMPLEMENTED，正式驗收以 PR CI 為準
- 學習狀態：DELIVERED（尚未作答）
- 實作：packages/bridge_core/lib/src/single_player_coordinator.dart
- 測試：packages/bridge_core/test/single_player_coordinator_test.dart
- 測試證據：docs/m2/M2_FOUNDATION_REPORT.md（提交時 NOT RUN）

## 功能目的與實際情境

單機橋牌由一位 Human 和三位 Bot 輪流叫牌與出牌。玩家可能在舊畫面上重複點擊；Bot 可能提出違規叫牌或不符合跟牌規則的卡片。SinglePlayerCoordinator 保存真正的 GameState，只有 BridgeGame.apply 可作出合法狀態變更。

DeterministicTrainingBot 是**測試用策略**，先叫 1NT 後盡量 Pass，出牌選第一張合法卡。它不是真正 BEN，也不能代表橋牌強度。

## 主要程式碼導讀

入口 submitHuman(...) 與 runBots(...)，在 submitHuman 內：

~~~dart
if (expectedVersion != _state.version) {
  throw const RuleViolation('Stale action version');
}
if (_state.actorToPlay != humanSeat || action.actor != humanSeat) {
  throw const RuleViolation('Action is not controlled by human seat');
}
_state = BridgeGame.apply(_state, action);
~~~

expectedVersion 是 Optimistic Concurrency Control：只有在 UI 所看到的版本仍然有效時才能操作。Bot 走 runBots()，只獲得 PlayerView，產生 GameAction 後，同樣交給 Bridge Core 驗證。明手由 Declarer 代操作，Actor 與 Hand Owner 仍可不同。

Kotlin 類比：Coordinator 類似負責協調 Repository/UseCase 的 ViewModel 或應用層服務；GameState 是權威 Domain State。Dart Future 對應非同步計算，但不等同 Kotlin Coroutine 的取消或生命週期語意。

## 為什麼這樣設計

- 替代方案：Flutter Widget 直接修改狀態、完全相信 Bot 決策。這讓權威分散，很難防止不合法操作，也難回放查錯。
- 選擇方案：私有 _state、版本檢查、明確座位授權與同一個 BridgeGame.apply。Bot 不獲得四家完整手牌。
- 易犯錯誤：Bot 非同步執行中重複提交人類動作；Coordinator 會在 Bot 工作進行中拒絕操作。非法 Bot 提案也會被拒絕而不污染狀態。
- 限制：尚未串接 BEN、登入或多人房間；這是本機單人協調器，非真正完整產品的伺服器權威實作。

## 驗證與實際證據

~~~sh
cd packages/bridge_core
dart pub get
dart test test/single_player_coordinator_test.dart --reporter expanded
dart analyze
~~~

測試內容：Bot 停在 Human 回合；Human 操作版本防重複；Bot 首攻後明手公開；完成 13 墩；四 Pass Out；非法 Bot 行動不改變權威狀態；Human 無法替其他座位行動。

提交時這些測試尚未在本對話執行，真實 PASS/FAIL 請以 docs/m2/M2_FOUNDATION_REPORT.md 的 CI 證據為準。使用的 Bot 是 deterministic placeholder，與真 BEN POC 不可混稱。

## 練習與自我檢驗

思考題：畫面仍顯示版本 4，但 Coordinator 狀態已是版本 5，為何不能接受舊畫面再按下的卡片？沒有 expectedVersion 會發生什麼？

5–15 分鐘小練習：在 single_player_coordinator_test.dart 中加測試，用相同 expectedVersion 重複提交 Human action，預期第二次 RuleViolation 且 version 不增長。能說明「狀態權威／Action 提案／版本驗證」三種職責，即達本題的成功標準。

使用者尚未答題，學習狀態維持 DELIVERED。

## 下一步

M2 接下來需要真正 BEN Adapter 與 UI；BEN 的資料可見性、回傳格式與重試邏輯要分別驗收。

