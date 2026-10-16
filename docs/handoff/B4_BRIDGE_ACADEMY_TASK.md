# B4 / P2 — 橋牌學院原創課程與互動練習

**Branch**: `feature/b4-bridge-academy`  
**Base**: `2a382ac2230afc8059b93f3d4271ccb9bab14c74` (master at assignment)  
**Status**: IMPLEMENTED / CI PENDING (see docs/product/B4_GUIDED_TRAINING_ACCEPTANCE.md)  
**Standalone source**: 此分支的 `AGENT_TASK.md`。請執行程式、測試與文件，不只交分析報告。

**目標**：新增獨立可操作的「橋牌學院」首版。玩家可挑課程、閱讀原創概念、回答練習題並看到可以追溯到 Bridge Core 或明確教學假設的解釋。完成整個使用流程不依賴帳號、雲端、BEN 或 B3.2 約定引擎。

## 建議功能拆分
**B4.1 教材 Domain**：建立 versioned `Lesson`、`Question`、`Answer`、`Explanation` 與驗證器。所有實體固定 `lessonId`、`questionId`、`schemaVersion`、`skillTag`，供未來 C3 統計使用。解析時驗證唯一 ID、合理選項、答案存在、語系完整、格式錯誤拒絕。教材使用雙語文案且有**可解釋的正確答案**。
**B4.2 原創入門課**：最少 3 個小單元、合計最少 9 道原創題，優先使用「52 張／四家位置與對家」、「HCP（A=4/K=3/Q=2/J=1）與牌力」、「跟牌義務／Pass Out／定約目標」等可獨立驗證的基本規則。只教可依 Core 或明確教學定義判斷的內容；涉及約定意義、競叫策略或專家不同流派之題目，標記需專家確認，不可自行宣稱專家核准。每題附答錯說明與來源/規則依據。
**B4.3 互動 Flutter UI**：學院入口（可以從現有桌面薄掛載、也可暫時是獨立可導覽的頁面）、課程卡片、題目操作、送出／正誤／教學說明、完成畫面；中文與英文、可讀取放大字體與窄螢幕。先做局部 session 進度；C3 專門處理加密持久化、跨裝置及弱點統計，不搶 C3 功能。

## 必備驗收與測試
- Domain 題庫 schema/ID/語系完整性；至少 9 道題的正解/錯誤路徑 deterministic tests；對涉及橋規的題利用 `bridge_core` 現有型別或 golden tests 交叉驗證。
- Flutter Widget 正確呈現雙語課程、使用者選項、答案回饋、下一題、返回課程；手機 320px 與文字放大不溢位。
- 模型可序列化且 stable ID 不綁 UI index；答錯不算通過；重複送出或同一題過期狀態不得不當重複計數。
- 不能將抽牌中的其他三家牌公開給玩家；題庫如使用完整牌例必須明確是**獨立教學 fixture** 而非正在進行的私密對局。
- `cd apps/bridge_academy_flutter && flutter analyze && flutter test && flutter build web`；附 CI SHA/URL。
- **排除**：正式帳號、學習紀錄加密持久化、排名、BEN 策略 AI、未核准的 SAYC/2-over-1、高成本完整課程製作、手機實機測試。

## 特別注意 C3 共用契約
這個分支是 `Lesson`/ `Question` **schema 的先行定義者**。必須在 `docs/handoff/B4_LEARNING_PROGRESS_CONTRACT.md` 建立清楚的最小唯讀介面：`lessonId`、`questionId`、`schemaVersion`、`skillTag`，版本及 ID 維護規則；讓未來 `feature/c3-learning-progress` 可以依這份契約新增儲存，不必動課程模型。先不要建立 C3 的帳號或進度服務。

