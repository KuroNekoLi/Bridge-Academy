# M2-F28｜A4.3.2：Server-side Bridge Core 權威、事件版本與去重

- Feature ID：M2-F28
- Milestone：A4.3.2（第一切片）
- 類型：Dart Server／Bridge Core／授權與一致性
- 工程狀態：IMPLEMENTED（CI 待驗）
- 學習狀態：DELIVERED（不代表使用者已練習或精熟）
- 程式：[AuthoritativeGame](../../services/bridge_gateway/lib/src/authoritative_game.dart)
- 測試：[真 localhost HTTP Tests](../../services/bridge_gateway/test/authoritative_game_http_test.dart)
- 驗收：[A4.3.2 合約](../product/A4_GATEWAY_A4_3_2_ACCEPTANCE.md)

## 功能目的與實際情境

前一階段的匿名 Token 只能代表使用 API 的資格，卻無法證明玩家 North 的手牌究竟是什麼。惡意客戶端仍可能自行編造 `hand`，請 BEN 計算別人的牌。因此新 API 由**伺服器發牌**，並用 Bridge Core `SinglePlayerCoordinator` 掌管事件與輪次。客戶端只送「我選擇 1NT」及「我認為當前版本是 0」，不提供真正的四家牌。

## 核心程式導讀

`AuthoritativeGame` 保存一份在內存的 `SinglePlayerCoordinator`，由 Server 在匿名 Session 建立時產生。公開 API 只能讀取 `humanView.toJson()`，不能取得權威 `Deal`、GameState 或其他座位的 PlayerView。對出牌／叫牌事件，伺服器使用 Core 的 `submitHuman(... expectedVersion:)` 與 `BridgeGame.apply` 進行合法性驗證。

```dart
if (expectedVersion != coordinator.version) {
  throw GatewayFailure(409, 'stale_version');
}
// Core owns the actor and validates whether the action is actually legal.
coordinator.submitHuman(action, expectedVersion: expectedVersion);
```

玩家的重送事件使用 `request_id` 辨別：一樣的 ID／版本／payload 回傳同一個結果，不再多執行；一樣的 ID 但更換 payload，直接 409。另一個 Bot 操作 `/v1/games/advance` 完全不接收玩家手牌，僅由 Coordinator 產生 AI 座位可見的 `PlayerView`，經 `BenBotPolicy` 派給 Worker。

## 為什麼這樣設計？

這與 Kotlin 後端採用 Domain Aggregate + Optimistic Locking + Idempotency Key 的思路相同。如果只在 Flutter 做 `isButtonEnabled`，任何人都可以直接重播 HTTP 或改寫 Request；權限判斷必須在真正擁有牌局狀態的伺服器執行。

但目前的 ledger 只有記憶體、最多保存 128 筆，Token 15 分鐘到期就失效。**不能宣稱 Exactly Once／Crash-safe Replay**。正式服務仍需交易性 Event Store、Event Version Compare-And-Set、持久 request log，以及跨程序恢復。

## 驗證證據

```bash
cd services/bridge_gateway
dart pub get
dart analyze --fatal-infos
dart test --reporter expanded
```

本切片測試是**真實 localhost HTTP + 假 AI Bot**；驗證越權提交 Seat／Deal、另一 Session 隔離、過期版本、同 ID 重送、Bot 由權威 PlayerView 取得資料、Dummy 公開與失效的 AI 回傳 503。**CI 尚未執行，不可寫成通過**。真 BEN 叫牌／首攻／出牌的驗收另有 [真模型 CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38837641285)。

## 思考題

如果使用者按下「出牌」後，HTTP 在回應前斷線，但伺服器已經提交了事件，為什麼客戶端不能立刻換一個 `request_id` 再送一次？應該如何用 `expected_version` 與 Query Current View 避免重複事件？

## 5–15 分鐘練習

在 `authoritative_game_http_test.dart` 新增一項「同一 `request_id`、不同叫牌」測試，驗證新的 payload 被 409 拒絕且 `view.version` 不變。

**下一步：** A4.3.2b 持久化事件／去重、跨程序恢復與移除 production raw caller-hand API，之後再進行完整真 BEN 牌局和部署。A3.5／Android／iOS 裝置 QA 維持使用者指定的暫停。
