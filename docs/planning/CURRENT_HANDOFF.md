# 目前開發交接（屬於產品規劃）

## 目前檢查點：M2-F60／F61（2026-10-26 21:59 Asia/Taipei／13:59 UTC）

- **保存進度／新門檻（2026-10-26 約 22:01 Asia/Taipei）：** 功能、測試、研究、課程與本交接已同批提交 `f22edb903d50ec94a62901e1f2b0b400d34d97ca`，提交後工作樹乾淨；**尚未 push**，新 SHA 的 CI 仍 NOT RUN。提交後再查 `rateLimitsByLimitId.codex.primary` remaining **15%**（used 85%）、secondary remaining **71%**（used 29%）；狀態 `TRIGGERED_PRIMARY_LE_15`，最後通知門檻 15%。本段先記錄再做 push／CI 查核，不開始新功能。以上「尚未 push」應以其後新增的 push 證據行為準。

- **新門檻（2026-10-26 22:00 Asia/Taipei／14:00 UTC）：** `rateLimitsByLimitId.codex.primary` remaining **19%**（used 81%）、secondary remaining **72%**（used 28%）；最後觸發狀態更新為 `TRIGGERED_PRIMARY_LE_20`，最後通知門檻 20%。先更新本交接，僅完成提交／CI 查核等安全收尾，不開始新的視覺功能。本次 `check_feature_lessons.py --paths ...` PASS（8 feature sections）、`docs/*.md` 7 份、`git diff --check` PASS；Chrome 本地專注桌視覺證據 `C:/Users/user05/.codex/visualizations/2026/10/26/01a175af-1471-7de1-9db7-6b9fa6279e83/bridge-focus-reuse-f61.png` 不入 Git。

