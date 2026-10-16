# M2-F30｜A4.3.3：真正 BEN 經過 Gateway 完成 13 墩

- Feature ID：M2-F30
- Milestone：A4.3.3
- 類型：Dart／HTTP Gateway／Python 真實 AI／端對端驗收
- 工程狀態：SCOPED ENGINEERING VERIFIED（真正 BEN Gateway 完成 13 墩；非 PRODUCTION READY）
- 學習狀態：DELIVERED（未表示已練習或掌握）
- 原始碼：`services/bridge_gateway/bin/live_gateway_ben_full_game.dart`
- 驗收與測試：`docs/product/A4_GATEWAY_A4_3_3_ACCEPTANCE.md`、`.github/workflows/ben-gateway-real.yml`

## 功能目的與實際情境

先前我們已有兩種工程證據：Bridge Core 搭配 BEN 原生 HTTP 完成過 52 張牌／13 墩；而 Gateway 透過真的 BEN 成功提出過叫牌、首攻、出牌各一個建議。但**兩種證據無法自動合併**，因為 Gateway 有匿名 Session、私有發牌、Bearer 驗證、`expected_version`、`request_id` 和過濾後的 `PlayerView`，任何一層都有可能出錯。

因此新增一個真實網路測試：使用確定可重現的固定牌例，完整經過 Gateway 的遊戲路由，直到 Bridge Core 統計 13 墩並完成計分。**這不是 AI 聰明程度測試，而是整條系統真的串接成功的驗收。**

## 主要程式碼導讀

流程是由測試端啟動本機 Gateway、登入匿名 Session，先查自己的 `games/view`，每步只回送版本和自己的叫牌／出牌決定。輪到 BEN 時只發 `games/advance`，由伺服器上的 `SinglePlayerCoordinator` 與 `BenBotPolicy` 自行決定可以讓哪個 AI 看哪家手牌。

```dart
if (state['canAct'] == true) {
  // Browser-style human: legal card from filtered own view.
  result = await _post(port, '/v1/games/action', payload, token: bearer);
} else {
  // Server chooses BEN bot seat and filters its private PlayerView.
  result = await _post(
      port, '/v1/games/advance', _request(version, id), token: bearer);
}
```

`_verifyFinal` 檢查 `phase == finished`、合約與計分存在、所有牌手剩餘牌數都為零、每一墩四家手牌各一張、52 張牌不重複，且 `version == auctionCount + 52`。`_MeasuredRealBen` 只紀錄各路由呼叫次數、總耗時及 p95，不印原始 Query 或手牌。

## 為什麼這樣設計

如果只 Mock BEN 回傳固定 `PASS` 或固定 `card`，能驗證 API 欄位卻不能驗證真正模型理解 `ctx`、`dummy`、`played`；反過來，直接呼叫 BEN `/play` 雖然可以測模型，也繞過了 Gateway 的 Session 與權威事件版本檢查。這個測試把兩邊整合起來。

對 Android/Kotlin 工程師，可以類比：Repository/Retrofit Unit Test 與真正 Backend E2E Test 是兩種不同證據；CI 需要區分兩者的真實依賴、風險和耗時。模型決策可能很慢，因此這個真 BEN Workflow 獨立於快速的 Flutter、Dart Gateway 單元測試，避免每次小修改都重新載入大量權重。

## 驗證與實際證據

```bash
# 真正 PINNED BEN Python gameapi.py 必須先在 127.0.0.1:8085 啟動。
cd services/bridge_gateway
dart pub get
dart analyze --fatal-infos
dart run bin/live_gateway_ben_full_game.dart
```

CI 會檢查 BEN Python 的確啟動，先跑 A4.3.1 真 BEN Smoke，再跑這個完整 52 張牌測試。[True BEN Gateway Full Game CI #38845244764](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38845244764) 在 [`c41cbf5`](https://github.com/KuroNekoLi/Bridge-Academy/commit/c41cbf5fdf7cd27af142c6a5b6f6d07ef1466f56) **PASS**！使用真 pinned BEN SHA `72653ec1`、Python 3.12；最後 **6NT、North 莊、南北 -250、13 墩、52 張不重複、auction=6、version=58**，總共呼叫真 BEN `bid:4`、`lead:1`、`play:25`（30 次），BEN 呼叫 p95 996 ms、最慢 2129 ms，整局約 10.7 秒。這些只是單一固定 CI 牌例、降低抽樣量的資源數字，不能當正式產品效能 SLO。[Gateway 靜態分析與 Unit HTTP CI #38845244822](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38845244822) 32/32 PASS，[Feature Learning Gate #38845244725](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38845244725) PASS。這一副固定牌驗收無法代表所有隨機牌局，也無法證明公開的 HTTPS、生產環境限流、抗濫用、模型授權成本、跨 OS 或裝置 UX 全部沒問題。

## 練習與自我檢驗

**思考題（1 題）：** 為什麼「真 BEN /play 單次回傳一張合法牌」不等於「整副 52 張牌、13 墩與最後計分都通過」？

**5–15 分鐘小練習：** 在 `_verifyFinal` 中找出 `terminalVersion == auctionCount + 52` 與「全部 52 張牌不能重複」兩項驗證，解釋它們各自抓得到什麼錯誤、抓不到什麼。

**完成標準：** 能解釋 Domain Core、Gateway、BEN 真模型、Browser 端 API、最後回歸驗收各自的信任邊界，並能區分 Mock／Smoke／Full-game／Production-release 的差異。

## 下一步

已完成單副牌固定 CI 驗收，並記錄 BEN 版本、Python 環境、完整 13 墩與三條路由計數。下一步應加入多副不同發牌者／局況／王牌／Pass Out／Double 回歸，避免只依賴固定 6NT 牌例。A4.4 才實作 Flutter 接到 Gateway 的持續遊戲流程；A4.5 才進行正式 HTTPS 與授權／記憶體／成本驗收。A3.5 和 Android／iOS 模擬器、實機測試持續依使用者決策延後。
