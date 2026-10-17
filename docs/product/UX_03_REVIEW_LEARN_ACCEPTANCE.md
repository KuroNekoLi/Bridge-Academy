# UX-03 — 複盤 → 原創題目 → 返回同一事件

- **分支**：`feature/ux-03-review-learn-loop`
- **目前狀態**：IMPLEMENTED / CI PENDING（不是產品正式上線驗收）
- **依據**：PRD GJ-03、UX-03 handoff、B5 ReviewTimeline、B4 Academy、C3 opt-in
- **資料界線**：只有終局 `CompletedReplay` 的過濾 `PlayerView` 與公開 Academy IDs

## 玩家流程與真實程式碼
1. 在已完成的當前牌局或歷史牌局的複盤事件，看到可驗證規則說明。
2. `ReviewLearningMap.forStep` 僅對精確且有據的 `ReviewEvidence.rule` 做對應（完整四 Pass 的 Pass Out、Core 已確認的跟牌、4♠ 定約所需墩數）；驗證 B4 課程中的 `lessonId/questionId/skillTag/schemaVersion` 後才顯示「練習這個觀念」。其他情況顯示可繼續複盤的明確空狀態。
3. 點擊 CTA 直接進入 B4 真的存在的題目。沿用原本 `AcademyPractice.submit`、C3 自願同意才加密記錄的政策；不自動保存與更改 opt-in。
4. 點「返回原複盤步驟」回到原本 `_replayIndex` 或 `_selectedHistoryId/_historyStep`。若歷史存檔在切頁時消失，安全關閉選取、不引用過期的路由資料。
5. 課程目標過時／不存在時顯示「題目已不存在」並安全回課程清單；保留雙語、窄畫面與大字體。

## 明確不做
不使用原始四手牌、PBN、DDS 的全知結果推論當時最佳策略。B3.2 未審核約定與 UNKNOWN 不會自動觸發推薦。沒有帳號同步、遙測、正式多人競賽，也不擴充其他三個 UX 分支的 UI。

## 驗證與工作證據
```bash
cd apps/bridge_academy_flutter
flutter analyze
flutter test test/ux_03_review_learn_test.dart
flutter test
flutter build web --release
```
**分支 CI 尚未結束：NOT RUN／PENDING**。請以本功能最新 SHA 的 GitHub Actions 更新，不得把測試檔視為 PASS。真人研究：USER_STUDY_NOT_RUN。Android/iOS emulator/real-device UI/E2E 依使用者決策持續暫停。

## Integration／Rollback
保留 UX-01 Shell、UX-02 結果頁、UX-04 每日面板；UX-03 只在 `BridgeTable` 既有 replay/history 接線。依 UX-01 → UX-02 → UX-03 → UX-04 順序整合，處理共用 `bridge_app.dart` 的小段差異。可撤回本分支而不刪除既有加密學習紀錄、B5 歷史牌局與 Core 事件。
