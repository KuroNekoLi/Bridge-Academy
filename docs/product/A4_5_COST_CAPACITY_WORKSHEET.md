# A4.5 — 成本與容量驗收工作表

**狀態：尚無正式 hosted BEN 的觀測樣本、供應商報價或容量上限，因此不能填入虛構數字。**

## 採樣表（每組不同 concurrency × fixed board fixture 各收集 n >= 30）
| 環境 / 版號 | 牌局數 | BEN commit / config | 並行牌局 | bid/lead/play calls | p50/p95/p99 end-to-end | p50/p95 BEN only | max RSS | fail/429/5xx/timeout | RTO/RPO |
|---|---:|---|---:|---|---|---|---|---|---|
| 待實測 | — | 固定 SHA / 配置 | 1,2,4,8（僅目標，非已通過） | — | — | — | — | — | — |

## 估算方法
- 每局模型資源 = 真 BEN bid + lead + play 的實際 CPU seconds、峰值 RSS、啟動/載入模型時間；計時分開排除安裝依賴。從 A6 的固定樣本結果延伸，不把 CI runner 值直接當 production SLA。
- `monthlyCompute = provisionedHours × hourlyPrice`；`monthlyVariable = completedBoards × measuredRequestsPerBoard × variablePricePerRequest`；另計 TLS edge、流量、存放/備份、監控、日誌、憑證、故障預備與非預期頻寬。
- 要有預期每日/峰值 DAU、每人每日牌數、每局 API requests、尖峰同時執行、retry 增幅和緊急額度。成本估算需寫來源日期、幣別與實際供應商方案，不能直接宣稱免費。
- 性能與可用性門檻由產品負責人另定，驗證之前 status = BLOCKED。

## 運營風險
- 同一匿名 bearer 的 30/min 研發配額不等於可支援完整牌局的 production quota；現有 localhost 180/min override 更不是 production 限額。
- 同機 BEN 的 CPU/RAM 若飽和，增加同時連線不會線性提升吞吐量。以 queue depth、timeouts 和經驗模型決定 admission control。
- 所有測量只能輸出耗時與安全識別碼，不記錄 token、原手牌、完整 PBN、密鑰或上游原始 HTTP body。
