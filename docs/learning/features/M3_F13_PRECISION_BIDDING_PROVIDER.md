# M3-F13｜M3.3：用 Strategy Pattern 整合獨立的 Precision 叫牌 Provider

- Feature ID：M3-F13
- Milestone：M3.3 BBA Meckwell Precision Provider
- 類型：Dart BotPolicy、AI 策略隔離、PlayerView／不可信 AI Proposal
- 工程狀態：**SCOPED VERIFIED**（Adapter 單元與真 native 短路徑，不是整局 Gameplay）
- 學習狀態：**DELIVERED**
- 原始碼：[Precision provider](../../../packages/bridge_precision_adapter/lib/src/precision_bidding_provider.dart) · [Transport](../../../packages/bridge_precision_adapter/lib/src/bba_precision_loopback_transport.dart)
- 驗收與測試：[Provider unit tests](../../../packages/bridge_precision_adapter/test/precision_bidding_provider_test.dart) · [Native live test](../../../packages/bridge_precision_adapter/test/native_precision_live_test.dart) · [CI #40095274359](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40095274359)

## 功能目的與實際情境

你希望 Bridge Academy 不只可以用 BEN 的 2/1/SAYC 神經模型，也能讓 BBA 的強梅花 Precision 參與打牌。問題是 BEN 並沒有可用的 Precision neural model，所以不能只將 `ourSystem` 換成 `PRECISION`。正確方式是讓不同 AI 都遵守同一個遊戲邊界：**提出 CallAction 建議，絕對不自行修改 GameState**。

這一輪建立 `BbaPrecisionBiddingProvider`，給它受控的 `PlayerView` 和固定的 `precisionSideIsNS`、`opponentModel`。它只支援輪到 Precision 玩家叫牌的 auction phase；其他座位或出牌階段直接拒絕，沒有「先用舊 BEN 猜一張」的 fallback。

## 主要程式碼導讀

實際程式的核心：

```dart
final policy = BbaPrecisionBiddingProvider(
  transport: nativeTransport,
  precisionSideIsNS: true,
  opponentModel: 'SAYC',
);
final action = await policy.choose(filteredNorthPlayerView);
// 提案交給 BridgeGame.apply(authoritativeState, action) 再驗證合法性。
```

真正的 `choose()` 只序列化 `PlayerView.viewer` 的 13 張私有手牌、public auction、dealer、vulnerability 與目前 actor，不接受完整 Deal、其他手牌或 DDS 看到的四家資訊。傳送固定 `BA-PRECISION-MECKWELL/r1`、Meckwell.bbsa SHA，並核對 native response 是否與相同版本一致。

資料流：可信任 Coordinator → PlayerView.forSeat → BbaPrecisionBiddingProvider → PrecisionBidTransport → 原生 BBA response → 版本/格式檢查 → CallAction → Bridge Core Reducer。

## 為什麼這樣設計

對你熟悉的 Kotlin 可以類比：

```kotlin
interface BotPolicy { suspend fun choose(view: PlayerView): GameAction }
class PrecisionBiddingProvider(
    private val transport: PrecisionBidTransport,
    private val isNS: Boolean,
) : BotPolicy { /* only propose, never mutate GameState */ }
```

這是 **Strategy + Adapter**。現有 `BenBotPolicy` 不需要假裝懂得另一個 AI 的全部能力；未來可以增加 native BBA、規則引擎或新版模型而不動純 Bridge Core。

**替代設計**是把 EPBot .so 直接載入 Dart Gateway 或混入既有 BEN `/bid`；這會造成原生 ABI、授權版本、AI 所知資訊與錯誤處理彼此混在一起，而且 BEN 現在沒有 Precision 對手 reader，所以不採用。

**常見錯誤**：把合法叫品視為符合搭檔制度。Bridge Core 只看有沒有越級、是否輪到誰，不能證明 1♣ 必定具有強梅花的約定意義。人工強梅花的語義仍需 goldens 和專家簽核。

## 驗證與實際證據

```bash
cd packages/bridge_precision_adapter
dart pub get
dart analyze --fatal-infos
dart test --reporter expanded
```

[CI #40095274359](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40095274359) 已完成：Dart analyze `No issues found`、Provider/Transport + Native optional test 合計 **7/7** 通過。在同一工作流程啟用真 EPBot 後，另以 `PRECISION_NATIVE_ORIGIN` 執行 Dart `PlayerView → private POST → native bid → BridgeGame.apply`，**1/1 PASS**。

此結果不涵蓋真的 NS/EW 兩組 BEN 神經／BBA 交替出價，因 BEN 的 `systems.conf` 沒有 Precision 對手 interpretation network。這是 M3.4 要實際解決的問題。

## 練習與自我檢驗

**思考題（1 題）：** 既然 Precision 的 `choose()` 已經回傳合法的 `1C`，為什麼仍必須讓 `BridgeGame.apply` 再驗證，不能直接更新場上的叫牌紀錄？

**5–15 分鐘小練習（可選）：** 在 `precision_bidding_provider_test.dart` 加一個測試，把 `precisionSideIsNS` 設成 false 卻提供 North 的 PlayerView，應得到 `not_precision_auction_turn` 且 transport 完全沒有收到請求。

**完成標準：** 能說出策略可替換、PlayerView 隱藏資訊，以及 Domain Core 法規權威各處理什麼風險。

## 下一步

M3.4 先決定 mixed engine 對 Precision 敵方叫牌的解釋方式，並以完整對局、checkpoint/version/卡牌合法性驗收後，才可把這套 V1 加入 Gateway/Flutter 玩家選項。
