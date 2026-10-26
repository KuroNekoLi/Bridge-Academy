# Bridge Academy｜正式文件入口

> **2026-10-26**：因專案擁有人要求極簡文件，已將原本 190 份 `docs/` 文件整併成 **7 份**，分三類。今後新增功能請更新現有文件，不要逐功能新開驗收、ADR、教學、週報 Markdown。

## 1. 已實現哪些功能

- [**已實作功能與核心規則**](implemented/FEATURES.md)：產品目前真正有的能力、原始碼、可用範圍、架構、核心不變條件與未實作功能。
- [**功能工程導讀**](implemented/ENGINEERING_NOTES.md)：對實際程式和測試的教學、原因、設計取捨與練習；追加章節即可。

## 2. 接下來的產品如何規劃

- [**產品路線與正式上線 Gate**](planning/ROADMAP.md)：玩家流程、開發順序 U3 → U4 → A4.5、Precision 與 custom AI 的待辦，以及正式發布驗收。
- [**已核准決策**](planning/DECISIONS.md)：制度版本、不變規則、owner hold、安全／權利、文件維護、配額與工作規則。
- [**目前工作交接**](planning/CURRENT_HANDOFF.md)：最新接續工作、真實測試狀態與 Git 回退方式，不當成產品已發行憑證。

## 3. 相關研究報告

- [**研究與驗收整合報告**](research/RESEARCH_REPORTS.md)：BEN／2/1／SAYC、Precision BBA、M4 自訂草稿、M5 教練、效能／授權／UX、可追溯 CI 與 SHA。

## 本文件編制與安全界線

本索引亦算入文件總數，因此目前 `docs/` 共 **7** 份。刪掉的歷史文件仍在 Git commit history，不是 `git filter-repo` 清除；不能將舊版驗收說成目前通過。研究 CI Pass 只適用於列明的版本、環境和 fixture。**正式公開服務仍 NO-GO；A3.5 和 Android/iOS emulator/實機 QA 仍 OWNER HOLD**，未經後續批准不可啟動。核心公平規則及 Bridge Core 的程式才是實際合法性裁判。

完整原始碼、CI workflow、測試與 agent skill 不在本次刪除範圍。
