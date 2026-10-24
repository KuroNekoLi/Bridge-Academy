# Bridge Academy — M1.4：BEN 單／雙 Worker 效能與 4GB VPS 部署判斷

> 2026-10-24 · **PENDING CI**（不是正式 VPS 已跑過測試）。  
> 基準：BEN `ad8608af6e6bfe095863023f344f3cb2cbafec3d`；Python 3.12、TensorFlow 2.21.0、Keras 3.15.1；隔離 Ubuntu 24.04 GitHub Actions Runner。  
> 主計畫：[三制度 AI](../product/THREE_SYSTEM_BIDDING_AI_MASTER_PLAN.md)。

## 1. 交付與範圍

- **方案 A：單 BEN Worker 載入多制度 bidder/info 模型**；一個 `gameapi.py` 同時回應不同 `ourSystem`，先依序（concurrency=1），再測 2／4 並行。
- **方案 B：兩個獨立 BEN Worker**（loopback 8085、8087；同一 commit、相同隔離配置）。同時執行兩組測試，記兩個 Python PID 的 RSS 及合併值。
- 測量 `p50/p95/p99`、max latency、完成請求數、elapsed time、requests/sec、RSS 起始/結束與每 100ms polling 峰值；**不列印或公開含手牌的 URL**。
- 研究環境 **不是** OVHcloud 2 vCPU/4GB VPS；Github-hosted CI 的 CPU/RAM/swap/共用資源不同，不能把這裡的 throughput 當成 production SLO。

## 2. 重新執行

入口：[M1.3 + M1.4 真模型 CI](../../.github/workflows/ben-m13-m14.yml)  
工具：[ben_multisystem_benchmark.py](../../scripts/ben_multisystem_benchmark.py)  
測試：[test_ben_multisystem_benchmark.py](../../scripts/test_ben_multisystem_benchmark.py)

本輪使用與 M1.3 相同的 **NN-biased 非完整 BEN 配置**，含 BBA/PIMC/SuitC 停用與簡化開叫模擬，故數據只是**對照配置下的最低限度容量研究**。不可由此推估完整版 DD simulation/BBA/競賽結果。

```bash
python scripts/ben_multisystem_benchmark.py \
  --mode m14 --url http://127.0.0.1:8085/ --pid "$BEN_PRIMARY_PID" \
  --secondary-url http://127.0.0.1:8087/ \
  --secondary-pid "$BEN_SECONDARY_PID" \
  --fixtures scripts/fixtures/ben_multisystem_m13.json \
  --rounds 2 --output m14-results.json
```

必要條件：兩個來源必須是獨立實體 BEN Python PID，不能是 Mock。`m14-results.json` 的 `observedRss` 是 sampling 最大值，**不是精確瞬間尖峰**；不包含系統 process tree、kernel page cache、隱含 OS、DB、Reverse Proxy 或部署軟體開銷。

## 3. 4GB VPS 的工程決策準則

**目前裁決：對正式多制度上線暫定 NO-GO**，直到在真實目標主機進行受控壓測與 license/security release gate。這是明確不批准 production deployment，**不代表 4GB VPS 已經被實測證明不足**。

建議（目標門檻，尚非實測）：
1. Docker Memory Limit / cgroup 限制，單程序及雙 Worker 配置加上資料庫、Gateway、reverse proxy、OS 的 RAM 合計，保留至少 25–30% 安全餘裕，避免 OOM killer 影響同機 MySQL 等服務。
2. 適用你現有的 2 vCPU/4GB 主機時，測 `concurrency=1/2/4`、連續運行、冷啟與重啟、負載時 p95/P99、CPU 與 RSS，並評估兩 Worker 是否反而因複製大量模型變差。
3. BEN Worker 僅 loopback；Gateway 負責外部 HTTPS/遊戲座位權限、限額／幂等、重試；不得將含私人手牌的 GET 原始 URL 經公開代理路由。
4. 如果單 Worker 觀測 RSS 有餘裕、低併發 p95 可接受，優先**單程序多模型＋有界 queue**，而不是兩份 TensorFlow 常駐程序。若存在需要以制度版本或 native BBA 獨立隔離的需求，再評估多 Worker。
5. 模型 weights、native BBA/DDS 授權未確認前不得發行；AI 引擎正式對局品質尚未完成就不要聲稱競賽 ready。

## 4. 真實效能證據

**PENDING**：GitHub Actions 完成後須填入 Run ID、測量結果（單/雙 Worker、p95、throughput、RSS峰值）、對照與風險。若任何情境 timeout、非法回應、HTTP error，必須保持 FAIL，不得以單元/Mock PASS 替代。

## 5. 結論範圍

CI Pass 僅能表示指定 GitHub-hosted Runner 上固定版本 **簡化 NN-biased BEN** 的小樣本性能測試成功；正式 4GB VPS 的容量核准、完整 BEN 參數、BBA 授權、真實手機、排行榜正式賽的公平與資安仍需後續 gate。性能研究不應改動 Bridge Core 的叫牌合法性、NS/EW 視角、實際出牌記錄。
