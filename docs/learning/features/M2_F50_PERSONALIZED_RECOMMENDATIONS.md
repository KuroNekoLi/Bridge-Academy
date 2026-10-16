# M2-F50｜C3.2 本機個人化學習推薦

- Feature ID：M2-F50
- Milestone：M2／C3.2
- 類型：Flutter UI／規則式推薦
- 工程狀態：IMPLEMENTED（CI 待確認）
- 學習狀態：DELIVERED
- 原始碼：`apps/bridge_academy_flutter/lib/src/learning_progress/learning_recommendations.dart`、`apps/bridge_academy_flutter/lib/src/academy/academy_page.dart`
- 驗收與測試：`apps/bridge_academy_flutter/test/c3_2_personalized_recommendations_test.dart`（初次提交 NOT RUN）

## 功能目的與實際情境
玩家同意 C3 加密保存並回答 B4 原創課程的題目後，重新開啟學院會看到「推薦下一堂練習」。點推薦卡片直接進入現有課程的相關題目。未 opt-in 時不讀紀錄；暫停紀錄者只使用已保留資料；刪除紀錄後推薦立即消失。無新帳號、雲端推薦 API 或額外資料蒐集。

## 主要程式碼導讀
`LearningRecommendationEngine.recommend` 只接收既有 `LearnerProgress`、`AcademyLesson` 與 UTC 時鐘，先核對 lessonId、questionId、schemaVersion、skillTag、optionId 及實際答案是否一致；舊題或不相容紀錄不參與排名。再算每堂課樣本數、正確率、已完成題目、最後仍錯的近 14 日題目。

```dart
if (attempts.length >= minSamples && correct / attempts.length < 0.7) {
  reason = RecommendationReason.lowAccuracy;
} else if (recent.isNotEmpty) {
  reason = RecommendationReason.recentMistake;
} else if (attempts.isEmpty) {
  reason = RecommendationReason.notStarted;
}
```

低正確率需要至少三次作答，只有一次錯誤不會被宣稱為確定弱項。近期錯誤以每題最近一筆合法作答為準，後來答對或超過 14 天就不標記未修正。排名先按理由優先級，再依正確率及穩定 lessonId 排序，不受加密紀錄的儲存順序影響。`AcademyPage._recommendations` 僅在 opt-in 且無儲存錯誤時顯示推薦卡片，點擊呼叫 `_open(lesson, questionId: ...)`，繼續使用 B4 原始答題引擎而不繞過其驗證。

## 為什麼這樣設計
類比 Android Clean Architecture：純 Dart Engine 是 UseCase，既有 `LearnerStore` 是加密 Repository，Flutter 頁面只轉換推薦理由成雙語文字並負責導航。替代方案是把使用者答題紀錄傳給大型語言模型，但涉及隱私、成本與不存在課程的幻覺，因此此階段只採透明規則。不能將 completedCount 當成準確率：它是不同題目完成集合，而準確率分母應是真實作答次數。

## 驗證與實際證據
```bash
cd apps/bridge_academy_flutter
flutter analyze
flutter test test/c3_2_personalized_recommendations_test.dart
flutter test
flutter build web --release
```

初次提交時尚未執行（NOT RUN；此執行環境沒有 Dart/Flutter SDK）。測試設計涵蓋樣本門檻、改正錯題、逾期錯題、未知題庫資料、排序一致性、雙語 UI、點擊導航、opt-in 與刪除。不得將測試程式已存在宣稱為通過。

## 練習與自我檢驗
**思考題（1 題）：** 為什麼玩家只答錯一題時，不應直接標為「弱項」，而且推薦卡片必須顯示作答樣本數？
**5–15 分鐘小練習（可選）：** 新增同課程四次作答三次答錯的例子，檢查推薦理由是否仍為 lowAccuracy。
**完成標準：** 能正確區分完成題數、作答率與最新錯題狀態，理解不同題庫版本不能直接混算。

## 下一步
增加更多原創且有審核依據的教材，才有充分選擇空間。若將來推出跨裝置同步，需另行取得同意，不能藉由此推薦功能擴大資料傳輸。
