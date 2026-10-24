# M3-F04｜BEN 的記憶體與延遲：單 Worker 還是雙 Worker？

- Feature ID：M3-F04
- Milestone：三制度 AI / M1.4
- 類型：系統效能／容量與架構決策
- 工程狀態：**SCOPED VERIFIED**（GitHub Runner 真實模型的短時間樣本；OVH VPS 未實測）
- 學習狀態：**DELIVERED**
- 原始碼：[Benchmark](../../../scripts/ben_multisystem_benchmark.py) · [Tests](../../../scripts/test_ben_multisystem_benchmark.py) · [CI](../../../.github/workflows/ben-m13-m14.yml)
- 驗收：[M1.4 Capacity](../../research/BEN_MULTI_SYSTEM_M1_4_CAPACITY.md) / [CI #40076200888](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40076200888)

## 功能目的與實際情境

使用者希望在 Bridge Academy 選 2/1、SAYC，未來還要 Precision。模型可能常駐多份；即使叫牌速度快，RAM 也可能使同機 MySQL、Gateway、Reverse Proxy 受到 OOM kill。M1.4 用 **同一個真實 BEN 版本**對照單 Worker 多制度和兩個獨立 Worker，量 p50／p95／p99 latency、throughput、實際 process RSS。

## 主要程式碼導讀

來源：`scripts/ben_multisystem_benchmark.py`。

```python
def read_rss(pid: int) -> int:
    """KiB, including real process memory; no assumption about target VPS."""
    try:
        for line in Path(f"/proc/{pid}/status").read_text().splitlines():
            if line.startswith("VmRSS:"):
                return int(line.split()[1])
    except (OSError, ValueError):
        pass
    return 0
```

另一個重要函式 `run_m14()` 使用 `ThreadPoolExecutor(max_workers=1/2/4)` 比較不同 request concurrency，並以每 0.1 秒 daemon thread 對兩個 BEN Python PID 取樣，將觀測峰值記入 `observedRss`。CI 先使用 `exec python gameapi.py`，避免當年 M1.2 初期曾誤量到 Bash PID 的問題。

## 為什麼這樣設計

可類比 Android 的 Perfetto／Android Studio Memory Profiler：快的單次操作不代表長期記憶體、背景執行、不同手機仍正確。要區分 **warm inference latency**、冷啟模型載入、並行服務時排隊時間，以及部署機器的總 RAM budget。

對不同併行度不要只看 req/s。CI 測得同一 Worker：concurrency 1/2/4 的 p50 約 26.0/35.3/78.7 ms，而 p95 為 89.2/98.2/126.1 ms，增加併行可能提高 throughput，但每個使用者感受到的延遲反而增加。

替代方案是每個叫牌制度各跑一個 BEN Worker；在本輪，雙程序觀測 RSS 合計約 1.95 GiB，單個約 1.01 GiB，代表分開程序會增加常駐記憶體。此觀察支援先測 **單 Worker 多制度＋bounded concurrency**。

## 驗證與實際證據

```bash
python scripts/ben_multisystem_benchmark.py --mode m14 \
  --url http://127.0.0.1:8085/ --pid "$BEN_PRIMARY_PID" \
  --secondary-url http://127.0.0.1:8087/ \
  --secondary-pid "$BEN_SECONDARY_PID" --rounds 2 \
  --output m14-results.json
```

**EXECUTED / CI PASS**：[CI #40076200888](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40076200888)；每個併發度 16 次真 `/bid`，雙 Worker 16 次，sampling 28 次。主程序觀測峰值 `1,059,016 KiB`、次程序 `981,420 KiB`、合併觀測峰值 `2,040,048 KiB`。

**CPU 計時補充：** [實際 CI #40076825813](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40076825813) 測得 Primary BEN 的 user+system CPU 時間 1.82 秒（測試期間約 65.4% 單核心），Secondary 1.34 秒（約 48.1% 單核心）。它是程序 CPU 時間，不是 OVHcloud 2 vCPU/4GB 主機使用率。請分別看待 CPU、RSS、服務延遲及其取樣區間。

**限制**：使用 NN-biased BEN 配置，BBA/PIMC/SuitC 關閉，GitHub Runner 不是 2 vCPU／4GB OVH 主機；未測長時間、較高同時人數、全部獨立服務的 memory budget、正式安全與授權。故正式 VPS 仍為 **NO-GO（尚未核准）**，不是「已證明 4GB 必定不夠」。

## 練習與自我檢驗

**思考題（1 題）：** 假設單 BEN Worker RSS 約 1.0 GiB，雙 Worker 約 2.0 GiB；在一台還要跑 MySQL、Gateway 的 4GB VPS 上，你會採用什麼設定？還要額外量測哪些資源，才能對 Production 說 GO？

**5–15 分鐘小練習（可選）：** 根據 [M1.4 報告](../../research/BEN_MULTI_SYSTEM_M1_4_CAPACITY.md) 的 p50/p95，說明提高 concurrency 時 throughput 變高但 p95 也變差的原因。

**完成標準：** 能分清 benchmark 樣本、觀察 RSS 峰值與實際 OOM 風險，不將測試機數據直接外推到 Production。作答前為 DELIVERED。

## 下一步

M2 將多制度 selection 透過 Gateway server-owned GameSystems 固定版本並限流，接著才能以正式環境依實際 CPU/RAM 做產品放行測試。