# Bridge Academy 目前交接：叫牌 UI 已實作，交付收尾

## 2026-10-29 延續 V3 驗收（11:14 Asia/Taipei）

- **目標／狀態：** 依 `AGENT_PROMPT.md` 繼續完成可在本機驗收的 V3 UI。已存在的 F66/F67 叫牌流程及 F68/F69 明手、教學功能未重做；本輪補齊明手上置／本人手牌下置的手機尺寸驗收。P4 仍未完成，不能稱為整份 V3 驗收完成。
- **配額：** 最新 `get_usage_limits`：primary used 33%／remaining **67%**；secondary used 9%／remaining **91%**。帳號共用配額；未到本次任一視窗 remaining ≤10% 門檻。
- **Git：** `master`，基底 `90c52c89773afc46f5c0b0bc36f02a2767fda55e`。本輪未提交變更：`apps/bridge_academy_flutter/test/m2_focus_table_test.dart`。尚未提交／推送。
- **本輪修改：** M2-F62 明手／本人相對牌桌位置測試由 `[320,1280]` 擴為 `[320,360,390,430,1280]`，涵蓋 V3 指定三種手機寬度；不改遊戲規則或 UI 程式碼。
- **實際執行：** `flutter test --no-pub test/m2_focus_table_test.dart --plain-name "M2-F62 dummy is above table and own hand below" --reporter expanded` — **5/5 PASS**；`flutter test --no-pub test/a3_bidding_box_test.dart --reporter expanded` — **3/3 PASS**；`flutter test --no-pub test/m2_focus_table_test.dart --reporter expanded` — **21/21 PASS**。失敗測試：無。未執行：全量 Flutter suite、Web production build、完整 T01–T10 的端到端固定牌局、Android/iOS 或真人 QA（owner hold）。
- **Web 視覺驗收：BLOCKED。** Flutter Chrome debug server 回 HTTP 200 且啟動 debug service，但瀏覽器擷取只得到空白頁；Windows Computer Use 隨後拒絕該視窗，原因是無法安全判定目前瀏覽器 URL。已停止 UI 操作，沒有繞過限制。故本輪沒有可用的 Flutter 牌桌截圖，也沒有 X01–X04 幾何差異量測；不能宣稱視覺比對通過。Android/iOS QA 仍 HOLD。
- **最新 SHA CI：** 對基底 `90c52c89773afc46f5c0b0bc36f02a2767fda55e` 的 GitHub Checks 唯一回傳項目為 [Feature Learning Gate](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40807858023) **success**。此為既有 handoff-only SHA；本輪測試變更尚無 CI。CI 查詢時間 2026-10-29 11:14 Asia/Taipei。
- **下一步：** 在受支援且可驗證 URL 的瀏覽器預覽中截取公開測試局，完成 X01–X04幾何比對及其餘 T01–T10 的固定局互動證據；不能以 widget 測試取代截圖／真 BEN 驗收。其後按 repo Git 政策提交並直接 push `master`（不 force push），檢查新 SHA 的相關 CI。若續作成本或 quota 接近 10%，先更新本 handoff。
- **風險／回退：** 本輪僅改一個測試寬度清單，無 runtime、Core、資料格式或依賴變更；回退此輪可還原該清單至 `[320.0, 1280.0]`。若已提交則用 `git revert <本輪commit>`，不可 reset／force push。未保存 private deal、憑證或截圖。

## 2026-10-29 V3 UI 實作續接（最新狀態）

