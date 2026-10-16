# M2-F49｜真正 BEN 的多副牌回歸測試

- Feature ID：M2-F49
- Milestone：M2／A6
- 類型：後端／AI 整合／測試工程
- 工程狀態：IMPLEMENTED（真 BEN CI 待確認）
- 學習狀態：DELIVERED（尚未代表已熟練）
- 原始碼：`services/bridge_gateway/lib/src/a6_board_fixtures.dart`、`services/bridge_gateway/lib/src/authoritative_game.dart`、`services/bridge_gateway/lib/src/gateway_service.dart`、`services/bridge_gateway/bin/live_gateway_ben_multiboard.dart`
- 驗收與測試：`services/bridge_gateway/test/a6_board_fixtures_test.dart`、`.github/workflows/ben-a6-multiboard.yml`、`docs/product/A6_REAL_BEN_MULTIBOARD_ACCEPTANCE.md`；[CI（狀態待檢查）](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38918776609)

## 功能目的與實際情境
先前單副真 BEN Chrome／Gateway 完整對局成功，仍無法證明不同 Dealer、Vulnerability 及手牌組合可反覆完成整副牌。A6 用四組「伺服器自有固定測試牌」驅動真 BEN，並讓 Core 檢查 52 張與 Duplicate 分數。這是 QA 基礎能力，**不等於玩家新增功能或上線許可**。

## 主要程式碼導讀
`BridgeGatewayService` 的 `trainingBoard` 是只有本機 server 建構者才能注入的可選值，普通 HTTP 請求沒有 `board`、`Deal` 或 `seat` 欄位。入口：
```dart
final gateway = BridgeGatewayService(
  backend: counted,
  dealFactory: () => fixture.deal,
  trainingBoard: fixture.metadata,
  config: const GatewayConfig(
    sessionTtl: Duration(hours: 2),
    decisionTimeout: Duration(minutes: 11),
    decisionLimit: 500,
  ),
);
```
其實際流程是：
`Fixture` → `Trusted Gateway Constructor` → `AuthoritativeGame` → `SinglePlayerCoordinator` → `PlayerView` → `/v1/games/action | advance` → `BenLoopbackBackend` → pinned genuine BEN → Core Reducer → score + security assertions。

第一個主體是 *玩家能看見什麼*（PlayerView），第二個是 *伺服器真正持有哪些牌*（Deal）。Android Clean Architecture 類比：`Deal` 是受保護的 Repository data，`PlayerView` 是受限的 UI State DTO；把全部四家牌塞進 UI 或 model API 相當於提前解密別人的敏感資料。

## 為什麼這樣設計
直接重用 `live_gateway_ben_full_game.dart` 與 Bridge Core 校驗，而不是在測試中製造 52 次 fake BEN Response；測試自己算牌墩仍有重複邏輯錯誤的風險，因此最終又用獨立的 `DuplicateScore.score` 做可重現交叉檢查。替代方案是直接 HTTP 單獨打 `/bid`、`/play`，但不包含 Gateway session、stale/idempotency 和合法動作整合的真實失敗模式。

常見錯誤：四副跑完總共 52 張不表示每副 52 張唯一；必須逐副驗證版本 `auction + 52`、每墩四人與完整 13 墩。另一個錯誤是用隨機牌測試而沒保存原始 PBN，日後 CI 失敗就無法重現。

## 驗證與實際證據
`cd services/bridge_gateway && dart test test/a6_board_fixtures_test.dart` 驗證 PBN、四手／座位、不同 BoardDefinition；`dart run bin/live_gateway_ben_multiboard.dart` 僅在真 BEN loopback 已啟動時才真正測試模型。
**尚未取得同一最新 SHA 的工作流程成功結果，標記 RUNNING／NOT VERIFIED，不能假稱四副牌已成功。** 證據見 [A6 CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38918776609)。

## 練習與自我檢驗
**思考題（1 題）：** 為什麼讓 HTTP 客戶端自己上傳一份 `Deal` 供 AI 測試，即使 Core 可以驗證跟牌規則，也不符合 Bridge Academy 的公平性和隱私設計？

**5–15 分鐘小練習（可選）：** 在 `a6_board_fixtures_test.dart` 補一個改動某一張牌後造成牌重複、`Deal.fromPbn` 必須拒絕的斷言。

**完成標準：** 能指出 server-owned Deal、PlayerView、BEN private hand 與公開 API 的四個責任邊界，並能說明為何 CI 成功不代表已經能正式部署。

## 下一步
A6 真模型四副牌穩定後，再擴增不同牌墩與加倍／再加倍情境、benchmark 多次分布、成本上限及 A4.5 正式部署，保持玩家玩法開發不被超長 BEN 測試阻塞。
