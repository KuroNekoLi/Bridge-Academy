# Bridge Academy 全產品缺口與 UI/UX 交付計畫

版本 1.0 · 2026-10-26 · 對應本次使用者要求：整理未完成工作並實作可玩的介面。

這是既有 [PRD v1](BRIDGE_ACADEMY_PRD_V1.md)、[產品交付 Roadmap](PRODUCT_DELIVERY_ROADMAP.md) 與 [三制度計畫](THREE_SYSTEM_BIDDING_AI_MASTER_PLAN.md) 的實作盤點；不是重訂橋牌規則、刪除舊驗收或公開發行核准。歷史文件的「下一步」必須和較新的程式／驗收一起閱讀。

## 1. 目標與不變條件

做到「打牌 → 知道結果 → 複盤 → 學會一件事 → 再打一副」的完整體驗，逐步補足 BBO／新睿類型產品能力。功能相似不等於可複製其商標、牌例、解說、圖片或程式。

- Bridge Core 維持叫牌、牌權、跟牌、明手、勝墩與計分的唯一權威。
- UI 只接收 PlayerView；牌面套件只把允許顯示的 Card 畫出來。對手手牌不能先送到 Widget 再遮起來。
- Demo、真正 BEN、Precision 研究版、自訂草稿及已審核約定清楚分開；沒有可用服務時不悄悄降級。
- 中英雙語、48px 可操作區、非僅靠顏色提示、鍵盤及放大字體是共同驗收條件。
- 不新增無法操作的「比賽」入口；每日固定練習繼續無排名，單桌分數不能改名 MP／IMP。
- Android 模擬器／Android、iOS 實機 UI/E2E 仍由 owner hold；本次要求改善 UX 不解讀為解除暫停。

## 2. 最新實作盤點

| 領域 | 已有可核對實作 | 真正剩餘缺口 |
| --- | --- | --- |
| 規則與發牌 | `packages/bridge_core`：不可變事件、四座位、52 張／13 墩、牌號局況、重播；固定／隨機牌 | 持續回歸，不重寫另一套發牌／規則器；正式賽事規則及 claim 仍需獨立規格 |
| 本機牌局 | `bridge_session.dart`、加密 checkpoint、恢復警告／確認 | 跨分頁競態、金鑰遺失／備份、原生故障耐久與正式部署威脅模型尚未完成 |
| 牌桌 UI | A3 共用表頭、四座位、叫牌盒、工具列、手牌元件 | 舊版入口全擠在牌桌頂部；叫牌階段漏顯示自己的手牌；缺少產品級視覺與操作實測。本輪補第一批，A3.5 保留 |
| 真 AI | Adapter、server-owned Gateway、同 ID 重試、單節點加密 checkpoint；已有固定及四副真 BEN CI | 沒有核准的公開 TLS 服務、長時負載、正式資源預算、已驗證跨重啟玩家身分／安全續局 |
| 歷史與複盤 | A5 本機加密最多 12 副、搜尋／篩選／分頁／刪除、PBN 匯入匯出、教學式事件回放 | Gateway 端授權完成歷史、跨裝置續局、分離的 server retention／刪除政策未完成；不能把本機歷史當雲歷史 |
| 四副／主打／叫牌／每日練習 | B1/B2/B3/B6 已有 Session、Widget 與測試。每日是固定原創四副、UTC 日期、Demo／無排名 | 真 BEN 無叫牌主打相容性、更多原創且專家審定的教材；不是全部都還沒實作 |
| 學院與進度 | B4/B4.2 六課二十一題；C3 加密且 opt-in 進度、C3.2 可點擊的本機規則推薦 | 擴充內容、專家審查、實際學習成效與跨裝置選擇性同步 |
| DDS | `bridge_dds_adapter`、終局分析與 C1.5 複盤整合，已有獨立真 DDS 證據 | 正式發行 native／服務、目標平台封裝與實際部署；不能拿來賽中看暗牌 |
| 2/1／SAYC | `bridge_conventions`、模型路由與混合制度真 BEN 全局 CI | 專家 100+ goldens、策略品質與正式主機容量，不只是 UI 選單 |
| Precision | pinned BBA Meckwell V1、混合研究局、約定推論出牌研究 | 競爭力／牌力、專家驗收、目標部署；仍是研究旗標，不開正式玩家選單 |
| 自訂約定 | M4 草稿、版本 SHA、diff、快進匯入、專家待審包；Gateway 拒絕偽造支援 | 真正可執行 BEN/BBA artifact、雙方 reader、可信 capability 與 expert goldens，仍 NO-GO |
| 叫牌教練 | M5 公開叫牌／來源證據、雙語草稿對照、Gateway 終局公開檢視 | 真候選建議／模型證據、已審核含義、品質比較；不能虛構 AI 內部推理 |
| 比賽／好友／多人 | PRD 的 D／E 計畫 | immutable BoardSet、可比 field、MP/IMP、延遲揭牌、反作弊、帳號／座位授權、WebSocket、director、維運全部還需要實作 |

