# Bridge Academy 目前交接：叫牌 UI 已實作，交付收尾

## 最新配額與 owner 指示（2026-10-28；本次檢查時間 UNKNOWN）

- 最新指示：本次任一可用視窗剩餘≤10%先寫交接，取代前一7%及原30%；已在AGENTS記本次任務覆寫。優先高風險Core／狀態／整合，低風險列出給owner之後派其他agent，不自行spawn／切模型。排程維持owner暫停，沒有重啟。
- **上次紀錄：** 2026-10-27 23:26 primary remaining 0%、secondary 7%。
- **本次觸發：** 本機用量工具於2026-10-28本輪讀值：primary used 4%／remaining **96%**，secondary used 94%／remaining **6%**（觸發10%門檻）。帳號共用用量，不代表專案獨佔消耗。最新狀態`TRIGGERED_SECONDARY_LE_10`。檢查具體時刻：UNKNOWN。立即更新本文件後，只做必要gate、commit/push與CI狀態保存，不開始另一功能。
- **新待辦請求：** owner要求盤點並刪除無意義測試與CI。尚未盤點／修改／刪除任何測試或workflow。需後續獨立執行：以產品風險和實際pipeline觸發找出重複、無行為斷言、裝置hold等候選，先區分核心規則/安全不變量必要保護，僅移除有證據可刪者，合併重複CI工作；不可將「通通刪除」解讀為刪光測試與CI。此新工作在本次≤10%門檻下未開始。

## Git／目標

- Repo C:/Users/user05/StudioProjects/Bridge-Academy；branch master；本輪基底／目前HEAD `9b6d1e746807c1e5fed3af9c4b325290beb738a8`，開始時clean。下方為本輪未提交清單，無其他人工作。尚未commit／push，新SHA CI目前NOT RUN。
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
3. direct commit/push master（不PR、不force），查新SHA CI並記實際status；有失敗只修必要回歸。若受quota限制未完成CI，記URL/in_progress並讓後續agent查，不聲稱PASS。
4. 回退以本次feature commit的git revert；無schema／資料遷移。不要reset --hard或清別人工作。若local preview要停，只針對本次exec sessions31187(8736)、52489(8737)、63848(8738)，不殺其他process。

## 留給其他 agent 的低風險任務（未派發；由 owner 後續指派）

- **L1 雙語／輔具文案核對。** 範圍app_copy.dart的新selectCall/confirmCall/submittingCall/biddingPaused/moreBidLevels/callMeaningUnknown/awaitingCall，及兩Widget的語意名。核對zh-TW/en、200%字體與375px截圖，可調字詞／換行，不能改Core legalCalls、canAct、_sentVersion、確認送出或未知含義政策。交付現有工程筆記補證據，不新增docs／不跑整副牌矩陣。
- **L2 文件證據校對。** 只改7份canonical docs中的舊F63～F65「CI尚未跑」與當前結論矛盾之處；以明確SHA/run URL核對，不改歷史FAIL為PASS、不把研究CI當release核准。不動功能／測試，無須重跑昂貴suite。此項也可補本次新SHA最終CI status。
- **L3 授權資料機械盤點。** 在既有RESEARCH_REPORTS列installed playing_cards內附檔案、版本／archive hash、LICENSE/notice路徑及可查來源；只收集事實，不裁決商用／再散布合法性，不下載未授權素材、不把API key或私牌寫入文件，不改dependency或資產bundle。法律／權重／native binaries發行範圍仍需較高風險審查。
- **L4 最終history對話框視覺留證。** 用fresh loopback origin的已編譯Web及公開測試局，在375px核對N/E/S/W全欄、四個call都在clip內、點call出現未知說明；保存正常尺寸截圖至本機artifact，不入Git。禁止改規則／送出狀態，裝置QA仍HOLD。

## 下一個高風險產品任務（尚未開始）

- 主工作區開局／繼續後預設進專注桌、返回同一session，統一Local與Gateway的路由／恢復／終局／錯誤生命週期。需保持續局同意與fail-closed；不要交輕量agent用單一按鈕改名冒充完成。
- 已驗證叫品解釋需要本局GameSystems身分與可信版本化含義；當前inspector只公開資訊與UNKNOWN。不能從上游SAYC或LLM捏造BEN推理。

## 本輪git status（checkpoint前）

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
