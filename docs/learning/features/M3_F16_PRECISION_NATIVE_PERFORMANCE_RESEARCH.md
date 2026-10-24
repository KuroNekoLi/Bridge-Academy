# M3-F16｜M3.5 用真 EPBot 做可重現的 1,000 次叫牌測量

- Feature ID：M3-F16
- Milestone：M3.5 Native Performance Research
- 類型：基準測試、效能指標、失敗率與 release gate
- 工程狀態：**SCOPED VERIFIED**（1000 原生叫牌與穩定性；非 1000 完整牌局）
- 學習狀態：**DELIVERED**
- 原始碼：[performance runner](../../../scripts/precision_m35_evaluate.py) · [reproducible CI](../../../.github/workflows/precision-m34-m35-research.yml)
- 驗收與測試：[M3.5 報告](../../research/M3_5_PRECISION_BENCHMARK_AND_RELEASE_GATE.md) · [CI #40102968596](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40102968596)

## 功能目的與實際情境

原生 EPBot 能跑 8 組牌例，並不代表它能承受長時間多次呼叫。M3.5 先以固定 seed 從標準 52 張牌中抽出單家 13 張手牌，對 NS 精準制／EW SAYC 與相反配置各 500 次，記錄真正 Native sidecar 的 latency 與錯誤率。因未組合完整四家 Deal，這項測試用語必須是「1,000 次開叫」，不可誤報成「1,000 場對局」。

## 主要程式碼導讀

`shuffled_hand(seed)` 對已知 52 張標準牌做固定亂數排列，每組取 13 張，BBA 只獲得 actor hand。`benchmark()` 執行 1,000 個 `table-bid` POST，並記錄 `time.monotonic_ns()`、HTTP 成功／失敗、per-side 數量、proposal histogram。最後用 `/proc/<pid>/status` 擷取 `VmRSS` 與 `VmHWM`；報表保留 `competitiveStrengthValidated=false` 與 `target4GbVpsLoadValidated=false`，避免 CI 成功變成產品上線的假證據。

## 為什麼這樣設計

性能測試要將「服務延遲」、「模型品質」與「目標設備運行」分開：即使 GitHub Runner 的單線程 P95 很好，也不等於 4GB VPS 上多使用者 BEN TensorFlow + EPBot + MySQL 的延遲可接受。尤其 `VmSize`（虛擬位址空間）和 RSS（實際駐留 RAM）不同，不可以把 VmSize 當記憶體實耗。

替代方式是測試 40 次便推估 1000 次；這沒有長時間穩定性證據，因此這輪在 isolated CI 實際量測 1,000 次，但仍沒有負載 2/4/8 同時請求的併發測試。

## 驗證與實際證據

```bash
python scripts/precision_m35_evaluate.py \
  --port 18088 --cases 1000 --pid "$BBA_RESEARCH_PID" \
  --output /tmp/m35-report.json
```

GitHub Actions [#40102968596](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40102968596) 真 BBA 結果：1000/1000 成功；NS/EW 各 500；P50 9.46ms、P95 12.96ms、max 51.64ms；VmRSS/VmHWM 79,220 KiB。最新重跑 [#40103865733](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40103865733) 仍為 1000/1000，P50=7.05ms、P95=10.03ms、max=43.59ms、VmRSS/HWM=79,816 KiB；以兩次 CI 差異說明延遲有測量波動。這些數字只適用於指定 CI，benchmark `fullBridgeDeals=0`、expert 叫牌正確性與目標 VPS 測試未執行；另有四場獨立固定 PBN 研究全局。

## 練習與自我檢驗

**思考題（1 題）：** 在你的 4GB VPS，為什麼 80 MiB 的 EPBot RSS 並不能證明 BEN + MySQL + Gateway 一起執行就有足夠記憶體？
**5–15 分鐘小練習（可選）：** 將 CI 腳本 cases 減成 20，解釋為什麼估計的 P95 可能更不穩定，以及跑測試是否需要先固定 seed。
**完成標準：** 理解 benchmark 的資料範圍、latency percentile、記憶體與 release gate 是不同的證據。

## 下一步

M3.5 發行完成還缺 expert-reviewed goldens、真實全局強度比較、並發與目標 VPS 壓測、TLS/裝置 QA。不要把研究基準數字當正式 SLA。
