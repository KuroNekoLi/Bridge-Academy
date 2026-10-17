# Bridge Academy — UX-04：每日練習與再次回訪

**Branch**：`feature/ux-04-daily-return-loop`  
**Base**：`master@41d0ac604554dc3581cbe59b796b172e81270ee9`  
**Current status**：HANDOFF_READY，尚未實作  
**Provisional learning ID**：`M2-F56`（整合時再查重）

## 玩家目標
回訪玩家立刻知道今日固定四副非排名練習還差多少、是否能接續已儲存的場次，以及下一個值得做的原創練習；不必登入，也不會看到虛構排行榜。

## 既有模組與可靠性約束
- B6：`lib/src/daily_practice.dart`、`lib/src/daily_practice_store.dart`、`widgets/daily_practice_panel.dart`；`BridgeSession.todaysDaily/dailyPractice/dailyHistory`。B1：`four_board_practice.dart`、`BridgeSession.fourBoardPractice`；A5：`BridgeSession.completedHistory` 的 bounded local summaries。C3：同意後 encrypted learner progress；C3.2 是可解釋規則推薦，不是 AI 臨床式評分。
- `DailyPracticeManifest.forDate` 使用 UTC，跨日要明確寫 UTC，不得與本地日期混淆；當天與昨日的存檔、完成、重新練習須依既有 B6 規則處理，不能重新定義 leaderboard 或 board identity。
## UX-04 玩家交付
1. **今日一眼看懂**：今日日期／UTC、未開始、進行中 1～3/4、完成 4/4，各狀態明確；目前保存有資料才顯示「繼續」，沒有紀錄要顯示 Empty State。保留「每日練習（非排名）」標示。
2. **可操作的開始／繼續**：按鈕連到既有 `startDailyPractice` / `nextDailyBoard` 與合法 board state；若目前有其他未完成 session，先展示安全選擇／不允許覆寫，尊重 `busy/saveFailed/recoveryNeedsConfirmation`。每日挑戰與 B1 四副練習是不同模式，絕不混寫。
3. **近幾次學習與進步**：只使用已有、使用者明確選擇保留的每日結果；顯示已完成日期與每次完成數。本機 History 只有至多 12 副，不能用它算誤導性的全球勝率；若加入 C3.2 推薦，只在使用者已同意儲存時讀資料，沒同意就不顯示。不能因「今天沒玩」羞辱玩家或建立隱性 streak。
4. **回訪入口接線**：製作獨立 typed `DailyReturnSummary` 和可重用 `DailyReturnPanel`（推薦 `lib/src/experience/daily/`、`widgets/ux_daily_return_panel.dart`），在現有 B6 panel 上提供玩家可操作內容；UX-01 主頁尚未合併時**不要 import 該非 master 分支**。後續 integration 由 UX-01 首頁注入相同 DTO。
## 最低驗收
- `test/ux_04_daily_return_test.dart`：注入 UTC clock；0/4、1/4、4/4、換日、已有途中 session、保存失敗、無 C3 consent、正常開始/下一副（不能暗中重建完整 Deal）。至少一條 Widget/可用 Web 路徑可真點擊而不是純展示。
- 不新增帳號、未授權推播、公開排名、MP/IMP 偽比較，不改 `Bridge Core` 牌局規則。繁中/en、窄螢幕、大字與無障礙標示。
- 驗收 `docs/product/UX_04_DAILY_RETURN_ACCEPTANCE.md`、教學 `docs/learning/features/M2_F56_DAILY_RETURN_LOOP.md`。
## 檔案責任
UX-04 擁有 `widgets/daily_practice_panel.dart`、`experience/daily/` 和對應測試；**不要改 UX-01 外層 App Shell、UX-02 結果 Widget、UX-03 複盤和學院頁**。如需在 `BridgeTable` daily 區插入 minimal callback，明確交接 hunk，不覆蓋其他分支修改。


## 四線平行整合契約
- 四個 UX 分支都基於 `master@41d0ac604554dc3581cbe59b796b172e81270ee9`，可以並行，但不能假定其他 UX 分支的內容已存在。只修改自己分支、只 push 此分支；不得直接 merge / push master、開 PR 或 force-push。正式整合順序 UX-01 → UX-02 → UX-03 → UX-04，最後由 Integration Agent Code Review、解衝突、跑合併回歸。
- 先讀 `AGENTS.md`、`docs/product/BRIDGE_ACADEMY_PRD_V1.md`、`docs/product/PRODUCT_DELIVERY_ROADMAP.md`、`docs/product/COMPETITOR_BENCHMARK.md`、`docs/ARCHITECTURE.md`、`docs/BRIDGE_RULES_BASELINE.md`、`docs/DECISIONS.md`、`skills/README.md`，再核對 `master` 代碼。Bridge Core 是叫牌、跟牌、墩數、計分的唯一權威；BEN 不作規則裁判。
- 只允許發給 UI 的 `PlayerView`、合法終局 `CompletedReplay`、`HistorySummary` 或 B4 公開課程資訊。不可把原始四手 `Deal`、PBN、密鑰、token、受信任 transcript 放入頁面路由、遙測或日誌。DDS 只能在終局授權後顯示雙明手分析；不能宣稱為真人當下最佳出牌。BEN 斷線不得悄悄切換 Demo。
- UX-01 擁有 `BridgeAcademyApp` 外層 Shell／首頁／導航（`bridge_app.dart` 約 110–160 行）。UX-02 擁有終局結果新 Widget，UX-03 擁有複盤→教學銜接，UX-04 擁有每日進度摘要。其他三線不改 UX-01 App Shell；如需在 `bridge_app.dart` 的 `BridgeTable` 內接線，只改最小區塊並在 handoff 標明，絕不可覆蓋不同分支的整個檔案。
- 繁中／英文、可見載入/錯誤/disabled/返回狀態、320/375px、2× font、可辨識 semantic label，已有元件 key/存檔語意保持相容。新行為交付實際可點擊的玩家功能與 deterministic Flutter Widget／必要 Domain/Chrome path。Flutter Analyze、全套 Flutter tests、Web Release Build，影響 BEN 當場修復/出牌時跑真 BEN Browser。沒跑的明列 `NOT RUN`。
- Android Emulator 與真實 Android/iOS 裝置 UI／E2E 仍由使用者要求**暫停**，不得重啟 workflow。未獲同意不建立遠端生產服務、登入、競賽、通知或持續蒐集玩家行為。B6 是本機非排名每日練習，絕不能顯示 MP/IMP、公開排行榜或好友比較。
- 完成功能須在 `docs/learning/features/` 寫一份真實程式碼繁中教學、更新 `docs/learning/INDEX.md`，並產出 `docs/product/` 的驗收報告。UX-01/02/03/04 預留教學 ID 為 `M2-F53`/`M2-F54`/`M2-F55`/`M2-F56`，整合時查重。真實 CI URL/SHA/PASS/FAILED/NOT RUN，不可編造。
- 不要把「5 名新手 + 5 名熟手」的建議研究目標冒充已完成：設計兩群玩家各一條具體操作任務，未觀察時明列 `USER_STUDY_NOT_RUN`。未經自願同意不可自行開啟遙測，觀測內容不得包含暗手。
- 根 `AGENT_TASK.md` 是各分支臨時任務入口；完成後在本分支提交刪除，長期 handoff 永久保留於 `docs/handoff/`。最後回報 branch/HEAD、已完成玩家流程、變更檔案、測試證據與 CI、風險、跟其他分支的 hunk 交集、rollback、工程教學及一題練習題。
