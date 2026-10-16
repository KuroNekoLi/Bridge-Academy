# B4 ↔ C3 學習資料契約 v1

**Branch:** feature/b4-bridge-academy  
**契約狀態：** IMPLEMENTED (B4)／C3 NOT IMPLEMENTED  
**設計目的：** 讓 C3 在不改 B4 題目結構的前提下開發本機加密學習紀錄。

## 公開只讀結構
程式碼：apps/bridge_academy_flutter/lib/src/academy/academy_models.dart

- Lesson：lessonId（全域穩定且唯一的非空字串）、schemaVersion（v1 int）、skillTag（非空穩定字串）、title／summary／introduction（zhTw、en）、questions（≥1）。
- Question：questionId（跨所有 Lesson 全域唯一）、skillTag（與 Lesson 一致）、prompt（zhTw、en）、options（每題至少 2 個、optionId 不重複）、correctOptionId（必須存在）、explanation（correct／incorrect 雙語＋ruleReference）。
- AcademyAnswer：lessonId、questionId、schemaVersion、skillTag、selectedOptionId。toJson/fromJson 可安全交接原始答題事件，但**目前 B4 不負責持久儲存**。
- 題庫版號由 Lesson schemaVersion 表示資料格式；未來更換內容不可讓舊紀錄的 questionId 對應到不同題意。新增題目用新 ID；替換題意時使用新 questionId 或引入 contentRevision 與明確遷移策略。
- 課程內部 optionId 為非語意標籤（a/b/c 等），不可依 Flutter 顯示順序或本地化文字儲存進度。

## C3 建議消費格式
- 每筆練習結果的最小識別：schemaVersion、lessonId、questionId、skillTag。
- 可新增：回答時間、是否正確、答題次數；與 B4 的 AcademyPractice session-only 已完成集合分離。
- C3 必須自己決定加密存檔的 ID/version/migration/retention；不得將 answer DTO 假裝已是安全儲存契約。
- 不把活動牌局 PlayerView 的私人牌張記在答題事件；目前所有 B4 題目是完全原創、固定的獨立教材，非遊戲當下 PBN。
- B4 答錯不計完成；重複對相同 questionId 答對僅首次計入集合。長期「正確率」應根據 C3 記錄的 Attempt，而非把完成數除以提交次數。

## API 使用範例
1. AcademyCatalog.validated()：檢查所有題目唯一性、答案存在、雙語完整。
2. AcademyLesson.toJson()/fromJson()：題庫模型資料往返與版本驗證。
3. AcademyAnswer.toJson()/fromJson()：單次答題記錄結構。
4. AcademyPractice.submit()：單頁暫存正誤與去重；C3 不依賴此物件序列化。

## 兼容性與後續驗收
現在只有 schema version=1；解析陌生版本後 AcademyValidator.validate 拒絕。C3 應測試舊 ID 重開、重複事件去重、損壞資料 fail-closed 及加密持久化。B4 不含帳號、排名、跨裝置同步。
