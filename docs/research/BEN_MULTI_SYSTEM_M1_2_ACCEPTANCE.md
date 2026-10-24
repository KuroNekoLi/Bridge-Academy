# Bridge Academy — M1.2 隔離新版 BEN、模型權重清冊與真實 Capabilities

> Status：**RUNNING / ACCEPTANCE PENDING**（以 CI 真實結果更新；禁止將 GitHub push 或靜態稽核等同於服務驗收）。  
> Date：2026-10-24 · Track：Three-System Bidding AI / M1.2。  
> 這是研究環境，不是部署到 OVHcloud VPS，也不是替換 Bridge Academy 正式 BEN Worker。

## 1. 目標與驗收定義

M1.2 在完全獨立 GitHub Actions Runner 中使用已固定 SHA 的 BEN，檢查真正的檔案存在、SHA-256、原生依賴、Python 依賴以及真實 `gameapi.py` 是否啟動。**僅檢查無手牌的 `GET /` `playsSystems`，不執行 `/bid` 策略驗證（留 M1.3）。**

驗收（必須全部符合才標 `M1.2 SCOPED VERIFIED`）：
1. GitHub checkout 實際 HEAD 必須精確等於 `ad8608af6e6bfe095863023f344f3cb2cbafec3d`；不得使用漂移的 main。
2. 上游 `systems.conf` 所有宣告的 `bidder/info/cc`（包括 readonly）以及平台原生依賴檔案均存在且 SHA-256 可讀，清冊不包含權重內容。
3. Python 3.12 + 所固定版本 `requirements.txt` 安裝完成；實際啟動 `src/gameapi.py`，所有網路服務僅 listen loopback。
4. 真實 BEN `GET /` 返回 `playsSystems` 同時包含 `21GF`、`SAYC`，`readsSystems` 與 `defaults` 也一致；記錄 startup elapsed/RSS snapshot。
5. 無 Android／iOS 實機或 emulator QA、沒有更改既有 Gateway / BEN Adapter / Core / 玩家資料，也不聲稱授權完成或可對外提供服務。

## 2. 工程交付

| 檔案 | 用途 |
|---|---|
| [scripts/ben_m12_inventory.py](../../scripts/ben_m12_inventory.py) | 對固定 BEN Git checkout 完整記錄模型、BBA card、原生 DDS/BBA/PIMC、requirements 與 license 文件 SHA-256；缺少檔案或不安全路徑 fail closed |
| [scripts/test_ben_m12_inventory.py](../../scripts/test_ben_m12_inventory.py) | 合成模型檔案、缺失模型、錯誤 plays flag、路徑跳脫、hash 變更、授權未核准等單元測試 |
| [ben-m12-isolated-runtime.yml](../../.github/workflows/ben-m12-isolated-runtime.yml) | 使用 GitHub-hosted Ubuntu 24.04、Python 3.12、固定 BEN SHA、稀疏下載 `src/models/BBA/bin`，單獨啟動並稽核服務 |
| [scripts/ben_system_probe.py](../../scripts/ben_system_probe.py) | 沿用 M1.1 已驗證的安全 loopback GET / capability 檢查 |

Runtime CI workflow 依序執行：
```text
checkout Bridge Academy
  → checkout lorserker/ben@ad8608af (sparse, isolated)
  → stdlib unittest (no ML)
  → SHA256 inventory (+ artifact existence)
  → pip install upstream Python requirements / verify TF/Keras version
  → copy & disable BBA/PIMC/SuitC only in isolated config
  → boot 127.0.0.1:8085 gameapi.py
  → GET / real capabilities + memory RSS snapshot
  → ben_system_probe.py both static and live
  → optional sanitized short-lived CI report artifact
```

舊版 `72653ec1` BEN CI 完全不動。固定候選版本不是最新版本浮動參考。從最新上游取得的模型未被直接 commit 到 Bridge Academy repo。

## 3. 目前基線與研究證據（須區分實際與推論）

