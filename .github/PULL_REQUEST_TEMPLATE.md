## 功能與工程驗收

一列代表一個可以獨立驗收的功能（不是一個 class）。

| Feature ID | 完成功能 | 實作路徑 | 測試證據 | Feature Lesson |
| --- | --- | --- | --- | --- |
| Mx-Fxx | 功能及驗收標準 | 原始碼路徑 | 測試 + CI URL | docs/learning/features/Mx_Fxx_TOPIC.md |

## Engineering Checklist

- [ ] 功能行為、範圍與失敗條件明確
- [ ] 規則正確、資料權限與私有手牌洩漏風險已審查
- [ ] 有確實執行的測試、命令與 CI URL；未執行項目標記 NOT RUN/BLOCKED
- [ ] 正式產品決策若有變更，ADR／Source of Truth 一併更新

## Learn While Building Checklist

- [ ] 每個獨立功能各有一份準確的繁體中文 Feature Learning Note
- [ ] 教材含實際情境、原始碼導讀、替代方案、驗證、練習與成功標準
- [ ] docs/learning/INDEX.md 已新增每個 Feature ID 的連結
- [ ] Agent 在功能完成回報時解釋 1–2 個重點並提出一題小練習
- [ ] 工程 PASS 與教學 DELIVERED／PRACTICED／MASTERED 分開標示

## 若沒有新增功能

純註解、格式或依賴變動可以沒有新教學，但請說明原因；如果改變既有教學重點，仍應更新相關教材。

## 尚待確認的風險與下一步

請列出未通過／未執行項目，不得把 Mock 或假資料冒充真實 BEN 對局。
