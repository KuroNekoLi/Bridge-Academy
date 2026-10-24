# BEN Multi-System M1 Spike — 實作、執行與驗收紀錄

> **2026-10-24 final M1 feasibility note:** M1.3 real 2/1 vs SAYC `/bid` A/B **SCOPED VERIFIED** ([16 × 2 requests](BEN_MULTI_SYSTEM_M1_3_ACCEPTANCE.md)); M1.4 isolated single/dual-worker CPU/RSS/latency study **SCOPED VERIFIED** ([capacity evidence](BEN_MULTI_SYSTEM_M1_4_CAPACITY.md)); [CI #40076200888](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40076200888) success. **Production NO-GO**: expert golden cases/Bridge Core e2e and actual 4GB VPS/load/license remain unverified. Previous future to-dos below are retained as historical plan.

> **2026-10-24 progress addendum:** M1.1 Capability 靜態/Mock 已通過；**M1.2 pinned BEN 實際啟動與 GET / 已 SCOPED VERIFIED**（[CI #40075250217](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40075250217)、[M1.2 驗收](BEN_MULTI_SYSTEM_M1_2_ACCEPTANCE.md)、[實際模型 SHA](BEN_M12_PINNED_ASSETS.md)）。以下 M1.2 工作清單為實作前規劃歷史；M1.3 /bid、M1.4 並行/部署仍未執行。


> Feature ID：**M3-F01**（與現有 M2 功能編號區隔）；Milestone：Multi-System M1.1  
> Date：2026-10-24  
> Scope：**靜態系統宣告與本機唯讀能力 API 檢查**；不是 BEN 神經網路推論驗收。  
> Status：**SCOPED VERIFIED**（Unit/Mock HTTP + pinned upstream systems.conf metadata in GitHub Actions）；**REAL BEN BIDDING NOT RUN**。

## 1. 規劃關係／程式碼

- 核准方向：[三制度完整實作計畫](../product/THREE_SYSTEM_BIDDING_AI_MASTER_PLAN.md)
- CLI：[scripts/ben_system_probe.py](../../scripts/ben_system_probe.py)
- 測試：[scripts/test_ben_system_probe.py](../../scripts/test_ben_system_probe.py)
- CI：[ben-system-capability.yml](../../.github/workflows/ben-system-capability.yml)
- 現有 BEN Adapter：[ben_bot_policy.dart](../../packages/bridge_ben_adapter/lib/src/ben_bot_policy.dart)
- 現有 Gateway：[ben_loopback_backend.dart](../../services/bridge_gateway/lib/src/ben_loopback_backend.dart)

這是獨立的研究工具；**沒有**更動 Bridge Core、BEN Adapter 實際叫牌、Gateway 的上游路由、Flutter 的制度切換、任何牌局存檔或正式部署。既有的 BEN `72653ec1...` 仍然是專案既有的固定真實模型驗收基準。

## 2. 上游原始碼／版本差異

| 項目 | 固定舊版驗收 | 候選新版稽核 |
|---|---|---|
| BEN Commit | `72653ec1b5c17116faea229e9b975ea5622aa1f7` | `ad8608af6e6bfe095863023f344f3cb2cbafec3d`（2026-10-23） |
| 驗證對象 | 舊版 `/bid`、`/lead`、`/play` 完整牌局 | `src/config/systems.conf` 之制度宣告、GET / 的本機探針契約 |
| 多制度可玩能力 | 未聲稱 | 靜態設定宣告 `21GF-GIB`、`21GF`、`SAYC` 可玩 |
| Precision | 未驗證 | 設定未宣告 native `PRECISION` plays=True |
| 真實多制度決策 | 無 | **NOT RUN** |
| 模型權重 hash/授權 | 需維持舊版紀錄 | **NOT CHECKED** |

官方依據：[BEN README-api.md](https://github.com/lorserker/ben/blob/ad8608af6e6bfe095863023f344f3cb2cbafec3d/README-api.md)、[systems.conf](https://github.com/lorserker/ben/blob/ad8608af6e6bfe095863023f344f3cb2cbafec3d/src/config/systems.conf)、[systems.py](https://github.com/lorserker/ben/blob/ad8608af6e6bfe095863023f344f3cb2cbafec3d/src/systems.py)。

BEN 的 `BEN:` 前綴部分模型用來讀取對手叫牌，當 `plays=False` 時不應拿來當自己搭檔的 `ourSystem`。即使 `plays=True`，真正模型是否已安裝、權重是否合法、決策正確與否都須額外驗證。

## 3. 可執行的能力檢查

### A. 靜態設定檔稽核（不啟動 BEN）

```sh
python scripts/ben_system_probe.py \
  --systems-conf third_party_ben/src/config/systems.conf \
  --require 21GF,SAYC
```

檢查：
- ConfigParser 段落、`plays` 布林、必需的 `bidder`、`info`、`cc` 路徑欄位。
- `plays=False` 不得誤計為可玩。
- 缺少必要制度、設定格式失效、缺少必需欄位 => FAIL，程式退出碼 1。
- 不會將靜態結果宣稱為真 BEN 推論或 Precision 已受支援。

預設不下載大型模型與權重，也不宣稱權重存在。如果在完整 BEN 工作目錄驗證實體 artifact：

```sh
python scripts/ben_system_probe.py \
  --systems-conf third_party_ben/src/config/systems.conf \
  --check-artifacts
```

`--check-artifacts` 會檢查 `bidder/info/cc` 檔案存在，但**不**計算權重 hash，也**不**判斷授權或可載入。

### B. 本機真 BEN 服務 capabilities 檢查（只呼叫 GET /）

啟動隔離 BEN 候選服務後：

```sh
python scripts/ben_system_probe.py --url http://127.0.0.1:8085/
```

只接受 IP literal loopback 與 HTTP origin；拒絕任意網域、認證資訊、Query、Redirect 和 /bid 路徑；不傳遞或記錄手牌、使用者 Token。這是 **真正 BEN API 能力宣告的 HTTP 檢查**，仍不是 `/bid` 模型推論。

可以同時啟用兩種來源比較：

```sh
python scripts/ben_system_probe.py \
  --systems-conf third_party_ben/src/config/systems.conf \
  --url http://127.0.0.1:8085/
```

輸出 JSON 中 `checks.static`、`checks.live` 分別為 `PASS/FAIL/NOT_RUN`，`realBiddingModelAcceptance=NOT_RUN` 不可改名誤導。Runtime JSON 必須包含合法、唯一的 `playsSystems`、`readsSystems`，以及有效 `defaults.ourSystem`。

## 4. 已驗證的 CI 證據

- Commit：[11f0e2da78be788aec32dfa85cd7d3698ed84ccb](https://github.com/KuroNekoLi/Bridge-Academy/commit/11f0e2da78be788aec32dfa85cd7d3698ed84ccb)
- GitHub Actions：[BEN Multi-System Capability M1 #40074082688](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40074082688)
- GitHub API 回報 job `capability` status=`completed`, conclusion=`success`，以下兩步均 success：
  1. `python -m py_compile scripts/ben_system_probe.py scripts/test_ben_system_probe.py` + `python -m unittest discover -s scripts -p 'test_ben_system_probe.py' -v`：**通過**（Unit + mock HTTP，不是真 AI）。
  2. 從 GitHub RAW 的固定 SHA 下載 `systems.conf`，執行 `--require 21GF,SAYC`：**通過**（靜態宣告檢查）。

**未驗證／不得推論**：服務 runtime `GET /`、BEN 模型啟動、2/1/SAYC 的 `/bid` 真實候選、出牌品質、Precision BBA、模型權重 hashes、四座位交互與 4GB 記憶體適用性。

## 5. 完成 M1 還需要的工作（M1.2–M1.4）

### M1.2 新版 BEN 隔離部署與權重釘選
- 在完全獨立的 BEN 目錄/Container 安裝候選 `ad8608af...`；不得覆蓋現有真 BEN fixture 基準。
- 對所有 bidder/info/cc、DDS、BBA native library 建 checksum + license registry；檢查新模型權重來源，遇授權不明即 BLOCKED。
- 真實啟動後本機跑 `--url`，紀錄原始成功/失敗；測量 cold-start、模型載入 RSS；失敗時不得宣稱其實可玩。

### M1.3 真實 2/1/SAYC /bid A/B 鑑別
- 以 100 個先審核過的固定 PBN/auction fixtures 起步；同一手牌、同一 dealer、vulnerability，分別查 `ourSystem=21GF` / `SAYC`；`theirSystem` 應以實際對手配置。
- 驗證不會無聲回落為 BEN 預設、合法動作、回應 timeout、模型或候選解釋的來源。不得假定兩種制度每一副牌都會產生不同出價。
- 記實際 BEN config、BBA flags、weights checksum、測試使用哪些合法資訊；出問題留 redacted fixture 而不曝光其他三家。

### M1.4 系統級隔離與部署裁決
- 比較各 2/1、SAYC 模型載入的 RSS、CPU、p50/p95、同時請求、不同 partnership 同局切換、recover。
- 審查單程序多模型 vs 兩個 Worker，再決定 4GB VPS 是否足夠；不要先承諾支援。
- 更新 [實作主計畫](../product/THREE_SYSTEM_BIDDING_AI_MASTER_PLAN.md) 的 M1 acceptance 與後續 M2 gate。
- 真實模型實測與授權通過之前，**M1 全部不算完成**。

## 6. 回退與治理

本輪程式只有新建 read-only 檔案／工作流程，不影響牌局；回退可以逐檔 revert。M1.2 不可覆寫線上 BEN 或啟動手機 UI QA。後續每個工程里程碑須依 [AGENTS.md](../../AGENTS.md) 同步測試、教學與 evidence。

## 7. 範圍內的安全/工程技術決策

- Capability 資料屬於未受信任的服務回應：限制 JSON 尺寸，拒絕缺鍵、錯型別、重名、default 指向不可玩模型。
- 使用 literal loopback + 禁止 proxy/redirect，避免使用者錯把公開 BEN 服務當作測試目標；未來如需遠端，透過受認證 Gateway，不能把 hand 直接送到外部。
- 程式退出碼與結構化 JSON 方便 CI 自動判定，但 `PASS` 的 scope 僅限 Capability Declaration。
- 任一選擇的模型在某場不可用時，應將結果標 `UNSUPPORTED`，不能悄悄改用其他制度。
