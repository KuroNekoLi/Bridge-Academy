# 發布／部署前必須通過的關卡

> 截至 2026-10-26，Bridge Academy **尚未獲准公開 Production 上線**。工程測試通過、GitHub Runner 能跑 BEN、研究版 Precision 能完成一局都不能替代下面的門檻。本文是下一步 release 依據，不是已通過報告。

| 關卡 | 產品 release 必須提交的證據 | 現況 |
| --- | --- | --- |
| 核心橋牌規則 | 完整 Pass Out/X/XX／Follow-suit、決定方、13 墩／計分回歸 | 已有 Core CI，仍需發行 SHA 回歸 |
| 真實玩家完整牌局 | 最少多張不同莊家／身價的四局以上真 BEN，固定與隨機牌 | 隔離真模型 CI 有；**公開服務 NOT RUN** |
| UX 與可用性 A3.5 | 真玩家、320/375/768/1280px、輔具／動畫／失敗處理 | **OWNER HOLD**；U3 尚未完成 |
| Android/iOS | 指定實機與 emulator 的生命週期、加密儲存、背景恢復、觸控及輔具 | **OWNER HOLD**，禁止無批准啟動 |
| Server 安全 A4.5 | HTTPS TLS／allowed origins、可信身份、原始私牌只走受權私路由、外部金鑰、異常限流／WAF、禁止 debug 端點 | **NO-GO** |
| Server durability | expired bearer、CAS/ID 重試、重啟／多節點同時事件、備份／還原與 RTO/RPO | **單節點研究版通過，跨節點 NOT RUN** |
| BEN 及本機 native 著作權 | 原始碼、模型 weights、BBA/EPBot、DDS、Flutter assets 的逐項商用 hosting／再散布許可與 notice | **未完成核准清單** |
| 實際部署容量 | 目標 2 vCPU／4GB 機器下 1/2/4/8 並發、真 bid+lead+play、冷啟、持續壓力、RPS／p95／RSS／CPU、故障恢復 | GitHub CI 樣本通過；**VPS NOT TESTED** |
| 精準制牌力 | 專家 Golden、完整同牌比較 MP/IMP、非全知合法訓練策略、對手推斷與進局成功率 | **研究 only / NO-GO** |
| 自訂 AI 制度 | 引擎能力／SHA、可玩模型、對手 reader、迫叫／競叫／Alert Golden | **草稿功能有，執行引擎 NOT VERIFIED** |
| 教練的建議 | 每個說明有來源；最佳叫品須有可重現 AI／專家證據 | **目前只提供公開證據，完整 Coach NO-GO** |
| 排名賽／多人 | 不變的 server BoardSet、跨人一致的 MP/IMP baseline、反作弊、角色／私牌權限 | **NOT IMPLEMENTED** |

## 容量採樣格式

固定測試環境、BEN 與 native/model SHA、模擬參數；記錄完整 13 墩的 `/bid`/`lead`/`play` 各自 P50/P95/P99、秒數、成功/失敗、timeout、CPU time、程序 RSS 峰值、系統 RAM、gateway / database / proxy 開銷；獨立測 1/2/4/8 併發與至少 30 副牌／組。成本須寫來源日期、幣別、帳單項、請求量與餘裕，不得猜測免費。

研究版 BEN 单程序約 1 GiB RSS、雙程序約 2 GiB 是**GitHub Ubuntu Runner 小樣本 NN-biased**，不是目標 VPS 的保證；採樣細節見 [BEN 報告](../research/BEN_SYSTEMS.md)／[營運研究](../research/OPERATIONS_AND_LICENSES.md)。

## 目前明確禁止

不得恢復 owner-held Android/iOS／A3.5 QA；不得公開 localhost BEN/Gateway、把私牌與 token 放在 URL／logs；不得在未核可第三方權重及 native binary 前發行；不得稱自訂草稿已影響 BEN，亦不得將非排名每日練習稱作公平比較的積分賽。

**重新准入流程：** 每個待測關卡都記實際環境／SHA／fixture 與結論，明確區分 PASS／FAILED／BLOCKED／NOT RUN，經 owner 確認後才更新正式 release 狀態。