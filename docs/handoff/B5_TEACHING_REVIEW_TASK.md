# B5 — 終局教學式複盤與規則解釋

**Target branch**: `feature/b5-teaching-review`  
**Based on**: `master 08a7fb5efcebd8538cfb70624c8975bd9b3eff88`  
**Status**: B5.1–B5.4 SCOPED VERIFIED（Flutter 152/152、Web Build、Chrome Demo）  
**Provisional lesson ID**: `M2-F47`（在整合時必須再次檢查是否衝突）

## 目標
將 A5 的歷史回放轉換成新手能理解的教學流程：逐步定位叫牌／出牌事件、標示已知關鍵規則與可追溯說明；不宣稱在沒有 DDS/完整資訊時知道真正最佳一手。

## 真實依賴
- `packages/bridge_core/lib/src/single_player_coordinator.dart` 已有 `CompletedReplay`、`ReplayFrame`，每幀有過濾過的 `PlayerView` 與 `GameAction`。
- `apps/bridge_academy_flutter/lib/src/widgets/bridge_replay_panel.dart`、`bridge_session.dart` 的 `completedReplay`／`historyReplay`／`HistorySummary`。
- B3.2 `conventions/convention_profile.dart` 有只靠 public dealer/vulnerability/auction 的 explanation engine，規則未審核時不可冒充 BEN。
- B5 擁有所有教學複盤 UI；**C1 僅負責 DD domain/service，勿改同一檔**。兩者在整合輪以公開 `AnalysisResult` DTO 接合。

## 實作拆片
**B5.1 Domain 時間軸：** 由 terminal `CompletedReplay.frames` 做 typed `ReviewStep` 與 `ReviewTimeline`，event index、合法叫品或出牌、round、定約、分數和查看者座位；不重演或竄改任何 Core state。前進／倒退／跳到第一／末／跳關鍵事件後一致，獨立 stored history 與剛完成本局都可進入。
**B5.2 規則解釋：** 區分「規則確定」（跟牌義務、定約所需墩數、dummy 曝露時間、得分）、 「約定前提」（B3.2 有 matched 且標記 unreviewed/proposed）、 「策略品質未知」。至少 5 個具體 deterministic fixtures，包括 Pass Out、加倍、無王牌／王牌、明手開始曝露、跟牌。不能對一個行動作沒有證據的最佳打法判斷。
**B5.3 時間軸 UI：** 終局回放 panel 或獨立 Review Route 可操作，包含事件分組、目前步驟高亮、說明卡、跳轉，zh-TW/en、寬／窄螢幕。不得洩漏四手 `Deal` 或原始 PBN，且不能於活躍牌局開啟事後模式。
**B5.4 玩家重點：** 最小必要的「加入學習重點」本頁標記／複盤摘要，鍵為 historyId + stepIndex，可由 service 接收未來 DDS 分析，但本 branch 不實作資料永久保存或 DDS 求解。若完成後保留本機標記，需使用本機加密且 bounded retention，避免擴大跨 store 負擔。

## 驗收
- 現有 A5 歷史 replay 相同 fingerprint/frames；任意定位正確，重新讀取不變；複盤顯示不揭露原始 full Deal；所有策略推測標記 UNKNOWN/NOT ANALYZED。
- 指標不能偽稱最佳牌或 BEN 策略優劣。明手、牌墩及得分讀自 `PlayerView`／Core，不自己計分。
- Flutter analyze/test/Web、Widget (320px/大字)、Chrome Demo 如果實際受影響；新增 `test/b5_*.dart`、`docs/product/B5_TEACHING_REVIEW_ACCEPTANCE.md`、`docs/learning/features/M2_F47_TEACHING_REVIEW.md`。
- **排除**：DDS 求解、live during-play analysis、將所有私牌公開、B4 課程儲存、直接擴充 Gateway APIs。
## 檔案責任
優先 `lib/src/review/`、`widgets/bridge_replay_panel.dart`、`test/b5_*.dart`。B5 掌握 replay widget；C1 不改它。既有 game reducer 與 BEN transport 禁止碰觸。


