# 目前開發交接（屬於產品規劃）

> 2026-10-26 18:29（台北／09:29 UTC）。本次宿主可用 `get_usage_limits`，實測帳號共用 primary 剩 **79%**、secondary 剩 **97%**（used 21%／3%，採 `rateLimitsByLimitId`）；未觸發 30% 交接門檻。歷史宿主的 UNKNOWN 不作即時值，不宣稱電腦關閉時持續監看。

## M2-F56 本次續作檢查點

- 目標：依 ROADMAP U3 實作公開出牌動態回饋與減少動畫偏好。Bridge Core／PlayerView 邊界不變；無新套件、資料 schema 或 AI 呼叫。
- 分支 `master`，實作基底 `7305bf4dd4abfe3c7b6f0ec6a43a8a268f80834c`；已 fetch origin，開始時沒有他人的未提交變更。當前未提交：Flutter app/copy/shared table、新 public entrance widget、六項 motion tests、browser full-board 設定切換測試，以及 FEATURES／ENGINEERING_NOTES／ROADMAP／本交接。提交後先以 `git status --short`、`git log -2 --oneline` 查最終 SHA。
- EXECUTED／PASS：Windows Flutter 3.47.8／Dart 3.13.7；`flutter analyze --no-pub` 無問題，scoped 20/20、全 `flutter test --no-pub --reporter expanded` **206/206**、`flutter build web --no-pub --release` PASS（既有 CupertinoIcons font inventory 警告仍在）。Python `scripts/test_check_feature_lessons.py` 7/7、canonical feature lesson gate、`git diff --check` PASS；docs 仍 7 份。
- FAILED→FIXED：初版 motion test 編譯名稱、座位時序與 semantics handle 問題已修正；公開牌重複語意標籤一併修正。錯誤的 Python module 執行方式 import 失敗，改以 script 路徑後 7/7 PASS。詳見 ENGINEERING_NOTES。
- CI：基底 merge `7305bf4` 查無綁定 run；歷史 F55 CI 不作本次驗收。下一步 direct commit/push source＋tests＋兩份 feature docs，查新 SHA 的 Flutter／Web／Chrome、Learning Gate；本次 browser full-board integration 本機 **NOT RUN**，由既有允許的 CI 驗證，不冒稱通過。
- 限制／風險：設定僅本次使用，裝置 reduce-motion 永遠優先。只動畫當前公開牌；不延後 submit、不保留 outgoing card。單屏牌桌、拖曳、完整收墩仍未完成。A3.5／Android/iOS HOLD，公開部署 NO-GO，沒有排程／dispatch 裝置測試。
- 接續：`git status --short` → 查當次 Actions → 若 scoped CI 有錯先修復；下一功能是 U3 單屏佈局。回退 `git revert <M2-F56 commit>`，不改歷史／不刪存檔。沒有待 owner 決定的規則或制度變更。

## 最近工作

- 目標：`docs/` 從 190 個檔案精簡至 7 個，三類來源：已實現功能、產品規劃、研究報告。已保留技術不變條件與發行 NO-GO，重寫入口 README/AGENTS/skills 參照；使用一個可回退的新 commit 執行內容更新與舊文件刪除。
- 仍維持：使用者允許直接 push master、不開 PR、不 force-push；A3.5、Android/iOS emulator 與實機 UI/E2E **OWNER HOLD**；尚未批准正式公開部署。
- 重要連結：[已實作](../implemented/FEATURES.md)、[工程導讀](../implemented/ENGINEERING_NOTES.md)、[產品路線與發行 Gate](ROADMAP.md)、[決策](DECISIONS.md)、[研究](../research/RESEARCH_REPORTS.md)。
- 下一項產品實作：**U3** 牌桌可操作性與動畫／窄屏；**U4** Gateway 安全續局／雲歷史；**A4.5** VPS 真測＋授權＋TLS。
- 驗證方式：檢查 master Git tree 中 `docs/` count ≤10、沒有保留文件死連結、Feature Learning Gate（`scripts/test_check_feature_lessons.py`）、既有 workflow 狀態。Docs 精簡不代表重跑了所有 BEN/Flutter/手機測試。
- 回退：對 docs 清理 commit 執行 `git revert <cleanup_commit>`；Git 歷史可以查閱完整 190 份來源資料。不要重寫 Git 歷史。

## 下次接續時

先讀 [README](../README.md) → [FEATURES](../implemented/FEATURES.md) → [ROADMAP](ROADMAP.md) → [RESEARCH](../research/RESEARCH_REPORTS.md)，再對照最新 GitHub Actions 與當前 master 程式碼。新特性需有真實測試與追加在同一份 [ENGINEERING_NOTES](../implemented/ENGINEERING_NOTES.md) 的教學片段。
