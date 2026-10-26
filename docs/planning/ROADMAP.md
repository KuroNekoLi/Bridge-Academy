# 接下來如何開發 Bridge Academy

> 2026-10-26 產品路線（**優先順序**），已完成成果不再複寫在本文。請先讀 [目前已有功能](../implemented/FEATURES.md)、[發行關卡](RELEASE_CHECKLIST.md)，再挑選下一項小任務。此路線不授權解除 owner-held QA、購買主機或發布服務。

## 下一個應做的功能

### U3｜牌桌操作、動畫與窄屏完整體驗（目前最高 UI 優先）

**前置已完成：** U1 練習工作區、U2 共用可見牌面、U3.1 橫向手牌列。

**待做：** 320／375／768／1280px 的可操作單屏牌桌，合法目標點選與可選拖曳、可中止選牌／出牌飛行／收墩動畫、等待與取消態、降低動態效果設定、長字體及鍵盤／輔助技術。不要讓展示動畫拖延回合／重複 submit，不能偷看暗牌。

**收斂標準：** 同一版 Web、Flutter 測試可完成 52 張／13 墩，請求失敗可復原，視覺／可及性無誤；**A3.5 使用者／裝置 QA 仍 OWNER HOLD**，未解禁前不可稱產品級體驗驗收。

### U4｜正式的續局、歷史及產品動線

確定 Gateway 受保護的續局協定（expired/revoked bearer、同 action ID 重試、版本衝突、UI 上清楚的模式來源）；處理「關頁→重新取得授權→同一局」的安全重啟。再提供經授權的雲端已完局清單、留存／刪除政策與清楚的 redo/new board 分隔。現有本機 history、加密 checkpoint 不等於雲端服務。

### A4.5｜BEN 正式託管的安全／成本／權利證據

固定 BEN 模型與版本、license／native binaries／資產 provenance、TLS／身份／密鑰輪替、session 限流、監控／備份、目標 VPS 的實際 CPU/RAM／多 Worker 長時壓測。4GB VPS 尚未 GO；優先評估**單 Worker 多制度+有界 queue**，必須以主機實測決定。不可對外公開目前 loopback Gateway 或傳輸原始私牌 URL。

### A7｜玩家、輔具與裝置發行驗收

A3.5 玩家體驗、全 Web 發行安全與實機長期儲存測試。**Android 模擬器／Android 與 iOS 實機 QA 使用者暫緩**；沒有明確後續批准就不執行，也不可把此 gate 劃為 PASS。

## 可與 UX 並行的技術／教學軌

| 軌道 | 已完成的工程基礎 | 待做／禁止誤稱 |
| --- | --- | --- |
| 2/1、SAYC（M2） | NS／EW 真 BEN 路由與兩局完整技術驗收 | 100+ 專家審核叫牌、全面競叫及解釋品質評比；不是另做一次模型選單 |
| Precision（M3） | BBA Meckwell V1 native sidecar、研究出價與混搭研究性合法出牌 | 專家 Golden corpus、自然牌力／同牌公平 benchmark、完整服務權利；不公開排名 |
| 自訂約定（M4） | 可編輯／保存／差異／審查待辦，Gateway 安全拒絕未認證草稿 | 版本綁定可執行 provider／opponent reader、forcing／競叫／alert／例外與 100+ 專家驗證；沒有證據不改 AI |
| 叫牌教練（M5） | 公開叫牌來源＋雙語草稿意義，未知即 UNKNOWN | 真 BEN/BBA 候選叫品與可複驗解釋、專家評分；不得捏造 AI 私有推理 |
| 比賽（D / M6） | 本機未排名每日練習 | Server-owned 同牌比較、MP/IMP、排行榜與反作弊；非短期優先 |
| 多人（E） | 單人與原生 AI 引擎 | 房間、座位驗證、斷線重連、旁觀私牌保護、會話一致性，待先完成營運基礎 |

## 工作排序建議與停損

`U3 → U4 security/remote-history → A4.5 hosted real BEN → A7 release validation → AI quality → ranked duplicate → live multiplayer`；獨立研究可並行，但不得為進度先解除安全門檻。

開始每個功能前：對照最新 `master` 原始碼與 CI，寫最小驗收、更新 [功能表](../implemented/FEATURES.md)、[工程筆記](../implemented/ENGINEERING_NOTES.md)。完成技術測試只標 **SCOPED VERIFIED**；涉及正式上線時由 [RELEASE_CHECKLIST](RELEASE_CHECKLIST.md) 逐項放行。