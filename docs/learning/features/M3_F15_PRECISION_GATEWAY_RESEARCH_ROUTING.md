# M3-F15｜M3.4 原生 BBA 混合制度的 Gateway 實驗路由

- Feature ID：M3-F15
- Milestone：M3.4
- 類型：安全 Gateway／BotPolicy、不可變版本、Flutter opt-in
- 工程狀態：**SCOPED VERIFIED**；非正式競賽 AI
- 學習狀態：**DELIVERED**
- 原始碼：[BbaResearchTablePolicy](../../../packages/bridge_precision_adapter/lib/src/bba_research_table_policy.dart) · [Gateway](../../../services/bridge_gateway/lib/src/gateway_service.dart) · [Sidecar](../../../scripts/precision_m33_sidecar.py)
- 驗收與測試：[Gateway tests](../../../services/bridge_gateway/test/m34_precision_research_gateway_test.dart) · [真實整局](../../../services/bridge_gateway/bin/live_precision_research_full_game.dart) · [CI #40102968596](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40102968596)

## 功能目的與實際情境

當 NS 選 Precision、EW 選 SAYC 時，兩邊對同一句 `1♣` 的理解必須不同。BEN 的正式 NN 沒有 Precision 對手 reader，因此不能讓 BEN 假裝能讀懂 Precision。本輪使用同一 native BBA 引擎及不同的兩張 CC，為 NS/EW 各自解讀出價，技術性驗證完整 Gateway 牌局。

## 主要程式碼導讀

`ConventionCatalog.precisionMeckwell` 記錄不可變版本與來源 SHA，**不列於正式 candidateProfiles**。`BridgeGatewayService` 預設 `enablePrecisionResearch=false`；只有顯式啟用且 `researchReady()` 回真，才用 `BbaResearchTablePolicy`。Policy 只從 `PlayerView` 組 `dealer/seat/ctx/vul/hand`，Native sidecar 綁定 NS/EW 的 CC 並輸出純叫牌 proposal，最後還是 Bridge Core 檢查合法性。研究出牌是合法優先而非競賽強度。

```text
Flutter research opt-in → Gateway allowlist & capability
 → PlayerView → BbaResearchTablePolicy → POST /v1/precision/table-bid
 → Native BBA (雙方約定卡) → proposed CallAction → Bridge Core
 → 研究用合法出牌 → 52 cards/13 tricks/score
```

## 為什麼這樣設計

就像 Kotlin sealed strategy，`BotPolicy` 可以有 BEN 與 BBA 兩種實作，但同一局的 `GameSystems` 不可被畫面暫時選單覆蓋。考慮過讓 BEN `theirSystem=PRECISION`，但此版 models 沒有 corresponding reader，會錯誤解牌；所以暫用原生 BBA 的兩邊約定卡與明確研究 UI 提示，而不是錯誤 fallback。

常見錯誤：把技術上合法出牌等同會依對手約定防守。這次的 `DeterministicTrainingBot` 只用於檢查完整 52 張合法牌、絕非真 BEN cardplay 品質。

## 驗證與實際證據

`cd services/bridge_gateway && dart pub get && dart analyze --fatal-infos && dart test --reporter expanded`，隔離 CI 47/47 PASS；另 `dart run bin/live_precision_research_full_game.dart` 在 [最新 CI #40103865733](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40103865733) 運行 Precision/SAYC 與 Precision/21GF 各自互換 NS/EW 共四局，每局 13 墩、52 unique cards、NS -100，且 repeated request_id 冪等；研究版 Flutter Widget 與版本核對亦通過。證據：[CI #40102968596](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40102968596)。

Flutter 常規版本完全不顯示 Precision。需要 `--dart-define=BA_M34_RESEARCH_PRECISION=true`，而 Gateway 也需要 `M34_RESEARCH_ENABLED=true` 加上 local sidecar origin 才能建立這種研究局；未跑完公開服務 TLS、專家 Goldens 或 VPS QA。

## 練習與自我檢驗

**思考題（1 題）：** 為什麼不可以把研究版雙方原生 BBA 的「叫牌通過」直接說成 BEN 已學會 Precision？
**5–15 分鐘小練習（可選）：** 在 Gateway HTTP 測試把 Sidecar `ready` 設 false，確認開局返回 503 且未建立 Session。
**完成標準：** 理解 Request-scoped Convention Engine 與 Bridge Core 合法性、Release Gate 的三個差異。

## 下一步

M3.5 量測原生叫牌與記錄穩定性，另排 100+ 專家案例、真正雙方 AI 出牌與 2vCPU／4GB VPS 延遲驗收。 
