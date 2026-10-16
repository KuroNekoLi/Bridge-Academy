# C3 — C3 — Opt-in 學習紀錄、加密保存與學習儀表板

**Target branch**: `feature/c3-learning-progress`  
**Based on**: `master 08a7fb5efcebd8538cfb70624c8975bd9b3eff88`  
**Status**: SCOPED VERIFIED / IMPLEMENTED ON FEATURE BRANCH  
**Provisional lesson ID**: `M2-F46`（在整合時必須再次檢查是否衝突）

## 目標
將已交付的 B4 橋牌學院三堂九題變成可持續學習的體驗：使用者明確同意後保存答題歷史，重啟仍能查看完成率、個別 skillTag 的正確率及錯題，且可完全刪除。

## 依賴與程式真實入口
- `docs/handoff/B4_LEARNING_PROGRESS_CONTRACT.md` 明確定義 `lessonId`、`questionId`、`schemaVersion`、`skillTag`、`AcademyAnswer`。
- `apps/bridge_academy_flutter/lib/src/academy/academy_models.dart` 的 `AcademyPractice.submit()` 與 `AcademyFeedback`，`academy_page.dart` 的 `_submit`／`_advance`、`academy_catalog.dart`。
- 已有獨立加密儲存慣例：`daily_practice_store.dart`、`secure_session_persistence.dart` 內 `AtomicArchiveRecordStore` 與 `ArchiveEncryptionKeyProvider`。不得與既有 active Deal、history、daily ledger 共用相同 AAD/鍵名/資料 namespace。

## 實作拆片
**C3.1 純資料領域：** 自訂 `LearnerAttempt`（獨立 attempt ID、日期／UTC 時間、lesson/question ID、schema/content 版本、skillTag、是否正確、必要時選項 ID），`LearnerProgress`、版本化 JSON codec。須防重放和兩次提交重複計數；「題目完成」與「歷史答題次數」分開統計，未答題不參與正確率分母；保留原題 ID 與 schema 的相容／遷移／不認得舊題語意政策。避免儲存無用或敏感的活躍牌局資訊。
**C3.2 Opt-in 加密紀錄：** 首次預設不保存，使用者明示同意後建立本機加密 Ledger；可停用保存、立即刪除所有歷史、成功通知與失敗保護。損毀 ciphertext 要 fail-closed、不得默默以空資料取代。單寫入 atomic 的合理性、跨 store 交易不保證 atomic 的限制需文件化。設定可本機保存但絕不預設同步雲端。容量、retention、改版本、時間注入、拒絕異常輸入。
**C3.3 真實 UI：** 學院課程及可進入的學習儀表板，包括已完成／未完成、每個 skillTag 的正確率（並顯示樣本數與 0 樣本的「未有資料」）、最近練習及清除確認對話；zh-TW/en，320/375 px、高倍率文字、無障礙標籤。
**C3.4 B4 整合：** 從 `AcademyPage` 的單次 `AcademyPractice.submit` 取得真實結果，僅在 opt-in 時落盤，不更改 B4 答案的正確性，不另行實作判定引擎。

## 最小驗收
- 總共 9 道現有 B4 題在 opted-out 情況不持久化；opt-in 之後原始答錯事件會記錄但不增加完成數，同題首次答對增加 1 次完成、反覆重複不加完成數。
- 關閉頁面與重新建構 App 恢復；切換語系不變 ID；同 skillTag 0/多次嘗試正確率有可重現數值；舊版／損毀資料拒絕覆蓋；永久刪除後重新啟動仍為空；沒有帳號同步及他人私牌。
- 跑完整 Flutter analyze/test/Web；新增 `test/c3_*` 的 Domain、加密 adapter、Widget 測試及相關回歸。寫 `docs/product/C3_LEARNING_PROGRESS_ACCEPTANCE.md`、`docs/learning/features/M2_F46_LEARNING_PROGRESS.md`。
- **排除**：跨裝置登入、會員後端、社群排行榜、AI 自動產題、C2 約定專家核准。
## 檔案責任
優先新增 `lib/src/learning_progress/`、`test/c3_*.dart`、`docs/product/C3_LEARNING_PROGRESS_ACCEPTANCE.md`；`academy_page.dart` 與 `bridge_app.dart` 僅作必要接線。不要修改 B5 重播／C1 DDS。


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

## 2026-10-16 完成交接與限制
C3 Domain、v1→v2 相容、預設不保存、分離加密金鑰與儲存、暫停/恢復、儀表板、永久刪除、繁中／英文已於此分支實作。 [Flutter CI 151/151 + Web + Chrome PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38919859220)；[Feature Learning Gate PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38920478719)。原本的 CI 觸發條件已還原，master 未變更。限制：無雲端同步、超過 500 筆拒寫、不保證跨多裝置/分頁交易原子性，無 Android/iOS 裝置測試。
