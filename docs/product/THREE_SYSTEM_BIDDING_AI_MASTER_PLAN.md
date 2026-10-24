# Bridge Academy — 2/1、SAYC、Precision 與可自訂制度的 AI 發展計畫

> **Precision 最終 V1 變體決議（2026-10-24）**：產品選定 [BBA Meckwell Precision V1](../conventions/PRECISION_BBA_MECKWELL_V1.md)，`BA-PRECISION-MECKWELL/r1`，1NT **13–15 HCP**，以固定 BBA `Meckwell.bbsa` SHA 為權威。不得與外部 Meckwell Lite 13–16 規格混用。使用者已表示取得 BBA 使用授權，惟其商用／hosting／再散布範圍尚待核對。研究原生 EPBot 真實開叫已通過；玩家選單、全套規則與正式部署仍 NO-GO。本文下方較早期關於 Precision「未決、候選 Meckwell Lite」的敘述，以此決議和 ADR-031 為準。

> Status: **APPROVED DIRECTION / IMPLEMENTATION PLAN**；非三制度已完成、非正式上線核准。  
> Date: 2026-10-24 · Owner decision: 首批支援 **2/1 Game Force、SAYC、Precision Club**，並朝可自訂搭檔約定發展。  
> Primary project: `KuroNekoLi/Bridge-Academy` / `master`。  
> 技術稽核基線：Bridge Academy `41d0ac604554dc3581cbe59b796b172e81270ee9`；BEN 原固定基線 `72653ec1b5c17116faea229e9b975ea5622aa1f7`；2026-10-23 BEN 候選 `ad8608af6e6bfe095863023f344f3cb2cbafec3d`。候選非產品已採用版本。

## 0. TL;DR（新工程師先讀）

產品目標不是在叫牌盒增加三個按鈕，而是讓同一組搭檔 **依指定且經版本鎖定的制度叫牌、理解叫品、推測牌力／牌型，並用可重播的證據驗證品質**。玩家選好制度後與三名 AI 進行完整對局；後續可以修改經支援的約定、比較制度、複盤以及參加制度公平的機器人賽。

**已批准**：三種基礎制度的產品範圍；朝可自訂 Convention Card 與 AI 搭檔配合方向開發。  
**建議基準，尚待橋牌專家／實測批准**：Precision 使用 Meckwell Lite（而不是將任意精準制混用）；各制度例外約定的精確點力、牌型及競叫結構。  
**明確不代表已完成**：BEN 上游列出 SAYC/21GF 的可玩模型，不等於本專案當前已安裝、已通過實測，更不代表 Precision 或任意自訂約定已受支援。

## 1. 現有工程事實與不變量

- Bridge Core（`packages/bridge_core`）掌管合法叫牌、X/XX、Pass Out、13 墩、52 張牌、定約、計分及 Event Replay；不能加入 SAYC / 2/1 / Precision 的語義。
- `packages/bridge_ben_adapter` 使用 `PlayerView` 將合法的單座位資訊映射到 BEN `/bid`、`/lead`、`/play`，最終動作由 Core 驗證。已證明固定真 BEN 牌局可跑完，不代表制度相容。
- `services/bridge_gateway` 有 localhost-only、server-owned Game、限額、幂等與檢查點的 scoped 實作；Production HTTPS、跨實例 durable session、完整授權、模型授權、實機 QA 仍為 release gate。
- B3.1/B3.2 Flutter ConventionProfile/Explain 是 **教育用顯示**，`BA-NATURAL-NT` r1/r2；預覽不會變更 BEN 或規則 Bot。應做 migration，而不是宣稱它已是制度引擎。
- A3.5／Android emulator／實機 Android/iOS E2E 繼續遵守 Owner 暫緩政策；本計畫不可藉由改 CI 偷跑。
- 不對普通 AI 傳四手牌；Dummy 只在已公開時傳，DDS 全知僅可用於對局後複盤／合法測試 fixture。
- BEN 是不可信的 ActionProposal；失敗不得默默改用錯誤制度或虛構決策。Pass Out 的原始歷史不可填造第四次 Pass。

