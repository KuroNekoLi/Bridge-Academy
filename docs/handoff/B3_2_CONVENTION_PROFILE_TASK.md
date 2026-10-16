# B3.2 / C2 — 版本化叫牌約定與可驗證的解釋器

**Branch**: `feature/b3-convention-profile`  
**Base**: `2a382ac2230afc8059b93f3d4271ccb9bab14c74` (master at assignment)  
**Status**: HANDOFF_READY / IMPLEMENTATION_NOT_STARTED  
**Standalone source**: 此分支的 `AGENT_TASK.md`。請執行程式、測試與文件，不只交分析報告。

**目標**：在 B3.1 的有限自然 NT 示範上新增可版本化 `ConventionProfile` 與嚴格依公開叫牌上下文運作的解釋引擎，先讓玩家看見可信的、標記審核狀態的約定資訊。**不得**把選擇 Profile 說成 BEN 會自動遵守該體系。

## 權威來源與既有實作
必讀 `docs/CONVENTION_SYSTEM.md`、`docs/product/B3_BIDDING_PRACTICE_ACCEPTANCE.md`、`apps/bridge_academy_flutter/lib/src/bidding_practice.dart`、`packages/bridge_core/lib/src/model.dart`、`player_view.dart` 與 `single_player_coordinator.dart`。

## 獨立切片
**B3.2a Versioned Domain**：新增 `ConventionProfile{id,revision,agreements,locales,references,reviewStatus}`、`BidContext{actingSeat,vulnerability,auction,partnership,...}`、`BidExplanation{ruleId,meaning,assumptions,reviewStatus}` 等明確的純 Dart 型別。保留 B3.1 的 `BA-NATURAL-NT` ID，提供明確遷移策略；未達成前不要破壞既有 B3.1 約定與 API。遇不明、含敵方干擾、或不合法／不一致的序列回 UNKNOWN/UNSUPPORTED，而非猜測。
**B3.2b 規則匹配與真實語義邊界**：將 1NT 15–17 HCP 均型、2NT 邀請、3NT 進局、開叫方 3NT 接受等**既有教學約定**遷移成資料驅動規則並驗證精確位置與對家關係；另外加入 Stayman 2♣、Jacoby Transfer 2♦／2♥ 的**預覽規則**，只有在啟用、上下文滿足且標記 UNREVIEWED 時才展示，並附不確定性與需專家覆核資訊。若專家來源不足，寧可保持規則 `proposed` 而不要讓自動建議或評分依賴。
**B3.2c Flutter 展示**：B3.1 叫牌練習使用新的 Explanation Engine 顯示約定版本、規則說明、審核/未核准標記與「無法判斷」狀態；如要給選單，僅在已有資料與明確可用的 profile 上顯示。**不要變更 BEN Bot 的選擇機制，不能宣稱切換約定就訓練或約束 BEN**；Bridge Core 仍驗證所有叫品。

## 驗收條件
- 純 Dart context fixtures：前置 Pass 的 1NT、對家無插叫 2NT／3NT、插叫、Double/Redouble、不同座位、南北/東西有局、回應前後已有其他叫品、版本失配等，證明 Unknown 優於假確定性。
- 不看隱藏牌：實時建議只使用 `PlayerView` 的自己 13 張與公開 auction，解釋器只依公開可見的座位／叫牌資訊。
- 所有規則可追蹤 `ruleId`、語系、版本、來源/專家狀態；不得把 B3.1 Demo 解釋冒充真正 BEN 支援。
- Flutter 中文／英文解釋與 UNKNOWN 狀態 Widget 測試。保持既有 B3.1 測試、全部 Bridge Core、A5/B1/B2 回歸。
- `cd apps/bridge_academy_flutter && flutter analyze && flutter test && flutter build web`，記錄 CI SHA；此階段的專家審查門檻**不因單元測試通過就宣稱完成**。
- **排除**：直接重訓 BEN、全套 SAYC 或 2/1 完整支援、網路教學模型、需要授權的外部資料直接搬用、手機實機測試。

## 建議責任區
新增 `apps/bridge_academy_flutter/lib/src/conventions/`、`test/b3_2_convention_*.dart`、`docs/product/B3_2_CONVENTION_PROFILE_ACCEPTANCE.md`，並只對 `bidding_practice.dart`/Flutter 入口做必要接線；不要改 A4 Gateway/BEN 或 Bridge Core 法律性。


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
