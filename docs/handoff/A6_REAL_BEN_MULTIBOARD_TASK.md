# A6 — A6 — 多副真 BEN 牌局、異常與隱私驗收

**Target branch**: `test/a6-real-ben-multiboard`  
**Based on**: `master 08a7fb5efcebd8538cfb70624c8975bd9b3eff88`  
**Status**: SCOPED VERIFIED / GENUINE BEN 4/4 (GATEWAY CI)  
**Provisional lesson ID**: `M2-F49`（在整合時必須再次檢查是否衝突）

## 目標
用固定且可重複的 Bridge Core 牌例對真正 BEN 經 Gateway／Flutter 路徑做多副牌回歸，從目前單副 smoke 升級到最少四副真實 52 張、13 墩的 bounded test matrix，且不誤認為正式部署準備完成。

## 真實基線
- `.github/workflows/ben-flutter-browser.yml` 在 master 真 BEN Chrome E2E 使用固定 BEN SHA `72653ec1b5c17116faea229e9b975ea5622aa1f7`（需對照最新 upstream 更動時另列批准，**本任務不更新 pin**）；現有 [master 真 BEN CI PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38913817917)。
- `services/bridge_gateway/bin/live_gateway_ben_full_game.dart` 提供真 BEN、localhost private backend、server-owned fixed Deal、合法動作與 idempotency 的既有 runner。
- `services/bridge_gateway/lib/src/authoritative_game.dart`、`services/bridge_gateway/lib/src/ben_loopback_backend.dart`、`packages/bridge_core/lib/src/`、`apps/bridge_academy_flutter/integration_test/browser_ben_test.dart` 與 `browser_ben_declarer_test.dart`。
- 禁止將任何 mock Bot 的 PASS 稱為真正 BEN 驗收；不用 mobile emulator 與實機。

## 任務分片
**A6.1 可重複 test fixtures**：選出／製作至少四副互異 52 張原始牌、四家各 13 張，明確固定 dealer、Vulnerability、contract/trump 覆蓋策略，以及合法的 actor 序列；記錄 fixture ID、PBN SHA/公開測試元資料，不輸出私牌到網路日誌。若真 BEN 自然 Pass Out，應仍驗證完整四 Pass terminal；不得偽造非 Pass Out 結果。
**A6.2 多副真 model matrix**：每副實際走既有 private Gateway + pinned BEN，要求至少四副不同真 BEN 場景；正常成約的每副驗證 52 不重複牌、13 完整 trick、合法 seat/ownership/follow-suit、終局 NS 分數與 Core 一致、duplicate board dealer/vul；比對 tournament-related cases 時只用真實 Core 計分（不可由測試寫死 BEN 決策）。
**A6.3 failure recovery**：Gateway timeout/503、被拒絕 action、相同 request ID 重送、event version 衝突、token 錯誤、暫存被竄改、SIGKILL／新 process restore 等；分別區分可使用假後端的安全負例測試及真正 model 正向測試，不硬塞昂貴的所有 fault cases 都要跑 genuine BEN。
**A6.4 可觀測測試結果**：每副耗時、真 BEN bid/lead/play 呼叫數、p50/p95/max、例外/逾時、RSS/負載環境、測試停止上限；標示 system/dependency 時間與模型時間，不把 runner 初始安裝與 AI latency 混算。記錄 model commit、config、seed、runner image。
**A6.5 CI 控制**：以獨立 `workflow_dispatch`（或僅本 branch push trigger）執行較耗時的真 BEN 多副矩陣；使用 timeout、cost/資源上限及可定位的 failed fixture ID，不更改現有 master 必跑 smoke 行為，不影響其他正常 CI、不取消原 PIN、不能啟動 Android/iOS。

## 驗收
- 至少 4 個**不同且固定**的 genuine BEN fixtures 達終局 PASS；清晰輸出非 Pass Out 的 13 tricks/52 張與 Pass Out 四個 Pass 的不同終局規則；包含 dealer/seat/vulnerability coverage（若四副不足完整涵蓋，追加便宜 Core fixture tests）。
- 負例：假 action 重送不變 Core Event version、HTTP auth/session scope、timeout/error sanitized、不被泄漏 deal、在 test-only harness 可恢復 deterministic checkpoint。
- CI 結果需回報成功副數／分母、花費、真模型配置與統計；不得假裝 4 副證明所有競叫、滿貫或生產 Ready。
- `docs/product/A6_REAL_BEN_MULTIBOARD_ACCEPTANCE.md` 詳列 PASS/NOT RUN 及 CI；本工作優先是 test/infrastructure，若產生可測試新工程功能才加 `docs/learning/features/M2_F49_REAL_BEN_MULTIBOARD.md` 並更新索引（不為純 test chore 捏造產品功能）。
## 責任區
優先 `services/bridge_gateway/bin/`、`services/bridge_gateway/test/`、`.github/workflows/ben-*-multiboard.yml`、`docs/product/A6_REAL_BEN_MULTIBOARD_ACCEPTANCE.md`；沒有理由不要動 `bridge_app.dart` 或 C1/B5/C3。


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

## Final integration evidence
Four-board actual BEN regression passed again on [integration CI #38922555451](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38922555451), same merged code SHA `4aa6a1e`. Gateway 34/34 PASS; this is NOT Flutter four-board browser E2E or formal release certification.
