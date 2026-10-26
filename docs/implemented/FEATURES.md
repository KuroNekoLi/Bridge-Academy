# 已實作功能（截至 2026-10-26）

> 「工程測試通過」不代表「已公開部署」；「研究可用」也不代表正式產品功能。

## 橋牌核心與資料安全
- **Bridge Core**：四家各 13 張牌、叫牌／Pass／Double／Redouble、合法跟牌、13 墩、定約、Pass Out、Duplicate NS 視角計分。程式：[bridge_core](../../packages/bridge_core/)；[CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/bridge-core.yml)。
- **牌局管理**：Board 編號、莊家與身價 16 局循環、固定牌局／新牌局、下一局、完成事件回放。
- **可見資訊隔離**：`PlayerView` 只顯示自己有權看的牌；明手依遊戲階段揭露，AI 請求不得偷看其他手牌。
- **本機儲存**：事件／版本校驗、未完牌 checkpoint、損毀回退與使用者通知；原生加密 SQLite 與瀏覽器加密 checkpoint 有分開驗收。未證明任意裝置斷電或雲端跨實例保證。

## Flutter 玩家可操作功能

| 領域 | 已實現 |
| --- | --- |
| 打牌 | 四座位牌桌、叫牌盒、點牌操作、本機 Demo 或明確選取的 Gateway Session、叫牌時顯示自己的牌 |
| 桌面／手機呈現 | 打牌／學院／本機複盤／我的導覽、保留 active session、練習入口、重開未完牌確認、桌面與窄屏水平手牌列 |
| 無障礙與雙語 | 中英介面、語義標籤、按牌大小和鍵盤操作的 scoped 測試 |
| 練習 | 四局練習、Just Declare（四座位）、叫牌練習、未排名的固定每日練習 |
| 完局複盤 | 完局清單、搜尋／清理、統計、Replay、PBN 匯入、叫牌與出牌匯出 |
| 教學 | 初階與進階學院、教學複盤、學習進度、個人化練習推薦、終局 DDS 分析 |
| 牌面 | `playing_cards 0.4.1+11` 僅作可見牌的呈現 adapter，不接管發牌與合法判定 |

代表性測試：[Flutter／Chrome 198 tests](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40255094253)、[窄屏與 200 tests](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40256171652)。**並非 Android／iOS 裝置驗收或正式產品 GO**。

## AI／Gateway／叫牌制度

| 功能 | 已做到 | 狀態 |
| --- | --- | --- |
| 真 BEN 橋牌 AI | 固定版本 `/bid`／`/lead`／`/play`、固定真牌局完成 52 張／13 墩 | **SCOPED VERIFIED**，尚未公開部署 |
| 伺服器牌局 | localhost Gateway、Server-owned Game／座位權限、Bearer、版本／動作 ID、限額與本機受控加密恢復；Flutter 可選 Gateway | 工程原型，非分散式正式營運 |
| 2/1 與 SAYC | NS／EW 各自選制度、不可變 `GameSystems`／fingerprint，真 BEN Adapter／Gateway／Flutter 導通；固定兩局交叉制度完成 | **工程已實現**，[真 BEN CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40087851963)，不是制度專家認證 |
| Precision | 已選 BBA Meckwell V1，原生 EPBot sidecar 能研究性出價、完成研究級混合牌局；BBA 約定推論供合法牌啟發式排序 | **RESEARCH ONLY**，非正式競賽 AI |
| 自訂約定卡 | 2/1／SAYC 受限草稿、不可變版本、差異與備份、專家審查待辦、引擎支援守門 | **草稿可編輯，修改後 AI 不可玩**（`ENGINE_UNVERIFIED`） |
| 叫牌教練 | 公開叫牌檢視、NS/EW 制度來源、雙語本機草稿對照與 `UNKNOWN` 標示、完局 Gateway 公開歷程 | **教學與資訊功能**，未做真 AI 最佳叫品判定 |

相關研究：[BEN](../research/BEN_SYSTEMS.md) · [Precision](../research/PRECISION.md) · [M4/M5](../research/CUSTOM_AND_COACH.md)。

## 尚未完成，絕不冒稱

正式公開 TLS／身分、正版 AI 權重／原生元件發行合規、真 2 vCPU/4GB 主機壓測、長期儲存與跨設備續局、專家級 100+ Golden、完整玩家 UX／動畫、正式競賽排名與多人、Android/iOS 實機／模擬器驗收。A3.5 及裝置 QA 仍在使用者 **OWNER HOLD**。見 [發行條件](../planning/RELEASE_CHECKLIST.md)。

技術資料流見 [架構](ARCHITECTURE.md)，不可變橋牌法則見 [規則](BRIDGE_RULES.md)。