- **目標：** 依使用者提供的 BBO／新睿手機參考與 `AGENT_PROMPT.md` 完成明手四花色選牌及可操作叫牌／出牌 spotlight 教學；沿用既有 Flutter 牌桌、Bridge Core 與 `PlayerView`，維持暗牌隔離與 owner-held 裝置 QA HOLD。依 repo AGENTS 只改七份 canonical docs，不採附件新增 `docs/ui/*` 的建議。
- **配額：** 提交前最近讀取 `get_usage_limits`：primary used 27%（remaining **73%**），secondary used 8%（remaining **92%**）；未觸發本任務 10% handoff 門檻。帳號共用配額，不表示此專案獨佔消耗。
- **Git：** branch `master`；source commit `f603742`（功能 `0164474`，字串 diff 收斂 `f603742`），handoff／推送 checkpoint `845fac9d85c7a33c65dfaf002aa60eb9819da6e3` 已直接 push 至 `origin/master`。localized strings 最終淨差異只新增本功能所需字串，避免整檔格式化 churn。此次handoff更新待提交；除此之外工作樹乾淨。
- **完成：** 明手桌上方四花色牌堆、選花色後展開牌列；合法性仍取自 `PlayerView.legalCards`；Overmark 0.2.0 spotlight 依牌桌實際操作提示叫牌、本人出牌或明手先選花色再選牌；叫品／牌步驟必須等新 PlayerView 明確包含該動作才前進；skip／關閉不改牌局。更新 F68/F69 feature／learning 記錄及 Overmark 授權來源。
- **已執行：** `flutter test --no-pub test/m2_focus_table_test.dart --reporter expanded` **18/18 PASS**；`flutter test --no-pub test/m2_focus_table_test.dart --reporter expanded --plain-name "tutorial"` **2/2 PASS**；`flutter analyze --no-pub` **No issues found**；`python scripts/check_feature_lessons.py --paths docs/implemented/FEATURES.md docs/implemented/ENGINEERING_NOTES.md` **PASS**；`git diff --check` **PASS**。
- **失敗／修復：** 第一次完整牌桌測試因 dummy 堆疊過高把 320px 墩牌縮至 41.43px，調低牌堆高度後同檔通過；舊拖曳案例未先選花色而找不到未掛載牌，已調整。教學測試曾在 action gate 尚未 armed 前點擊，增加測試等待後通過；錯用 `Play` 類型的編譯錯已改為 Core `PlayedCard`。Skip 測試一度沿用錯誤起始 version 期望值，改正後完整測試通過。Lesson gate 無參數執行曾回 usage error，補 `--paths` 後 PASS。沒有未解決的測試失敗。
- **未執行：** 完整 Flutter suite、Web build、Chrome E2E／新畫面截圖、Android/iOS 與真人 QA 未執行。未改 CI workflow。推送後讀取 SHA `845fac9d85c7a33c65dfaf002aa60eb9819da6e3` 的 GitHub Checks：`analyze-test-build` 與 `Real ChromeDriver end-to-end (demo, not BEN)` **in_progress**（[run 40807812878](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40807812878)）；`Real BEN + Flutter Chrome UI` **in_progress**（[run 40807812820](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40807812820)）；`feature-learning` **success**（[run 40807812911](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40807812911)）。這些是 GitHub 自動觸發工作，不代表本次本地執行；不要把 in_progress 說成 PASS。
- **接續：** handoff 更新提交後直接 push `master`（禁止 force push）；若要核對新 handoff-only SHA，查該 SHA 的 GitHub Checks。CI 若有失敗，只修本輪可重現的相關項目，不擴成全量測試維護。失敗／影像證據仍未查，Android/iOS 與真人 QA 保持 HOLD。
- **風險／回退：** Overmark 0.2.0 是較新、採用度有限的 MIT Flutter overlay 套件；來源與退回 Flutter `OverlayEntry` 方案記於 `RESEARCH_REPORTS.md`。本輪未改 Core／Gateway schema／存檔，無資料遷移；以本功能 commit 的 `git revert <sha>` 回退，勿 reset 或 force push。裝置 QA／release 仍 HOLD。

## V3 新睿風格 UI 任務狀態（2026-10-29；更新 10:21 Asia/Taipei）

