# Bridge Academy — M3 Precision Club 原型研究與驗收

> Date：2026-10-24  
> 工程狀態：**M3-A（隔離 BBA/EPBot 原型）SCOPED VERIFIED**；正式 Precision 註冊／玩家選項 **BLOCKED**。  
> 真模型 CI：[M3 Precision Native Research #40092078930](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40092078930)，completed/success。  
> 對象：**BEN pinned `ad8608af6e6bfe095863023f344f3cb2cbafec3d` 的原有 BBA/CC/Meckwell.bbsa（system type=3）**；本 repo 不散布 EPBot binaries 或第三方 Convention Card。

## 1. 為什麼不能直接把 Precision 選單打開

M2 已經完成的 BEN Seat Robot API 只認識 `21GF-GIB`、`21GF` 和 `SAYC` 等可玩模型；釘選版本 `src/config/systems.conf` 沒有 Precision 的 bidder/info neural model。將 `ourSystem=PRECISION` 直接加入 Gateway 必定不是合法且已驗證的行為。

BBA/EPBot 是不同的**原生約定叫牌引擎**，不是 SEN/BEN 的 Precision 神經網路。釘選 BEN 含有 `BBA/CC/Meckwell.bbsa`（System type=3），`src/bba/BBA.py` 的 `BBABotBid` 知道如何依座位對 NS/EW 設定原生系統並取得出價。然而：
1. 這份 BBA 卡與 `Meckwell Lite Precision System v1.13.0 (2026-01-05)` **不是等價版本**：**Meckwell.bbsa 選擇 1NT 13–15，而參考文件為 13–16**，其他人為約定也有待比對。
2. BBA 上游 [EdwardPiwowar/BBA](https://github.com/EdwardPiwowar/BBA) README 明言 **目前沒有明確的 repo 授權**；商業使用及再散布要先聯絡作者。不能從 BEN 自身 GPL-3.0 自動推定 EPBot 原生庫可商用或散布。
3. 一次原生叫牌成功不表示整個 Auction 的 1♣ 回應、干擾、同伴推理與 card play 已符合約定。不可把「合法叫品」誤當「制度語義相容」。
4. 在此之前，正式 `ConventionCatalog.resolve('BA-PRECISION', 1)` 仍應回 null，Gateway 拒絕，Flutter 沒有 Precision 可選項；M2 的 21GF/SAYC 不變。

## 2. 工程交付

| 路徑 | 說明 |
|---|---|
| [research-only Dart metadata](../../packages/bridge_conventions/lib/src/precision_research.dart) | 明確區分 2026-01-05 Meckwell Lite 參考文件與釘選 BBA Meckwell 原型；保留 Backend、授權、專家簽核獨立 Gate |
| [Dart release-gate tests](../../packages/bridge_conventions/test/precision_research_test.dart) | 驗證 13–15 vs 13–16 差異、BBA type=3、未核准與正式 allowlist 拒絕 Precision |
| [isolated native probe](../../scripts/precision_m3_probe.py) | 固定 BEN upstream SHA、實際 .bbsa SHA256、開局 8 組研究牌例；可選 `--live` 呼叫原生 EPBot；避免私人牌與原生庫輸出到專案 |
| [Python safety tests](../../scripts/test_precision_m3_probe.py) | 無原生 binary 的前置稽核測試，包含牌例合法性、SHA pin、.bbsa 占位欄與 duplicated meaningful rules |
| [fixtures](../../scripts/fixtures/precision_m3_cases.json) | 8 個公開測試牌例，4 個高牌點強 1♣ 候選，3 個 1NT 附近的邊界牌型，1 個弱牌 |
| [ephemeral CI](../../.github/workflows/precision-m3-research.yml) | 僅在 Ubuntu 24.04 GitHub Runner checkout 上游 pinned source，建立暫時環境、不修改 BEN、不打開正式 Gateway |

## 3. 固定來源與觀察

- BEN checkout：`ad8608af6e6bfe095863023f344f3cb2cbafec3d`。
- Meckwell BBA 約定卡：`BBA/CC/Meckwell.bbsa`，SHA-256 `5c2a6c8d84094a0a9efd2cefe98a93983185140e6bde81b2520086b8b27d9cbc`。
- CC 解析規則：首列必須 `System type = 3`；允許 BBA 以 `Not defined = 0` 作占位，但 meaningful rules 不允許重複、不允許有多組互斥的 NT ranges。
- 實驗 [CI #40092078930](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40092078930) 真原生 EPBot：**8 個叫牌情境全部執行、4 個事先列明的強 1♣ 候選均回 1♣（0 discrepancy）**。
- 該成功是 **真實原生 BBA**，而不是 BEN TensorFlow Precision 模型；Python Unit tests 為 **6/6 pass**（後續有擴充到 7 tests，需以 CI 版本為準）。
- 不把手牌／秘鑰／全牌 PBN／EPBot native binary 放入結果工件；僅紀錄公開固定 fixture ID、牌點、出價與已知差異。工件 14 天保留。

## 4. 風險與下一步（M3 的必要阻擋）

| Gate | 要求 | 狀態 |
|---|---|---|
| Native EPBot 技術可運作 | pinned upstream、真原生模型 1♣／非強 1♣ 對照 | **SCOPED PASS**（8 cases） |
| 制度語義相容 | 確定唯一 Precision 版本及完整規則，包括 1NT／1♣ 回應／敵方干擾 | **BLOCKED / discrepancy 13–15 vs 13–16** |
| 授權 | BBA/EPBot Native、.bbsa、權重、hosted use/redistribution 的書面許可與權限 | **BLOCKED** |
| 可替換引擎 | 將 Precision 與現有 BEN 神經路由解耦；擬選 BBA、可自有規則或訓練模型 | **DESIGN CANDIDATE** |
| 正式使用者選單 | 有 playable/validated/licensed backend 與 gateway capability 及多局 Golden fixtures | **NOT ENABLED** |
| Production Release | 模型授權、4GB VPS、負載、TLS/部署、裝置 QA | **NO-GO** |

**決策建議**：繼續以 BBA 進行隔離實驗，但**不登錄玩家選單**。先完成精準制變體 ADR（可選擇完全採用上游 BBA Meckwell 並定義 13–15，或參考 Meckwell Lite 13–16 另建經核准的 CC），並取得作者授權。M3 正式接線必須先完成強 1♣/1♦/1NT、responder 的 1♦ artificial／competitive auctions、50–100+ 參照 golden fixtures，再保證 Bridge Core/EW pairing、重啟、錯誤清晰。更改 .bbsa 並不會重訓 BEN 的神經網路。

## 5. 指令與回滾

```bash
python -m unittest discover -s scripts -p 'test_precision_m3_probe.py' -v

# 必須先 checkout exact pinned BEN，不能從 floating main 讀 BBA
python scripts/precision_m3_probe.py --ben-root third_party_ben_m3 \
  --output /tmp/precision-audit.json
python scripts/precision_m3_probe.py --live --ben-root third_party_ben_m3 \
  --output /tmp/precision-native.json

cd packages/bridge_conventions
dart pub get && dart analyze --fatal-infos && dart test --reporter expanded
```

回滾：刪除 research-only metadata、probe、CI 與研究文件即可；此功能**不修改** `GameSystems`、`ConventionCatalog`、BEN adapter、Gateway production route 或 Flutter UI，故 M2 的 21GF/SAYC、LEGACY 邏輯不變。
