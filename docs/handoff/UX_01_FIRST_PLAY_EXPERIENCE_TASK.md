# Bridge Academy — UX-01: 首頁、模式導航與第一次練習

**狀態**：IMPLEMENTED／CI PENDING（實際玩家研究尚未執行）  
**分支**：`feature/ux-01-first-play-experience`  
**源自**：`master@41d0ac604554dc3581cbe59b796b172e81270ee9`  
**暫定教學 ID**：`M2-F53`（整合時再查重）

## 玩家目標
新玩家可不登入、不理解 BEN/Gateway 開發細節，選擇「快速練習」或「學習橋牌」，從首頁進入真實可操作遊戲/課程；回訪玩家可繼續已保存的合法牌局。


## 已存在程式及目標接線
- `BridgeAcademyApp` 的外層 Scaffold/AppBar/AcademyPage 目前在 `lib/src/bridge_app.dart` 約 110–160 行；`BridgeTable` 內含座位／牌源／Demo/BEN／每日／四副／叫牌模式的入口。**這是 UX-01 唯一擁有的外層 Shell**。
- `BridgeSession` 的 `started`、`finished`、`busy`、`saveFailed`、`recoveryNeedsConfirmation`、`restoredFromStorage` 提供可用性；`GatewayGameSession` 為另一條 server-owned 路徑，不可把 `BridgeSession` local resume 當成遠端 Gateway session。
- 新首頁/導航應放在 `lib/src/experience/home/` 或 `lib/src/widgets/ux_home_*.dart`，`bridge_app.dart` 只做 Shell 最小整合，不搬移 Core 或改整張牌桌邏輯。保留既有 `academy_open`、`new_game` 等測試鍵或提供同義可操作兼容入口。

## 玩家故事與分片
1. **UX01-A 首次進入**：首頁第一畫面突出「開始打牌」「學習橋牌」「短時間練習」「每日挑戰」，保留 `打牌／學院／複盤／我的` 的可用導覽。PRD 概念第五目的地「比賽」目前未發佈，**不可製造空殼入口或展示假的排行**。首次玩家有明確不登入即可試玩的路徑。
2. **UX01-B 快速開始/進階設定**：快速開始選擇 Demo 練習且**清楚標示 Demo 並非 BEN**；熟悉玩家可打開進階設定選座位／固定/新牌／機器人模式，只有真 BEN 已設定可用才顯示可操作入口（或明確 unavailable/retry），不可在 BEN 失敗時默默降級到 Demo。要避免覆寫已有進行中牌局，若需放棄須二次確認並尊重 saveFailed/recovery guard。
3. **UX01-C 可恢復進度**：確有可用、授權的 in-progress checkpoint 才顯示「繼續」，錯誤/回退等待確認則顯示適當警告，不因視覺重構自動清除牌局。對 Gateway 模式，避免冒用本機 `BridgeSession` 的完成旗標；沒有可恢復的 remote session 則不虛構。
4. **UX01-D 可操作導覽與語系**：不管從哪個入口都能返回首頁而不重置未完成遊戲；切換繁中／英文保持選擇與進度；320/375px 及大字體可使用；無 disabled 裝飾按鈕。

## 驗收
- Fresh start → 首頁 → Demo 快速練習 → 一個由 Bridge Core 驗證的合法 action；另一條首頁 → 學院 → 第一道可答題項；已有 checkpoint → 關閉再開可繼續。
- BEN 無設定/連線錯誤/忙碌/未授權的狀態有正確可見文本與可恢復操作；絕不自動切換對手；登入非必要。
- Widget／Web/Chrome deterministic acceptance；`test/ux_01_first_play_test.dart` 與可選 `integration_test/browser_ux_01_first_play_test.dart`。截圖/使用者研究如未執行不得宣稱通過。
- 教學 `docs/learning/features/M2_F53_FIRST_PLAY_EXPERIENCE.md`、`docs/product/UX_01_FIRST_PLAY_ACCEPTANCE.md`。

## 修改權限與跨分支依賴
**擁有** `BridgeAcademyApp` app shell、首頁／路由／模式入口新檔、UX-01 測試；**不要修改** B5 複盤 timeline、B4 題庫、B6 daily logic 和核心 game reducer。其他 UX 分支只需對既有 `BridgeTable`／`AcademyPage` 介面提供 callback，**不要等待 UX-01 程式碼合併才開始**。


## 共同開發與整合契約

**基準**：四個分支均從 `master@41d0ac604554dc3581cbe59b796b172e81270ee9` 建立，按玩家價值切分，可並行實作，不可暗中假設其他 UX 任務已合併。

