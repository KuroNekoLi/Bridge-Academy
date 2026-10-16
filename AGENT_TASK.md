# Bridge Academy — B4 Agent Task

**只執行本分支：`feature/b4-bridge-academy`**。本 branch 從 master `2a382ac2230afc8059b93f3d4271ccb9bab14c74` 建立；**目前只有派工文件、沒有宣稱已完成實作。**

## 開始方式
1. 先執行 `git status -sb` 與 `git branch --show-current`，確認是 `feature/b4-bridge-academy`；若非目標分支，必須先切換。工作目錄有未提交變更時，不可直接覆蓋。
2. 詳讀 `AGENTS.md` 與 [本分支完整任務規格](docs/handoff/B4_BRIDGE_ACADEMY_TASK.md)，以及文件要求的來源。
3. 將任務拆成小型、獨立可測試切片，**直接實作**，完成每片就跑測試並提交到本 branch。
4. 同時完成繁體中文工程教學及驗收文件；不要漏掉 Flutter 真實畫面入口。
5. **僅 push 回 `feature/b4-bridge-academy`，不要 push master、不要自己 merge、不要 PR。**
6. 最後一個完工 commit 請刪除此 `AGENT_TASK.md` 避免三支 branch 同路徑合併衝突，保留 `docs/handoff/B4_BRIDGE_ACADEMY_TASK.md` 作為歷史與交接文件。

## 範圍
**目標**：新增獨立可操作的「橋牌學院」首版。玩家可挑課程、閱讀原創概念、回答練習題並看到可以追溯到 Bridge Core 或明確教學假設的解釋。完成整個使用流程不依賴帳號、雲端、BEN 或 B3.2 約定引擎。

要讓人類能獨立使用，不接受只交 Domain Skeleton、Mock Screenshot 或 TODO。若因技術、授權或需人工專家審核而無法完成某部分，請先交可合法驗證的最小切片並在報告標出 BLOCKED。
