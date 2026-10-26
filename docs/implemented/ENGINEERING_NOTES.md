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