來源：[AGENTS.md](../../AGENTS.md)、[PRD v1](BRIDGE_ACADEMY_PRD_V1.md)、[Roadmap](PRODUCT_DELIVERY_ROADMAP.md)、[既有約定契約](../CONVENTION_SYSTEM.md)、[B3.2 驗收](B3_2_CONVENTION_PROFILE_ACCEPTANCE.md)、[真 BEN 驗收](../m2/M2_F04_REAL_BEN_ACCEPTANCE.md)。

## 2. 競品啟示／產品能力

| 能力 | 第一階段 | 長期 |
|---|---|---|
| 1 人 + 3 AI，真 BEN 可完成 13 墩 | 繼續保有既有能力 | 更穩定的運行／速度 |
| 2/1、SAYC、Precision 基礎制度 | 分別由相容引擎與固定版約定卡驅動 | 每個制度逐步升級 |
| 叫牌前顯示搭檔如何理解 | 顯示已驗證、可追溯的規則 | 完整雙語教學與反例 |
| 自訂 Convention Card | 先規則白名單、版本化並顯示兼容程度 | 完整 DSL、測試與衝突檢測 |
| 賽後複盤 | 分開合法性／約定／策略 | 多制度同牌比較／教練 |
| 每日機器人賽／排行榜 | 先沿用 **非排名練習** | 僅在 server-authoritative 公平牌局、MP/IMP 比較成立後上線 |

僅參考功能原理，不複製 BBO／新睿的程式、品牌、牌局資產或私有 AI。既有 [Competitor Benchmark](COMPETITOR_BENCHMARK.md) 仍有效。

## 3. 三制度規格基線（V1 有效範圍需明訂）

### 3.1 SAYC
- 美國標準黃卡的五張高花自然制；常見 1NT 15–17、強 2♣、弱二、Stayman、Jacoby Transfer。
- 必須具體寫出 1m、1M、1NT、2♣、weak two 的 opening、responses、rebids、競叫、double/redouble、slam、干擾後的例外。
- 不可把任意教學或自訂版 SAYC 當成官方標準黃卡；以 **原始規格及實際 BEN 的 SAYC convention card** 做差異對照。
- 工程候選：BEN `ourSystem=SAYC` + 對應 `bidder/info` 模型、`BEN-SAYC.bbsa`，以實測為準。

### 3.2 2/1 Game Force
- 一般未經 Pass 且無干擾的 1M–P–2m 或 1S–P–2H 達到 game-forcing 的適用條件必須明文；不可套用到已經 passed hand 或競叫序列。
- 需決定並版本鎖定：1NT Forcing vs Semi-Forcing、1D–2C 的處理、1m 開叫、Jacoby 2NT、Drury、splinter、reverse、強跳叫、RKC、競叫及雙方 Pass 例外。
- 工程候選：BEN `ourSystem=21GF`，將 `21GF-GIB` 作為對照組，而非二者含義完全相同的假設。
- 應保存真實 BEN 模型 ID/commit/weights SHA；「訓練使用 2/1」不能取代規則驗收。

### 3.3 Precision Club
- 使用者核准的是「精準制」大方向；**Meckwell Lite Precision** 只是 V1 推薦候選，未經規格審核前標為 `PROPOSED`。
- 候選基準（**不能直接宣稱為所有 Precision 版本共同規則**）：人工強 1C（常見 16+）、1D 限制性／catchall、1M 限制性五張高花、1NT 範圍可能採 13–15、1C–P–1D 人工示弱等。其他 2C/2D、asking bids、干擾後特殊答叫必須對照所選 Meckwell Lite 原始資料及 BBA 設定。
- **1C 最關鍵**：AI 必須把強 1C 的資訊反映到搭檔牌力／牌型推測，而不僅是強制輸出 1C。
- BEN 目前上游 `systems.conf` 僅列 `21GF-GIB`、`21GF`、`SAYC` 為 `plays=True`；沒有可直接聲稱為原生可玩 Precision 的模型。
- 可研究 BBA/EPBot `System type = 3`（PC）；須先確認具體可用的 Precision 版本、BBA API、原生二進位授權及 BEN 混用的資訊偏差，再決定正式實作。

