# M3-F02｜把 BEN 新版放進隔離環境：模型釘選與真服務驗收

- Feature ID：M3-F02
- Milestone：三制度 AI / M1.2
- 類型：AI 整合／GitHub Actions／供應鏈追蹤
- 工程狀態：**SCOPED VERIFIED**（真實 BEN GET / 啟動與模型清冊通過；制度 /bid 與授權 NOT VERIFIED）
- 學習狀態：**DELIVERED**
- 原始碼：[inventory script](../../../scripts/ben_m12_inventory.py)、[unit tests](../../../scripts/test_ben_m12_inventory.py)、[isolated BEN CI](../../../.github/workflows/ben-m12-isolated-runtime.yml)
- 驗收與測試：Ubuntu 24.04 Python 3.12、固定 BEN `ad8608af...`；[CI Workflow](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/ben-m12-isolated-runtime.yml)。[CI #40075250217](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40075250217) 實際完成：8/8 inventory 測試、12/12 capability 測試、固定 BEN 真服務 GET / PASS；RSS 899920 KiB（約 879 MiB）、啟動 9.03 秒。

## 功能目的與實際情境

Bridge Academy 已經能用 BEN 完整打一副牌，但舊 BEN 固定版本不代表目前的新版 BEN 多制度模型已安裝。此功能獨立 checkout 新版 BEN，記錄實際載入模型所依賴的檔案 SHA-256，再嘗試啟動真正的 `gameapi.py`、只查安全的 `GET /` 能力，不改動既有正式服務。

也就是說，M1.2 解決「**我部署的究竟是哪一份模型？它能否啟動並宣告所需功能？**」，還沒有解決「叫得好不好？」（M1.3）。

## 主要程式碼導讀

來源：[ben_m12_inventory.py](../../../scripts/ben_m12_inventory.py)

```python
def digest_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()
```

這段用 1 MiB 的 chunk 串流計算 SHA-256，而不是把每個模型權重全部讀進記憶體。它產生 **模型版本的內容指紋**，並不驗證模型數學內容或授權。

真實流程是 `inspect()` 驗證固定 `EXPECTED_BEN_SHA` → 讀 `systems.conf` → 逐一查找所有（不只是 21GF/SAYC）已宣告的 bidder/info/card 檔案 → 計算 digest → 紀錄第三方 Native DDS/BBA/PIMC 等依賴。若找不到或路徑跳脫即 fail closed，不將失敗檔案標為成功。

注意 Git Commit SHA 和單檔 SHA-256 不一樣：前者是完整 Git 版本位置，後者是單檔內容驗證；兩者搭配才有利於重現。授權檢查又是第三個彼此獨立的問題。

## 為什麼這樣設計

對 Android 開發者來說，類似用 Gradle Version Catalog + Dependency Locking + checksum verification 確保 release build 取到正確 dependency；不能只寫 `implementation("x:y:latest")` 就假定執行環境一定使用經審核版本。

不用立即修改 `packages/bridge_ben_adapter`、`services/bridge_gateway` 是因為先把供應鏈、權重與 runtime 準備好，才能在 M1.3 對照真正模型叫牌，而不會把服務配置故障誤判為叫牌策略故障。

一個合理替代是將新 BEN 直接覆蓋既有 CI 的老權重，但風險是讓先前驗證的固定牌局測試失去可追溯比較基準，所以不採用。

## 驗證與實際證據

```sh
python -m unittest discover -s scripts -p 'test_ben_m12_inventory.py' -v
python scripts/ben_m12_inventory.py --ben-root third_party_ben_m12 \
  --commit ad8608af6e6bfe095863023f344f3cb2cbafec3d
python scripts/ben_system_probe.py \
  --systems-conf third_party_ben_m12/src/config/systems.conf \
  --url http://127.0.0.1:8085/
```

最後一條需先完成真 BEN 隔離啟動。沒有真服務時必須失敗；即使有 `GET /`，**真 BEN 21GF/SAYC `/bid` 仍是 NOT RUN**，不可標成 AI 策略驗收通過。

證據：[M1.2 Acceptance](../../research/BEN_MULTI_SYSTEM_M1_2_ACCEPTANCE.md)；[Pinned SHA256](../../research/BEN_M12_PINNED_ASSETS.md)。GitHub Actions [#40075250217](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40075250217) 已通過 scoped 真實啟動；CI 會產生只包含 digest/模型名稱/時間/RSS 的短期 JSON 工件，但不會上傳第三方權重或包含手牌的原始伺服器 log。

## 練習與自我檢驗

**思考題（1 題）：** 假設兩次 CI 都取得同一個 `systems.conf`，但 SAYC 權重 SHA-256 不同，應該允許它們算作同一版本的 AI 嗎？為什麼？

**5–15 分鐘小練習（可選）：** 打開 `scripts/test_ben_m12_inventory.py`，看看 `test_digest_changes_when_weight_changes` 如何驗證不同權重必須產生不同 SHA；再想一下缺少 BBA 原生庫時，在本輪不執行 BBA 的情況下應如何報告。

**完成標準：** 能說明固定版本、模型清冊、真的能啟動、策略品質、第三方授權是五個不同的驗收問題。答題前學習狀態為 DELIVERED。

## 下一步

M1.3 在單一 `PlayerView` 的合法資訊範圍內執行不同 `ourSystem` 的真實 `/bid` 對照。M1.4 再研究多種制度載入記憶體、4GB VPS 能否部署及併發公平性。