盤點來源：[本機歷史](A5_2_HISTORY_MANAGEMENT_ACCEPTANCE.md)、[四副練習](B1_FOUR_BOARD_PRACTICE_ACCEPTANCE.md)、[主打](B2_JUST_DECLARE_ACCEPTANCE.md)、[每日](B6_DAILY_PRACTICE_ACCEPTANCE.md)、[學習推薦](C3_2_PERSONALIZED_RECOMMENDATIONS_ACCEPTANCE.md)、[DDS 整合](C1_5_DDS_REVIEW_INTEGRATION_ACCEPTANCE.md)、[四副真 BEN](A6_REAL_BEN_MULTIBOARD_ACCEPTANCE.md)、[部署準備](A4_5_DEPLOYMENT_READINESS.md)、[M4](../research/M4_CUSTOM_CONVENTION_DELIVERY_ACCEPTANCE.md)、[M5](../research/M5_PUBLIC_AUCTION_COACH_ACCEPTANCE.md)。這些是各自命名環境的證據，不能合併聲稱全產品通過。

## 3. 資訊架構與體驗規格

| 入口 | 玩家意圖 | 導向實際功能 |
| --- | --- | --- |
| 打牌 | 快速選擇適合的練習 | 自由打牌／四副／專心主打／每日／叫牌，各自說明 AI 類型、限制與目標 |
| 學院 | 學一個概念並實際答題 | 既有課程、重試、opt-in 進度與推薦；保留返回牌桌能力 |
| 複盤 | 找到並回看完成的牌 | 既有加密本機歷史、篩選、PBN、事件回放、終局 DDS；Gateway 尚未具備雲歷史時隱藏該入口 |
| 我的 | 設定與工具 | 語言、自訂約定草稿、公開證據教練、開源授權；不暗示已有登入與雲同步 |
| 比賽（後續） | 和同條件玩家比較 | D 階段通過才加入，現在不做假按鈕 |

牌桌進行中依序顯示：模式／儲存警示 → 牌號局況與輪次 → 四座位及本墩 → 自己可見手牌／公開明手與當前操作 → 結果／下一副／複盤。其他練習放在下方。切換頁籤不能改動對局版本；重發未完牌必須有明確放棄選擇。

桌面內容限制最大寬度 1240；練習卡片依可用寬度顯示 1／2／3 欄，手機採可捲動且不重疊的 48px 以上按牌操作，保留放大文字。下一批才優化單屏緊湊牌桌和橫向手牌；不為扇形外觀犧牲點擊區或暗牌隔離。

## 4. 分批實作、依賴與完成條件

