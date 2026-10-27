# Bridge Academy 目前交接

> 本檔只描述目前狀態。舊交接流水帳可從 `5915bac0c3d96371f9e82b4086c81c5dcc1654f0` 的 Git 歷史查閱；不能用舊記錄的「尚未提交／執行中」判斷目前版本。

## 使用者目標與工作規範

- 依 ROADMAP 完成 BBO 風格單人橋牌體驗，Reuse First：上方明手、下方自己的扇形手牌，清楚的公開引牌／跟牌／收墩。
- 精簡重複測試及無關 CI；保留 Core 法則、PlayerView 隱私、合法操作／重試和實際流程驗收。
- 只在 agent 實際執行工作時查用量；使用者已暫停排程，不重啟或建立重複排程。配額為帳號共用，不歸因單一專案。
- Direct push master、不開 PR、不 force push；Android/iOS 裝置及模擬器、A3.5 真人 UX 仍 OWNER HOLD，Production NO-GO。

## 目前 Git 與用量（2026-10-27 19:05 Asia/Taipei）

- 專案：`C:/Users/user05/StudioProjects/Bridge-Academy`；branch `master`；本輪基底 HEAD `5915bac0c3d96371f9e82b4086c81c5dcc1654f0`。開始時工作樹乾淨，fetch origin/master 後 0/0。
- 本輪尚未提交：`apps/bridge_academy_flutter/lib/src/widgets/{bridge_trick_geometry,bridge_focus_table,bridge_table_components}.dart`、`test/m2_focus_table_test.dart`、`docs/implemented/{FEATURES,ENGINEERING_NOTES}.md`、`docs/planning/{ROADMAP,CURRENT_HANDOFF}.md`、`docs/research/RESEARCH_REPORTS.md`。無其他人的未提交工作。
- 最新實測 `rateLimitsByLimitId.codex`：primary used28%／remaining **72%**，secondary used66%／remaining **34%**。未觸發30%交接門檻；大型新切片前與提交前仍需再查。

## 已完成的工程範圍

- F63/F64（`d5f9a634e0834ecd4d68a915904585d21f1f405a`）：綠桌面、手機13張完整扇形、角標、抬起／確認出牌、寬牌列切換；明手面板在上、己方在下；公開墩牌和收墩共用座標。只在專注頁完成，整個工作區產品 UX 仍有待辦。
- CI 精簡（`42c12e230bd752ede6d0e115cf01dfb24ec99517`）：隔離 card_game probe；M4/M5/Precision 不因共用 app_copy 文案誤觸發，重型 workflow-only 修改可手動 dispatch。主 app 完整 tests/analyze/Web build/Chrome 與真BEN流程保留。專注桌少6個重複寬度案例，整副13墩只在窄屏重播一次。
- **本輪 M2-F65：** 玩家選北／東／南／西時，中央玩家座位均在下方、搭檔在上方，標籤／公開墩牌／入場／收墩使用同一可逆視角映射。CardAction、handOwner、Core winner 和真實座位名稱不變。切換 viewer，即使同version，也清除舊選牌／提交鎖／收墩；公開入場按viewer重新建立，避免舊方位演出。
- 明手上方手牌面板仍標示真實座位；玩家為防家時，該面板不代表中央上方的搭檔座位。沒有引入四家暗牌或新規則引擎。來源是已釘選 Nickel TrickArea 的 flipped compass 契約；未複製外部程式／素材、未加依賴。

## 精確驗證與 CI

- **本輪 EXECUTED/PASS：** Windows Flutter3.47.8；`flutter test --no-pub test/m2_focus_table_test.dart` **16/16 PASS**，最後補四視角的defender projection與同版本選牌清除斷言後已重跑；既有共享演出回歸 `flutter test --no-pub test/m2_table_motion_test.dart` **6/6 PASS**；`flutter analyze --no-pub` **0 issue**；`scripts/check_feature_lessons.py --paths <9個變更路徑>` PASS；`git diff --check` PASS。無失敗測試。只新增1個四座位情境，不另加完整牌局／viewport矩陣。
- **本輪 NOT RUN：** 完整本機 app suite、Web build／Chrome人工目視、新SHA GitHub Actions（尚未提交）。Android/iOS及A3.5為HOLD，未執行。沒有部署或手動派發昂貴研究workflow。
- **前一功能 SHA d5f9a63，已重新查到全部 success：** [Flutter/Web/Chrome #40485202583](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40485202583)、[真BEN Chrome #40485202676](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40485202676)、[Precision research #40485202623](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40485202623)、[probe #40485202644](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40485202644)、[M4 #40485202606](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40485202606)、[M5 #40485202853](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40485202853)、[learning #40485202635](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40485202635)。這些驗證F63/F64，不當作F65驗收。
- workflow trigger SHA42c12e2 只有 [learning #40485775560](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40485775560) success；docs SHA5915bac 只有 [learning #40485930106](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40485930106) success。確認workflow-only／docs-only更新未重跑其他昂貴suite。

## 尚未完成與下一步

1. **當前安全交付：** lesson gate／diff檢查 → 查quota → 程式、測試與兩份feature文件同批commit/push master → 查新SHA Flutter/Chrome、BEN、learning結果；只修必要回歸，不能沿用前述舊綠燈。
2. **下一個產品切片：主工作區到牌桌的預設動線。** 使用者開始／繼續一局後直接進可玩的專注桌，返回工作區仍保留同一session；Local與Gateway需一致，開局／續局／完局／錯誤重試可達。現仍需額外按專注桌入口，未實作自動導向。這需要整合路由與生命週期，不是單純改標題。
3. **Web可用性：** 依真實高度／大字體／鍵盤與輔具核對，保留取消、等待和請求失敗重試。四viewer工程測試不等於真人／實機UX已通過。
4. **第三方權利／素材inventory：** playing_cards內附未使用Wikimedia圖像、Nickel依賴／素材、模型與native binary notices仍需逐項記exact artifact／license／發行範圍。card_game probe有已知drag-end與reduced-motion缺口，尚未正式採用。
5. 後續依ROADMAP進U4安全續局／雲端history與A4.5託管；不能跳過identity/TLS、目標VPS、durability與QA門檻。

## 接續命令、風險與回退

- `git status --short --branch`、`git rev-parse HEAD`、`git fetch origin master`、`git rev-list --left-right --count HEAD...origin/master`；只在必要變更後執行對應測試。
- 本輪測試：在`apps/bridge_academy_flutter`執行`flutter test --no-pub test/m2_focus_table_test.dart`；完整suite由正常Flutter CI執行，不重複本機重跑。
- F65純presentation轉換，沒有Core/API/schema遷移；預設geometry仍為南家視角，其他既有caller保留行為。回退用F65功能commit的`git revert`；CI refinement可`git revert 42c12e2`，UI基線可`git revert d5f9a63`。禁止重寫歷史／清掉別人的檔案。
- 未列為PASS的發行gate仍未放行。舊本機預覽session95261／98821已無可用exec session，不能據此聲稱HTTP listener仍在或已停止；不任意終止其他process。
