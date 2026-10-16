# A6 — 四副固定真 BEN 牌局、自動驗收與私牌保護

**Date**: 2026-10-16  
**Branch**: `test/a6-real-ben-multiboard`  
**Status**: IMPLEMENTED / REAL BEN CI RUNNING — **非正式產品 Release Gate**。

## 設計範圍與真實架構
本任務是測試／後端驗收，不新增玩家 UI。每副牌均由 *伺服器* 指定完整 `Deal.fromPbn` 與 `BoardDefinition.forNumber`；瀏覽器或 HTTP 玩家不能自行設定 Deal／莊家／局況。專有 `PlayerView` 只含 North 的 ownCards、公開資訊與規則允許後顯示的 dummyCards。Bridge Core 依原本 reducer 決定合法性及終局分數。

真正模型來源與版本：`lorserker/ben@72653ec1b5c17116faea229e9b975ea5622aa1f7`；啟動 `third_party_ben/src/gameapi.py` 並綁 `127.0.0.1:8085`，Gateway 使用 `BenLoopbackBackend`，**沒有 mock fallback**。既有 master BEN workflow 不改 pin、不改測試程序。

## 四個測試情境
| Fixture | WBF 板號 | Dealer | Vulnerability | 首次北家示範叫品 |
| --- | --- | --- | --- | --- |
| `A6-01-NT` | 1 | N | None | 3NT |
| `A6-02-S` | 2 | E | NS | 4S |
| `A6-03-H` | 3 | S | EW | 4H |
| `A6-04-C` | 4 | W | Both | 5C |

四副由同一個公共測試 PBN 的手牌順時針輪換組成，座位組合互異，原始牌都是四家各 13 張、52 張唯一。絕非隨機競賽或玩家可參與的公平排行榜，**測試的 3NT／4S／4H／5C 是強制規則回歸的訓練情境，不是 BEN 自主選出的莊家契約**；若北家第一次輪到叫牌前，其他座位已有更高叫品，會改用 7NT 避免違法叫牌。**並不保證最後的定約花色與示範叫品一致，真實結果以 Core 決定**。固定牌的 PBN 完整內容只留在 Server fixture 原始碼，CI 只公開 SHA-256、ID、回合和 aggregate counts，不列印完整四家手牌／token／BEN URL。

## 核心測試條件
- **真的 model**：每副必須由實際 BEN 決策經 loopback Gateway 產生，非 Pass Out 必須 13 墩、52 張唯一、每墩四個不同的 Seat、Core Event version == auction calls + 52。
- **Double Dummy 以外的正確性**：用公開終局 `Contract`、勝墩數與 `Vulnerability` 重算 `DuplicateScore.score`，須和 Gateway 的 NS Score 一致；不假設 BEN 在資訊不足時最優。
- **Pass Out**：若真的出現，檢驗 *四個* Chronological PASS、0 墩、0 分；此輪要達成四副完整 13 墩，所以 Pass Out 會使整批 A6 acceptance FAIL，而不是算成 13 墩 PASS。
- **安全負例**：無 token 401，HTTP 客戶端私自加入 Deal 400 且 Event version 保持不變；合法 requestId 重送回相同完整快照、重送後事件版本不變；改 requestId 重送舊版本 409；既有 Gateway 測試覆蓋 action 拒絕、Session Scope、執行逾時／錯誤與 SIGKILL/新程序 checkpoint 恢復。
- **有界資源**：單 CI Job 上限 115min，BEN 四副牌執行步驟上限 92min；每副最多 160 client/robot 交替批次、單 Gateway 呼叫 11min timeout、BEN loopback 呼叫 120 秒、只使用 CPU Runner；沒有 Android/iOS 實機／Emulator。
- **量測**：輸出每副實際 BEN 成功的 bid/lead/play 次數、transport calls、p95/max 毫秒、已完成 13 墩、final score、wall elapsed、當時的 runner RSS。模型啟動／依賴安裝不算入本程式的 BEN 呼叫延遲；CI runner wall time 額外包含依賴安裝，成本取決於使用者 GitHub Actions 配額，不能當零成本。

## 正確的測試執行
短測試（不用 BEN）：
```bash
cd services/bridge_gateway
dart pub get
dart analyze lib bin/live_gateway_ben_multiboard.dart test/a6_board_fixtures_test.dart
dart test test/a6_board_fixtures_test.dart
dart test test/authoritative_game_http_test.dart
dart test test/ben_loopback_backend_test.dart
dart test test/process_restart_test.dart
```
真 BEN（須先依 `.github/workflows/ben-a6-multiboard.yml` 啟動**真模型**）：
```bash
cd services/bridge_gateway
dart run bin/live_gateway_ben_multiboard.dart
```

## 證據與未完成
- [A6 GitHub Actions 初始執行](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38918776609)：**RUNNING / 不可宣稱 PASS，需檢查最後 commit 的新執行**。
- `A6.1` 固定資料與 server metadata、`A6.2` 四副真模型 Runner、`A6.4` 機器可讀指標、`A6.5` 獨立 CI：已提交程式碼，驗證待結果。
- `A6.3` 負面測試重用現有 HTTP／Encrypted Restart／SIGKILL 回歸；多服務同時高負載與生產級恢復不包含本輪。
- `A4.5` HTTPS 正式部署、安全審查、模型授權與真實成本未完成；Android/iOS 實機／模擬器按要求暫停。
- 完整牌局 4/4 PASS 前不可將 A6 標為 VERIFIED。
