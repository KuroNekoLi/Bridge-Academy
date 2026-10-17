# Bridge Academy — UX-03：複盤 → 課程 → 回到牌局

**Branch**：`feature/ux-03-review-learn-loop`  
**Base**：`master@41d0ac604554dc3581cbe59b796b172e81270ee9`  
**Current status**：HANDOFF_READY，尚未實作  
**Provisional learning ID**：`M2-F55`（整合時再查重）

## 玩家目標
玩家檢視已完成牌局的叫牌或出牌教學時，能直接去做對應的 B4 題目，完成或退出後回到原本的複盤事件與歷史牌局，而不必重新搜尋。

## 既有模組與邊界
- `apps/bridge_academy_flutter/lib/src/review/review_timeline.dart` 的 `ReviewTimeline`、`ReviewStep.insights`、`ReviewEvidence.rule/convention/unknown`。
- `widgets/bridge_replay_panel.dart`、`widgets/bridge_history_panel.dart`、`academy/academy_page.dart`、`academy/academy_catalog.dart`、`learning_progress/learning_recommendations.dart`；C1.5 `widgets/dds_review_section.dart` 須保留。
- 不宣稱 B3.2 Stayman/Jacoby `UNREVIEWED` 約定是 BEN 的真實內部決策；DDS 全知結果不等於當時玩家該如何打。策略品質缺乏獨立證據時必須標明 UNKNOWN，不能變成「你打錯了」。
## UX-03 交付切片
1. **已完成牌局的學習機會**：從 `ReviewStep` 明確的規則證據建立 typed `ReviewLearningTarget`；優先用已存在的 `lessonId/questionId/skillTag` 驗證課程 catalog 中是否真的有相對應題目。只有規則有據且實際存在課程才顯示「練習這個觀念／Practice this concept」，UNKNOWN 或不相容 schema 不推薦。
2. **導向真實題目**：`AcademyPage` 增加可選的 course/question deep link，能直接開原題且沿用 `AcademyPractice.submit`。C3 opt-out 時依然能練習，但不得自動 opt-in 或保存答題歷史。
3. **保留返回位置**：從 `BridgeHistoryPanel` 或 `BridgeCompletedReplayPanel` 打開課程，在回來時保留 `reviewHistoryId/replayIndex`，不因切頁重新開始遊戲。如原存檔遭刪除，安全回到歷史列表，絕不使用其他人的資料或留無效路由。
4. **兩語、可達與錯誤**：中英文教學前提、返回 CTA、窄畫面 scroll/無障礙，沒有課程映射時整頁仍可正常複盤。
## 技術責任與跨分支
建議新增 `lib/src/experience/review_learning/review_learning_target.dart` 與 `review_learning_map.dart`；UX-03 擁有 `widgets/bridge_replay_panel.dart` 與 `academy/academy_page.dart` 的極小修改，必要時在 `BridgeTable` 增加 callback。**不要修改 UX-01 的 `BridgeAcademyApp` 外層 Shell、UX-02 結果 Widget、UX-04 Daily Panel**。UX-01 router 尚未合併時，要能透過當前已存在的歷史複盤入口或 Widget harness 實際導向 Academy，不能只有 inert callback。
## 最低驗收
- 有合法規則解釋 → 開指定存在的題目 → 作答／返回 → 原本事件位置不變；無對應/unknown 不誤導、B3.2 未審核聲明保留；未完成的 live Deal 不暴露。
- `test/ux_03_review_learn_test.dart` 驗證 mapping 與 callback/deep-link、opt-out、刪除歷史、中文/英文、320px/2x、跨頁返回；有可執行的 Web browser flow 更好但實際結果要記錄。
- 驗收文件 `docs/product/UX_03_REVIEW_LEARN_ACCEPTANCE.md` 與教學 `docs/learning/features/M2_F55_REVIEW_LEARN_LOOP.md`。


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
