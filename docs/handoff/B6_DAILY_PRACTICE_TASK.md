# B6 / P1 — 每日固定牌局練習（無排名）

**Branch**: `feature/b6-daily-practice`  
**Base**: `2a382ac2230afc8059b93f3d4271ccb9bab14c74` (master at assignment)  
**Status**: SCOPED_VERIFIED / READY_FOR_INTEGRATION  
**Standalone source**: 此分支的 `AGENT_TASK.md`。請執行程式、測試與文件，不只交分析報告。

**目標**：玩家可以在 Flutter 單人模式開啟今日固定四副原創練習牌局，當天重進或重新啟動能找到同一組牌，完成後看到個人進度與原始 Duplicate 得分總和。不得假冒賽事、公開排行或跨玩家公平比較。

## 目前可重用的程式
- `packages/bridge_core/lib/src/model.dart` 的 `Deal.shuffled(seed: ...)` 與 `Deal.fromPbn`；`board_definition.dart` 的標準 dealer/vulnerability。
- `apps/bridge_academy_flutter/lib/src/four_board_practice.dart`、`bridge_session.dart`、`session_persistence.dart`、`bridge_app.dart` 已提供四副牌練習、加密活躍 checkpoint、完成歷史。
- 禁止把 B1 改造成每日練習而破壞原模式。獨立建立 B6 `DailyPracticeManifest`、`DailyPracticeProgress`、可注入的 `Clock`／日期解析器及 session adapter。

## 建議切片（依序完成，每片可獨立驗收）
**B6.1 日期與牌組模型**：定義 `challengeId`（穩定的 `YYYY-MM-DD` + manifest version）、UTC 日期定義、四個互異的 `boardId`、指定種子或原創 PBN 與 board metadata。相同日期/版本在重啟與重新建構時必須得到相同 52 張、四家各 13 張、dealer/vulnerability；不同日期的挑戰 ID 不相同。manifest 發版方式要可版本化、可重現；若採 seed，固定生成演算法／順序並附 golden fixture，不能依 Dart runtime 未承諾的跨版本 shuffle 實作來保證未來永遠一致。原創教材素材不得複製競品 PBN。
**B6.2 本機練習進度**：保存 `challengeId`、正在進行的副數、完成的副數與每副原始分數、重試／切換日期政策；復用加密 checkpoint／獨立加密結果儲存，未完成與完成的狀態不可不當覆蓋。跨 UTC 換日後舊挑戰保留可閱讀，不自動把未完成局當成今日新牌；不需要雲端比較。
**B6.3 Flutter 可操作入口**：新的「每日練習」按鈕及進度卡、四副牌導航、完成摘要、重試提示、日期標籤，中文與英文；需真實串接 session、選擇合法叫牌／出牌仍交由 Core。桌面/Web 與 320/375px 無溢位。

## 必備測試與驗收
- 固定時鐘同日兩次結果完全一致；跨日不同 ID；四副原始牌分布皆為 52 張唯一；板號、dealer/vul 遵守 Core；manifest 版本改變不誤認為舊挑戰。
- 固定日進度記錄 0→1→2→3→4，重啟恢復；中途退出、重打、跨日期、損毀儲存要有定義並驗證；完成四副的玩家視角得分符號正確。
- 真正 Flutter Widget 操作、zh-TW/en、無出牌前公開其他三家手牌、沒有 MP/IMP/排行榜 UI。
- `cd apps/bridge_academy_flutter && flutter analyze && flutter test && flutter build web`，對應 CI/Chrome 需附 SHA、完整結果。
- **排除**：雲端今日牌局比較、MP/IMP 排名、好友 PK、BBO 賽事、公平性與反作弊、手機實機 E2E。

## 建議責任區
優先新增 `apps/bridge_academy_flutter/lib/src/daily_practice.dart`（或 `daily_practice/`）、`test/b6_daily_practice_test.dart`、`docs/product/B6_DAILY_PRACTICE_ACCEPTANCE.md` 和獨立 Flutter Widget。Session/UI 只作薄掛載；不得動 Gateway 與 BEN 接口。


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

## 完成交接（2026-10-16）
- Source commit `24754685`; [Flutter 124/124 + Web + Chrome Demo](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38910655183) PASS.
- 已完成功能與限制請參見 [B6 驗收](../product/B6_DAILY_PRACTICE_ACCEPTANCE.md) 與 [工程教學](../learning/features/M2_F43_DAILY_PRACTICE.md)。
- 共用整合衝突面：bridge_session.dart、bridge_app.dart、session_persistence.dart、app_copy.dart、docs/learning/INDEX.md。Integration Agent 須逐一複查其他 Feature Branch 修改。
- 本分支最終移除根目錄 AGENT_TASK.md；不可自行 push master、merge 或開 PR。
