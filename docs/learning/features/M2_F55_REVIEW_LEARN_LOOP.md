# M2-F55｜複盤直達練習題，學完返回原事件

- Feature ID：M2-F55
- Milestone：M2／UX-03
- 類型：Flutter UI／只讀 Domain Mapping
- 工程狀態：SCOPED VERIFIED（Flutter 180/180 + Web + Chrome Demo）
- 學習狀態：DELIVERED
- 原始碼：`apps/bridge_academy_flutter/lib/src/experience/review_learning/review_learning_map.dart`、`widgets/bridge_replay_panel.dart`、`academy/academy_page.dart`、`bridge_app.dart`
- 驗收與測試：`apps/bridge_academy_flutter/test/ux_03_review_learn_test.dart`；[Flutter 180/180、Web、Chrome PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38990226292)

## 功能目的與實際情境
玩家看到終局 B5 複盤的規則解釋時，可以直接做相關 B4 練習題。例如四次 Pass 構成 Pass Out、Core 確認的跟牌，然後按「返回原複盤步驟」回到剛才的事件。未同意保留學習歷史仍可作答。

## 主要程式碼導讀
`ReviewLearningMap.forStep` 僅接受 `ReviewEvidence.rule`，不會把未審核的叫牌約定、UNKNOWN、DDS 雙明手全知數據推論成某張「最佳牌」。在找到規則所對應的精確 `questionId` 後，還需檢查課程 `schemaVersion`、`skillTag` 與有意義的 `ruleReference`。

```dart
for (final insight in step.insights) {
  if (insight.evidence != ReviewEvidence.rule) continue;
  String? questionId;
  if (insight.key == 'reviewPassOutRule' &&
      step.frame.view.phase == Phase.finished &&
      step.frame.view.contract == null) {
    questionId = 'b4.play.pass-out';
  }
  // 其他規則以相同方式檢查可驗證前提
  if (questionId == null) {
    continue;
  }
}
```

UI 不傳 `Deal`、PBN、持久化 key 給新路由，只傳公開課程 stable IDs。 `AcademyPage._openInitialQuestion` 對不匹配的題目安全退回清單；`BridgeTableState._practiceFromReview` push 路由時不重置 `_historyStep` 和 `_replayIndex`，所以 pop 時還在原複盤步驟。若歷史被刪除則清除無效選取。

## 為什麼這樣設計
與 Android/Kotlin Compose 的 `ReviewInsight → NavArgument(lessonId, questionId)` 相似：路由只帶 stable IDs，目的地自行驗證；不把 ViewModel 的私有牌局狀態塞進 Intent／SavedState。另一種方案是用 AI 自由推薦所有叫牌／出牌策略，但目前既無具體規則證據，也可能把 DDS 當成真人能知道的資訊，因此嚴格限制為三種有原創題目的規則。

常見陷阱：用 `ReviewEvidence.convention` 直接解讀 BEN 真實意圖，或把「出牌沒有跟色」當成牌手缺門的證明。這兩者都是缺乏足夠證據的推論。

## 驗證與實際證據
```bash
cd apps/bridge_academy_flutter
flutter analyze
flutter test test/ux_03_review_learn_test.dart
flutter test
flutter build web --release
```
**實際 EXECUTED：** [Flutter CI #38990226292](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38990226292) on commit `075006562f654cac9e3884de6c84d3bf6b272572`：`flutter analyze` 無問題、**180/180 測試 PASS**、Web Release Build 與 Chrome Demo E2E PASS；[Learning Gate #38990226274](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38990226274) PASS。映射、歷史回放、opt-out、過期 ID、320px／2× 字體等已涵蓋；真 BEN/native DDS、Android/iOS 與真人觀察 NOT RUN。

## 練習與自我檢驗
**思考題（1 題）：** 為什麼 `ReviewEvidence.convention` 即使有 ruleId，也不應直接推成「AI 最佳叫牌」的學院建議？

**5–15 分鐘小練習（可選）：** 在 `ux_03_review_learn_test.dart` 加入一份 `schemaVersion` 不相容的假課程，檢查 `ReviewLearningMap.forStep` 必須返回 null。

**完成標準：** 能說出 Evidence 的信任邊界、目標課程 stable ID 的驗證責任、路由切頁和加密學習紀錄的分工。DELIVERED 不代表 PRACTICED／MASTERED。

## 下一步
與 UX-01／UX-02／UX-04 整合，完成全鏈路 Flutter/Web 複盤返回測試和真人觀察；目前 USER_STUDY_NOT_RUN。

**整合測試修正紀錄：** 首次 [Flutter CI #38990088814](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38990088814) 3 項 curly-braces lint 失敗，已修正。對同類型 AcademyPage 的 stale deep link 測試使用新的 ValueKey，確保觸發 initState；後續 [#38990226292](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38990226292) 180/180 PASS。
