# Bridge Academy — C1 Coding Agent Task

**指定分支：`feature/c1-dds-analysis`**。起始基準 `master@08a7fb5efcebd8538cfb70624c8975bd9b3eff88`。目前尚未實作本輪功能。

## 啟動
1. 請先確認現在分支為 `feature/c1-dds-analysis`；否則安全切換。目錄如有未提交變更，先停下處理，不能覆寫。
2. 先讀 `AGENTS.md`，再完整閱讀 `docs/handoff/C1_DDS_ANALYSIS_TASK.md`；請依其中的範圍與驗收自行切片並立即實作，非僅提出規劃。
3. 只 commit/push 本分支，交付真實跑過的測試與繁體中文教學；不可推送 master、開 PR 或合併其他分支。
4. 完工最末次提交刪除此臨時 `AGENT_TASK.md`，只保留 branch 專屬永久任務文件供審查／整合。

## 主要目的
提供獨立的 post-game DDS analysis API：已完成牌局才可在受信任的分析邊界用 52 張牌求得 DD Table 或出牌解；任何 live session／普通 BEN／玩家視圖不得取得這份特權資訊。

[詳細工作拆分、驗收與限制](docs/handoff/C1_DDS_ANALYSIS_TASK.md)
