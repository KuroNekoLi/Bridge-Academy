# A4.5 — HTTPS / BEN 部署準備與 Release Gate

**日期：2026-10-17。狀態：STATIC PREPARATION VERIFIED（[GitHub Actions #38983766063](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38983766063) PASS）；HOSTED STAGING/PRODUCTION NOT DEPLOYED / NOT VERIFIED。**

## 本輪交付
- `scripts/a4_5_preflight.py`：不接觸秘密、不連網的部署設定 allowlist 與 fail-closed 檢查。只能確認*宣告的設定*是否符合最低條件，**不能證明**配置實際生效或 TLS 安全。
- `deploy/a4_5/staging.metadata.example.json`：非秘密、示範用 .invalid 網域；**不是可直接運行的反向代理或雲端部署設定**。
- `.github/workflows/a4-5-deployment-readiness.yml`：新分支與 master 的靜態驗證、自動測試、對 production profile 強制負例。
- `docs/product/A4_5_COST_CAPACITY_WORKSHEET.md`：成本/延遲採樣方法，沒有假設價格或虛構效能。
- `docs/handoff/A4_5_RELEASE_GATES.md`：正式 staging / production 上線前的阻擋條件。

## 既有能力與真實限制
現有 `services/bridge_gateway/bin/serve.dart` 總是只綁 `127.0.0.1`；`BridgeGatewayService.start()` 拒絕非 loopback 地址。 BEN `BEN_INTERNAL_ORIGIN` 也必須是 loopback HTTP。這是現有安全邊界，**本次沒有移除**。

Gateway server-side Bridge Core authority、同一 request ID 幂等、15 分鐘匿名 bearer、本機加密 checkpoint、現有 BEN Worker 與 A6 多副驗收存在；但沒有 TLS termination、正式身分／座位權限、集中式 rate limiting、multi-instance exactly-once、production key rotation、public hosting、license/weights 核准或負載壓測。匿名 capability 不等於玩家身分驗證或可承諾的比賽公平性。A6 測試的多副結果不等於正式容量驗收。

## 目標拓撲（**設計參考，未部署**）
```text
Browser (HTTPS only)
    |
    v
Approved TLS edge / reverse proxy [future: cert auto-renew, HSTS, WAF, rate limit]
    |
    +--> (private loopback, same trusted host) Dart Gateway :8086
                  |
                  +--> (private loopback) Pinned genuine BEN :8085
                  |
                  +--> (external key + private file permissions) encrypted checkpoint
```
- 只有 edge 可接受外部連線。BEN 與 Gateway 不得公開監聽。封鎖外部 8085/8086，監控 /healthz 僅用於 liveness，不是 readiness 成功或 BEN 健康證明。
- 前端固定 HTTPS Origin；瀏覽器 Access-Control-Allow-Origin 僅白名單、無 wildcard；CORS **不是**認證手段。所有 secret 以部署平台 Secret Manager 注入，不寫入 JSON、Dart define、Web bundle、image layer、GitHub Action log。
- 公開 staging 之前，必須實作/驗證防濫用、以同一使用者/牌局授權範圍綁定 session、可靠的 token 到期處置以及加密 checkpoint 的 key rotation／備份策略。
- 若要維持單 instance，應明示無 HA/停機風險、使用者可接受的資料保留條款，並做斷電/中止負例；**不能**把開發用 atomic rename 宣稱為跨節點永久性保證。

## 人工 staging 驗收清單（未執行）
1. 經核准的 domain、DNS、TLS 有效憑證、續期、TLS 設定與 HSTS；只有 HTTPS 對外，HTTP 301/308 且無敏感資料經 HTTP。
2. 外部直接連 8085/8086 拒絕；測試非法 Origin、偽造 forwarded headers、過期 token、跨 session、重送 request ID、權限繞過、匿名濫用、錯誤日誌衛生。
3. 在 staging 跑真 BEN 4+ 固定牌局、一般 Chrome-to-HTTPS Gateway-to-BEN 操作、逾時與恢復、負載 p50/p95/p99、RSS、request/seat concurrency、恢復 RTO/RPO。
4. 確認發行權利：上游 BEN 程式碼、模型權重、推論依賴、DDS（如果與服務一起發行）的 license、來源與再分發權由負責人逐項簽核；不能僅因原始碼公開就視為有權商用。
5. 估算每局最大推論 CPU／記憶體／頻寬與成本上限；提供日/月預算、警示與緊急停用。無上限服務不得公開。
6. 演練密鑰輪替／備份恢復、暴露事件緊急處理、服務回退、資料刪除與瀏覽器錯誤 UI，不開啟被 owner 暫停的 Android/iOS 裝置驗收。

## 指令
```bash
python3 -m unittest discover -s scripts -p 'test_a4_5_preflight.py' -v
python3 scripts/a4_5_preflight.py --profile staging --config deploy/a4_5/staging.metadata.example.json
python3 scripts/a4_5_preflight.py --profile production --config deploy/a4_5/staging.metadata.example.json
# 最後一行應回傳 1，表示目前配置禁止 production
```

**合格定義**：只是 STATIC SAFETY PRECHECK，不包含任何免費／付費雲端服務操作或公開發布。正式 staging 與 production 必須各自有真實執行證據與人工核准。A3.5 和 Android/iOS 裝置 QA 按使用者要求保持暫停。

## 實際驗證證據
- [A4.5 Deployment Readiness CI #38983766063](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38983766063) **SUCCESS**, source SHA `da8978841a32303c084e8e9f35024806e4188b45`. `python3 -m unittest discover`、staging metadata positive static validation、production-profile fail-closed check 均成功。
- 此驗證**沒有** TLS edge、真 BEN staging HTTP 呼叫、負載測量、外部模型授權審查、金鑰輪換實測。不可把此 CI 當作 production-ready。