- **用量先交接觸發：** `get_usage_limits.rateLimitsByLimitId.codex.primary` used 72%／remaining **28%**；secondary used 27%／remaining **73%**。2026-10-26 13:59 UTC 查得；是目前登入帳號共用額度，不是此專案消耗。最後觸發狀態 `TRIGGERED_PRIMARY_LE_30`、最後通知門檻 30%；本段已優先寫入，後續只做安全收尾、必要修復、驗證與保存，不開始新大型 UI 改造。下次只在新低門檻、恢復或需 owner 處理時提醒。
- **使用者目標：** 依 ROADMAP、Reuse First 及使用者提供 BBO 四圖，做可操作的弧形南家手牌、北／東／南／西方位公開牌引牌／跟牌動畫及向 winner 收墩；維持 Core、PlayerView 私牌界線，裝置／A3.5 QA HOLD 與正式部署 NO-GO。
- **Git：** `C:/Users/user05/StudioProjects/Bridge-Academy`，`master`，HEAD `e3b4c7231d0a74911f9c30d851be0307b2e1266e`；本次尚未 commit／push，新 SHA CI **NOT RUN**。未提交：`.github/workflows/flutter-single-player.yml`；Flutter `bridge_card_strip.dart`、`bridge_focus_table.dart`、`bridge_public_card_entrance.dart`、`bridge_table_components.dart`、`test/m2_focus_table_test.dart`、新 `test/m2_reuse_fan_test.dart`；既有文件 `FEATURES.md`、`ENGINEERING_NOTES.md`、`ROADMAP.md`、`RESEARCH_REPORTS.md`、本交接；新隔離 `experiments/card_game_probe/{pubspec.yaml,pubspec.lock,lib/,test/}`。以上為本次工作，未覆蓋他人檔案；忽略的 build/reuse_audit 不提交。
- **已完成：** 上游 `playing_cards 0.4.1+11` FlatCardFan 作排位，子牌形成輕微弧度、保留可點 48px 與窄屏捲動；Nickel Bridge pinned SHA `92a81b5e81cb7aac2eabc147e82f18e0040b512e` 的 TrickArea 只作互動參考，沒有複製 code/assets；隔離 card_game 2.0.0 PoC 重現單張 stack、drag-end 空值與 reduce-motion 不相容，正式 app 未依賴。公開墩四方位顯示、新牌按 seat 飛入、四牌從原 slot 向 Core winner 收攏；動畫不擁有 action。Chrome 本機看見專注桌南／北手牌輕微弧形與中央公開牌；實際真人／裝置觀感仍未驗收。
- **EXECUTED／PASS：** Windows Flutter 3.47.8／Dart 3.13.7；Scoped `flutter test --no-pub test/m2_reuse_fan_test.dart test/m2_focus_table_test.dart test/m2_table_motion_test.dart --reporter expanded` **20/20**；最後 `flutter analyze --no-pub` **0 issue**；全 `flutter test --no-pub --reporter expanded` **220/220**；`flutter build web --no-pub --release` **PASS**（Wasm dry run、原有 CupertinoIcons font inventory 警告，不等於 Wasm runtime）。`experiments/card_game_probe` 的 `flutter pub get --enforce-lockfile`、analyze、3/3 tests **PASS＝已重現 upstream 阻礙**，不是 card_game 可上線。`scripts/test_check_feature_lessons.py` **7/7**、`git diff --check` **PASS**。
- **FAILED→FIXED：** 新四方位墩牌起初使 320／375px 整桌溢出 24px，再測 320px version5 溢出 40px；縮至 116px 墩牌格、移除專注窄屏手牌多餘底空後 scoped 20/20 與全 220/220 PASS。PoC 初版 upstream drag-end TypeError 被測試當成未預期例外，調成明確記錄既知相容阻礙；沒有 patch upstream。
- **NOT RUN／CI：** 本次新 source 的 GitHub Actions Chrome／feature learning gate／probe 尚未 push，URL／狀態 `UNKNOWN/NOT RUN`；Android/iOS、A3.5 真人 UX、真 BEN 本地、正式部署 **NOT RUN／OWNER HOLD**。舊 HEAD `e3b4c72` 的 Flutter Chrome [#40304575247](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40304575247)／[learning #40304575236](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40304575236) success 只作基底證據。
- **接續與風險：** 先檢查 `git diff --check`／lesson gate、交接與文檔中的新數字及 status；配額復查；若仍 ≤30% 只作必要修復並 direct commit/push master（不用 PR／force）。查新 SHA 對應 Actions，不挪用舊 run。Web 視覺目前弧度輕微且中央牌偏小，需日後在額度恢復後做響應式卡尺寸與 BBO 參考質感迭代；真人／裝置 QA 仍 hold。回退 `git revert <M2-F60/F61 commit>`；無 Core/schema 遷移。剩餘大型 UI 工作及 card_game 相容修正留待額度恢復。

## Heartbeat 最新狀態（2026-10-26 19:43 Asia/Taipei／11:43 UTC）

- `get_usage_limits` 的 `rateLimitsByLimitId` 實測：primary used 0%／remaining **100%**；secondary used 16%／remaining **84%**，均為目前登入帳號共用視窗。已從先前 ≤30% 恢復；最後監看狀態 `RECOVERED_ABOVE_30`，最後通知值 100%／84%。未跨新門檻時不重複提醒，不宣稱未執行的 heartbeat 或機器關閉期間仍有監看。
- 查核分支 `master`、HEAD `e3b4c7231d0a74911f9c30d851be0307b2e1266e`，更新前工作樹乾淨；本次僅本交接文件未提交，沒有功能檔變更、測試執行、提交或推送。
- 上次返回步驟修正已在 `e3b4c72` 保存。此 SHA 的 [Flutter／Web／Chrome CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40304575247) 與 [Feature Learning Gate](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40304575236) 實際 workflow conclusion 均 **success**；本 heartbeat 只查 run 狀態，未另讀 job logs／重跑昂貴測試。下方 `5ef07a0` Chrome FAILED 保留為歷史，不是目前修正後的結論。
- 本次只監看及更新交接，不自動開始新的 UI 整合。接續仍是 owner 指定的 Reuse First：釘選 Nickel Bridge、比較 card_game／FlatCardFan adapter，再決定移植；保持 Core／PlayerView／QA HOLD／Production NO-GO。回退方式保留 `git revert <功能 commit>`，不重寫歷史。

## 最新：M2-F57／F58／F59 安全收尾

- **最後額度查詢：2026-10-26 約 19:04 Asia/Taipei（10:04 UTC）**，工具 primary used 97%／remaining **3%**、secondary used 15%／remaining **85%**，狀態 `TRIGGERED_PRIMARY_LE_5`，最後通知值 3%／85%。先更新交接，只保存這次必要測試修復後停止；不要開始重用整合／研究大任務。以實際 tool 訊息時刻為準，非持續監看保證。
- **CI 修正：** `5ef07a0` [Flutter CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40303963908) 的 analyze/test/build job **success**，Chrome job **FAILED**：完整牌局／拖曳斷言已走過，最後 `tester.pageBack()` 找英文 Back tooltip，在 zh-TW 找不到而回退搜尋 Cupertino button。改由 focus_result 的 Navigator.pop 返回，產品 Core／UI 沒有變更；必須新 CI 成功後才改整體 PASS。禁止掩蓋該失敗。
- **最新 owner steering：Reuse First**，Nickel Bridge owner 已表示完整授權可改。已寫 AGENTS／DECISIONS／RESEARCH_REPORTS；下一工作改為先釘選 Nickel 與 card_game／FlatCardFan 適配 PoC，而非再擴寫自製 UI。沒有安裝 card_game／複製外部原始碼；UI 基線不丟棄。≤30% 下本次只核對一次來源與保存，完整研究／整合待額度恢復。Owner 所列 Android PoC 仍受 QA HOLD 限制，未另批准前不執行。
- **保存結果（2026-10-26 19:00 台北）：** 功能／tests／三篇合併 lesson／Reuse First 決策已同批 `5ef07a07fdd38ed1308041d7079bbc7f9c3ee1bf` commit/push master，push 後工作樹乾淨；下方未提交與 NOT RUN 描述是提交前檢查，已被本段取代。本次僅補 evidence-only 文件。新 [Flutter／Web／Chrome](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40303963908)、[Learning](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40303963935)、[M4](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40303964385)、[M5](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40303964002)、[Precision](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40303963959)、[真 BEN](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40303964345) 均 in_progress，不提前稱 PASS；只做有限結果查核。
- 使用者明確要求完成「單屏牌桌、拖曳、收墩動畫」。目前已實作 Local／Gateway 共用專注牌桌、合法長按 drag/drop、公開收墩 overlay；仍保留 Core、PlayerView、QA HOLD／Production NO-GO。
- Repository `C:/Users/user05/StudioProjects/Bridge-Academy`，分支 master，修改基底 `6ad2de02372bb22433e4f86663b39b63350ac350`，開始時 clean，fetch 後與 origin/master 0/0。未提交：app_copy、bridge_app、gateway_table、bridge_table_components、browser_table_test；新 bridge_focus_table.dart／m2_focus_table_test.dart；FEATURES／ENGINEERING_NOTES／ROADMAP／本交接。沒有覆蓋他人工作。
- **已觸發 30% 先交接：2026-10-26 18:56:30 Asia/Taipei（09:56:30 UTC）**，`rateLimitsByLimitId` primary used 75%／remaining **25%**、secondary used 12%／remaining **88%**，均為帳號共用。首次觸發值 25%／88%。安全收尾再查 primary remaining **17%**／secondary **87%**，最後狀態 `TRIGGERED_PRIMARY_LE_20`，最後通知值 17%／87%；使用數值 83%／13%，仍為帳號共用。本文件已先更新；後續僅必要修復、 bounded verification、提交與證據收尾，不開始大型新功能。除新門檻／恢復／需 owner 處理不要重複提醒。
- EXECUTED／PASS：Windows Flutter 3.47.8／Dart 3.13.7；九項專注牌桌 scoped tests：四寬度 320/375/768/1280×812，一般字體逐張完整 52／13；大字體退路、真 pointer 拖曳取消／一次提交、過期／重複／paused 拒絕、收墩中止、頁面往返。較早 full suite 215/215 與 Web release PASS；最後置中／自然捲動修正後 analyzer 再 PASS，最終 full suite **215/215**／Web release 已完成 PASS。
- FAILED→FIXED：Tooltip 長按搶 drag 手勢，改 dragEnabled 時 manual trigger；中央公開座位標籤太寬，compact 40×56 但保留完整語意；2×字體固定高度溢位改自然內容高度。測試初版點擊離屏按鈕已改 ensureVisible。沒有改 Core 法則。
- 最後 full suite 曾 FAILED：320px／version 3 公開牌區 40px overflow，重讀檔案發現 compact 仍為 44×62 且 Column 沒有 min，已明確改為 40×56／mainAxisSize.min，再跑 scoped **9/9 PASS**，並重讀檔案確認。最終修正後已重跑 analyzer PASS、全 Flutter **215/215 PASS**、Web release PASS；`build/focus-final-tests.log` 為本機忽略檔，不提交。
- Chrome 人工工程檢查：127.0.0.1:8734 真 Web 開啟新專注桌、叫牌後顯示合法牌；觀察到 current trick 貼頂，已修正 mainAxisSize.min，最後修正後已 reload 核對中央牌區置中，最終截圖保存於 Codex visualization 目錄 `bridge-focus-table.jpg`（不入 Git）。這不是 A3.5 玩家驗收，沒有裝置 QA。
- CI：本次 source 尚未 commit/push，新 SHA 的 Flutter／Web／Chrome NOT RUN。新 browser_table_test 含首張實際長按拖到中央、其後點牌完成 13 墩；需確認 CI，不能用前批 F56 success 替代。
- 接續命令：讀 running verification 結果；`git diff --check`；`python -B scripts/check_feature_lessons.py --paths <source> docs/implemented/FEATURES.md docs/implemented/ENGINEERING_NOTES.md`；重新查 quota；direct commit/push master（source＋tests＋三節 lesson 同一批）；查新 SHA Actions；記真實結果後提交 evidence-only 文件。不要 dispatch held device workflows。
- 風險／回退：大字體和矮視窗允許捲動；本次使用的 reduce-motion 設定仍不跨重啟保存；收墩只做公開副本，不延遲動作；無 schema／新相依。回退以 `git revert <本次功能 SHA>`。未決 owner 決策無新增；A3.5／裝置／託管安全／模型權利仍未放行。

> 2026-10-26 18:34（台北／09:34 UTC）。本次宿主可用 `get_usage_limits`，實測帳號共用 primary 剩 **70%**、secondary 剩 **95%**（used 30%／5%，採 `rateLimitsByLimitId`）；未觸發 30% 交接門檻。歷史宿主的 UNKNOWN 不作即時值，不宣稱電腦關閉時持續監看。

## M2-F56 本次續作檢查點

- 目標：依 ROADMAP U3 實作公開出牌動態回饋與減少動畫偏好。Bridge Core／PlayerView 邊界不變；無新套件、資料 schema 或 AI 呼叫。
- 分支 `master`，實作基底 `7305bf4dd4abfe3c7b6f0ec6a43a8a268f80834c`；已 fetch origin，開始時沒有他人的未提交變更。Flutter app/copy/shared table、新 public entrance widget、六項 motion tests、browser full-board 設定切換測試，以及 FEATURES／ENGINEERING_NOTES／ROADMAP／本交接已同批提交並 push **`030276b1e10d8243a429146ec1a5d7e559592998`**，push 後工作樹乾淨。之後僅補實際 CI 證據文件，最終 SHA 用 `git status --short`、`git log -2 --oneline` 查核。
- EXECUTED／PASS：Windows Flutter 3.47.8／Dart 3.13.7；`flutter analyze --no-pub` 無問題，scoped 20/20、全 `flutter test --no-pub --reporter expanded` **206/206**、`flutter build web --no-pub --release` PASS（既有 CupertinoIcons font inventory 警告仍在）。Python `scripts/test_check_feature_lessons.py` 7/7、canonical feature lesson gate、`git diff --check` PASS；docs 仍 7 份。
- FAILED→FIXED：初版 motion test 編譯名稱、座位時序與 semantics handle 問題已修正；公開牌重複語意標籤一併修正。錯誤的 Python module 執行方式 import 失敗，改以 script 路徑後 7/7 PASS。詳見 ENGINEERING_NOTES。
- CI：基底 merge `7305bf4` 查無綁定 run；歷史 F55 CI 不作本次驗收。本次 `030276b` [Learning Gate](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40300087861) **success**；[Flutter／Web／Chrome](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40300087862) **success**（logs 已驗證 206 tests、Web release、browser_table_test 含中途動畫偏好切換／13 墩與 browser_secure_checkpoint_test 均成功）；自動 path triggers 的 [M4](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40300087891)、[M5](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40300087872) **success**；[Precision](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40300088005)、[真 BEN Chrome](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40300087864) **in_progress**。本次 browser integration 本機 **NOT RUN**，由上述真 Chrome CI 已成功執行；真 BEN／Precision 則仍未完成，不提前稱通過；沒有手動 dispatch 或 held device QA。
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