上游 `ad8608af` [systems.conf](https://github.com/lorserker/ben/blob/ad8608af6e6bfe095863023f344f3cb2cbafec3d/src/config/systems.conf) 宣告：
- `21GF-GIB` / `21GF` / `SAYC` 的 `plays=True`。
- `BEN:` 相關系統 `plays=False`，不可用 `ourSystem` 假裝可玩。
- `21GF` 對應 `BEN-21GF-8742_2026-10-22-E30.keras` 和 Info 模型。
- `SAYC` 對應 `BEN-Sayc-8730_2025-04-20-E30.keras` 和 Info 模型。

注意：新候選版同時載入許多對手資訊模型，這就是為何 inventory 涵蓋 **所有宣告模型**。只記 `21GF/SAYC` 兩檔並不足以證明該程序能啟動。

所有 manifest 的 `redistributionApproved=false`。BEN 上游 GPL-3.0 不等於其模型權重、native BBA/PIMC/DDS 以及訓練資料均自動取得發行授權。Native BBA/PIMC/SuitC 在此次 Runtime Smoke 中停用；相容性及效能不代表正式預設模式。

## 4. 重現命令

Repo 根目錄：
```bash
python -m unittest discover -s scripts -p 'test_ben_m12_inventory.py' -v
python scripts/ben_m12_inventory.py \
  --ben-root third_party_ben_m12 \
  --commit ad8608af6e6bfe095863023f344f3cb2cbafec3d \
  --out m12-inventory.json
python scripts/ben_system_probe.py \
  --systems-conf third_party_ben_m12/src/config/systems.conf \
  --check-artifacts \
  --url http://127.0.0.1:8085/
```

**注意**：最後一條需先在隔離本機啟動相同 BEN，否則應明確 `FAIL`；真正 CLI 不會自己啟動 TensorFlow 服務。

## 5. CI / Runtime 證據

CI：[BEN M1.2 Isolated Live Runtime and Artifact Inventory](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/ben-m12-isolated-runtime.yml)

**待確認：** 檢查最新 workflow run job 的 `completed/success`、`ben-m12-inventory.json`、`ben-m12-runtime.json`，並記錄 startup seconds、RSS、capabilities 的實際值。沒有輸出可核對前 **不能宣稱 M1.2 全部完成**。

| 驗收 | 狀態 |
|---|---|
| 新 BEN SHA 固定與稀疏隔離 checkout | 待 CI |
| 模型／權重／原生庫檔案 SHA-256 | 待 CI |
| 單元測試 | 待 CI |
| 真的啟動 BEN 並讀 GET / | 待 CI |
| Python / TF / Keras、記憶體紀錄 | 待 CI |
| 真實 `21GF/SAYC` `/bid` | **NOT RUN（M1.3）** |
| Precision | **NOT RUN（M3）** |
| 商用授權／正式部署／4GB 容量合格 | **BLOCKED / NOT REVIEWED** |

## 6. 已知風險與補救

- TensorFlow 2.21 + Keras 3.15、原生 DDS3、系統 boost/icu 需要匹配 Linux；安裝或啟動失敗就停止，不能拿 Mock 代替。
- 非常多可讀的對手系統在 BEN 啟動時可能一起載入；高 RSS 時先記錄，而不是自動把 CI 當成 4GB VPS 容量測試。
- CI GitHub Runner 是暫態環境，不代表本機 Windows、OVHcloud 與正式服務已完成部署。
- License 必須另有使用與再分發核准；本輪 CI 若僅作研究，不應把原生二進位／大型權重傳到應用 repo 或當作正式發行物。
- 當 BEN / API 跟 M1.1 的 capabilities 有偏差，保留實際錯誤，更新 Adapter 設計，不要自動 fallback 到別的制度。

## 7. 下一步

M1.3 需使用已核准的完整 fixture 在真實 `/bid` 執行 `ourSystem=21GF` 與 `SAYC` 對照，並核對 partner-level 叫牌語義、真正模型用到的權重及後續合法性；M1.4 再做併發、4GB VPS 容量與隔離部署裁決。
