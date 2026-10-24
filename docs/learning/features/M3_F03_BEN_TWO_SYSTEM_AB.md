# M3-F03｜BEN 2/1 與 SAYC A/B：為何「選了模型」還不等於懂制度？

- Feature ID：M3-F03
- Milestone：三制度 AI / M1.3
- 類型：AI 真實模型整合／叫牌制度
- 工程狀態：**SCOPED VERIFIED**（實際 BEN /bid；16 未專審情境，不是制度完整審核）
- 學習狀態：**DELIVERED**
- 原始碼：[Benchmark](../../../scripts/ben_multisystem_benchmark.py) · [Fixed fixtures](../../../scripts/fixtures/ben_multisystem_m13.json) · [Tests](../../../scripts/test_ben_multisystem_benchmark.py) · [CI](../../../.github/workflows/ben-m13-m14.yml)
- 驗收：[M1.3 Acceptance](../../research/BEN_MULTI_SYSTEM_M1_3_ACCEPTANCE.md) / [CI #40076200888](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40076200888)

## 功能目的與實際情境

玩家選 2/1 Game Force 與 SAYC 時，搭檔叫牌必須由對應的真實 AI 模型推論，而不只是 Flutter 文案改了。M1.3 對一樣的單手牌、公開叫牌歷史、發牌者、位置與身價，分別送出 `ourSystem=21GF`／`SAYC`，核對是否真的回應、是否有合法格式、迫叫序列是否異常。對未知制度必須回 400，不可以改用預設 GIB。

## 主要程式碼導讀

來源 `scripts/ben_multisystem_benchmark.py` 的核心請求：

```python
def query_bid(url: str, fixture: dict, system: str, *, timeout: float) -> dict:
    q = {k: fixture[k] for k in ("hand", "seat", "dealer", "vul", "ctx")}
    q.update({"ourSystem": system, "theirSystem": "21GF", "matchtype": "IMP"})
    started = time.perf_counter()
    data = get_json(url, "/bid", q, timeout=timeout)
    ms = (time.perf_counter() - started) * 1000.0
    bid = data.get("bid")
    if not isinstance(bid, str) or not legal_next(fixture["ctx"], bid):
        raise BenchmarkError("BEN returned missing or illegal auction proposal")
    return {"fixture": fixture["id"], "system": system, "bid": bid,
            "latencyMs": round(ms, 1), "legalPrecheck": True}
```

資料流是固定 public/test fixture → explicit system-specific Request → 真實 BEN Response → 最低限度合法性驗證 → redacted result。特別重要：`query_bid()` 不允許在報告中寫入 `q`，因為這裡包含使用者或機器人的 private hand；本輪用的是合成測試牌。

## 為什麼這樣設計

這類似 Android/Kotlin 的 Repository Pattern + Strategy Pattern：UI 的 `selectedStrategy` 要真正傳入對應的資料來源／策略引擎，而不能只改選單的文字。**正確的 request routing 是必要條件，但不是制度正確性的充分條件。**

本輪觀察到：16 個固定情境 × 2 系統 = 32 次真 BEN 請求全成功、0 非法叫品、3 個指定 forcing cases 沒有 PASS 違規，其中在 `1S–P–2H–P` 情境出現 `21GF=4H` 與 `SAYC=3H`。這僅證明**兩模型能產生不同行為**；是否為最佳叫品需橋牌專家或可信的黃金答案及更多牌局審查。

另一個替代方案是直接相信 BBA 文案「本張是 2/1」，但 B3.2 既有 `ConventionProfile` 是顯示用途，不能據此推論 NN 模型已遵守。

## 驗證與實際證據

```bash
python -m unittest discover -s scripts -p 'test_ben_multisystem_benchmark.py' -v
# 真 BEN 先於本機 127.0.0.1:8085 啟動
python scripts/ben_multisystem_benchmark.py \
  --mode m13 --url http://127.0.0.1:8085/ \
  --fixtures scripts/fixtures/ben_multisystem_m13.json \
  --output m13-results.json
```

**EXECUTED / GENUINE BEN PASS**：[CI #40076200888](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40076200888)，Python 3.12.15、TF 2.21.0、Keras 3.15.1；21GF 與 SAYC 共 32 次，0 個 forcing 違規、1 個叫品差異，回應 p50 分別 26.3/27.7 ms、p95 532.6/514.1 ms。詳細限制見 [M1.3 研究報告](../../research/BEN_MULTI_SYSTEM_M1_3_ACCEPTANCE.md)。

**NOT DONE**：100+ 專家簽核 fixture、Bridge Core 逐動作回放、完整出牌、完整 BEN BBA/PIMC 配置、Precision。此功能不代表三制度已在 Flutter 可選。

## 練習與自我檢驗

**思考題（1 題）：** 假設 `21GF` 和 `SAYC` 在 16 副牌全部叫出相同叫品，你會將 M1.3 判 FAIL 嗎？應如何證明「兩套制度」的不同語義？

**5–15 分鐘小練習（可選）：** 讀 `test_real_bid_invalid_response_must_fail`，新增測試確保當 BEN 對下游返回 `{"bid": "1C"}` 而當前最高叫品是 `1S` 時會被拒絕。

**完成標準：** 可清楚區分「真模型有回應」、「符合基本叫牌合法性」、「符合搭檔約定」、「策略效果良好」四層證據；沒有答題證據前仍是 DELIVERED。

## 下一步

M1.4 控制資源成本；M2 將選定制度寫成 server-owned、不可變 GameSystems，讓 BEN Adapter、Gateway 與 Flutter 真正端到端統一。