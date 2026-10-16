# Bridge Academy — B3.2 Agent Task

**只執行本分支：`feature/b3-convention-profile`**。本 branch 從 master `2a382ac2230afc8059b93f3d4271ccb9bab14c74` 建立；**目前只有派工文件、沒有宣稱已完成實作。**

## 開始方式
1. 先執行 `git status -sb` 與 `git branch --show-current`，確認是 `feature/b3-convention-profile`；若非目標分支，必須先切換。工作目錄有未提交變更時，不可直接覆蓋。
2. 詳讀 `AGENTS.md` 與 [本分支完整任務規格](docs/handoff/B3_2_CONVENTION_PROFILE_TASK.md)，以及文件要求的來源。
3. 將任務拆成小型、獨立可測試切片，**直接實作**，完成每片就跑測試並提交到本 branch。
4. 同時完成繁體中文工程教學及驗收文件；不要漏掉 Flutter 真實畫面入口。
5. **僅 push 回 `feature/b3-convention-profile`，不要 push master、不要自己 merge、不要 PR。**
6. 最後一個完工 commit 請刪除此 `AGENT_TASK.md` 避免三支 branch 同路徑合併衝突，保留 `docs/handoff/B3_2_CONVENTION_PROFILE_TASK.md` 作為歷史與交接文件。

## 範圍
**目標**：在 B3.1 的有限自然 NT 示範上新增可版本化 `ConventionProfile` 與嚴格依公開叫牌上下文運作的解釋引擎，先讓玩家看見可信的、標記審核狀態的約定資訊。**不得**把選擇 Profile 說成 BEN 會自動遵守該體系。

要讓人類能獨立使用，不接受只交 Domain Skeleton、Mock Screenshot 或 TODO。若因技術、授權或需人工專家審核而無法完成某部分，請先交可合法驗證的最小切片並在報告標出 BLOCKED。