| 順序 | 工作包／負責域 | 具體工作 | 量測與完成條件 | 依賴／狀態 |
| --- | --- | --- | --- | --- |
| U1 | 入口與工作區／Flutter | 分組練習卡、可用頁籤、保留對局、未完牌重發確認 | 中英、320/768/1280px 與 2x 字體、切換不改事件、取消不丟進度 | **本輪 M2-F53 實作** |
| U2 | 牌面與叫牌手牌／Flutter | 重用牌面套件、單向 Card adapter、自己的叫牌手牌、合法／鎖定圖示、公共本墩牌面 | 52 種映射、排序不改 projection、暗牌負例、明手 owner、不合法／busy 不送出、鍵盤操作 | **本輪 M2-F54 實作** |
| U3 | 牌桌互動／Flutter | 更緊湊的橫直屏布局、選牌／確認偏好、出牌飛行／收墩動畫、減少動態效果、必要時採拖放呈現器 | 320/375/768/1280px、完整 52/13 Browser flow、不重送、不因動畫擋重試、不洩漏未授權牌 | 接 U2；**未完成**；需保留 A3.5 實際玩家／輔具驗收 |
| U4 | 完局與恢復／Flutter + Gateway | 結果主要動作、可理解的模式可用性、網路重試／expired bearer、server-authorized history／retention | 取消／失敗不覆蓋、過期／錯誤 token 拒絕、同 ID 重試不重複、實際關頁續局／跨重啟 | 接 A2/A4/A5；**未完成**；先定安全續局政策 |
| A4.5 | 真正可用服務／AI + Architecture + OSS | 既有 Gateway 前可信 TLS edge、私有 BEN、權重／native notices、金鑰輪替、監測／成本、目標 VPS 壓測 | 真 HTTPS 四副以上、斷線恢復、p50/p95/RSS／併發實測、隱私和授權清單 | **Release blocker**；不自行採購、公開 listener 或承諾預算 |
| A7 | 發布驗收／QA | Web 部署與儲存威脅、A3.5、人類新手／熟手旅程、Android/iOS 壽命週期與輔具 | 至少四副真 AI、恢復／歷史、無秘密、命名裝置、實際使用者觀察 | 裝置部分 **OWNER HOLD**；需要日後明確批准才執行 |
| T1 | AI 教學品質／Conventions + AI | 2/1/SAYC expert goldens、Precision fair-play strength、M4 executable evidence、M5 reviewed candidate feedback | 每個 meaning 的來源／版本、UNKNOWN 負例、真模型和基準比較、策略不偷看 | 可平行 U3；不足證據繼續 research/draft |
| T2 | 課程內容／Conventions + Learning | 原創主打／防守教材、分級關卡、按弱點導向已審核練習 | 每題獨立規則驗證、可重現、同意／刪除、真人學習驗收 | 基於 B4/C3，不重寫進度引擎 |
| D1–D4 | 公平非同步比賽／Server + Rules | Server BoardSet、同設定 bot、可比分數集、MP/IMP、好友／群組比較、延遲揭牌、防重複提交 | 多使用者同條件、獨立 MP/IMP oracle、授權／retention／反作弊、壓力負例 | 在可信部署和公平規格後；**未實作** |
| E1–E4 | 真人桌與社群／Server + Client | 帳號與座位權限、WebSocket、房間／邀請、重連、觀戰／延遲、導師／director、社群管理 | 並行隔離、斷線重入、權限負例、監測／管理員與隱私政策 | 依 D 的身份與伺服器基礎；**未實作** |

不給尚未量測的服務成本／日期承諾。各包在直接 push master 的變更集中提供 implementation＋deterministic tests＋獨立 feature lesson＋真實證據，再推進下一包。工程通過不等於產品 READY，文件也不等於實作。

## 5. 撲克牌套件調查與採用邊界

2026-10-26 查詢 pub.dev registry 和實際 archive，而不是只看名稱：

| 套件 | 釘選版本／來源 | 能力與選擇 |
| --- | --- | --- |
| [playing_cards](https://pub.dev/packages/playing_cards) | `0.4.1+11`，2023-08-02；[上游](https://github.com/bedardjo/playing_cards)，Apache-2.0 | 無額外 runtime 相依、標準牌面與 fan。**本輪採用公開 renderer API**，用自己的花色／點數樣式。發布較久，SDK 相容性以本機 analyze/test/build 證據為準，不能說仍活躍維護 |
| [card_game](https://pub.dev/packages/card_game) | `2.0.0`，2025-04-28；[上游](https://github.com/JLogical-Apps/card_game)，pub.dev 標示 MIT | 具拖放／翻牌／移動動畫，額外 provider/flutter_svg 等依賴。**評估保留，不安裝**；若 U3 導入只給可見 Card group，disabled/validator 回到 session，不接管 deal／規則 |

`playing_cards` 的內附 Wikimedia 圖像沒有逐圖完整來源資訊；目前所有標準 rank/suit 覆寫為字形，不讀那些圖像，UI 有開源授權頁。Flutter 仍可能將 package 宣告的未使用圖像打包，所以**公開 binary release 前還要查清、排除或用已審核無圖像版本**，不可宣稱所有資產已完成授權稽核。精確 archive SHA、整合模式與發行條件記在 [OSS audit](../OPEN_SOURCE_AUDIT.md)。

外部套件無法替專案完成暗牌隔離、合約、跟牌、turn、dummy ownership、checkpoint 或 MP/IMP；這些繼續由既有 Core／Session／Gateway 負責。

## 6. 本輪驗收與回退

本輪只接受 U1/U2，對應 [M2-F53](../learning/features/M2_F53_PRACTICE_WORKSPACE.md) 與 [M2-F54](../learning/features/M2_F54_CARD_PRESENTATION.md)。完整命令、實際版本、結果、Chrome 範圍與未執行事項見 [驗收紀錄](UX_WORKSPACE_ACCEPTANCE.md)。未改牌局存檔 schema；可以以單一 `git revert` 回退介面、套件與文件，不改寫歷史或搬遷玩家資料。

下個可執行工作包為 **U3：單屏牌桌、手牌操作與可中止動畫**。安全續局／server history 先做 U4 的授權協定設計；公開服務、比賽與裝置驗收繼續遵守既有決策。