## 通用執行契約
1. 先 `git fetch origin && git switch <本分支>`，確認 `git branch --show-current` 與 `git status --short`。只修改本分支；**禁止自行 push / merge master、禁止 PR、禁止 force-push**。完成後只推回本分支，交給 Integration Agent 審查。
2. 依序閱讀 `AGENTS.md`、`README.md`、`docs/product/BRIDGE_ACADEMY_PRD_V1.md`、`docs/product/PRODUCT_DELIVERY_ROADMAP.md`、`docs/BRIDGE_RULES_BASELINE.md`、`docs/DECISIONS.md`、`docs/ARCHITECTURE.md`、`skills/README.md` 與本任務指定來源；使用最小必要技能。
3. Bridge Core 是唯一合法叫牌、跟牌、牌墩、計分權威。一般 UI／BEN／分析摘要只接受其被允許的 `PlayerView` 與公開歷史；不得於 live play 將所有四手 `Deal`、密鑰、權杖或原始受信任 checkpoint 曝露給一般玩家、聊天 AI 或非受信任服務。終局授權分析是獨立的受信任邊界。
4. UI 文案必須繁中／英文。每片完成時有可驗證的 Domain／Widget／端對端證據與玩家可操作的結果，不得只交架構或空畫面；測試使用 deterministic fixtures。
5. 完整執行可行的 `flutter analyze`、`flutter test`、`flutter build web --release`（Flutter 專案在 `apps/bridge_academy_flutter`）。其他 Dart 套件請跑對應 tests；報告列出實際指令、SHA、CI URL、PASS / FAILED / NOT RUN，不能虛構驗收。若 branch CI 未啟動，可暫時只在本分支加入允許的 CI trigger，並在最後一個 commit 還原；不得更動 master 的長期觸發規則。
6. Android Emulator 與任何實體 Android/iOS UI／E2E **繼續暫停**；不可排程、重啟或修改其 guards。Web/Chrome、純 Dart、Flutter Widget、既有真 BEN CI 仍可按任務許可執行。
7. 每項新增玩家行為功能須在 `docs/learning/features/` 寫真實程式碼導讀、設計取捨、測試證據與一題思考題，更新 `docs/learning/INDEX.md`，編號使用本分支暫定保留號但在整合時再次檢查唯一性；不得將 LESSON_DELIVERED 稱為玩家已精通。
8. 最後提交 `docs/product/` 專屬驗收報告，交代玩家流程、實際測試、證據、已知限制、隱私／授權及 rollback。結束前刪除根目錄臨時 `AGENT_TASK.md` 並提交刪除，但保留 `docs/handoff/` 完整任務；若尚未完工勿刪。
9. 除非本分支所需的最小接線，避免改 `bridge_app.dart`、`app_copy.dart`、`bridge_session.dart`、`docs/learning/INDEX.md` 等共用檔案；需要時限縮修改，將可能衝突的 hunk 列在交接報告。不得把其他三個分支合併進來。

## 完工交接格式
請回報 branch 與 HEAD SHA、分段完成情況、實作檔、測試與 CI URL、教學檔、對使用者可見的操作、剩餘風險、與其他分支的衝突風險，最後留一題繁體中文學習題。**測試通過不等於正式產品 Release Gate 通過。**

## 2026-10-16 完工與實測交接
- 變更：`lib/src/review/review_timeline.dart`、`widgets/bridge_replay_panel.dart`、`widgets/bridge_history_panel.dart`、`app_copy.dart`、`test/b5_teaching_review_test.dart`。
- [Flutter CI #38919162697](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38919162697) source SHA `7c5d62942a599032ad5610cb4a49d964531d5bfb`：analyze **PASS**、152/152 tests **PASS**、Web Release **PASS**、Chrome Demo E2E **PASS**。第一輪測試使用 suit-per-seat fixture 沒有跟牌情境，已改用 mixed-suit 牌例回歸。
- [Feature Learning Gate #38919162925](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38919162925)：**PASS**。
- 書籤只存在 Widget 的當次開啟頁面；未修改 Bridge Core、HistoryStore schema 或 BEN/Gateway；不宣稱 DDS 最佳解或裝置／正式部署驗收。
- 合併衝突注意：`app_copy.dart`、`bridge_replay_panel.dart`、`bridge_history_panel.dart`、`docs/learning/INDEX.md`。C1 僅能在下一階段以可信分析 DTO 介接，不可覆寫 B5 複盤 UI。