- 使用者要求依附件`AGENT_PROMPT.md`與`BRIDGE_UI_REFERENCE_AND_VALIDATION_V3.md`開始實作；並附四張 IMG_7347～IMG_7350 參考圖。更正用量解讀：初次工具輸出的轉換值是剩餘 primary89%、secondary95%，我誤把它說成11%／5%而錯誤暫停。使用者截圖顯示87%／95%；隨後原始讀值used13%／5%，換算remaining即87%／95%，與截圖一致；**本任務沒有觸發≤10%門檻，已恢復實作**。這是帳號共用配額。
- 任務起點 branch `master`、HEAD `884a1ca0e8769cec459c9ac0db0d83683258584c`；起始工作樹僅handoff有未提交checkpoint。附件提到的agent_run／reference_alignment檔、docs/ui研究包均不在repo。repo現存七份canonical docs；依repo AGENTS.md將狀態記在CURRENT_HANDOFF，不新增第八份文件。
- P0 source reconciliation：`BridgeCardStrip`/`playing_cards.FlatCardFan`、`BridgeFocusTable`、`BridgeBiddingBox`/`BridgeAuctionGrid`、`BridgeCurrentTrick`/`BridgePublicCardEntrance`分別承擔扇形手牌、單屏整合、叫牌與history、四方位墩牌及收墩；FEATURES/ENGINEERING_NOTES已有F60–F67執行記錄，對應source與test files存在。叫牌、扇形與收墩已有功能；V3缺口是明手仍呈單一扇形、沒有四花色欄／先選花色再選牌流程，以及沒有tutorial/spotlight。既有F60–F67測試是歷史證據，V3專屬幾何仍未驗收。
- Overmark官方pub.dev目前為`0.2.0`、MIT、純Flutter無依賴且支援action gate；專案Dart SDK `>=3.8`、本機Flutter `3.47.8`符合其Dart `>=3.4`／Flutter `>=3.22`需求。實際採用及lock hash待POC及pub get確認。來源：[pub.dev package](https://pub.dev/packages/overmark)、[license](https://pub.dev/packages/overmark/license)。
- 規範衝突：repo AGENTS.md限定七份canonical docs且要求direct push `master`；附件提示要求新增多個`docs/ui/*`交付物及不push master。依repo AGENTS.md，不新增文件並保留既定Git政策，將進度／驗收併入七份文件。附件另要求不改CI；先前測試與CI簡化請求仍是獨立待辦。Android/iOS owner QA hold有效。
- **本輪精確執行：** quota讀取；讀取兩附件、bridge-orchestrator skill、docs README、canonical feature紀錄、狀態檔存在性及相關source/test搜尋；Flutter 3.47.8版本查詢；Overmark官方package／license研究。**未執行：** 程式修改、測試、CI、新Flutter screenshot、commit。**V3 CI：** 尚未查。**回退：** 僅本handoff為原有未提交checkpoint，功能切片採`git revert`，不得reset/force。

## 最新配額與 owner 指示（2026-10-28；本次檢查時間 UNKNOWN）

- 最新指示：本次任一可用視窗剩餘≤10%先寫交接，取代前一7%及原30%；已在AGENTS記本次任務覆寫。優先高風險Core／狀態／整合，低風險列出給owner之後派其他agent，不自行spawn／切模型。排程維持owner暫停，沒有重啟。
- **上次紀錄：** 2026-10-27 23:26 primary remaining 0%、secondary 7%。
- **本次觸發：** 本機用量工具於2026-10-28本輪讀值：primary used 4%／remaining **96%**，secondary used 94%／remaining **6%**（觸發10%門檻）。帳號共用用量，不代表專案獨佔消耗。最新狀態`TRIGGERED_SECONDARY_LE_10`。檢查具體時刻：UNKNOWN。立即更新本文件後，只做必要gate、commit/push與CI狀態保存，不開始另一功能。
- **新待辦請求：** owner要求盤點並刪除無意義測試與CI。尚未盤點／修改／刪除任何測試或workflow。需後續獨立執行：以產品風險和實際pipeline觸發找出重複、無行為斷言、裝置hold等候選，先區分核心規則/安全不變量必要保護，僅移除有證據可刪者，合併重複CI工作；不可將「通通刪除」解讀為刪光測試與CI。此新工作在本次≤10%門檻下未開始。

## Git／目標

- Repo C:/Users/user05/StudioProjects/Bridge-Academy；branch master；本輪基底 `9b6d1e746807c1e5fed3af9c4b325290beb738a8`；功能commit `531ba3f83e2202b2b89a7d5378a5cd4aa38a9ae1` 已push至origin/master。本handoff checkpoint commit `23376b2ec40ce16d95a1d0380f71a3eb050aec22` 亦已push；最新master checkpoint為`417980f6244778c25afc17aaacc99b02e4bf498a`。工作樹乾淨。GitHub Actions對功能SHA的實際狀態：Feature Learning Gate、Bridge Core CI、Bridge Gateway A4.2 CI **success**；Flutter M2 Single Player、M3.4-M3.5 Experimental Precision Gateway and Evaluation、BEN Flutter Chrome Real E2E (M2-F07/F09)、M4 Custom Convention Drafts、M5 Public Auction Coach **in_progress**。查詢時間UNKNOWN；各run URL見本handoff末尾。不能以success三項代表整體或已完成真BEN驗收。
- Owner要求真正把Nickel Bridge React/TypeScript成熟叫牌互動適配Flutter；已實作F66/F67，並非只讀source。不要把當前結果誇成完整BBO產品UX或已審核制度解釋。

## 已完成的高風險工作

- **M2-F66**：Core BridgeGame.legalCalls只用公開phase/turn/actor/auction，與reducer共用_validateCall，不改PlayerView/Gateway JSON schema、不給UI暗牌。新BridgeBiddingBox共用於Local／Gateway／專注桌；35叫品矩陣+Pass/X/XX，先選後獨立確認、非法停用、最低合法階窗口與高階展開、等待／暫停／送出狀態、version/viewer/turn清過期選取，同version只送一次。Widget自己再核對view.canAct，caller旗標不能開放其他座位。
- **M2-F67**：BridgeAuctionGrid共用於一般桌／專注桌／公開歷史；N/E/S/W固定欄頭、dealer首列補空格、本人★／pending?／活動欄、最後叫品高亮、內捲追最新。每call可inspect公開Seat／Call，沒有驗證含義就明示未知，不套用Nickel的SAYC詞庫至本局任意制度。375px對話框第四欄裁切已修minWidth並補既有代表test的可見邊界斷言。
- 源碼互動來源 pinned Nickel SHA `92a81b5e81cb7aac2eabc147e82f18e0040b512e` 的BidBox.tsx/AuctionGrid.tsx；以Flutter重寫，未複製TSX/CSS/素材，無新第三方依賴。source/provenance已寫研究文件及Widget檔頭，owner授權聲明不推定其他模型／DDS／圖像權利。
- 移除caller舊level/strain狀態。widget與browser整局測試走真實選取／確認，browser BEN/Gateway固定3NT點bid_3NT；共享helper只pump，由原wait處理HTTP，避免pumpAndSettle卡真網路。held Android來源僅同步操作，不執行或dispatchQA。

## 真實測試與限制

- Core `dart test` **58/58 PASS**；`dart analyze --fatal-infos`無問題。
- Flutter scoped4檔 **29/29 PASS**；完整suite第一輪226PASS/1FAIL為舊a3_table_components在auction要求BridgeCurrentTrick，改驗真實grid後 **227/227 PASS**。
- Web目視找到窄history dialog裁到第四欄，修復後 `a3_bidding_box_test.dart`＋`a3_table_toolbar_test.dart` **8/8 PASS**，再補view.canAct防護後同2檔 **8/8 PASS**。最新 `flutter analyze --no-pub` **0 issue**。完整227是在這兩個最後補強前，不假裝又跑過整套；正常CI仍會全跑。
- 最新 `flutter build web --no-pub --release` **PASS**，build/bidding-release-final.log；只有既有CupertinoIcons字型inventory警告。沒有另重跑Core全suite來驗純排版。
- Chrome工程檢查：375×812與桌面，點2♥後合約仍未定／N欄仍?，確認後2H成立；返回工作區保留同局，歷史顯示2H及三個實際PASS。只含授權PlayerView。最終選牌手機證據：`C:/Users/user05/.codex/visualizations/2026/10/26/01a175af-1471-7de1-9db7-6b9fa6279e83/auction-mobile-selected-f66.jpg`。桌面證據auction-desktop-selected-f66.jpg。
- history最終成品截圖曾受瀏覽器cache／分頁控制與viewport中斷影響，不能把縮小失真的auction-history-mobile-f67.jpg當可靠視覺證據；窄dialog的code/test修復已通過，仍可交他人再目視。這不是owner-held A3.5／裝置QA。
- 新SHA Flutter/Chrome／Bridge Core／真BEN CI **NOT RUN（尚未push）**；不得沿用F65舊綠燈。Android/iOS模擬器與真機、真人UX均OWNER HOLD，Production NO-GO，無部署。

## 立即安全收尾

1. 文件F66/F67已追加FEATURES及ENGINEERING_NOTES、研究實作來源／決策／ROADMAP；跑輕量lesson gate及git diff --check，確認只收本輪來源與測試。
2. packages/bridge_core/pubspec.lock是本次測試生成、原先不存在，已刪，不要誤commit。截圖及build logs不入Git。
3. 本交接更新提交後，查新SHA CI並記實際status；有失敗只修必要回歸。若CI仍未觸發或受quota限制，記URL／pending並讓後續agent查，不聲稱PASS。
4. 回退以本次feature commit的git revert；無schema／資料遷移。不要reset --hard或清別人工作。若local preview要停，只針對本次exec sessions31187(8736)、52489(8737)、63848(8738)，不殺其他process。

## 留給其他 agent 的低風險任務（未派發；由 owner 後續指派）

- **L1 雙語／輔具文案核對。** 範圍app_copy.dart的新selectCall/confirmCall/submittingCall/biddingPaused/moreBidLevels/callMeaningUnknown/awaitingCall，及兩Widget的語意名。核對zh-TW/en、200%字體與375px截圖，可調字詞／換行，不能改Core legalCalls、canAct、_sentVersion、確認送出或未知含義政策。交付現有工程筆記補證據，不新增docs／不跑整副牌矩陣。
- **L2 文件證據校對。** 只改7份canonical docs中的舊F63～F65「CI尚未跑」與當前結論矛盾之處；以明確SHA/run URL核對，不改歷史FAIL為PASS、不把研究CI當release核准。不動功能／測試，無須重跑昂貴suite。此項也可補本次新SHA最終CI status。
- **L3 授權資料機械盤點。** 在既有RESEARCH_REPORTS列installed playing_cards內附檔案、版本／archive hash、LICENSE/notice路徑及可查來源；只收集事實，不裁決商用／再散布合法性，不下載未授權素材、不把API key或私牌寫入文件，不改dependency或資產bundle。法律／權重／native binaries發行範圍仍需較高風險審查。
- **L4 最終history對話框視覺留證。** 用fresh loopback origin的已編譯Web及公開測試局，在375px核對N/E/S/W全欄、四個call都在clip內、點call出現未知說明；保存正常尺寸截圖至本機artifact，不入Git。禁止改規則／送出狀態，裝置QA仍HOLD。

## 本次功能 SHA 的 CI URLs

- Flutter M2 Single Player: https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40599751337 (in_progress)
- M3.4-M3.5 Experimental Precision Gateway and Evaluation: https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40599751294 (in_progress)
- BEN Flutter Chrome Real E2E (M2-F07/F09): https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40599751276 (in_progress)
- M4 Custom Convention Drafts — Domain and Flutter: https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40599751296 (in_progress)
- Feature Learning Gate: https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40599751250 (success)
- M5 Public Auction Coach — Domain and Flutter: https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40599751293 (in_progress)
- Bridge Core CI: https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40599751233 (success)
- Bridge Gateway A4.2 CI: https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40599751247 (success)

## 下一個高風險產品任務（尚未開始）

- 主工作區開局／繼續後預設進專注桌、返回同一session，統一Local與Gateway的路由／恢復／終局／錯誤生命週期。需保持續局同意與fail-closed；不要交輕量agent用單一按鈕改名冒充完成。
- 已驗證叫品解釋需要本局GameSystems身分與可信版本化含義；當前inspector只公開資訊與UNKNOWN。不能從上游SAYC或LLM捏造BEN推理。

## 功能commit前git status（供追溯）

```
 M AGENTS.md
 M apps/bridge_academy_flutter/integration_test/android_rollback_confirm_test.dart
 M apps/bridge_academy_flutter/integration_test/android_table_test.dart
 M apps/bridge_academy_flutter/integration_test/browser_ben_declarer_test.dart
 M apps/bridge_academy_flutter/integration_test/browser_ben_test.dart
 M apps/bridge_academy_flutter/integration_test/browser_gateway_real_test.dart
 M apps/bridge_academy_flutter/integration_test/browser_secure_checkpoint_test.dart
 M apps/bridge_academy_flutter/integration_test/browser_table_test.dart
 M apps/bridge_academy_flutter/lib/src/app_copy.dart
 M apps/bridge_academy_flutter/lib/src/bridge_app.dart
 M apps/bridge_academy_flutter/lib/src/gateway_table.dart
 M apps/bridge_academy_flutter/lib/src/widgets/bridge_bidding_box.dart
 M apps/bridge_academy_flutter/lib/src/widgets/bridge_focus_table.dart
 M apps/bridge_academy_flutter/lib/src/widgets/bridge_table_components.dart
 M apps/bridge_academy_flutter/lib/src/widgets/bridge_table_toolbar.dart
 M apps/bridge_academy_flutter/test/a3_accessibility_test.dart
 M apps/bridge_academy_flutter/test/a3_bidding_box_test.dart
 M apps/bridge_academy_flutter/test/a3_table_components_test.dart
 M apps/bridge_academy_flutter/test/a3_table_toolbar_test.dart
 M apps/bridge_academy_flutter/test/a5_history_test.dart
 M apps/bridge_academy_flutter/test/a5_pbn_export_test.dart
 M apps/bridge_academy_flutter/test/b1_four_board_practice_test.dart
 M apps/bridge_academy_flutter/test/b5_teaching_review_test.dart
 M apps/bridge_academy_flutter/test/b6_daily_practice_test.dart
 M apps/bridge_academy_flutter/test/board_management_test.dart
 M apps/bridge_academy_flutter/test/bridge_app_test.dart
 M apps/bridge_academy_flutter/test/checkpoint_recovery_notice_test.dart
 M apps/bridge_academy_flutter/test/completed_replay_test.dart
 M apps/bridge_academy_flutter/test/m2_focus_table_test.dart
 M apps/bridge_academy_flutter/test/responsive_layout_test.dart
 M docs/implemented/ENGINEERING_NOTES.md
 M docs/implemented/FEATURES.md
 M docs/planning/CURRENT_HANDOFF.md
 M docs/planning/DECISIONS.md
 M docs/planning/ROADMAP.md
 M docs/research/RESEARCH_REPORTS.md
 M packages/bridge_core/lib/src/game.dart
?? apps/bridge_academy_flutter/lib/src/widgets/bridge_auction_grid.dart
?? apps/bridge_academy_flutter/test_driver/bidding_test_actions.dart
?? packages/bridge_core/test/auction_choices_test.dart
```