- 以 `AGENTS.md`、`docs/product/BRIDGE_ACADEMY_PRD_V1.md`、`docs/product/PRODUCT_DELIVERY_ROADMAP.md`、`docs/product/COMPETITOR_BENCHMARK.md`、`docs/BRIDGE_RULES_BASELINE.md`、`docs/ARCHITECTURE.md`、`docs/DECISIONS.md` 為權威。這是**玩家 UX 最小可用切片**，不重做既有 Core、BEN、A5、B1–B6、C1/C3 功能。
- 先 `git fetch origin`、切到任務分支，檢查 `git status --short`。只 push 自己的分支，**不要自行 merge master、不要開 PR、不要 force-push**；由 Integration Agent 在四組 Code Review 後決定合併順序。不得修改其他 Agent 的分支或進行覆蓋式 cherry-pick。
- 新元件設計成小型、可 DI 的 typed DTO + callback / Widget，不得直接讀取原始四手 `Deal`、加密存檔、BEN secret、全量 PBN。Bridge Core 唯一決定合法叫品／打牌／定約／牌墩／得分；UI 僅用 `PlayerView`、獲授權的 `HistorySummary`、終局 `CompletedReplay`。DDS 只在終局且有受信任授權後可用，不能在 live play 偷看全牌。不可隱式從 BEN 切換 Demo。
- 所有 UI 實際文字繁體中文／英文；載入、無資料、disabled、錯誤、恢復與返回狀態須完整。320/375px、1.6–2x 字體／無障礙名稱／48px touch target 至少做 Widget 可測驗收；不能以 Widget 結果宣稱真實 VoiceOver 或 TalkBack 已驗收。既有 widget keys／導航與存檔語義原則上不破壞。
- 一個功能須有可操作的玩家路徑，不可只交 model、UI mockup 或文件。交付相應 `test/ux_0x_*.dart`，有影響時加 `integration_test/browser_ux_*.dart` 及既有 Demo Chrome + real BEN 必要回歸。基本命令（在 `apps/bridge_academy_flutter`）：`flutter analyze`、`flutter test`、`flutter build web --release`。**精確報告實際執行／未執行、測試數量、SHA 和 CI URL**；不能把各自分支 PASS 當作整合 PASS。
- **Android emulator 與實體 Android/iOS UI/E2E 維持使用者指定的暫停**；不重啟相關 workflow，也不把它當成無需驗收。任何遠端 BEN staging／網路事件分析／外部服務部署須另經安全與費用授權。本任務不部署公開 HTTPS 或啟用正式比賽。
- 每個功能通過自身 scoped 驗收時，按 `docs/learning/FEATURE_LESSON_TEMPLATE.md` 建立**繁體中文工程教學**，在 `docs/learning/INDEX.md` 加唯一 ID，教學必須對應實際程式與真實測試。預留編號：UX-01=`M2-F53`、UX-02=`M2-F54`、UX-03=`M2-F55`、UX-04=`M2-F56`；合併時仍查重。不得假稱用戶已學會。
- 若需改 `apps/bridge_academy_flutter/lib/src/bridge_app.dart`、`app_copy.dart` 或 `docs/learning/INDEX.md`，只作達到該玩家路徑所必要的最小 hunk，記錄衝突區段，避免重排整檔。**UX-01 擁有最外層 `BridgeAcademyApp` shell/導航；其他 Agent 不得改該 shell**。測試不要硬編目錄數量或假設長 ListView 中的 Widget 一定已建立；使用 bounded `scrollUntilVisible`。
- 每個 branch 有自己臨時的根 `AGENT_TASK.md`，最終交接前刪除此臨時檔（提交刪除），永久規格保留於 `docs/handoff/`。每個 Agent 的最後回覆：Branch/HEAD、玩家可操作入口、修改檔案、真實測試與 CI、未驗證項目、隱私／授權、整合衝突／rollback、教學檔、一個學習問題。
- 正式合併建議 UX-01 → UX-02 → UX-03 → UX-04，每次均檢查共享檔案及終局／存檔規則，跑合併後 Flutter/Chrome（必要時真 BEN），解決學習 ID 衝突。此順序是**整合依賴**，不阻止四個分支現在同時作業。

## 玩家證據政策
每個 UX 切片需設計可讓 5 位新手與 5 位有經驗玩家操作的**觀察任務**、成功定義、摩擦點／改善假設。沒有實際招募與觀察，就明確寫 `USER_STUDY_NOT_RUN`，不能編造成功率。遙測需自願同意，僅收集匿名 UX 事件，絕不收集暗手、PBN、token；最初可先用手動匿名研究表，不必建立追蹤後端。
