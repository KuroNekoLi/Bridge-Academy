# 接下來如何開發 Bridge Academy

> 2026-10-26 產品路線（**優先順序**），已完成成果不再複寫在本文。請先讀 [目前已有功能](../implemented/FEATURES.md)、[下方正式上線驗收門檻](#正式上線驗收門檻)，再挑選下一項小任務。此路線不授權解除 owner-held QA、購買主機或發布服務。

## 下一個應做的功能

**M2-F66／F67當前：** 已把Nickel BidBox／AuctionGrid互動契約實作到Flutter共享元件及Local／Gateway／專注桌／歷史：合法矩陣、選取確認、等待／版號鎖、四欄dealer排列及最新列。Core提供公開合法集合並與reducer共用驗證，無JSON schema變更。完整本機227tests、Core58tests及最新scoped8tests通過；Web工程證據與新SHA CI以CURRENT_HANDOFF為準。原「只研究、未實作」是歷史checkpoint，不代表現況。下一高風險產品切片仍是主工作區預設導向牌桌與安全返回；低風險工作已拆入CURRENT_HANDOFF，交由owner之後派agent。

**Owner最新優先序（2026-10-27）：叫牌UI同等程度移植。** 充分採用 pinned Nickel Bridge BidBox／AuctionGrid 的直接叫品矩陣、合法停用、獨立確認、等待鎖定、四座位叫牌表與最新回合提示，整合Local／Gateway／專注桌及歷史。此項排在工作區預設導航之前。2026-10-27 19:15 secondary額度剩30%，已依AGENTS先寫交接；本輪只有來源研究和介面盤點，**UI／Core helper／測試移轉均未實作**。恢復後從CURRENT_HANDOFF的具體檔案和驗收開始，不把這段計畫當成交付。

**2026-10-27 M2-F65：** 已補專注牌桌四座位 viewer 視角：玩家在下、搭檔在上，中央標籤／墩牌／入場／收墩使用相同映射；切換視角清除舊演出與選取。本機 scoped16 tests／analysis PASS。**下一個工程範圍是主工作區到專注桌的預設動線**：開局／繼續後直接到可玩的牌桌，返回工作區不遺失 session，Local 與 Gateway 需一致；尚未實作。另待完成第三方套件／內附素材 inventory，以及 owner-held 裝置／真人驗收。不能把單一專注頁工程成功稱作整個 U3 已完成。

**2026-10-27 M2-F63／F64：** 專注桌已改為手機全13張扇形、選牌抬起／確認、可切換寬牌列；公開墩牌響應式放大、共用座標收向贏家。核心／授權不變。最終本機與新SHA CI、Chrome視覺證據以CURRENT_HANDOFF為準；裝置／真人QA仍HOLD。

**Reuse First 最新進展：M2-F60／F61／F62** 專注牌桌重用 FlatCardFan 並加輕微弧形，保留 ≥48px 可見操作區及窄屏／大字體退路；公開墩牌依座位四方位入場、向贏家收攏，已揭露明手與己方手牌分列同一桌面的上、下緣。主 app 無新增依賴。Nickel UI 來源已釘選並作座位／動態參考；card_game 隔離 probe 重現拖曳結束空值例外、單張 stack 與 reduce-motion gate，不能直接切換正式牌桌。已核對桌面與 375px 真 Web 畫面，後續仍需 owner-held 真人／裝置 UX 及上游修正適配，詳見 RESEARCH_REPORTS。

**最新 owner steering：Reuse First。** 新 UI 先研究 Nickel Bridge（owner 已明示完整修改授權）、card_game／playing_cards／官方 template，以小型 presentation adapter PoC 比較重用；不再先擴寫自製互動。保留 Core／BEN／計分權威，細節見 DECISIONS 與 RESEARCH_REPORTS；額度恢復後先做此適配研究，裝置 QA HOLD 不變。

### U3｜牌桌操作、動畫與窄屏完整體驗（目前最高 UI 優先）

**前置已完成：** U1 練習工作區、U2 共用可見牌面、U3.1 橫向手牌列。

**U3.3 本次實作：** M2-F57 專注單屏牌桌、M2-F58 合法牌長按拖曳、M2-F59 公開收墩效果已加入 Local／Gateway；scoped 九項 PASS，最終 full suite／Web／Chrome CI 以 CURRENT_HANDOFF 為準。大字體／矮視窗保留捲動退路；仍不解除 A3.5／裝置 QA hold，也不稱整個 U3 產品驗收完成。

**本次小範圍 U3.2／M2-F56：** 公開新牌入場與活動座位過渡、可中止動態及本次使用的減少動畫設定已實作；本機 206 tests／analyze／Web release PASS，[當次 030276b Chrome CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40300087862) 已成功（含完整 Demo 中途切換動畫偏好及加密 checkpoint）。詳見 [功能與限制](../implemented/FEATURES.md#m2-f56公開出牌動態回饋與減少動畫)。尚未完成下面完整 U3 驗收；下一個範圍仍為單屏牌桌佈局。

**待做：** M2-F57～F61 已有工程級單屏、合法點牌／長按拖曳、來源方位入場／收墩及減少動畫；仍須實際 Web 視覺／輔具檢查、更多高度／裝置適配、等待與取消態的完整產品驗收。不要讓展示動畫拖延回合／重複 submit，不能偷看暗牌。

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

開始每個功能前：對照最新 `master` 原始碼與 CI，寫最小驗收、更新 [功能表](../implemented/FEATURES.md)、[工程筆記](../implemented/ENGINEERING_NOTES.md)。完成技術測試只標 **SCOPED VERIFIED**；涉及正式上線時由 [本文正式上線驗收門檻](#正式上線驗收門檻) 逐項放行。

## 產品目標與玩家旅程


> 版本 2026-10-26。這是**尚待完成的產品需求**，不是聲稱所有功能已上線。已存在的功能見 [功能清單](../implemented/FEATURES.md)。

## 目標與受眾

讓新手、進階橋牌玩家透過真實規則、可信賴的機器人搭檔、牌局練習、事後複盤與有來源的教學，建立可持續的橋牌學習體驗。產品靈感可參考 BBO、新睿、BBO Trainer，但**不複製**第三方程式與資產。

## 玩家旅程

| 場景 | 使用者預期 | 真正完成的要求 |
| --- | --- | --- |
| 開局到下一局 | 選座位、模式、制度 → 叫牌／打完 13 墩 → 計分與下一局 | AI 真實回應、事件合法、身價／莊家正確、斷線可處理 |
| 暫停與恢復 | 關閉視窗後明確選擇繼續，保留已完成事件 | 本機／雲端正確來源、版本一致、不重複執行 |
| 練習與學院 | 自由對局、Just Declare、四副練習、叫牌課、個人進度 | 清楚區分教學練習與排名結果 |
| 回顧與分析 | 完局 history、Replay、PBN、DDS、可以信任的制度意義 | 過去牌局可重播；雙明手分析不在進行中偷看 |
| 叫牌搭檔 | 分別選 NS／EW 的 2/1、SAYC；研究可用的 Precision | profile 與模型版號釘選、可以證明真模型在決策 |
| 自訂約定與教練 | 編輯約定卡、檢視來源、經過驗證後可用於 AI | 沒有引擎證據的草稿不得假裝可玩；Coach 必須標 UNKNOWN |
| 排名競賽與多人 | 公平比較同一副牌、MP/IMP、排行榜、同桌互動 | Server-owned BoardSet／權限、重現性、公平分數、反作弊與多人協定 |

## 產品導航與體驗

`打牌`、`學院`、`複盤`、`比賽`、`我的` 是規劃分區；目前只顯示**已有可操作內容**，不可先做不能點的空頁籤。桌面／平板／手機要支援中文繁體與英文、鍵盤／螢幕閱讀器、合法動作提示及大尺寸觸控，並保留遊戲進度。演出動畫**不能**篡改事件或使重試雙重生效。

## 資料、隱私與公平原則

- Bridge Core 永遠裁判合法叫牌／出牌與分數。只讓當前座位獲得 `PlayerView` 有權看見的牌。
- 真人、電腦及教學模式必須明確標示；不得把研究版 Precision 或自訂草稿當已核准商用 AI。
- 伺服器不可在公開 query/log 洩漏原始私牌、token 或未完成全四手牌。
- 每場可比較的排名必須由不可變 BoardSet 與 scoring/verifiable event log 建立；未排名每日練習不得改稱賽事。
- 真人／裝置 QA 與正式第三方原生套件、權重、資產授權都屬上線必要條件。

下一階段先完成 [本文件產品路線](#下一個應做的功能) 的 U3／U4，再解除 [下方正式上線驗收門檻](#正式上線驗收門檻)，不以 CI 成功取代真人體驗。

## 正式上線驗收門檻


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

研究版 BEN 单程序約 1 GiB RSS、雙程序約 2 GiB 是**GitHub Ubuntu Runner 小樣本 NN-biased**，不是目標 VPS 的保證；採樣細節見 [整合研究報告](../research/RESEARCH_REPORTS.md)。

## 目前明確禁止

不得恢復 owner-held Android/iOS／A3.5 QA；不得公開 localhost BEN/Gateway、把私牌與 token 放在 URL／logs；不得在未核可第三方權重及 native binary 前發行；不得稱自訂草稿已影響 BEN，亦不得將非排名每日練習稱作公平比較的積分賽。

**重新准入流程：** 每個待測關卡都記實際環境／SHA／fixture 與結論，明確區分 PASS／FAILED／BLOCKED／NOT RUN，經 owner 確認後才更新正式 release 狀態。

## 更新與排序規則

先核對 master 真正實作與最新 CI。優先修復使用者有感的 U3 體驗，再處理 U4 安全續局、A4.5 實機實測與權利確認，正式發行依 A7 Gate。每一個新功能仍要更新 [已實作功能](../implemented/FEATURES.md)、[工程導讀](../implemented/ENGINEERING_NOTES.md)。

### 2026-10-30 單一活動牌桌 UI

使用者要求移除一般桌、不要區分一般桌與專注桌。活動 Local 與 Gateway session 改為直接顯示同一 `BridgeFocusTable`；移除 focus 跳轉按鈕與重複牌局操作區。開局設定、歷史、session 重試／刷新、練習和已完成牌局操作仍保留。這不等於已通過真人或裝置驗收；owner-held Android/iOS QA HOLD。實作與驗證詳見 M2-F72。
