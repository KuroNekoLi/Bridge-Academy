# Feature Learning Index — Bridge Academy

本索引是「每功能一份可追溯教學」的入口；規範及格式見 [README](README.md) 與 [Template](FEATURE_LESSON_TEMPLATE.md)。

- DELIVERED：文件已提供，未暗示使用者理解。
- PRACTICED：使用者實際作答或完成練習。
- MASTERED：使用者在回答或實作展示理解，且有可引用的明確證據。

| Feature | 概念 | 教學 | 真實實作／測試 | 學習狀態 |
| --- | --- | --- | --- | --- |
| M1-F01 | 四家 Pass Out、Reducer 與事件完整性 | [M1-F01 — Pass Out](features/M1_F01_PASS_OUT.md) | [game.dart](../../packages/bridge_core/lib/src/game.dart) · [auction_test.dart](../../packages/bridge_core/test/auction_test.dart) · [M1 CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38672191891) | DELIVERED |

## 新功能加入方式
1. 在 PR 中給每個獨立功能唯一 ID：Mx-Fxx。
2. 建立 docs/learning/features/Mx_Fxx_TOPIC.md，填入實作路徑和實測證據。
3. 更新索引本表（若多功能則多列），PR 描述附對應表。
4. 合併前由人工檢查教學是否準確，完成時在 Chat 用一個問題引導學習。
5. 不因 Agent 自己生成教材就將進度提升為 PRACTICED 或 MASTERED。

## M1 其他功能的教學回補候選
合約／莊家判定、Double／Redouble、Actor 與 Hand Owner、Follow Suit、Duplicate Scoring、事件回放與完整手牌隱私。此處只是**尚未交付的回補清單**，不代表已有教材或已驗收學習。