### 3.4 三套制度共用的規格欄位
每張 Convention Card 最少需有 `id`、`revision`、`canonicalProfileHash`、`variant`、`sourceReferences`、`reviewStatus`、`supportedEngine`、`agreements`、`alerts`、`legalityIndependent`。每個規則需有：
- Auction pattern（含 dealer、座位、Pass、X/XX、誰先 Pass、opening/competitive 狀態）。
- Vulnerability、scoring method、forcings、HCP/shape ranges、最低張數、例外／適用條件、rule priority 與衝突區間。
- bid meaning（人工／自然）、告警與雙語說明、專家來源、預期/替代合理叫品。
- 未匹配時 `UNKNOWN`；引擎缺能力時 `UNSUPPORTED`，不能猜測或產生肯定說法。

## 4. 分層架構與資料流

```text
Flutter Play / Learn / Review / Settings
    | chooses system IDs, rule revision, game mode
    v
Dart Gateway (server-owned session & authorized seat)
    | immutable GameSystems {NS/EW profileId/revision/hash/engineId/weights}
    v
Convention Runtime (new, no Deal/GameState)
    +-- ProfileRegistry / RuleInterpreter / CompatibilityChecker
    +-- EngineRouter
           +-- BEN 21GF / SAYC worker (request scoped)
           +-- Precision prototype worker (BBA only when permitted)
           +-- future own rule engine / dedicated model
    |
    v
BEN or equivalent: proposal only -> Bridge Core validates -> event log -> PlayerView
```

**不要**讓 Flutter 自己宣告 `ourSystem` 就使伺服器信任；Server 從 immutable GameSystems 推出 seat-specific profile，再把該動作轉到正確 Worker。對 N/S 與 E/W 各設獨立搭檔設定。請求重試、崩潰恢復、重播、模型版本升級期間不得改變 game 的 profile hash。過期或不支援的配置應 fail closed 並保留可追溯原因。

建議新增 `packages/bridge_conventions`（無網路的領域模型，和 Core 平行）；Gateway `ConventionSessionConfig`／`EngineRouter`；BEN Adapter 僅負責合法映射，不能讀取全四手牌或代替 Core 判定合法。

## 5. BEN 上游支援事實與必要確認

BEN `main`（2026-10-23）：
- `src/config/systems.conf` 有 `21GF-GIB`、`21GF`、`SAYC` 的 bidder/info/cc 及 `plays=True`；`BEN:` 前綴某些模型 `plays=False`，僅用於讀取／推測對手，不能傳成 `ourSystem`。
- `src/systems.py` 會載入模型並對 per-request `ourSystem` 切換 bidder/info/cc，`theirSystem` 切換對手模型。錯誤名稱應 HTTP 400。
- BEN REST `GET /` 宣告 `playsSystems`、`readsSystems`、`cardings`、`defaults`，`GET /bid` 支援 `ourSystem`/`theirSystem`。
- `use_bba=False` **不代表所有 BBA 諮詢/解釋路徑必定關閉**；要另外檢查 `consult_bba`、`use_bba_rollout`、`use_bba_to_count_aces`。固定 CI 曾關閉 BBA 相關路徑，故不代表其授權／可運行性已驗證。
- `Systems.load` 可能載入多個大模型。部署前量測 RSS、啟動耗時、切換延遲、併行請求，而不是假定 4GB VPS 夠用。

