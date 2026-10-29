# 已完成功能的工程導讀

> 將原本數十個 Mx-Fxx 獨立 Lesson 收斂為一份教學摘要。歷史詳細課程可在整理前 Git commit `425da3ed393e6b9307f3d9961e52e542368c79e5` 找回，不視為已完成學習驗收。

## 功能更新時的筆記規格

新增一個可測試的功能，請在本檔追加一節 `## Mx-Fxx｜功能名稱`，寫出：**使用者情境、真實程式／測試路徑、資料流、架構選擇與替代方案、EXECUTED／NOT RUN 的真實證據、5–15 分鐘練習**。同時更新 [FEATURES.md](FEATURES.md)；避免每次產生額外空白模板和各種版本週報。學習問答是能力檢查，不得從 CI PASS 推論使用者已學會。

## M1-F01｜Pass Out 與 Core 裁決

橋牌 Auction 必須有四次**實際**連續 Pass 才是未叫合約的 Pass Out；有合約後最後三個 Pass 才結束。BEN 若三口 Pass 就標 Pass Out，保留矛盾並由 Core 驗證，**不補造第四口**。程式：[Core](../../packages/bridge_core/)；測試：[Core CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/bridge-core.yml)。練習：逐項判斷 P-P-P、P-P-P-P、1S-P-P-P 哪個終止。

## M2-F25～M2-F32｜Gateway 與安全的 AI 提案

