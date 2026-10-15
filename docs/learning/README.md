# Bridge Academy — 邊做邊學（Learn While Building）

這份流程是幫助**開發者**在 Agent 寫程式時理解技術，不是未來 App 內的橋牌教學功能。

## 核心契約
一個完成的功能 = **可驗證的實作 + 測試證據 + 專屬功能教學 + 完成時的互動講解**。

- **功能**指有獨立可驗證的行為，例如 Pass Out、PlayerView、BEN 首攻 Adapter、Flutter 叫牌盒。不是每個 class、commit 或註解都要各寫一篇。
- 同一 PR 有三個獨立功能，就要三篇篇幅適中的 Feature Lesson。純格式修正、設定更新等不必虛構新功能。
- 與功能同一個 PR 在 docs/learning/features/ 提交教學，更新 INDEX.md，連回實作與測試。
- 工程 PASS 不等於使用者已學會。只有教學寫完時標記 DELIVERED；使用者實際回答／操作後才能標 PRACTICED 或 MASTERED。
- 程式註解解釋不直覺的決策；**註解不能取代教學**。也不必為了教學在產品程式碼塞滿教科書式註解。

## 教學的五個必備部分
1. **功能目的與實際情境** — 這個功能解決什麼、玩家看到什麼、驗收條件。
2. **主要程式碼導讀** — 真正的類別／方法與資料流，短的關鍵片段，必要時用圖。
3. **為什麼這樣設計** — 原理、替代方案、取捨、陷阱；適當和 Android/Kotlin 比較。
4. **驗證與實際證據** — 可重現的操作或指令、預期斷言、真實 CI 和版本；沒有跑就寫 NOT RUN。
5. **練習與自我檢驗** — 一道思考題與可選的 5–15 分鐘小練習，附完成標準。

格式見 [Feature Lesson Template](FEATURE_LESSON_TEMPLATE.md)。

## Chat 的教學節奏
Agent 先完成工程與測試；完成一個功能時同步寫 Feature Lesson。回報進度後，**用 3–8 句口語化繁體中文講解一個重點，附真實原始碼連結，問一道題**。使用者答後優先評估思路，最多糾正 1–2 個最重要的錯誤，再給一個應用變化題。若使用者選擇不作答，仍可繼續開發，不應卡在測驗。

## Kotlin / Android 概念遷移

| Android 已熟悉 | Bridge Academy 對照 | 不可混淆的差別 |
| --- | --- | --- |
| ViewModel + UiState / 單向資料流 | GameState + Action + Reducer | Domain Core 才有規則判定權 |
| Kotlin sealed class | Dart sealed class | 語法與版本限制不同 |
| Repository / UseCase | BEN Adapter / Bridge Core | AI 只是行動提案者 |
| StateFlow 與 Compose | Flutter reactive state | 並非完全同義 |
| Room migration | 事件版本與回放 | 需額外確認隱私與完整性 |
| Android instrumented test | 牌局回放與固定種子測試 | 合法對局 ≠ AI 策略強 |

## PR Review 的教學 Gate
Reviewer 逐一核對 Feature ID → Lesson → Implementation → Test，確認題目可答、解釋與真正原始碼相符、測試狀態沒有造假。CI 會做最低限度的檔案門檻檢查，但一個 PR 中多功能一對一對應仍需人工審查。

另見 [Feature Index](INDEX.md)、AGENTS.md 與 skills/bridge-learning-mentor/SKILL.md。
