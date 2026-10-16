# M2-F46｜C3 儲存學習進度與 Privacy by Default

- Feature ID：M2-F46
- 工程狀態：IMPLEMENTED / CI PENDING
- 學習狀態：DELIVERED
- 原始碼：`apps/bridge_academy_flutter/lib/src/learning_progress/` 與 `academy/academy_page.dart`
- 驗收：`docs/product/C3_LEARNING_PROGRESS_ACCEPTANCE.md`

## 主要程式碼導讀
`LearnerAttempt` 代表一次真實送出的回答；`LearnerProgress` 裡的 Set 只用於已答對的不同 questionId。因此同題答錯兩次、答對一次，答題正確率是 1/3，但完成數是 1 題。

```dart
_items.add(item);
_ids.add(item.id);
if (item.correct) _completed.add(item.answer.questionId);
```

`EncryptedLearnerStore` 使用 AES-GCM 且為學習資料獨立的 AAD 與 key namespace；沒有保存 consent 前不存在歷史紀錄。解析格式錯誤或驗證失敗會向 UI 呈現儲存錯誤，不會假裝成功恢復。

## 設計取捨
對 Android 工程師可類比 Clean Architecture 的 Domain 事件、Repository 及 ViewModel；避免把 B4 的 session-only Set 直接序列化，因為完成題數與所有作答紀錄具有不同的統計意義。相比直接塞進牌局的 checkpoint，獨立資料可避免洩漏 PBN／全手牌。

## 測試證據
`flutter test test/c3_learning_progress_test.dart`、`flutter analyze`、`flutter build web`：待 GitHub CI 驗證，尚不可標記 PASS。Android/iOS 真機驗收依原決策暫停。

## 練習與自我檢驗
**問題：** 同一題答錯兩次後答對一次，完成率與正確率各是多少？為什麼要保留兩種統計？
**實作練習：** 為 `LearnerProgress.fromJson` 寫一項重複 attempt ID 的拒絕測試，然後為未來 schema migration 設計版本策略。

## 下一步
保留真正跨版本內容更新、超過 500 筆的淘汰政策作為下一里程碑。
