# 目前開發交接（屬於產品規劃）

> 2026-10-26（台北）。本檔僅為目前工作狀態與下一工作入口，避免積累版本流水帳。**外部 Codex 用量工具在本 ChatGPT 工作環境並未提供**，其使用量數值為 **UNKNOWN**；不推算、不宣稱有持續即時監控。若其他具用量工具的 Agent 偵測任一窗剩餘 ≤30%，優先更新本檔並通知使用者。

## 最近工作

- 目標：`docs/` 從 190 個檔案精簡至 7 個，三類來源：已實現功能、產品規劃、研究報告。已保留技術不變條件與發行 NO-GO，重寫入口 README/AGENTS/skills 參照；使用一個可回退的新 commit 執行內容更新與舊文件刪除。
- 仍維持：使用者允許直接 push master、不開 PR、不 force-push；A3.5、Android/iOS emulator 與實機 UI/E2E **OWNER HOLD**；尚未批准正式公開部署。
- 重要連結：[已實作](../implemented/FEATURES.md)、[工程導讀](../implemented/ENGINEERING_NOTES.md)、[產品路線與發行 Gate](ROADMAP.md)、[決策](DECISIONS.md)、[研究](../research/RESEARCH_REPORTS.md)。
- 下一項產品實作：**U3** 牌桌可操作性與動畫／窄屏；**U4** Gateway 安全續局／雲歷史；**A4.5** VPS 真測＋授權＋TLS。
- 驗證方式：檢查 master Git tree 中 `docs/` count ≤10、沒有保留文件死連結、Feature Learning Gate（`scripts/test_check_feature_lessons.py`）、既有 workflow 狀態。Docs 精簡不代表重跑了所有 BEN/Flutter/手機測試。
- 回退：對 docs 清理 commit 執行 `git revert <cleanup_commit>`；Git 歷史可以查閱完整 190 份來源資料。不要重寫 Git 歷史。

## 下次接續時

先讀 [README](../README.md) → [FEATURES](../implemented/FEATURES.md) → [ROADMAP](ROADMAP.md) → [RESEARCH](../research/RESEARCH_REPORTS.md)，再對照最新 GitHub Actions 與當前 master 程式碼。新特性需有真實測試與追加在同一份 [ENGINEERING_NOTES](../implemented/ENGINEERING_NOTES.md) 的教學片段。
