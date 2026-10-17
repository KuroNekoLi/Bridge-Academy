# Bridge Academy — UX-02: 完整牌局結果與下一步操作

**狀態**：TASK READY／Implementation NOT STARTED  
**分支**：`feature/ux-02-postgame-results`  
**源自**：`master@41d0ac604554dc3581cbe59b796b172e81270ee9`  
**暫定教學 ID**：`M2-F54`（整合時再查重）

## 玩家目標
玩家打完（或四家真實 Pass Out）一副牌，立即看懂這局的合約、莊家、得失墩與合法得分，接著能重播、再練同一副、進下一副，而不用重新摸索各模式。


## 依賴與入口
- 既有 `BridgeSession.view`、`completedReplay`、`humanSeat`、`board`、`fourBoardPractice`、`dailyPractice`、`isJustDeclare`；`bridge_app.dart` 內 `BridgeTable` 的終局/重播 UI；`widgets/bridge_replay_panel.dart`、`completed_history_store.dart`。
- 對任何結果數值都必須透過 Bridge Core 已決議終局 DTO／PlayerView，包含 NS signed score 視角轉人類座位、通過定約的墩數、Pass Out 不記為失敗定約；不要自行重算 score、猜暗手或杜撰第四次 Pass。
- UX-02 **不擁有** `BridgeAcademyApp` 外層 Shell／首頁；新增 `widgets/ux_postgame_result_panel.dart` 或 `experience/result/`，只需在 `BridgeTable` 終局區做最小接線，可透過已有牌桌進入結果。若需要 UX-01 未來路由，提供 callback，不 import UX-01 非 master 程式碼。

## 實作分片
1. **UX02-A 可讀結果卡**：終局才顯示 `Board number`、dealer、vulnerability、final contract/pass-out、declarer、tricks made/target、Made/Down、得分與人類視角正負標籤。對不存在的資料顯示不適用，不編造出牌/完成。B2 Just Declare 無叫牌，依其獨立模式正確標籤，不能顯示虛假完整競叫。
2. **UX02-B 下一步分流**：主 CTA 根據模式優先「下一副練習」(B1/B6 有明確可 advance 時) 或「開始下一副」；次 CTA「查看本局複盤」「重練同一副（練習成績另計）」「查看歷史」。要有可返回結果的路徑，不能因開啟複盤而自動重建/改變 Core State。
3. **UX02-C 失敗與保護**：當 saveFailed/busy/recovery consent 等 guard 阻擋時，禁用會導致資料遺失的 action 並提示原因；Pass Out 不顯示錯誤的 13 墩。對 Demo、BEN、B2、B1、B6 限定真實資訊，不顯示 MP/IMP 或偽比賽排名。
4. **UX02-D 分享預覽（選配）**：僅可分享安全摘要；既有 PBN export 含四手，保留原本獨立確認警告，不能無提示複製 PBN／暗手。

## 驗收與資料契約
- `test/ux_02_postgame_result_test.dart` 覆蓋非 Pass Out（NS/EW human score 正負）、Pass Out、Just Declare、四副練習／每日練習正確主 CTA、禁止未結束提前出現、開啟複盤不 mutate active state。
- 至少一條 Widgets/Browser 路徑：完成終局 → 見結果 → 點複盤 → 返回 → 下一副；若真正 BEN 需要服務可做 gated optional，不把 Demo fake pass 說成真 BEN。
- 功能課 `docs/learning/features/M2_F54_POSTGAME_RESULT.md`、驗收 `docs/product/UX_02_POSTGAME_RESULTS_ACCEPTANCE.md`。

## 修改邊界
擁有 `experience/result/`／`widgets/ux_postgame_result_panel.dart` 和結果相關 Widget tests；`bridge_app.dart` **只允許 BridgeTable 終局呈現區的最小整合**，禁止改 UX-01 外層首頁/導航與 UX-03 replay body。其他任務完成後需由 Integration Agent 檢查共享文件 hunk。


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