呼叫流程：Flutter → authorized Gateway session → BEN Adapter／AI proposal → Bridge Core legality → event log → filtered PlayerView。限額、Bearer、版本／重試與 server authority 用來防止重放和私牌洩漏；**localhost 技術可玩不代表全網服務可用**。程式：[Gateway](../../services/bridge_gateway/)；真實整局 [CI #38849429500](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38849429500)。練習：如果 BEN 建議不合法的 CardAction，哪一層應該拒絕？

## M3-F01～M3-F09｜2/1 與 SAYC 兩搭檔制度

產品建立 `GameSystems` 並用 SHA fingerprint 鎖定 NS 與 EW，BEN 請求根據輪到的座位填不同 `ourSystem`／`theirSystem`。相同測試牌兩個模型有時可叫一樣，不能因此判模型根本沒切換。真 A/B [CI #40076846012](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40076846012) 16×2 次呼叫；真雙搭檔完整兩局 [CI #40087851963](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40087851963)。練習：NS 21GF、EW SAYC，輪到東家時兩個 request system 值為何？

## M3-F10～M3-F17｜Precision 是另一種引擎

`BBA/EPBot` 的 `Meckwell.bbsa` 被釘選為 `BA-PRECISION-MECKWELL/r1`。1NT 範圍 13–15 HCP，不能偷換外部 Meckwell Lite 13–16。研究可完成整局合法牌，但沒有受測的競賽級 Precision neural cardplayer。[整合研究報告](../research/RESEARCH_REPORTS.md#precision-club-研究)。練習：為什麼 1000 次原生開叫 PASS 不代表 1000 局比賽通過？

## M4-F01～M5-F03｜本機約定草稿與來源可追的教練

原有規格允許編輯本機約定規則、sha256-linked revision、差異、匯入、審查包，但**草稿不是可執行 AI**。`PublicAuctionCoach` 只解釋公開資訊：無已驗證規則時返回 `UNKNOWN`，草稿標 `USER_DRAFT`。程式：[Conventions](../../packages/bridge_conventions/)；[整合研究報告](../research/RESEARCH_REPORTS.md#自訂約定與公開叫牌教練)。練習：何時允許草稿進入 Gateway playable system whitelist？

## M2-F53～M2-F55｜工作區與可見牌

Flutter 將打牌、學院、複盤、我的分開；現有遊戲跨頁保留。牌面套件只顯示 `PlayerView` 允許的牌，窄屏水平捲動不改 GameState。程式：[Flutter](../../apps/bridge_academy_flutter/)；[198/198](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40255094253)、[200/200](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40256171652)。練習：為什麼排序玩家手牌時不能直接 mutate Core 的清單？

## 本次文件精簡後的維護規則

原本分散為數十份的 Mx-Fxx 教學不再每新增一個功能就建立新 Markdown。只要維護本文的一節，保留真正的來源／測試連結、為何採取此解法、設計替代方案、限制和練習即可。M1.3/M1.4 真 BEN 對照與容量資料統一查 [整合研究報告](../research/RESEARCH_REPORTS.md)；以 CI 狀態而不是文字敘述判定是否真正執行。

## M2-F60｜重用弧形手牌元件，保留動作與可及性邊界

**情境：** Reuse First 要避免重寫 fan 排列，也不能把 13 張牌壓成無法點選的小條。[BridgeFocusTable._hand](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_focus_table.dart) 對 [BridgeCardStrip](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_card_strip.dart) 開啟 useFan。以既有 68px slot 與至少 48px 可見步距計算 `68 + (n - 1) * 48`，13 張為 644px；寬度符合且一般字體時，用上游 FlatCardFan 排列原 child widgets，子牌各自旋轉最多 0.06 弧度並在 100px 高內做 6px 弧線。若不足或大字體，沿用原水平捲動；不是另一個卡牌引擎。

**真實資料流：** filtered PlayerView → 既有合法牌 Button／Draggable → layout-only FlatCardFan → 原 callback → Session／Gateway → Core。Fan 不知道 Card／Deal／分數，不讀未揭露手牌，不另送動作。Android/Compose 類比是把同一批 state-hoisted buttons 換成可重用 Layout，而不是把規則塞進 Layout。

**為何與替代方案：** 直接把 13 張重疊到 320px 只剩約 21px 步距，背後卡的 68px widget 雖然還在，實際點擊卻會被後面的卡攔截。此處測試點的是每張卡左方可見區，沒有只量完整 widget 尺寸就冒稱可及性。FlatCardFan 的 Stack 以最後卡疊最上層，故可見步距是驗收重點。無動畫／schema 變更，縮放偏好仍由既有 MediaQuery 處理。

**已執行證據：** Windows／Flutter 3.47.8／Dart 3.13.7；加入弧形與四方位墩牌後，scoped `flutter test --no-pub test/m2_reuse_fan_test.dart test/m2_focus_table_test.dart test/m2_table_motion_test.dart --reporter expanded` 20/20 PASS；`flutter analyze --no-pub` 無問題；完整 `flutter test --no-pub --reporter expanded` 220/220 PASS；`flutter build web --no-pub --release` PASS（既有 CupertinoIcons font inventory 非致命警告）。最初 num clamp 無法傳給 double width 的編譯失敗已加 toDouble 修正。本次新 SHA CI 待提交後確認，不沿用舊來源綠燈。

**隔離 PoC 的學習：** [experiments/card_game_probe](../../experiments/card_game_probe/) 精確依賴 card_game 2.0.0，自訂 Renderer 只畫 Card.code，不使用上游 SVG。CardGame 只輸出 proposal，測試證明 Core state/version 不變。`flutter analyze --no-pub`、三項 probe tests PASS；其中兩項刻意斷言已知限制：非最後牌的 stack size 1 不可拖、同步 proposal guard 會使上游 drag-end `!` 拋 TypeError、以及 reduce-motion 下 AnimatedPositioned 仍有非零 duration。這是 **REPRODUCED／正式採用 BLOCKED**，不是「修好 card_game」或完整 gameplay PASS。Probe 不在正式 app dependency graph；CI 以獨立步驟驗證。

**5–15 分鐘練習：** 在 644px 與 643px 各跑一次 13 張 hand，預測哪個會用 fan；計算可見步距與左右旋轉方向，再逐張點選左方 24px、用 Tab／Enter 操作第一張。讀 probe 中 onPropose 後的 `_sent`，說明為何 UI 的 proposal guard 合理，卻會暴露第三方 drag-end 的空值假設。狀態 ENGINEERING_PASS（本機 fan）／LESSON_DELIVERED；PRACTICED／MASTERED 須真實參與。回退 `git revert <M2-F60 commit>`，無存檔遷移。Android/iOS／A3.5／正式發布未驗收。

## M2-F61｜四方位公開牌與朝贏家收墩

**情境／邊界：** 使用者提供 BBO 截圖，要求牌從引牌／跟牌座位移入、四家公開牌可辨、完成墩往贏家收攏。對照 Nickel Bridge 釘選 SHA 的 `web/src/components/game/TrickArea.tsx`：其 compass slots、diff-driven glide、collect sweep 只作設計參考，未複製原碼／素材；其 Board staging 若使操作等演出則不採用。[BridgeCurrentTrick](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_table_components.dart) 的 compact 分支用 PlayerView.currentTrick 的 handOwner 放四個固定方位，[BridgePublicCardEntrance](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_public_card_entrance.dart) 以來源方位參數動畫，只在新公開牌出現時啟動。完整工作區原本的非 compact 呈現保留。

**收墩／替代方案：** [BridgeFocusTable](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_focus_table.dart) 依 completedTricks 增量取得公開四張牌及 Core winner，overlay 從各自 slot 朝 winner 線性靠攏並淡出；IgnorePointer／ExcludeSemantics、版本與 reduced motion 保護照舊。原先四張橫列整體平移看不出各座位，改為各自起點。320px 下較高的 compass 曾讓牌桌底部 overflow；把公開牌 slot 壓到 116px，且專注桌的窄屏手牌捲動不另留 14px 空白，保留正常字體 812px 高的單屏。沒有新 schema／Core 邏輯／動畫完成後 action。

**已執行證據：** `flutter test --no-pub test/m2_reuse_fan_test.dart test/m2_focus_table_test.dart test/m2_table_motion_test.dart --reporter expanded` 20/20 PASS；新增測試驗證四方位來源、同版不重播與四張牌實際距離贏家縮短，舊測試驗證四寬度 52 張／13 墩、減少動畫及取消。首次兩次 scoped 嘗試因 24px／40px overflow FAILED，調整後重跑 PASS。完整測試與 Chrome CI 需以最後新 SHA 紀錄，不挪用舊版 PASS。狀態 **ENGINEERING_PASS（本機 scoped）／LESSON_DELIVERED**，PRACTICED／MASTERED 待使用者練習；A3.5／裝置 QA HOLD、Production NO-GO。

**5–15 分鐘練習：** 用固定 seed 對局走四張公開牌，指出 `handOwner` 與 `winner` 各決定哪個畫面座標；在第三張入場時重新建立相同 view，預測動畫會否重播，再開減少動畫檢查立即顯示。回退 `git revert <本功能提交>`，無資料遷移。

## M2-F62｜明手與己方手牌回到牌桌兩端

**使用者情境／驗收：** 使用者的 BBO 參考圖是北側明手、南側己方手牌，先前 focus table 把 `_hand(dummy)` 與 `_hand(viewer)` 都接在 `_arena()` 後，導致兩排都在桌面下方。現在 [BridgeFocusTable._tableSurface](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_focus_table.dart) 在同一 ColoredBox 內依序放已授權明手、中央 DragTarget、自己的手牌；足夠寬時 `BridgeCardStrip.centerWhenFits` 使牌列置中。Flutter 用既有授權卡牌與 Session，不複製 Nickel Bridge 的 React 元件；其 pinned `TrickArea.tsx` 與 BBO 參考只指導座位關係，沒有匯入第三方素材。

**邊界／替代：** `view.dummyExposed && view.dummyCards != null` 仍是揭露條件，未揭露時不建立北側牌列；沒有把四家暗牌傳給 Widget。沿用已有 FlatCardFan、合法點牌、長按拖曳、取消與回合版本檢查。原本只把明手移到 arena 前卻保持桌面底色分離的方案不足以表達同一牌桌，因此用容器包三區。正常高度的中區 Expanded，矮視窗／大字體使用既有自然捲動，沒有修改 Core、schema 或 API。

**測試證據：** `flutter test --no-pub test/m2_focus_table_test.dart --reporter expanded` 14/14 PASS（補上揭露前不渲染斷言後已重跑）：320／375／768／1280px 明手底緣在中區頂緣上方、己方頂緣在中區底緣下方、寬版居中；既有四寬度完整 52 張／13 墩、2×字體、拖曳與收墩回歸同批通過。`flutter analyze --no-pub` 0 issue、完整 `flutter test --no-pub --reporter expanded` 224/224 PASS、`flutter build web --no-pub --release` PASS（既有 CupertinoIcons 字型警告）；真 Chrome 檢查桌面與 375px 成品，截圖在 Codex visualization 目錄、不入 Git。這是工程視覺核對，不冒稱 A3.5 真人驗收；新 SHA CI 仍需提交後讀。狀態 **ENGINEERING_PASS（本機）／LESSON_DELIVERED**；PRACTICED／MASTERED 未驗收，A3.5／Android／iOS HOLD，Production NO-GO。

**5–15 分鐘練習：** 在固定 1NT 南家局比較第一張公開牌之前與之後的 PlayerView，指出何時允許建立北側明手牌列；把視窗改為 375px 與 1280px，檢查上下位置及水平可達性。回退使用 `git revert <M2-F62 commit>`；無資料遷移。

## M2-F57｜專注牌桌與可及性退路

**情境：** 打牌時不要一直捲過練習入口與設定。Local／Gateway route 使用 AnimatedBuilder 監聽原 Session，再投影 PlayerView 給 [BridgeFocusTable](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_focus_table.dart)；Widget 沒有 Deal／Bearer。一般高度用 Expanded arena＋兩組水平手牌，返回頁面仍是同一局。矮視窗或大字體使用無固定總高度的 Column，讓內容自然捲動，而不是縮字／縮觸控目標。相當於 Compose 將遊戲 ViewModel 留在上一層，新增同一狀態的不同畫面。

**替代／陷阱：** 直接刪掉舊工作區會破壞教學／存檔恢復入口；複製 Session 會開另一局。固定最小高度曾在 2×字體溢位，現改自然延伸。中央公開牌使用 compact 顯示、完整語意標籤不變；Column 使用 mainAxisSize.min 才能真正置中。Local saveFailed／恢復確認與 Gateway actionsPaused 仍必須守住。

**驗證：** [m2_focus_table_test.dart](../../apps/bridge_academy_flutter/test/m2_focus_table_test.dart) 的四種寬度逐張跑到 52 張／13 墩、2×字體退路、開啟／叫牌／返回保留版本；scoped 九項 PASS。最終 analyzer PASS、全 Flutter 215/215 PASS、Web release PASS（既有 CupertinoIcons font inventory 警告），ENGINEERING_PASS 限本機範圍；Chrome CI 待 push 後確認。新 [browser target](../../apps/bridge_academy_flutter/integration_test/browser_table_test.dart) 驗證專注桌完整 Demo 牌局；真 BEN／裝置／真人 QA 不由 Widget 測試代替。**5–15 分鐘練習：** 375×812 與 320×600／2×字體各執行一次，解釋為何後者允許捲動而不是隱藏按鈕。LESSON_DELIVERED，未聲稱熟練。

## M2-F58｜拖曳是動作意圖

**資料流：** 可見牌 → LongPressDraggable 的 `BridgeCardDrag(version, owner, card)` → DragTarget `_allowed` 重新檢查最新 PlayerView → `_play` 單版本 guard → 原 Session submit → Core。過期、非輪到、非法牌、paused、重複 drop 都不送出；桌外取消無動作。點擊／鍵盤仍走同一 callback，拖曳不是唯一操作方式。

**為何／替代：** 若在 drag start 就提交，取消也會出牌；若只相信 drag start 的合法性，網路已更新時會送過期輸入。UI guard 只改善互動，Server action ID／Core validation 才是權威。實測找到 Tooltip 子節點的長按搶先贏得 gesture arena；[BridgePlayingCardButton](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_table_components.dart) 的 dragEnabled 才採 manual tooltip trigger，其他頁面保留原互動。

**驗證：** 上述九項中實際 pointer 長按→桌外取消→回桌放下一次，以及直接過期／重複 payload、paused／wrong-owner 不送出。Chrome 新 target 首張也用實際 drag，結果須查 CI 後才宣稱通過。**5–15 分鐘練習：** drag 開始後版本更新，說明 drop 為何必須拒絕；保留合法點擊與語意操作。LESSON_DELIVERED；PRACTICED／MASTERED 需真實參與。

## M2-F59｜收墩與權威狀態分開

**實作：** `didUpdateWidget` 觀察 completedTricks 增加，只取最後公開 Trick；AnimationController 在 IgnorePointer／ExcludeSemantics overlay 將四張牌朝贏家方向位移／淡出。沒有 animation-complete submit，也不把演出存入 checkpoint。新墩可替換，dispose／reduce-motion／版本重設會中止，已存在的還原 snapshot 靜態顯示。

**替代／陷阱：** 留著上一墩作真正的 currentTrick 會混淆合法狀態，等 220ms 才允許下一張則會卡回合。Overlay 只做視覺副本，當前 cards 與 legalCards 直接用新投影。類似 Compose 的 presentation animation state，不應回寫 domain reducer。

**驗證：** 固定 seed 57，四種寬度逐張驗證；收墩卡只等於剛完成的公開四張，reduce-motion 立即消失，再開動態不重播，52 動作／13 墩後 dispose 無 ticker 殘留。Scoped 九項 PASS，最終證據見交接；不代表 A3.5／裝置 QA。**5–15 分鐘練習：** 在收墩第一幀檢查下一張合法牌仍可操作；指出為何 overlay 需要 IgnorePointer 和 ExcludeSemantics。LESSON_DELIVERED，未推論 MASTERED。三功能無新相依／schema，回退 `git revert <本次功能提交>`。

## M2-F56｜公開出牌動態回饋與減少動畫

**情境／驗收：** 玩家需要看見新公開牌及輪到的座位，但動畫不能延後合法操作。還原 snapshot 不重播；新牌只進場一次；換墩／離頁可取消；設定與裝置減少動畫偏好都使效果立即結束。狀態：**ENGINEERING_PASS（本機與下列 scoped CI）／LESSON_DELIVERED**；PRACTICED、MASTERED 待真實練習。

**程式與資料流：** 已接受 Action → Core／Gateway → `PlayerView` → [BridgeCurrentTrick](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_table_components.dart)。比較新舊 view version，對新增的公開 `completedTricks.length:handOwner:card.code` 建立穩定 key → [BridgePublicCardEntrance](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_public_card_entrance.dart) 自有 `AnimationController` → 180ms 淡入與最多 12px 位移。Widget 不讀 Deal、不呼叫 Session，沒有 completion callback 或延遲 submit。換墩移除 widget，dispose controller，因此不留下上一墩 ghost。公開牌語意從第一幀就存在，不因 opacity=0 而延遲讓螢幕閱讀器知道已接受的出牌。

**設定：** [BridgeAcademyApp](../../apps/bridge_academy_flutter/lib/src/bridge_app.dart) 的本次使用偏好 `_reduceMotion`，透過 `MaterialApp.builder` 向子樹投影 `MediaQuery.disableAnimations = system || user`。系統要求減少動畫時，關閉 app 開關也不能覆蓋它。文字由 [AppCopy](../../apps/bridge_academy_flutter/lib/src/app_copy.dart) 提供 zh-TW／en；未宣稱跨重啟保存。

**為何這樣做／替代方案：** 效果狀態與權威牌局分開，類似 Compose 在穩定 `key` 下以 `remember` 保存 animation state，而非把播放進度寫進 ViewModel 的牌局事件。用 `AnimatedSwitcher` 保留 outgoing card 會短暫顯示前一墩；用 timer 在結束時送動作則可能雙送或鎖回合。此處只渲染目前投影；穩定 key 保留同張牌的 controller，語言／設定重建不重播。還原先前已公開的牌直接顯示，避免把 checkpoint 當成新動作。

**EXECUTED（Windows，Flutter 3.47.8／Dart 3.13.7）：**

- `flutter test --no-pub test/m2_table_motion_test.dart test/a3_accessibility_test.dart test/a3_table_components_test.dart test/m2_practice_workspace_test.dart --reporter expanded`：20/20 PASS。
- `flutter analyze --no-pub`：No issues found。
- `flutter test --no-pub --reporter expanded`：206/206 PASS。新增六項涵蓋穩定 key、不重播、restore、取消、公開語意、動畫中合法操作、中英／系統偏好；固定 seed 56 的全局 widget projection 測試 52 unique cards／13 tricks／version 52，不稱真 BEN。
- `flutter build web --no-pub --release`：PASS；既有 CupertinoIcons font inventory 非致命警告仍存在，Wasm dry run 非 Wasm runtime 驗收。

**修正過的失敗：** 初版測試誤用 `BridgeEngine`（正確名稱 `BridgeGame`）、誤認兩張牌後輪到 South，及語意 handle teardown 時機；均修正後重跑。語意測試另找出公開座位子標籤重複，現以單一完整 seat/card label 排除子節點重複內容。Python gate 以錯誤 module 工作目錄執行曾 import 失敗，須使用 `python scripts/test_check_feature_lessons.py`。

**Chrome 已執行／其餘限制：** 新增 [browser_table_test](../../apps/bridge_academy_flutter/integration_test/browser_table_test.dart) 在完整 Demo 牌局第二次選牌後切換減少動畫再繼續到 13 墩，已由下列真 Chrome CI 執行成功。未啟動 Android/iOS／A3.5 QA、真 BEN 本機、部署。此功能未完成全桌單屏／拖曳／收墩飛行；回退以 `git revert <本功能提交>`，無 schema 遷移與新相依。

**5–15 分鐘練習：** 執行上述 scoped tests，讀 `didUpdateWidget` 的新舊 identity 比較，在 90ms 時加入一次相同 view rebuild 並確認 opacity 不回到 0。再開啟系統減少動畫、關閉 app 開關，說明為何仍應立即顯示牌；不要為測試加入第二次 Session submit。CI 通過不代表已掌握此概念。

**提交與 CI：** source＋tests＋本節及 FEATURES 已同一 commit `030276b1e10d8243a429146ec1a5d7e559592998` push master。[Feature Learning Gate](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40300087861) success；[Flutter／Web／Chrome](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40300087862) **success**。已讀 jobs `121495539167`／`121495538670` 實際 logs：No issues found、206 tests passed、Built build/web；browser_table_test 及 browser_secure_checkpoint_test targets 均 All tests passed。這是 Demo／Chrome 技術驗收，不是真人或正式發行驗收。M4/M5 CI 亦 success；真 BEN／Precision 自動回歸當時仍執行中，不能提前稱成功。

三功能最後共同驗證：`flutter analyze --no-pub` 無問題、`flutter test --no-pub --reporter expanded` **215/215 PASS**、`flutter build web --no-pub --release` PASS；Windows／Flutter 3.47.8／Dart 3.13.7。無外部元件移植、未新增規則引擎。新 browser target 真 Chrome 待 CI，Gateway 專注路由的真 BEN／裝置／A3.5 NOT RUN。


## M2-F63｜讓墩牌與收墩共用座標

**情境與資料流：** 先前中央牌固定 40×56，收墩又有獨立的 148×116 魔術數字。現在 `BridgeFocusTable._arena` 依實際寬高建立 `BridgeTrickGeometry`，交給 `BridgeCurrentTrick` 及 `_collectionLayer`。幾何類只含尺寸／Seat；公開牌與贏家仍來自 PlayerView。入場從對應座位邊緣開始；收墩使用同一個 `seatOffset`，先集中再飛往 winner anchor，沒有第二個規則或動作排程器。

**取捨與已修問題：** 參照 Nickel `TrickArea.tsx` 的 slot／flight layer 概念，以 Flutter 原生 AnimationController 接現有 PlayingCardView，避免引入有 drag-end／reduced-motion 缺口的 card_game。測試曾抓到第一墩完成後 footer 新增造成 10px 跳位，改為固定保留依文字縮放計算的高度。窄屏依可用高度調整牌面，不能只按螢幕寬度放大；收墩純裝飾且 IgnorePointer／ExcludeSemantics，不阻擋下一回合。還原、縮減動畫與卸載仍能中止。

**真實證據：** Windows／Flutter 3.47.8，`flutter analyze --no-pub` 0 issue；精簡前 `flutter test --no-pub --reporter expanded` 231/231 PASS；`flutter build web --no-pub --release` PASS（既有 CupertinoIcons inventory 警告）。測試精簡後把重複寬度矩陣收斂為 320／1280px，保留端點尺寸、收墩首幀連續與贏家方向；完整13墩重播只跑一次窄屏，不在桌面重複重播。精簡後 `flutter test --no-pub test/m2_focus_table_test.dart` 15/15 PASS；新 SHA CI 待 push，不沿用舊綠燈。狀態 ENGINEERING_PASS／LESSON_DELIVERED，owner-held 裝置／A3.5 NOT RUN。

**5–15 分鐘練習：** 讀 `bridge_trick_geometry.dart` 的 `position` 和 `seatAnchor`，指出前者為何只用局部 stage、後者為何需要整個 arena。把瀏覽器從 375px 改成 1280px，觀察牌面變大後收墩第一幀仍不跳位。回退用本功能 commit 的 git revert；無 schema/API 遷移。

## M2-F64｜把重疊手機手牌的選取與提交分開

**情境與實作：** 使用者提供 BBO 手機圖，要求同屏看完 13 張牌、真正的扇形上下手牌。先前 48px exposed-width gate 導致手機只顯示可捲動列，未達此要求。現在 `BridgeCardStrip.compactFan` 重用 FlatCardFan 定位，選中牌的原槽放尺寸佔位，並在同一 Stack 最上層繪製一次抬起的牌；沒有重複的可點擊／語意實例。PlayingCardView 保留背景／牌面渲染，focus 牌加大左上角牌點並留白中心，使被遮住的牌仍可辨識。

**邊界與替代方案：** 從 pinned Nickel `HandFan.tsx` 選取／第二點提交與 lift 概念移植為 Flutter `_selected`。小於 48px 可見步距時第一點只更新 UI 選取，第二點或獨立確認鈕才呼叫 `_play`；`_play` 仍以投影版本、owner、canAct、legalCards、paused、同版本防重檢查提交。新版本／暫停會清除選取。寬版保留直接點牌；大字體或標題列手動切換採原寬牌列。單純把手機牌縮到很小可保住48px點擊區，但可讀性差；取消整副手牌則違反 owner 的參考，因此採重疊預覽＋確認＋可切換寬版。沒有外部 AI／規則移植。

**真實證據與修復：** 320／375px 中英文測試初點不提交、抬起、一次確認、13 張牌點位於 viewport、新版本／暫停清除、寬列可及；大字體回歸找到 header Row 英文溢位，已加 Flexible／ellipsis。拖曳測試改在扇形真正露出的牌緣施作，不再把被下一張遮住的中心當命中點；仍驗證送出卡牌等於原合法牌、取消不送、同版本一次。最終 analyzer 0 issue、全測試231/231與Web release PASS；Chrome 375px 實際目視和選取操作已核對，新 SHA CI 待 push。ENGINEERING_PASS／LESSON_DELIVERED；PRACTICED／MASTERED 不由 CI 推論。

**5–15 分鐘練習：** 在375px選一張合法明手牌，先確認墩牌數沒有改變，再按確認出牌；切換寬牌列並用鍵盤操作。讀 `_selected` 和 `_submittedVersion`，說明兩者為何不能合成同一個欄位。回退用本次 commit 的 git revert；無存檔遷移。

## M2-F65｜真實座位與畫面方位分開

**問題與實作：** 手牌原已放在底部，但中央標籤、墩牌和收墩仍固定北上南下，導致北／東／西家玩家看見不一致的來源方向。現在 PlayerView.viewer → BridgeTrickGeometry.fit(viewer: ...) → displaySeat／seatAt → seatOffset／position／seatAnchor；BridgeFocusTable 的四個標籤及 collection layer 共用同一幾何。這是 presentation adapter，CardAction 與 PlayedCard.handOwner 始終使用原本的 Seat，不旋轉 Core 事件。

**取捨與邊界：** 參考 pinned Nickel `TrickArea.tsx` 的 flipped compass mapping，擴展為四座位的可逆映射；未複製上游程式／素材，沿用既有 renderer、drag 和動畫。另一方案是旋轉整個 Widget，但會把文字／牌面一併轉向，亦讓手牌與語意定位難以維持。明手上方獨立面板仍標實際座位；防家視角下不把明手偽稱搭檔。相同 version 也可能換 viewer，因此選牌／提交鎖／收墩必須按 viewer identity 重置；公開入場 Widget key 加入 viewer，避免繼續播放舊方位動畫。

**驗證：** `flutter test --no-pub test/m2_focus_table_test.dart` **16/16 PASS**；既有 `flutter test --no-pub test/m2_table_motion_test.dart` **6/6 PASS**；`flutter analyze --no-pub` **0 issue**。只新增一個四座位情境，不為每個寬度重播整副牌；斷言開引者在左、明手在上、下一家在右及 Core winner 的實際收墩方向，另驗視角切換後沒有殘留暗牌或舊選取。最終補 defender projection／選取清除斷言後已重跑同一 scoped 檔與分析。SHA `aced15754ab108d79903004a6deb1d15cc0a49f0` 的 [CI #40493585512](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40493585512) **success**：完整app tests、analysis、Web release與Chrome table/checkpoint；[learning](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40493585440) success。[真BEN](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40493585616)最後查詢仍in_progress。完整本機suite／新本機Web build NOT RUN。狀態 ENGINEERING_PASS（上述範圍）／LESSON_DELIVERED，PRACTICED／MASTERED 未驗收。

**5–15 分鐘練習：** 選東家當莊家，指出畫面上、下、左、右各對應哪個真實 Seat，再讀 `seatAt` 檢查答案。確認事件中的 handOwner 沒有被改成畫面方位。回退使用本功能 commit 的 `git revert`，無 schema／API 遷移。


## M2-F66｜用公開狀態提供合法叫品，讓選取與送出分開

**資料流：** PlayerView公開auction/phase/turn → Core BridgeGame.legalCalls → BridgeBiddingBox合法集合 → 本地selected code → 確認 → 原session.submitCall → Core reducer。新_validateCall由公開choices與_applyCall共同使用，保留原先bid outrank、X/XX、turn／phase檢查；不把手牌送進UI helper，也不改Gateway JSON欄位。呼叫方原level/strain本地狀態已刪除，由共享盒持有一次選取。

**移植與取捨：** Nickel BidBox（pinned SHA見研究）提供最低合法階起的4階窗口、折疊高階、全叫品先選後確認、busy/waiting鎖定。Flutter以OutlinedButton矩陣、內部ListView及FillButton確認實現；短視窗顯示較少列但可內捲，避免整個手機桌被擠掉。保留Flutter標準鍵盤focus/semantics；叫品有完整語意名及selected狀態。與直接下拉或直接Pass相比，多一次確認減少誤觸。_sentVersion在原投影尚未回覆時鎖一次提交；重新可操作的失敗回覆可重選重試。Widget再核對view.canAct，不因caller旗標錯誤就開放其他座位。這是UI提案控制，最後合法性仍由原session/Core裁決。

**真實驗證：** Core `dart test`58/58；Core `dart analyze --fatal-infos`無問題；Flutter完整suite227/227、analyzer0，完整suite是在最後窄對話框／權限補強前；最終 `a3_bidding_box_test.dart`＋`a3_table_toolbar_test.dart`8/8。新測試明確驗證選2S不變version、確認一次、等待／非本人不能選、版本失效、7NT後僅正確X、展開高階及2×字體。既有Chrome/BEN fixture移除bid_level下拉，實際選bid_3NT再確認；test helper只pump，真HTTP仍由原wait等待，不能pumpAndSettle卡網路。新SHA CI尚未跑，held Android來源只跟隨遷移而未執行QA。

**5–15分鐘練習：** 在固定局選2♥但先不確認，確認叫牌表仍顯示?；再確認後查事件只有一筆2H。讀Core legalCalls與_applyCall，指出共同驗證位置。ENGINEERING_PASS限上述範圍／LESSON_DELIVERED；PRACTICED／MASTERED待實際練習，回退用本功能commit的git revert，無schema遷移。

## M2-F67｜四欄歷史是公開事件的排列，不是另一個規則引擎

**實作：** BridgeAuctionGrid用dealer.index在首列前補空格，再依公開事件順序每4口分列；固定欄頭標本人與活動座位，pending?放在下一個合法輪次。ScrollController於事件數改變後捲到最後一列，mount/restore不虛構新叫牌。每口按鈕只顯示公開Seat／Call；沒有已審核含義時用明確未知說明，不將Nickel的SAYC glossary套用至本局NS/EW制度。一般桌在auction以grid取代出牌墩區、專注桌直接用arena裝grid、toolbar歷史也用同一Widget。

**取捨／修復：** 參照pinned AuctionGrid的dealer-padding、固定欄頭、pending、新列追蹤與inspect；使用Flutter元件重寫。最新叫品以背景高亮，不加入上游機器人逐口staging或延遲真正回合。Web目視發現375px AlertDialog第四欄被過大的minWidth裁切；最小寬度改成4×48px與文字縮放所需寬度，並在既有toolbar用例檢查每個call的左右邊界都在grid內。大字體仍允許橫捲，避免把字硬縮小。Web reload曾取得舊cache，最終成品需用fresh-origin核對，不把舊畫面當修復證據。

**證據：** 初版full suite226PASS/1FAIL是舊a3_table_components_test要求auction顯示BridgeCurrentTrick；更新為真實grid後227/227PASS。最後窄dialog／權限補強後既有代表檔8/8PASS，analysis0；先前Web releasePASS，最新build與fresh-origin／CI結果見CURRENT_HANDOFF。fixture覆蓋4個dealer的跨列、pending、長歷史最新列及未知說明。沒有以畫面測試推論制度正確或牌力。

**5–15分鐘練習：** 以西家dealer的前5口叫牌手畫4欄，指出首列前3格為何必須留空，再對照測試的auction_call_0與W欄中心。ENGINEERING_PASS限工程驗證／LESSON_DELIVERED，未宣稱PRACTICED／MASTERED。回退用同批功能commit git revert。

## M2-F68／F69｜明手花色選擇與依狀態確認的 spotlight 教學

**操作與資料流：** 明手 `PlayerView.dummyCards` → `sortedVisibleCards` → 四個花色堆疊；點花色只設定 `_selectedDummySuit`，展開該花色的牌列；點牌進入既有 `_play`，仍以暫停、version、viewer、owner、turn、`canAct` 及 Core `legalCards` 驗證。新版本、暫停或 viewer 轉換清除未提交花色。明手測試確認面板在桌上方，自己的手牌在桌下方；牌面堆疊縮短後，320px 墩牌仍達原有最小可讀尺寸。

**教學與確認邊界：** 使用 MIT `overmark 0.2.0` 對叫牌盒、手牌或明手花色／牌列開 action-gated spotlight。叫品／牌的 UI callback 不直接完成教學；記錄提交前 version 與動作，僅在下一個投影 version 增加且公開 auction entry／trick play 完全吻合時呼叫 `completeAction`。選花色是純本地檢視狀態，所以可在實際點擊後繼續；Skip／系統關閉只清本地教學狀態。Core reducer、合法性、PlayerView及事件 schema 未改。

**取捨與常見陷阱：** 重用通用 spotlight action gate，保留原牌桌元件與 callback；沒有照搬 React、改造規則，也不另加教學狀態存檔。不能在 tap handler 立刻把「已送出」當作「已接受」：Gateway／Core 拒絕、失敗或尚未回覆時，提示應停留。明手教學只在明手公開且玩家有權控制時出現；其他回合不暴露手牌或解鎖動作。

**EXECUTED：** `flutter test --no-pub test/m2_focus_table_test.dart --reporter expanded` **18/18 PASS**；同檔 `--plain-name "tutorial"` **2/2 PASS**；`flutter analyze --no-pub` **No issues found**；`python scripts/check_feature_lessons.py --paths docs/implemented/FEATURES.md docs/implemented/ENGINEERING_NOTES.md` **PASS**。教學測試驗證 Core 接受叫品／出牌前提示不前進、接受後結束，skip 不改動遊戲狀態。完整新 SHA CI、Web/Chrome、Android/iOS與真人 QA **NOT RUN**；不可沿用舊 SHA CI 宣稱本次通過。

**5–15 分鐘練習：** 檢查 `BridgeFocusTable.didUpdateWidget` 的 call/card 比對，手動把測試 callback 改成不更新 state，確認教學不會假完成；再用原 Core reducer更新 view。回退以本功能 commit `git revert`，無 schema／存檔遷移。狀態 ENGINEERING_PASS（上述 scoped 行為）／LESSON_DELIVERED；PRACTICED、MASTERED 未驗收。

## M2-F70｜讓明手可出的花色一眼可辨

`BridgeFocusTable._dummySuitColumn` 已經用 `PlayerView.legalCards` 決定哪些花色能點，但畫面先前把合法與非法花色畫得幾乎一樣。現在輪到玩家控制明手時，含合法牌的花色會有青綠邊框、淡底色與勾記；含牌但無合法選擇的花色降低透明度。外層 `Semantics` 用同一個布林狀態設定啟用旗標，並在 `AppCopy` 提供中英文「可從此花色出牌」標籤。視窗字體放大時不顯示小勾記，標頭採受限寬度與省略號，完整名稱和狀態仍由語意標籤提供。

替代方案是只保留目前的點擊停用行為，或在 Flutter UI 重算跟牌規則；前者仍讓玩家猜測，後者會複製 Bridge Core 規則。採用同一份 `PlayerView.legalCards` 作視覺、輸入與輔助技術狀態，保留 Core 作唯一權威。改動位於 `bridge_focus_table.dart`、`app_copy.dart`，回歸位於 `m2_focus_table_test.dart`。已執行 `flutter test --no-pub test/m2_focus_table_test.dart --reporter expanded` **21/21 PASS**，驗證非法花色點擊不展開／不變更版本；`flutter analyze --no-pub` **No issues found**；曾發現並修正大字體下標頭橫向溢位，最終回歸已通過。遠端 CI 依新 SHA 狀態記於 CURRENT_HANDOFF；真人操作與裝置 QA 未執行。

**5–15 分鐘練習：** 在 `_dummySuitColumn` 找出 `hasLegalCard`、`isDummyAction` 與 `dimmed` 三個狀態，說明為什麼「有牌可跟」和「現在輪到我且可以操作」要分開計算。再看測試如何用 `PlayerView.legalCards` 對照 `SemanticsFlags.isEnabled`，而不自行重寫橋牌規則。

## M2-F71｜兩種牌桌共用明手選花色與套件牌面

**情境與改動：** 使用者指出明手應先以四個花色堆疊摘要呈現；點某花色後，其他花色必須完全隱藏，只看該組完整牌面。一般桌與專注桌先前有不同互動，現在都使用 `BridgeDummySuitPicker`，花色選擇和返回路徑一致。自己的手牌也在兩種桌型使用緊湊 FlatCardFan。`BridgeCardFace` 是 Core `Card` 至 `playing_cards.PlayingCard` 的單向 adapter，再使用套件 `PlayingCardView` 畫點數、花色符號及人頭牌；它不發牌、不判定合法性、不讀取其他座位手牌。原 action callback 和 Core 驗證保持權威。

**替代方案與邊界：** 不再沿用自繪點數／單一大花色牌面，也不複製 Nickel 的 React runtime；採用研究已核對版本的 Flutter 元件。`card_game` 拖放 probe 有已記錄的相容性缺口，本次沒有引進。`playing_cards` Apache-2.0 package license 與內附 Wikimedia 圖像各自授權是兩件事；工程驗證不代表正式素材權利已放行。明手資料仍限於揭露後的 scoped `PlayerView`。

**驗證與回退：** 已執行 `flutter test --no-pub test/m2_focus_table_test.dart test/a3_table_components_test.dart test/bridge_app_test.dart --reporter expanded`，**28/28 PASS**。`flutter analyze`、Web/Chrome、CI、Android/iOS QA 本次未執行。回退以本功能變更的 `git revert`；無存檔或 API schema 遷移。人工視覺驗收與套件圖像 release inventory 尚未完成。

**5–15 分鐘練習：** 在一般桌及專注桌各選一次明手花色，確認展開後只有該花色、返回後四組恢復；再找到 `BridgeDummySuitPicker` 的 `legalCards` 判斷，說明 UI 為何只表達操作意圖，而實際出牌仍需 Core 接受。狀態 ENGINEERING_PASS（scoped）／LESSON_DELIVERED；PRACTICED／MASTERED 待實際練習。

## M2-F72｜活動牌局只顯示單屏牌桌

**決策實作：** 依使用者明確要求刪除一般桌。Local 與 Gateway session 一旦有 `PlayerView`，便直接以 `BridgeFocusTable` 作活動牌局根畫面；不再由散落式 `BridgeTableSurface` 顯示一遍牌局，再提供跳轉到第二套 focus UI。focus surface 使用 `bridge_board` 作為唯一活動桌面標記，所有牌面與動作仍走原 scoped `PlayerView`／Core validator。

**保留功能：** 無活動牌局時的 Local 開局與 Gateway 連線／制度選擇、歷史檢視、恢復確認、錯誤重試、日常／四副練習、完成結果／重打／下一副及 Gateway 刷新／新 session／公開叫牌複盤保留在單屏桌牌周邊操作。底層舊桌面元件仍可供獨立呈現元件測試使用，但不再由進行中的產品流程呈現。

**驗證與回退：** 已執行 `flutter test --no-pub test/m2_focus_table_test.dart test/bridge_app_test.dart test/a4_gateway_integration_test.dart --reporter expanded`；31 PASS、1 FAIL（舊一般桌使用的 `dummy_card_*` key 在 focus 桌不存在）。只改該測試 selector 後，`flutter test --no-pub test/bridge_app_test.dart --plain-name "make bid -> demo lead -> exposed dummy card is playable" --reporter expanded` **1/1 PASS**；沒有重跑整組 32 項。`flutter analyze --no-pub` **No issues found**；feature lesson gate、`git diff --check` PASS。CI、瀏覽器目視及裝置 QA NOT RUN。無 Core／存檔／網路 schema 遷移；以本功能 commit `git revert` 回退。PRACTICED／MASTERED 尚未驗收。

**5–15 分鐘練習：** 從 Local 開始一副牌並從 Gateway 開啟牌局，確認兩邊都直接進入同一桌面；完成一口叫牌並打開叫牌歷史，說明 session callback 如何保持不變而桌面切換被移除。

## M2-F73｜共同樞紐放射扇形手牌

**實作與取捨：** `BridgeCardStrip` 不再以 `FlatCardFan` 加獨立旋轉／弧形位移疊算。每張牌依正規化索引計算角度，底部沿共同虛擬中心的放射方向定位，再以 `Alignment.bottomCenter` 旋轉；寬度決定半徑，避免桌面超寬時牌扇壓縮墩牌。選牌置頂，抬升及端牌微調沿同一放射向量。牌面與 callbacks 沿用原元件，沒有改牌局規則或 `PlayerView`。

**開源研究：** 檢視 [netgfx/playing_cards_layouts](https://github.com/netgfx/playing_cards_layouts) README 的 `fanCards()` 座標／角度輸出模型；來源 HEAD pin：`401eb837252a869a56da2068a07be761921fadd6`。其 [LICENSE](https://github.com/netgfx/playing_cards_layouts/blob/401eb837252a869a56da2068a07be761921fadd6/LICENSE) 為 MIT，README 說明其 layout 是 cardsJS 的直接移植。本功能未複製該 repository 程式碼或新增依賴，故未引入其 notice；`playing_cards 0.4.1+11` 仍用於牌面。幾何依共同樞紐需求在專案內自行實作。

**驗證：** `flutter test --no-pub test/m2_focus_table_test.dart --reporter expanded` **21/21 PASS**；涵蓋 320–1280px、選牌／確認、明手位置、墩牌可讀及無垂直 overflow。桌面寬度曾測得墩牌低於最小可讀寬度，已限制扇形半徑後全檔通過。`flutter analyze --no-pub`（相關 source files）**No issues found**。瀏覽器實際畫面未驗證；Android/iOS QA 仍 HOLD。ENGINEERING_PASS／LESSON_DELIVERED；尚無學習者練習證據。無規則／存檔遷移；以本功能 commit `git revert` 回退。

**5–15 分鐘練習：** 比較中心、左右端牌的角度與露出牌角，再點選端牌並確認出牌；說明共同 hub、繪製堆疊順序及 action callback 的關係。

## M2-F74｜活動牌局不顯示開局練習面板

**實作與邊界：** `BridgeApp` 活動牌局的 `BridgeFocusTable.sessionActions` 不再嵌入 `_practiceHub`。無活動牌局的開局頁保留面板；叫牌、Core phase transition、明手揭露與 play callbacks 未修改。避免開局面板擠壓牌桌與 Flex overflow。

**驗證：** `flutter test --no-pub test/bridge_app_test.dart --plain-name "make bid -> demo lead -> exposed dummy card is playable" --reporter expanded` **1/1 PASS**；案例尺寸 1245×718，斷言牌桌存在、活動牌局不顯示開局面板且無 layout exception。`flutter analyze --no-pub`（相關 source files）**No issues found**。無 Core／資料遷移；以本功能 commit `git revert` 回退。ENGINEERING_PASS／LESSON_DELIVERED。

**5–15 分鐘練習：** 在 1245×718 測試視窗開始牌局並完成叫牌，確認桌面仍顯示，且沒有開局練習面板或 overflow stripe。
