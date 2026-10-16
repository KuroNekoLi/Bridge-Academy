# M2-F50｜B4.2 進階課程：從靜態題庫到可驗證的玩家教學

- Feature ID：M2-F50
- Milestone：M2 / B4.2
- 類型：Flutter UI、雙語教材、Bridge Core 規則交叉驗證、C3 整合
- 工程狀態：IMPLEMENTED（CI 待核）
- 學習狀態：DELIVERED
- 原始碼：`apps/bridge_academy_flutter/lib/src/academy/academy_advanced_catalog.dart`、`academy_catalog.dart`、`academy_page.dart`
- 驗收與測試：`apps/bridge_academy_flutter/test/b4_2_advanced_domain_test.dart`、`b4_2_advanced_widget_test.dart`；**NOT RUN（尚待 CI）**

## 功能目的與實際情境
原本 B4.1 的三堂九題著重座位、HCP 與跟牌入門。B4.2 再提供三堂共十二題雙語情境練習：防守跟牌／王牌／明手、定約與計分規劃、如何辨認教學約定的適用邊界。玩家可以照原本的學院流程「選課→作答→錯誤說明與重試→完成→返回」，亦可在 C3 明確同意保存後，於進度頁看到正確率與已完成數。

## 主要程式碼導讀
`AcademyCatalog.lessons` 保留原本 B4.1 常數題目的穩定 ID，藉由 `...AcademyAdvancedCatalog.lessons` 將額外課程接入唯一的 `AcademyValidator.validate`。所有新增題目使用 `b4.2.*` 全域唯一 ID，並維持 C3 schema v1 與每課 skillTag 一致。

```dart
static List<AcademyLesson> validated() {
  AcademyValidator.validate(lessons);
  return lessons;
}
```

學院頁面仍使用原 `AcademyPractice.submit` 驗證已提交的 optionId，並呼叫 C3 `LearnerProgress` 以獨立 attempt 記錄。這相當於 Kotlin/Compose 中「純領域題庫 + ViewModel 事件 + opt-in Repository」的分層，而非在 UI 字串上做答案比對。

對定約題，在測試中將答案與 `Contract.targetTricks`、`DuplicateScore.score` 相互驗證；對 Stayman/Jacoby 問題，以 `ConventionExplanationEngine.resolve` 的 public-only `BidContext` 驗證 `PREVIEW-*` ruleId，並檢查 `unreviewed`。**不使用完整四家 Deal、BEN 模型推理或即時私牌**。

## 為什麼這樣設計
直接增修 B4 題庫即可復用 C3 的 `AcademyAnswer{lessonId,questionId,schemaVersion,skillTag}`，不需修改加密存檔 schema。合理替代方案是做全新進階學院，但會重建課程 UI、答題狀態與 C3 鍵值契約，產生兩套學習真相。最容易犯的錯，是把「某約定的公開意義」寫成「可驗證對家真的持有該牌力」；因此約定課首段明確聲明只有教學檔案的未審核解釋。

## 驗證與實際證據
```bash
cd apps/bridge_academy_flutter
flutter analyze
flutter test test/b4_2_advanced_domain_test.dart
flutter test test/b4_2_advanced_widget_test.dart
flutter test
flutter build web --release
```

狀態：**NOT RUN**。等待分支 Actions 的具體 SHA、測試數和結果。非真 BEN 上課、不含真人橋牌專家內容審核、Android/iOS 裝置 QA 暫停。

## 練習與自我檢驗
**思考題（1 題）：** 為什麼「2♦ 是轉到紅心的 Jacoby 約定」即使有 `ConventionExplanationEngine` 的 matched 結果，也不能證明真正 BEN 會這樣叫牌？

**5–15 分鐘小練習（可選）：** 在 `b4_2_advanced_domain_test.dart` 增加 Jacoby 2♥→♠ 的正向情境，再把 East 改為合法插叫確認 matcher 回 UNKNOWN。

**完成標準：** 能明確分辨 Bridge Core 規則、Duplicate Scoring、固定課程假設與沒有經專家審核的叫牌協定，並說明資料信任邊界。

## 下一步
可逐步加入有版號的牌例練習、題目層級審核狀態、與 C3 的自動弱點推薦。還不應把固定教學約定當成正式競賽標準。