## 建議責任區
新增 `apps/bridge_academy_flutter/lib/src/academy/`、`test/b4_academy_*.dart`、`docs/product/B4_GUIDED_TRAINING_ACCEPTANCE.md`、`docs/handoff/B4_LEARNING_PROGRESS_CONTRACT.md`；Flutter 入口只做薄掛載，既有歷史／叫牌／四副牌功能不得退化。


## 工程與協作底線
1. 先讀此分支的 `AGENT_TASK.md`、`AGENTS.md`、`README.md`、`docs/product/BRIDGE_ACADEMY_PRD_V1.md`、`docs/product/PRODUCT_DELIVERY_ROADMAP.md`、`docs/BRIDGE_RULES_BASELINE.md`、`docs/ARCHITECTURE.md`、`docs/DECISIONS.md`、`skills/README.md`。具體規則、隱私與產品限制以上述正式文件為準；本交辦僅限定新增功能的工作範圍。
2. **僅在指定 feature branch 寫入及 push；不得 push、merge、rebase 或 cherry-pick 到 master；不得開 PR。** 與 master 差異由後續 Integration Agent 審查合併。不得 force push 或重寫別人的 commit。
3. 禁止修改無關功能、Bridge Core 的既有叫牌／出牌／計分規則、A4 Gateway 驗證與 BEN 介面。必須修改共用 `bridge_app.dart`、`bridge_session.dart`、`app_copy.dart` 或 `docs/learning/INDEX.md` 時，限制為極小的掛載／新增與測試；先在交接報告說明衝突可能性。
4. 僅將 bridge-scoped `PlayerView` 與公開資訊交給 UI、一般 Bot 或網路。完整 Deal/PBN 僅存在受信任的 Domain／加密持久層。所有玩家可見文字使用 zh-TW/en 文案。不可宣稱 Demo Bot 等於真正 BEN。
5. 先寫 domain/純 Dart 的可重現測試，再接 Flutter Widget，最後做可操作的 happy path、失敗路徑與窄螢幕 UI；禁止只交靜態假畫面。驗收需提供**實際執行**的命令、結果與 GitHub Actions URL；沒跑寫 NOT RUN，不可編造 PASS。
6. 依 `skills/bridge-learning-mentor/SKILL.md` 和 `docs/learning/FEATURE_LESSON_TEMPLATE.md` 每個可獨立驗收功能附一篇**繁體中文實際程式碼教學**，更新 `docs/learning/INDEX.md`；請在交接中提供一個問題供學習。
7. 使用者要求 Android emulator 與真實 Android/iOS UI/E2E **暫停**；不得啟用或執行該類工作。允許 Dart/Flutter static analysis、unit/widget、Web build、原本允許的 browser／BEN CI。
8. 完工時更新本分支獨有的驗收文件，列明已實作／未實作、測試證據、可觀察的玩家功能、已知限制及回退方式。完成 feature branch 後**刪除根目錄 `AGENT_TASK.md` 並提交該刪除**：避免其他分支合併時此相同路徑衝突；本分支的 `docs/handoff/*_TASK.md` 必須保留。若還需要下一輪 Agent 交接，先讓 Agent 讀完 `AGENT_TASK.md` 並複製本分支專屬 handoff 連結，再刪根目錄短期入口。

## 共用檔案衝突與整合出口
- 可盡量新增獨立 `lib/src/<feature>/`、`widgets/<feature>_...`、`test/<feature>_...`、`docs/product/<feature>_ACCEPTANCE.md`、`docs/learning/features/<unique-id>.md`。
- B4 與未來 C3 學習進度共用的最小契約固定為 **`lessonId`、`questionId`、`schemaVersion`、`skillTag`**；保持穩定字串 ID，後續狀態管理可使用該 ID；不提前打造帳號同步。
- 如果同時有別的 Agent 改同一個 UI/Session 檔，維持 branch 中最小修改，不主動把另一個分支整包合併進來。
- 最後只回報：branch、最新 SHA、操作步驟、變更檔案、CI 證據、教學連結、已知限制、整合注意事項及一個學習問題。
