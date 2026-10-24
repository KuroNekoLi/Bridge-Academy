# M3-F01｜BEN 多制度能力檢查：Capability Declaration ≠ AI Strategy

- Feature ID：**M3-F01**
- Milestone：Multi-System M1.1（技術可行性第一步；不是多制度產品完成）
- 類型：AI 整合／CLI／CI
- 工程狀態：**SCOPED VERIFIED**（Mock HTTP 和固定上游設定檔）；**REAL MODEL NOT RUN**
- 學習狀態：**DELIVERED**（沒有 PRACTICED 或 MASTERED 證據）
- 原始碼：[Probe](../../../scripts/ben_system_probe.py)、[Tests](../../../scripts/test_ben_system_probe.py)、[Workflow](../../../.github/workflows/ben-system-capability.yml)
- 驗收：[研究報告](../../research/BEN_MULTI_SYSTEM_M1_SPIKE.md) ／ [GitHub Actions #40074082688](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40074082688)

## 功能目的與實際情境

你正在做可以選 SAYC、2/1、Precision 的 AI 搭檔。第一個問題並非 Flutter 要如何顯示三個按鈕，而是：**BEN 的伺服器究竟宣告自己可以「打」什麼制度？** 有些 `BEN:` 預訓練模型只能「讀懂／猜對手叫牌」而不能作為我們搭檔的可玩模型，必須嚴格區分 `playsSystems` 與 `readsSystems`。

本輪建立安全、唯讀的 `scripts/ben_system_probe.py`，同時支援靜態 `systems.conf` 審核和本機 BEN `GET /` 能力契約測試。它 **不傳牌、不能證明 AI 真的照該制度叫牌**。

## 主要程式碼導讀

```python
def assess(*, static=None, live=None, required=DEFAULT_REQUIRED):
    normalized = {v.upper() for v in required}
    checks = {}
    successful = True
    for label, evidence in (("static", static), ("live", live)):
        if evidence is None:
            checks[label] = {"status": "NOT_RUN"}
            continue
        missing = sorted(normalized - set(evidence["plays"]))
        errors = evidence.get("errors", [])
        ok = not missing and not errors
        checks[label] = {"status": "PASS" if ok else "FAIL", ...}
        successful = successful and ok
```

上方 `...` 僅為教學時省略報告其他欄位，原始碼請以連結為準。主要入口是 `main()`，輸入是本機 config path 或 loopback origin，然後進入 `inspect_systems_conf()` / `probe_runtime()`，最後交給 `assess()` 產生分離狀態的 JSON 報告。工具不修改任何牌局或模型設定。

請注意 `if evidence is None`：如果沒有啟動真 BEN，它就顯示 `NOT_RUN`，而不是把靜態 PASS 冒充為 live PASS。即使跑了 `GET /`，`realBiddingModelAcceptance` 還是 `NOT_RUN`。

另外 `_loopback_origin()` 強制 HTTP loopback IP、無 path/query/credentials；`_NoRedirect`、`ProxyHandler({})` 預防跳轉／代理；`_names()` 拒絕重複或非法 capability 名稱，`MAX_RESPONSE_BYTES` 限制不受信任資料。

## 為什麼這樣設計

這相當於 Android 專案的 **Capability Negotiation**：App 不能只因 UI 有一個選單，就假設遠端 Server 支援某個 API/Feature。先查詢 Service Capability，確認版本，再送出使用者行動。也類似 Play Services feature availability：裝了套件不是功能就一定可用。

合理替代方案是直接修改 Flutter 切換 `ourSystem=SAYC` 並期待 BEN 接受，但這可能在舊版 BEN 傳回錯誤、沒載入 weights、或悄悄沿用其他模型時造成制度錯誤。先建立 capability gate 比直接加 UI 安全。

常見錯誤：
- `plays=False` 的對手模型被誤當成可玩的搭檔模型。
- `systems.conf` 有名稱，但實體權重缺失／模型啟動 OOM。
- API 只宣告支援叫牌，但沒有證明 `/bid` 在兩套制度真的使用不同語義。
- 把 MockClient 的測試通過當成 AI 神經網路實戰品質。

## 驗證與實際證據

```bash
python -m py_compile scripts/ben_system_probe.py scripts/test_ben_system_probe.py
python -m unittest discover -s scripts -p 'test_ben_system_probe.py' -v
python scripts/ben_system_probe.py --systems-conf third_party_ben/src/config/systems.conf
# BEN 真正啟動後才可另執行：
python scripts/ben_system_probe.py --url http://127.0.0.1:8085/
```

- **EXECUTED/CI PASS**：GitHub Actions #40074082688（Ubuntu 24.04 / Python 3.12）Unit + Mock HTTP 與固定 SHA systems.conf。
- **NOT RUN**：真實 BEN GET /、實際 21GF/SAYC bid、Precision、牌局品質、記憶體。
- 測試資料是完全合成的 `systems.conf` 和本機 HTTP mock，不包含真實權重或用戶牌局。
- 若要取消本輪能力，revert 新 script/test/workflow 即可；不需要動既有 GameState。

## 練習與自我檢驗

**思考題（1 題）：** 假設 BEN 的 `readsSystems` 中有 `BEN:XYZ`，但 `playsSystems` 沒有；玩家在 Flutter 選 `BEN:XYZ` 作自己的叫牌制度時，你應如何處理，為什麼不能只把 `theirSystem` 設成 `BEN:XYZ`？

**5–15 分鐘小練習：** 在 `test_ben_system_probe.py` 新增案例：runtime `playsSystems = ["SAYC"]`、`readsSystems=["SAYC","21GF"]`，確保要求兩制度的 `assess()` 回報 `FAIL` 且缺 `21GF`。

**完成標準：** 能區分靜態 config、服務宣告及真實模型行為，並解釋 `playsSystems` vs `readsSystems`；完成練習前學習狀態維持 DELIVERED。

## 下一步

M1.2 在隔離環境安裝固定 BEN 新版及授權可用的權重，實際查 `GET /` 並測記憶體，再進入 M1.3 的真實 `/bid` 固定牌局 A/B 測試。不可跳過權重／授權與模型版本核對。
