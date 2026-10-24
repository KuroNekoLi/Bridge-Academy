# M3.5 — Precision BBA 性能、穩定性與發行 Gate

> 2026-10-24 · **1,000 native opening-bid evaluations PASS / RELEASE NO-GO**  
> Source evidence：[GitHub Actions #40102968596](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40102968596)  
> 與 M3.4 固定完整牌局區分：**1,000 次開叫 ≠ 1,000 場完整橋牌對局**。

## 1. 實測對象

- 固定原生 BBA `libEPBot.so`、BEN commit `ad8608af6e6bfe095863023f344f3cb2cbafec3d`、BBA Meckwell Precision V1 `Meckwell.bbsa` 雜湊；單機 isolated Ubuntu 24.04 GitHub Actions Runner。
- [precision_m35_evaluate.py](../../scripts/precision_m35_evaluate.py)：從 52 張牌用 seed `20261024 + i` 隨機抽每個 actor 的 13 張手牌（單家可知手牌，不組合完整四家），各 500 個 NS=Precision／EW=SAYC 與相反配置，走真正的原生 sidecar HTTP POST。
- 不傳任何私人帳號與尚未公開的玩家牌局；沒有 DDS 作弊或全四家情報。記錄錯誤率、P50/P95/max、EPBot worker RSS/HWM、兩種 pairing。
- **單線程／無競爭下的冷暖合併開叫 API latency**；並非一場遊戲延遲、BEN TensorFlow 整局運行或使用者網路延遲。

## 2. GitHub Actions 實測結果

| 指標 | 結果 |
| --- | --- |
| 真原生 EPBot request 數 | **1,000** |
| 成功／失敗 | **1,000／0** |
| Precision NS, SAYC EW | 500 |
| SAYC NS, Precision EW | 500 |
| 叫牌 P50 | **9.46 ms** |
| 叫牌 P95 | **12.96 ms** |
| 最大延遲 | **51.64 ms** |
| EPBot worker VmRSS | **79,220 KiB（約 77.4 MiB）** |
| EPBot worker VmHWM | **79,220 KiB（約 77.4 MiB）** |
| VmSize | 33,315,080 KiB（大幅虛擬位址保留，不能當作實際 RAM 使用量） |
| 完整牌局數（本 benchmark） | **0**（M3.4 另外完成兩場） |
| 多人併發／實際 2vCPU、4GB VPS | **NOT RUN** |

**最新重跑驗收**：[CI #40103865733](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40103865733) **1000/1000、0 failures，P50=7.05 ms、P95=10.03 ms、max=43.59 ms、VmRSS/VmHWM=79,816 KiB**。原表的數字是前一次 CI #40102968596 的有效量測，兩者皆標註 CI runner、單工、固定種子（不同 run 存在延遲波動）。同一最新 run 中，NS/EW 對調的 Precision/SAYC 與 Precision/21GF 共 **4 場**固定牌局完成 52 張牌與 13 墩（研究合法策略出牌，非競賽 AI），Flutter 研究選單 Widget CI 也通過。

此數據只代表 GitHub CI 環境及當時 worker，不能據以聲稱有 77–78 MiB 的正式多模型部署足夠；完整 BEN TensorFlow、MySQL、API、原生庫載入、容器及 CPU 同時消耗需要另外量測。

## 3. 測試驗證層級

| Release Gate | 驗收結果 |
| --- | --- |
| Native sidecar 版本與 SHA pin | PASS |
| 混合 NS/EW 精準制 native 叫牌 1,000 次無 API 錯誤 | **SCOPED PASS** |
| M3.4 雙方向各一完整 52 張牌／13 墩 | **TECHNICAL PASS**（非競賽出牌） |
| 嚴格 Dart/Flutter 前端與 Gateway 常規 CI | 各自 scoped CI 檢查 |
| 100+ 人工強 1♣、強迫應叫、1NT、競叫 expert Goldens | **NOT COMPLETED** |
| 1,000 場完整隨機牌局和同種子 MP/IMP AI 品質比較 | **NOT COMPLETED** |
| 原生 BBA + BEN 互懂人工 Precision 的 cardplay inference | **NOT COMPLETED** |
| 2vCPU/4GB VPS 程序、套件與 DB 共存下的 p95/RSS／併發 | **NOT COMPLETED** |
| 授權文書、native manifest/notice、TLS 和正式使用者 QA | **PENDING / OWNER DEVICE QA HOLD** |
| 產品公開／積分競賽釋出 | **NO-GO** |

## 4. 可重現腳本與下一步

```bash
# 須先確保真正 pinned native BBA worker 在 localhost:18088 運行
python scripts/precision_m35_evaluate.py \
  --port 18088 --cases 1000 --pid "$BBA_RESEARCH_PID" \
  --output /tmp/precision-m35-research.json
```

發行前須以目標 VPS 重跑、加上 concurrency 1/2/4/8、長時間記憶體增長、崩潰重啟和私牌日誌洩漏回歸，並建置 expert-reviewed golden corpus、完整牌局實驗（同牌、同莊家/局況/定約制度下比較 score, MP/IMP）才能評估真正精準制牌力。本次只有 M3.5 **性能研究與測試架構**達工程 scoped pass，**M3.5 production release Gate 未通過**。