上游：[README-api](https://github.com/lorserker/ben/blob/main/README-api.md)、[systems.conf](https://github.com/lorserker/ben/blob/main/src/config/systems.conf)、[systems.py](https://github.com/lorserker/ben/blob/main/src/systems.py)、[BBA adapter](https://github.com/lorserker/ben/blob/main/src/bba/BBA.py)。

## 6. API 與 Domain 契約草案

```json
{
  "gameSystems": {
    "northSouth": {
      "profileId": "BA-21GF",
      "revision": 1,
      "hash": "sha256:...",
      "engine": "BEN",
      "model": "21GF",
      "modelArtifact": "pinned-sha256"
    },
    "eastWest": {
      "profileId": "BA-SAYC",
      "revision": 1,
      "hash": "sha256:...",
      "engine": "BEN",
      "model": "SAYC",
      "modelArtifact": "pinned-sha256"
    }
  }
}
```

以上為 **草案**，不可直接傳给未更新的 Gateway。後續實作前做既有 transcript/checkpoint migration；新的欄位一律後端來源可信、版本化、不可隨回合改動。若 UI 表示已啟用 21GF 而後端回報未支援，就拒絕開始對局，而不是退回 `21GF-GIB`。

Runtime 至少提供：
- `listCapabilities()`：實際可玩的制度、讀取制度、模型 SHA、精度／授權狀態。
- `validateProfile(profile)`：規則衝突、覆蓋與 engine mismatch，產生 `SUPPORTED / PARTIAL / UNSUPPORTED`。
- `explain(publicAuction, profileRevision)`：解釋附 rule ID、適用條件與 UNKNOWN。
- `proposeBid(seatView, GameSystems)`：只用 PlayerView，由 Bridge Core 驗證提案合法性。
- `compareProfiles(fixture)`：不可在未結束對局時使用隱藏四手牌向玩家提供提示。

## 7. M1–M6 交付路線與停損點

**M3.4／M3.5 最新進度（2026-10-24）**：已建立可選編譯、伺服器顯式允許的 Precision **研究版**：全桌採真 BBA/EPBot 按 `Meckwell.bbsa`／`BEN-SAYC.bbsa`／`BEN-21GF.bbsa` 協作叫牌，固定 `GameSystems` 版本，不讓 BEN NN 假裝有 Precision opponent reader。固定公開 PBN 的雙方向 Precision/SAYC 52 張牌技術性整局 PASS；出牌使用合法訓練策略，非競賽 AI。原生 1000 次固定種子開叫評估全部成功、P95=12.96ms，這不是 1000 場實戰。詳細見 [M3.4 驗收](../research/M3_4_PRECISION_MIXED_GAME_ACCEPTANCE.md)、[M3.5 性能](../research/M3_5_PRECISION_BENCHMARK_AND_RELEASE_GATE.md)、[CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40102968596)。**產品的 AI 品質與正式 4GB VPS/裝置驗收依然 NO-GO**。



**M3.3 引擎原型進度（2026-10-24）**：[PrecisionBiddingProvider](../../packages/bridge_precision_adapter/lib/src/precision_bidding_provider.dart) 與[安全 EPBot sidecar](../../scripts/precision_m33_sidecar.py) 已實作。真原生獨立 [M3.3 CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/precision-m33-provider.yml) 檢查每次載入唯一 V1/Meckwell 13–15 卡與 native binary SHA、僅 POST 私牌、依 NS/EW 和敵方 21GF/SAYC 約定卡出價，並由 Dart Bridge Core 核對合法 CallAction。**使用者已確認 BBA 許可涵蓋商業託管、修改及再散布**，但仍須將授權原文和元件、notice 私下歸檔。此階段不修改 BEN 的 `systems.conf` 或假稱它可以解釋 Precision，也不修改 Gateway／Flutter 正式選項。M3.4 真實 mixed-engine 溝通、完整 52 張牌對局及 M3.5 品質／VPS 仍是獨立門檻。



**M3 Precision 技術研究最新結果（2026-10-24）**：已完成首個隔離 native BBA/EPBot Spike（[報告](../research/M3_PRECISION_SPIKE_ACCEPTANCE.md)、[CI #40092096757](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40092096757)），8 次真原生開叫測試、4 個 1♣ 強開叫候選皆符合研究預期；**BBA Meckwell 上游卡 1NT 13–15 與公開 Meckwell Lite v1.13.0 13–16 不同**。新 [PrecisionResearchCatalog](../../packages/bridge_conventions/lib/src/precision_research.dart) 僅為候選規格，因版本/授權/完整叫牌語義未核准，**不能註冊為 BA-PRECISION，不能在 Flutter/Gateway 選擇**。M3 要從此候選原型延續到 Production 必須先完成書面授權、唯一的 Meckwell 版本／完整約定卡與 100+ expert golden fixtures、真 BBA mixed partner 整局和伺服器分離路由，現階段保持 release NO-GO。



**M2.2～M2.5 工程完成（2026-10-24，SCOPED PASS）**：Adapter 對 N/S vs E/W 正確傳送 21GF/SAYC；Gateway 使用 operator-pinned BEN commit + 真實 GET / abilities + server allowlisted GameSystems；Flutter 新局前可分別選 N/S、E/W 制度並驗證回傳 fingerprint。實際真 BEN 在同一固定 Deal 的兩種互換配置分別完整完成 13 墩／52 張牌／有效計分、每局 56 次 BEN requests；真實證據：[CI #40087851963](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40087851963) · [綜合驗收](../research/M2_2_TO_M2_5_IMPLEMENTATION_ACCEPTANCE.md) · [整局驗收](../research/M2_5_REAL_BEN_MULTISYSTEM_ACCEPTANCE.md)。現有 Legacy/Flutter Demo 邊界保留。**這不等於完整叫牌制度專家核可、裝置 QA 或 Production GO。** Precision／自訂制度待 M3。



**M2.1 狀態（2026-10-24）：** 已新增純 Dart `bridge_conventions`：南北／東西各自不可變的 `PartnershipSystem`、`GameSystems`、allowlisted revision 與 SHA-256 fingerprint；可信任 Gateway 建局綁定、encrypted checkpoint 恢復、舊版 legacy migration、未知版本拒絕。為避免使用者誤認 AI 已切換制度，M2.2 真實 BEN routing 前已選 `21GF/SAYC` 的遊戲動作先以 `503 system_router_unavailable` fail closed；正常舊遊戲不受影響。詳見 [M2.1 驗收](../research/M2_1_GAME_SYSTEMS_ACCEPTANCE.md)。**真正 BEN routing、UI 和競賽仍未完成**。



**M1.3/M1.4 最新研究進度（2026-10-24）**：
- **M1.3 — SCOPED VERIFIED**：Pinned `ad8608af` 真實 BEN，16 個未專家審核的 auction contexts × 2 制度 = **32/32 次 /bid**，無基本非法叫品，三個 2/1 forcing 測試無 PASS 違規，1 組叫品不同；資料與限制見 [M1.3 真模型驗收](../research/BEN_MULTI_SYSTEM_M1_3_ACCEPTANCE.md) ／ [CI #40076200888](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40076200888)。
- **M1.4 — SCOPED VERIFIED**：同版 BEN 單 Worker concurrency 1/2/4、小樣本雙 Worker、p50/p95/p99 與實際 PID RSS 已驗證；觀測單 Worker 約 1.01 GiB、雙 Worker 合計約 1.95 GiB，詳見 [M1.4 容量研究](../research/BEN_MULTI_SYSTEM_M1_4_CAPACITY.md)。**不是目標 4GB VPS 壓測，也不是完整預設 BEN**。
- **M1 feasibility scoped research 已完成四步**；但 100+ 專家 golden auction cases、Bridge Core end-to-end、正式賽事／完整版模型、4GB VPS 與授權／安全／裝置 release gate 均未通過。部署裁決維持 **NO-GO**。下一步是 M2 server-owned `GameSystems` 與真 BEN Adapter/Flutter 切換，不可將 M1 視為正式產品 GO。



**M1 狀態（2026-10-24）**：M1.1 靜態能力探針 SCOPED VERIFIED；M1.2 隔離新 BEN 真實啟動／SHA256／GET / SCOPED VERIFIED（[CI #40075250217](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40075250217)、[驗收](../research/BEN_MULTI_SYSTEM_M1_2_ACCEPTANCE.md)）；**M1.3 真實 2/1/SAYC 叫牌和 M1.4 RAM/部署決策仍未完成**。不可把兩個子階段的 PASS 等同 M1 整體 GO。


| 里程碑 | 交付 | 最低驗收條件 | 不可假稱 |
|---|---|---|---|
| **M1 上游 BEN 多制度可行性** | 版本釘選、systems.conf 審核工具、GET / live capabilities probe、可重現單元測試、真模型評估方案 | 21GF、SAYC 靜態 capability 及（啟動真 BEN 後）API 實測分別報告，未跑要 NOT RUN | 靜態設定可用≠真模型可用 |
| **M2 兩制度整合** | Gateway/Adapter server-authoritative NS/EW profile、模型切換、Flutter 制度選擇、恢復 migration | 真 BEN 兩制度實測、雙搭檔隔離、合法及隱私 regression | UI 切換≠模型真的切換 |
| **M3 Precision 原型** | Precision 約定文件、BBA PoC、license review、未來替換介面 | 真實 1C 系列/競叫完整測試；混用 BEN 下推測正確性評估 | 沒有授權≠可以發行；合法叫牌≠策略正確 |
| **M4 自訂約定** | 以既有制度複製、有限規則編輯、conflict detection、revision/hash | 所有可儲存並標 `SUPPORTED` 的約定有引擎證據 | 更改 bbsa≠神經網路重訓 |
| **M5 AI 教練** | 候選叫品、雙語解釋、證據來源、賽後制度差異 | 叫品/含義/策略分層、UNKNOWN、隱藏資訊測試 | LLM 解釋≠當時 AI 真實推理 |
| **M6 機器人競賽** | 制度專屬賽、固定 BoardSet、可比較 MP/IMP、排名 | Immutable server board、同種 scoring/bot/version、反作弊/去重 | 單桌 duplicate score≠MP/IMP |

**M1 本輪邊界**：可以先實作靜態與本機 capabilities probe/單元測試/CI，不可在尚未真正起 BEN 服務時寫「真 BEN 已通過」。後續真模型 benchmark 不與普通靜態檢查合併聲稱。

## 8. 精準制的正式架構決策入口

| 路線 | 可行性 | 成本與限制 | 採用條件 |
|---|---|---|---|
| A：BBA / EPBot Precision 叫牌器 | 適合最快研究 | native binary、license 未明、與 BEN sampling 不一致 | 授權書面確認 + call sequence 實測 |
| B：自有 Precision 規則器 | 高可控、能自訂 | 需完整實現大量競叫與後續序列 | 團隊有專家校訂 fixtures，零臆測 |
| C：訓練 Precision BEN bidder/info | 長期可擴展 | 大量合法訓練資料、算力、模型品質評估 | 資料/模型授權 + 牌局對照達標 |

目前 **先 A 做隔離技術 Spike，同時保留 B/C 可替換接口**；實際商用方案待 Precision 授權與模型品質證據後再審定。BBA 官方聲明目前倉庫未提供明確 license，不能當成 BEN GPL-3.0 的自動延伸。[BBA README](https://github.com/EdwardPiwowar/BBA)。

## 9. 測試與品質矩陣

1. **規格 fixture**：每套至少 100 組專家覆核的開叫、答叫、再叫、邀請/GF、passed hand、競叫、double/redouble、不同身價；每個 fixture 記 rule ID、可接受多種候選、預期語義、來源與例外。此為**提議目標**。
2. **真模型**：每套至少 1,000 個固定種子/牌局序列，標記 model commit/sha、PIMC、BBA 是否啟用、候選機率與 error；絕不以 Mock 充數。此為**提議目標**。
3. **完整對局**：同牌／座位交換比較終局的合法性、IMP、合約到達、滿貫、嚴重誤解；進行配對、必要的信賴區間；不得以少數牌例聲稱 AI 強弱。
4. **安全／恢復**：非法 AI 出價 fail closed；非行動座位沒有隱藏手牌；切換制度後舊 checkpoint/replay 保有舊模型 hash；舊 API raw `/v1/ai/decision` 僅允許本地開發。
5. **效能**：單模型與三模型 RSS、cold-start、p50/p95/p99、worker queue、同時用戶、4GB 主機 OOM、重試/timeout。
6. **CI 策略**：靜態/Mock probe 日常短 CI；受控且版本釘選的真 BEN runner 獨立執行，僅真模型實際測試才能標真人工智慧驗收。Android/iOS 實機/模擬器遵循 owner QA hold。

## 10. 競賽公平性

正式排名賽：固定 partnership profile hash、engine/model commit、scoring/boardset/vulnerability、延遲比較結果、Server 權威與不可變 replay；機器人牌力差異要以分組或公開條件處理。自由制度賽：與官方排名分離，顯示制度及相容性限制。B6 仍是 *Unranked Daily Practice*，不能偷跑 D/P3 的排行榜。

## 11. 授權、部署與安全門檻

- BEN GPL-3.0：公開代碼與發行義務由法務確認；服務端執行、分發、權重再分發要分開審視。
- BBA/EPBot：無明確使用許可前，不上正式部署、不可再分發；須評估商用／託管服務／訓練資料使用的授權範圍。
- TensorFlow 模型權重／DDS／BBA native lib：每個 artifact 記 SHA、上游、授權及使用權，不推論整包授權。
- 私有 BEN Worker 僅允許 loopback，前端只能走 HTTPS Gateway；不公開包含手牌的 BEN GET URL、log、錯誤內容。
- 即使目前使用 2vCPU/4GB 主機，也不能預設載入 3 個 bidder/info pair + DDS/BBA 一定不會 OOM；先跑量測與容量規劃。
- 定義開發／測試／正式發行三種獨立 release gate；工程 scoped PASS ≠ 裝置 PASS ≠ Prod GO。

## 12. 追蹤與實施規範

- 優先順序：**M1 BEN 原生支援稽核 → M2 2/1/SAYC 端到端 → M3 Precision → M4 自訂卡 → M5 Coach → M6 正式賽**。
- 依 [AGENTS.md](../../AGENTS.md) 直接 push `master`，不強推、不偷改正式部署；每個功能需完整測試/學習文件與可回滾變更。
- Decision record: [docs/DECISIONS.md](../DECISIONS.md)。開始 M2/M3 前如涉及 Precision 版本與 2/1 forcing 細節，產生明確 ADR；在此之前標 `PROPOSED`。
- M1 實作／證據索引：[BEN Multi-System M1 Spike](../research/BEN_MULTI_SYSTEM_M1_SPIKE.md)；切勿把後續的「計畫」寫成「已通過」。

## 13. 參考文獻

- [BEN API](https://github.com/lorserker/ben/blob/main/README-api.md)
- [BEN systems.conf](https://github.com/lorserker/ben/blob/main/src/config/systems.conf)
- [BEN systems.py](https://github.com/lorserker/ben/blob/main/src/systems.py)
- [BEN BBA.py](https://github.com/lorserker/ben/blob/main/src/bba/BBA.py)
- [BEN default convention card](https://github.com/lorserker/ben/blob/main/convention_card.md)
- [BBA 官方程式庫及授權聲明](https://github.com/EdwardPiwowar/BBA)
- [ACBL Learn Bridge / Convention Resources](https://www.acbl.org/learn/)
- [BBO / 新睿來源索引](COMPETITOR_BENCHMARK.md)

此文件為工程規劃，不宣稱已獲橋牌專家簽核、已完成權重/二進位授權核查或已對最新 BEN 跑過三制度對局。