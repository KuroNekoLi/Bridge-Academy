# A4.5 — Release Gate / Codex 後續交接

## 本階段已作
- 只建立靜態 preflight、正負例 unit tests、CI、示例 metadata 與文件。不建置 staging 主機，也不對外啟動目前 loopback Gateway。
- 提供 `docs/product/A4_5_DEPLOYMENT_READINESS.md`、`docs/product/A4_5_COST_CAPACITY_WORKSHEET.md`。任何「preflight PASS」均不等於 hosted HTTPS PASS。

## 開放阻擋項（按推薦實作順序）
1. **A4.5a 安全的 edge staging**：決定有授權的 host/proxy、可信任 TLS、自動續約、真正 Gateway 127.0.0.1 與 BEN 127.0.0.1；健康檢查區分 edge/Gateway/BEN。選擇供應商／是否產生成本，先請 owner 核准。
2. **A4.5b 身分與反濫用**：匿名 practice threat model、token/session/game 隔離，跨 session 拒絕；持久化 user- or IP-scoped quota、防 DDoS、concurrency limit。legacy raw caller-hand 在 staging 必須停用並驗證。
3. **A4.5c 可靠性**：外部 key manager、輪替、可還原 backup、恢復演練、node restart；若要 multi instance，改用有 transaction 的集中式 request ledger，絕不可只讓多個 Gateway 共享本地目錄。
4. **A4.5d 授權**：上游 BEN code、配置、weights、DDS/其他 transitive deps 的具體 license、commercial redistribution/hosting rights、第三方聲明和法律審核。無證據即標 BLOCKED。
5. **A4.5e 現場量測**：在批准的 staging 實際執行 HTTPS Chrome→Gateway→真 BEN、多牌局、故障恢復、不同並發、CPU/RSS/latency/cost。確認監控與關閉開關。
6. **A4.5f 推出決策**：完成 [部署驗收](../product/A4_5_DEPLOYMENT_READINESS.md) 各門檻的證據、設定資訊來源及簽核，再給 PROD_GO；不可以把離線 CI、localhost 或 mock 冒充完成。

## 注意
`scripts/a4_5_preflight.py` 目前只驗證**非秘密、宣告式** metadata。即使使用人為造出的 production metadata 使其 PASS，仍需要上述實證且必須有獨立授權與 owner 決策。Android/iOS 裝置及 A3.5 仍暫緩。
