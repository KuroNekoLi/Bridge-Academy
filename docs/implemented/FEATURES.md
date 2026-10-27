# 已實作功能（截至 2026-10-27）

> 「工程測試通過」不代表「已公開部署」；「研究可用」也不代表正式產品功能。

## 橋牌核心與資料安全
- **Bridge Core**：四家各 13 張牌、叫牌／Pass／Double／Redouble、合法跟牌、13 墩、定約、Pass Out、Duplicate NS 視角計分。程式：[bridge_core](../../packages/bridge_core/)；[CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/bridge-core.yml)。
- **牌局管理**：Board 編號、莊家與身價 16 局循環、固定牌局／新牌局、下一局、完成事件回放。
- **可見資訊隔離**：`PlayerView` 只顯示自己有權看的牌；明手依遊戲階段揭露，AI 請求不得偷看其他手牌。
- **本機儲存**：事件／版本校驗、未完牌 checkpoint、損毀回退與使用者通知；原生加密 SQLite 與瀏覽器加密 checkpoint 有分開驗收。未證明任意裝置斷電或雲端跨實例保證。

## Flutter 玩家可操作功能

## M2-F60｜重用 FlatCardFan 的可及弧形手牌排列

專注牌桌（Local／Gateway 共用）在空間足夠時，使用既有 `playing_cards 0.4.1+11` 的 **FlatCardFan** 定位，再對子牌旋轉與高低位移形成輕微弧形；每張牌至少保留 48px 不被後牌遮住的操作區。13 張牌至少需 644px；不足、字體放大或只剩 0／1 張時保留原排列／水平捲動，不縮觸控目標。只接已授權的 child widgets，不修改 Core、排序、合法性或 submit。沒有新增正式 app 相依。

程式：[BridgeCardStrip](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_card_strip.dart)、[專注桌](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_focus_table.dart)；[四項重用測試](../../apps/bridge_academy_flutter/test/m2_reuse_fan_test.dart) 在 644／768／1280px 檢查弧度、逐張點擊可見區、鍵盤 Tab／Enter、窄屏／大字體退路與 0／1 張。與十項完整專注桌及六項動態測試合計 20/20 scoped PASS；完整驗證依本次新 SHA 為準。狀態 **ENGINEERING_PASS（本機 scoped）／LESSON_DELIVERED**；Chrome CI 待 push 後確認，A3.5／裝置與 Production gate 不變。

另有隔離 [card_game probe](../../experiments/card_game_probe/) 與三項相容性測試：只載入 PlayerView；記錄上游單張 stack limit、同步鎖提案後 drag-end 空值例外、忽略 reduce-motion 三項限制。Probe 的綠燈表示**成功重現已知問題**，不是 card_game 產品驗收通過；正式 app 沒有依賴該實驗。Nickel 已釘選並核對 UI 邊界，未移植其程式／AI／資產，詳見 [研究紀錄](../research/RESEARCH_REPORTS.md#reuse-first-實作核對2026-10-26)。

## M2-F61｜四方位公開牌入場與收墩

專注桌的公開牌依北／東／南／西座位放進四個固定位置。已接受的引牌或跟牌從來源方位滑入；完成的四張公開墩牌由各自位置往 Core 公布的贏家位置收攏並淡出。還原盤面不重播，下一回合操作不等動畫結束。這是以 BBO 畫面作操作參考、以釘選 Nickel Bridge `TrickArea.tsx` 的公開狀態 diff／compass layout 作設計參考，未複製其程式、素材、規則或 AI。

程式：[公開墩](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_table_components.dart)、[入場效果](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_public_card_entrance.dart)、[專注桌收墩](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_focus_table.dart)；[專注桌測試](../../apps/bridge_academy_flutter/test/m2_focus_table_test.dart) 驗證四方位、只對新牌演出、四牌往贏家移動、取消／減少動畫及 320／375／768／1280px 完整 52 張。只讀 PlayerView 的公開牌與完成墩，狀態 **ENGINEERING_PASS（本機 scoped）／LESSON_DELIVERED**；Chrome CI、真人及裝置驗收依實際新 run 判定。

## M2-F62｜明手在北側、自己在南側的同一牌桌

專注牌桌把揭露後的明手牌列放在桌面**上緣**，把自己的手牌放在**下緣**，中央保留四座位與本墩公開牌；兩排都在同一桌面底色內。可容納時兩排居中，窄屏仍可水平捲動，不會把未揭露的明手或防家暗牌放進畫面。這修正使用者指出的舊版錯位：明手與自己原本都擠在桌面下方。參考 BBO 截圖與已釘選 Nickel Bridge 的座位佈局；Nickel 是 React 實作，沒有直接複製其 TSX／CSS 或取代 Flutter／Bridge Core。

程式：[專注牌桌](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_focus_table.dart)；[位置與既有牌局測試](../../apps/bridge_academy_flutter/test/m2_focus_table_test.dart) 保留 320px 窄屏與 1280px 桌面兩端的上下關係、揭露限制及置中驗收；中間寬度由扇形操作的 320／375px 用例覆蓋，不重複跑完整墩流程。本機原完整 Flutter 224/224、Web release PASS；真 Chrome 375px 與桌面畫面已核對，這是工程視覺檢查而非 A3.5。狀態 **ENGINEERING_PASS（本機範圍）／LESSON_DELIVERED**；新 SHA CI、PRACTICED／MASTERED 與 A3.5／裝置驗收仍待確認。

## M2-F57｜專注單屏牌桌

Local／Gateway 活動牌局可開啟專注牌桌，保留原 Session，返回工作區不重開局。四座位、牌號／莊家／身價／定約／墩數、公開叫牌、可見牌與叫牌盒整合在同頁。320／375／768／1280 × 812px 一般字體打牌測試不需垂直捲動；矮視窗與大字體採內容自然延伸的捲動模式。錯誤與重試仍可見，存檔失敗／恢復確認／Gateway pending 會鎖操作。程式：[共用專注牌桌](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_focus_table.dart)、[Local](../../apps/bridge_academy_flutter/lib/src/bridge_app.dart)、[Gateway](../../apps/bridge_academy_flutter/lib/src/gateway_table.dart)。

## M2-F58｜合法牌長按拖曳

公開明手與自己的合法牌可點擊或長按拖到桌面；桌外放下取消。拖曳資料只有 PlayerView 已授權的牌、owner、version，落點重新驗證 canAct／legalCards／turn／paused；同版本有一次提交保護。原有鍵盤／語意按牌仍保留。長按提示改為 manual trigger，避免搶走拖曳手勢；原工作區牌面行為不變。Core 仍做最後裁決，沒有 UI 自判跟牌規則。

## M2-F59｜可中止公開收墩

只對新完成墩的公開四張牌播放 220ms 朝贏家方向淡出，不讀暗牌、不延遲下一回合。IgnorePointer／ExcludeSemantics 避免搶操作及重複語意；減少動畫、離頁、重設或更快的新墩可中止，還原 snapshot 不重播。F57–F59 共用 [九項測試](../../apps/bridge_academy_flutter/test/m2_focus_table_test.dart)，含四寬度逐張 52／13、2×字體、實際拖曳／取消、過期／重複拒絕、公開收墩與頁面往返。[工程教學](ENGINEERING_NOTES.md) 分三節。最終 analyzer、完整 **215/215 Flutter tests**、Web release PASS；Chrome CI 仍待本次 push，不能沿用 F56。狀態 ENGINEERING_PASS（本機範圍）／LESSON_DELIVERED，PRACTICED／MASTERED 未驗收；A3.5／裝置 QA HOLD、Production NO-GO 不變。

## M2-F56｜公開出牌動態回饋與減少動畫

新接受的公開出牌以 180ms 淡入／12px 位移呈現，活動座位邊框平順切換。「我的」提供中英減少動態效果開關，僅適用本次使用；裝置減少動畫偏好永遠優先。還原 snapshot 靜態顯示、換墩即移除舊牌、設定切換中止現有效果，動畫不提交動作也不鎖住下一回合。Local／Gateway 共用 `BridgeCurrentTrick`；只接收 `PlayerView`，不新增套件或存檔格式。

程式：[公開牌動畫](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_public_card_entrance.dart)、[共用牌桌](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_table_components.dart)、[設定](../../apps/bridge_academy_flutter/lib/src/bridge_app.dart)；[測試](../../apps/bridge_academy_flutter/test/m2_table_motion_test.dart)、[教學](ENGINEERING_NOTES.md#m2-f56公開出牌動態回饋與減少動畫)。本機 `flutter analyze --no-pub`、**206/206 Flutter tests**、Web release PASS；[本次 030276b CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40300087862) 已確認 206/206＋Web Release＋真 Chrome Demo 完整牌局／減少動畫切換及加密 checkpoint PASS。狀態 **ENGINEERING_PASS（上述範圍）／LESSON_DELIVERED**；未聲稱 PRACTICED／MASTERED。全桌單屏、選牌／拖曳與收墩動畫仍待實作，A3.5／裝置 QA、Production NO-GO 不變。

| 領域 | 已實現 |
| --- | --- |
| 打牌 | 四座位牌桌、叫牌盒、點牌操作、本機 Demo 或明確選取的 Gateway Session、叫牌時顯示自己的牌 |
| 桌面／手機呈現 | 打牌／學院／本機複盤／我的導覽、保留 active session、練習入口、重開未完牌確認、桌面與窄屏水平手牌列 |
| 無障礙與雙語 | 中英介面、語義標籤、按牌大小和鍵盤操作的 scoped 測試 |
| 練習 | 四局練習、Just Declare（四座位）、叫牌練習、未排名的固定每日練習 |
| 完局複盤 | 完局清單、搜尋／清理、統計、Replay、PBN 匯入、叫牌與出牌匯出 |
| 教學 | 初階與進階學院、教學複盤、學習進度、個人化練習推薦、終局 DDS 分析 |
| 牌面 | `playing_cards 0.4.1+11` 僅作可見牌的呈現 adapter，不接管發牌與合法判定 |

代表性測試：[Flutter／Chrome 198 tests](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40255094253)、[窄屏與 200 tests](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40256171652)。**並非 Android／iOS 裝置驗收或正式產品 GO**。

## AI／Gateway／叫牌制度

| 功能 | 已做到 | 狀態 |
| --- | --- | --- |
| 真 BEN 橋牌 AI | 固定版本 `/bid`／`/lead`／`/play`、固定真牌局完成 52 張／13 墩 | **SCOPED VERIFIED**，尚未公開部署 |
| 伺服器牌局 | localhost Gateway、Server-owned Game／座位權限、Bearer、版本／動作 ID、限額與本機受控加密恢復；Flutter 可選 Gateway | 工程原型，非分散式正式營運 |
| 2/1 與 SAYC | NS／EW 各自選制度、不可變 `GameSystems`／fingerprint，真 BEN Adapter／Gateway／Flutter 導通；固定兩局交叉制度完成 | **工程已實現**，[真 BEN CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40087851963)，不是制度專家認證 |
| Precision | 已選 BBA Meckwell V1，原生 EPBot sidecar 能研究性出價、完成研究級混合牌局；BBA 約定推論供合法牌啟發式排序 | **RESEARCH ONLY**，非正式競賽 AI |
| 自訂約定卡 | 2/1／SAYC 受限草稿、不可變版本、差異與備份、專家審查待辦、引擎支援守門 | **草稿可編輯，修改後 AI 不可玩**（`ENGINE_UNVERIFIED`） |
| 叫牌教練 | 公開叫牌檢視、NS/EW 制度來源、雙語本機草稿對照與 `UNKNOWN` 標示、完局 Gateway 公開歷程 | **教學與資訊功能**，未做真 AI 最佳叫品判定 |

相關研究：[BEN](../research/RESEARCH_REPORTS.md#ben-2-1-與-sayc-兩制度) · [Precision](../research/RESEARCH_REPORTS.md#precision-club-研究) · [M4/M5](../research/RESEARCH_REPORTS.md#自訂約定與公開叫牌教練)。

## 尚未完成，絕不冒稱

正式公開 TLS／身分、正版 AI 權重／原生元件發行合規、真 2 vCPU/4GB 主機壓測、長期儲存與跨設備續局、專家級 100+ Golden、完整玩家 UX／動畫、正式競賽排名與多人、Android/iOS 實機／模擬器驗收。A3.5 及裝置 QA 仍在使用者 **OWNER HOLD**。完整的發行條件見 [後續規劃](../planning/ROADMAP.md#正式上線驗收門檻)。

技術資料流見 [架構](FEATURES.md#已實作架構與資料流)，不可變橋牌法則見 [規則](FEATURES.md#橋牌核心正式不變條件)。


## 已實作架構與資料流


更新：2026-10-26。本文件只記目前程式中存在的組件與邊界。橋牌權威規則另見 [下方橋牌核心正式不變條件](#橋牌核心正式不變條件)。

```text
Flutter (BridgeAcademyApp)
 ├─ local BridgeSession ─ SinglePlayerCoordinator ─┐
 ├─ opt-in GatewayGameSession → server-owned Game ─┼─→ Bridge Core
 │                              ├─ BEN AI adapter ─┤    叫牌／出牌是否合法、
 │                              └─ Precision 研究 ─┘    墩數與計分唯一裁判
 ├─ local encrypted checkpoint / completed history
 ├─ learning, DDS completed-game review, public auction coach
 └─ filtered PlayerView → BridgeTable / visible playing_cards renderer
```

## 主要模組

| 來源 | 職責 | 不可跨越的邊界 |
| --- | --- | --- |
| [bridge_core](../../packages/bridge_core/) | Auction、play、contract、duplicate scoring、replay | AI／UI 只能提議 Action，Core 才能裁決 |
| [bridge_conventions](../../packages/bridge_conventions/) | 南北／東西 GameSystems、revision/fingerprint、草稿與公開叫牌 | 使用者草稿 `ENGINE_UNVERIFIED` 絕不改真 AI |
| [bridge_ben_adapter](../../packages/bridge_ben_adapter/) | BEN 21GF／SAYC 真模型每回合請求 | 只傳合法座位可見資料，不能默默 fallback |
| [bridge_precision_adapter](../../packages/bridge_precision_adapter/) | BBA/EPBot Meckwell 研究 | 不是 BEN neural Precision reader，正式版仍關閉 |
| [bridge_dds_adapter](../../packages/bridge_dds_adapter/) | 終局 DDS 分析 | 真牌局進行中不得泄漏雙明手牌 |
| [bridge_gateway](../../services/bridge_gateway/) | 本機 server-owned Game／Bearer／版本、重試與復原 | 非公開託管與跨節點一致性 |
| [bridge_academy_flutter](../../apps/bridge_academy_flutter/) | 桌面 UI、練習、歷史與可見手牌 | Widget 不拿私有 Deal、不判合法 |
| [scripts 與 CI](../../scripts/) | 正版固定測試、負載研究與 safe preflight | CI runner success ≠ Production GO |

## 資料流與安全

1. Core 以 `PlayerView` 限定每座位所見牌；明手只在法則允許時出現。原生 DDS、BEN 與 Flutter 不得繞過視角權限。
2. 玩家點叫牌／牌張 → 送出有版本的 Action → Core／Gateway 驗證 → 更新事件與投影。UI 切換、捲動、動畫不應改權威 GameState。
3. Gateway 會鎖定每局 NS/EW profile（21GF／SAYC）；BEN request 的 `ourSystem`／`theirSystem` 必須隨座位正確轉換。Unknown system fail closed。
4. Gateway 研究版 Precision 由獨立 BBA/EPBot sidecar 叫牌；其研究出牌提案只可從 `legalCards` 選取，不能當正式強牌力證明。
5. PBN 匯入必須驗證；本機 checkpoint 必須經 schema、版本、完整性／rollback 核對。未實作跨節點原子交易、正式 TLS 身分與雲端 history。
6. `playing_cards 0.4.1+11` 是 render-only adapter；窄屏橫向捲動保持手牌順序、授權與可點擊大小，不能把未曝光牌丟入 Widget。

詳細 release blocker 見 [產品規劃](../planning/ROADMAP.md) 和 [發行門檻](../planning/ROADMAP.md)。

## 橋牌核心正式不變條件


Intended game: four-player contract bridge, initially Duplicate scoring. Consult current WBF Laws of Duplicate Bridge before claiming sanctioned-tournament compliance; this document is an implementation checklist, not a replacement for the Laws.

## Auction
- Each seat has 13 unique cards; dealer acts first, then clockwise N→E→S→W→N (with correct seat ordering).
- Legal contract strain ranking: clubs < diamonds < hearts < spades < notrump; higher contract must increase level or, at same level, strain.
- Pass always permitted before termination. Double permitted only against opponents' currently highest undoubled contract while auction live; Redouble only by side whose contract was doubled.
- If no contract has been bid, the auction ends after **four actual consecutive passes**. If a contract has been bid, auction ends after **three consecutive passes** following the last bid/double/redouble; those calls reset the pass count.
- Final contract is highest legal bid plus X/XX status; declarer is first player on the winning partnership who named the final strain; dummy = partner of declarer; opening lead = declarer's left-hand opponent.
- A raw AI "PASS OUT" outcome with only three displayed PASS calls is not a complete auction event history. Treat contract result as provisionally valid with a warning; do not invent missing decision.

## Play
- Opening leader leads first. Dummy is exposed after opening lead per rules.
- Each trick contains four turns following winner-led clockwise order.
- Following the lead suit is mandatory if a player holds that suit, otherwise may play any card.
- Winner: highest trump played; if none, highest of led suit. All cards played exactly once; 13 complete tricks must equal 52 played cards.
- Only controlling legal player/actor can choose a dummy card as allowed; log physical hand owner separately from selecting actor.

## Duplicate scoring, signed NS perspective
- Contract target = level + 6; made/down logic uses declarer's tricks.
- Undoubled contract trick values: minor 20, major 30, NT 40 first then 30. Doubled x2, redoubled x4.
- Overtricks undoubled per strain trick rate; doubled overtrick 100 nonvul / 200 vul; redoubled twice doubled bonus.
- Partscore bonus 50 or game bonus 300 nonvul / 500 vul, based on contract trick score ≥100; insult 50 X /100 XX; small slam 500/750; grand slam 1000/1500 nonvul/vul.
- Undertricks undoubled 50 nonvul /100 vul each. Doubled nonvul: first 100, second/third 200 each, fourth+ 300 each. Doubled vul: first 200, subsequent 300 each. Redoubled penalties doubled.
- PASS OUT score 0 with no play.
- Explicit test fixtures for E/W declarer scored with reversed NS sign and 3NT one down nonvul = NS +50.

## Replay and edge cases
- Immutable state; reject invalid actions without mutation or appending a valid-action event.
- Regression fixtures: 4-Pass, 3-Pass incomplete transcript warning, contract-after-3-Pass, X/XX, all 5 strains, vulnerability, trick follow suit, void, trump, all-seats and score symmetry.
- Claim/concession and tournament irregularities are OUT OF SCOPE for M1 until separately specified.



## 維護要求

新增產品功能時，同一次提交必須更新本文件與 [工程導讀](ENGINEERING_NOTES.md)，附真正可重現的測試與 CI 證據。舊驗收細節並未遺失，可用本次精簡前的 Git 歷史還原；**不能把曾經通過的特定環境 CI 當作最新正式版全部通過**。


## M2-F63｜可讀墩牌與連續的收墩路徑

專注牌桌改為深綠桌布，公開墩牌依可用寬高放大（320px 工程 fixture 至少 52px，寬版最大 84px）；[BridgeTrickGeometry](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_trick_geometry.dart) 同時供目前墩牌、座位入場與收墩使用。完成墩先短暫保留，再集中並飛向 Core 公布的贏家座位。上一墩資訊預留高度，第一墩完成時不再讓墩牌跳位；動畫不鎖下一次合法動作，減少動畫仍即時完成。

[專注桌／幾何與動態測試](../../apps/bridge_academy_flutter/test/m2_focus_table_test.dart) 在 320／1280px 驗證牌面尺寸、收墩首幀與原墩牌重合、飛向贏家、結束移除；既有 52 張／13 墩、取消、重複提交與大字體回歸保留。Flutter analyzer 0 issue、精簡前全測試 231/231 PASS、Web release PASS；精簡後專注桌 15/15 PASS。最新 SHA CI 尚未執行。狀態 **ENGINEERING_PASS（本機工程範圍）／LESSON_DELIVERED**，真人／裝置 QA 與正式部署仍未放行。

## M2-F64｜手機完整扇形手牌與選牌確認

手機專注牌桌預設把全部 13 張牌放進同一個扇形，明手與自己的手牌維持上、下兩端。重用 `playing_cards` 的 FlatCardFan 和牌面 renderer，增加重疊時可讀的左上角牌點；選中的合法牌會抬起並移到最上層。窄到每張可見區不足 48px 時，第一次點擊只選牌，再點同牌或「確認出牌」才提交；長按拖曳仍走既有授權檢查。標題列可切到寬牌列，大字體自動保留捲動退路。新版本、暫停及切換排列會清掉選牌，避免過期提交。

程式：[BridgeCardStrip](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_card_strip.dart)、[牌面](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_card_face.dart)、[專注桌](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_focus_table.dart)、[雙語文案](../../apps/bridge_academy_flutter/lib/src/app_copy.dart)。[測試](../../apps/bridge_academy_flutter/test/m2_focus_table_test.dart) 驗證中英文 320／375px 的全部牌點可見、初點不提交、選牌抬起、確認只提交一次、版本與暫停清除選取、寬牌列切換；全 Flutter 231/231 PASS，Chrome 工程目視已核對。這是移植 Nickel pinned HandFan 的選取／第二次點牌概念到 Flutter，沒有匯入其 React runtime、AI 或暗牌。狀態 **ENGINEERING_PASS（工程範圍）／LESSON_DELIVERED**，PRACTICED／MASTERED 需使用者真實練習。

## M2-F65｜玩家視角一致的公開墩牌與動畫

專注桌不再把方位固定為北上南下。無論玩家選北／東／南／西，自己的中央座位在下方、搭檔在上方；實際座位名稱、actor、handOwner 和 Core 贏家不變。座位標籤、公開墩牌、入場與收墩共用 [BridgeTrickGeometry](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_trick_geometry.dart) 的視角轉換。已揭露明手仍使用上方獨立手牌面板並標實際座位；玩家當防家時，該面板不代表中央上方的搭檔座位。切換 PlayerView.viewer 會清除舊選牌與動畫，不沿用舊視角的演出。

[專注桌測試](../../apps/bridge_academy_flutter/test/m2_focus_table_test.dart) 新增一個四座位行為案例，核對真實座位與位置、公開卡片權限、收墩首幀及贏家方向、切換視角取消；原選牌案例補同版本切換 viewer 的清除檢查。Windows／Flutter 3.47.8，最終 scoped **16/16 PASS**、既有共享 motion **6/6 PASS**、analyzer **0 issue**。SHA `aced15754ab108d79903004a6deb1d15cc0a49f0` 的 [Flutter/Web/Chrome CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40493585512) 與 [learning gate](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40493585440) **success**；[真BEN](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40493585616) 最後查詢仍in_progress。未另重跑完整本機 suite／Web build。狀態 **ENGINEERING_PASS（上述範圍）／LESSON_DELIVERED**；裝置／真人 QA HOLD 與 release NO-GO 保留。


## M2-F66｜成熟叫牌矩陣、合法停用與確認送出

一般Local桌、Gateway桌和專注桌已共用新的 [BridgeBiddingBox](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_bidding_box.dart)：直接選35個階數／花色叫品與Pass/X/XX，所有叫品先選取、再獨立確認；明確標示選取、等待、暫停、送出中，防止同version重複送出，view/version/turn改變清除過期選取。依最低合法階顯示最多4階資料、展開更高階；短視窗在矩陣內捲動，大字體保留橫捲與至少48px目標。這已取代舊階數／花色Dropdown，不保留假下拉控制給測試。

[Core BridgeGame.legalCalls](../../packages/bridge_core/lib/src/game.dart)只需要公開phase/turn/actor/auction，與reducer共用相同合法驗證；UI依Core集合停用非法叫品。沒有改PlayerView JSON／Gateway schema或帶入完整暗牌。參照Nickel pinned BidBox互動契約，以Flutter重寫，來源詳見RESEARCH_REPORTS。Core58/58、完整Flutter227/227（最後窄對話框修復前）、最後叫牌／toolbar scoped8/8、兩套analyzer無問題；Web release已通過，最後權限補強後build結果與新SHA CI以CURRENT_HANDOFF為準。ENGINEERING_PASS限已執行範圍／LESSON_DELIVERED；裝置與真人QA仍HOLD。

## M2-F67｜四欄叫牌表與公開歷史檢視

新增共享 [BridgeAuctionGrid](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_auction_grid.dart)：N/E/S/W固定欄頭、dealer首列前補空格、本人★、活動欄與待叫?、最後叫品高亮、內部捲到最新列；用於一般桌／專注桌／歷史對話框。叫品可點開查看公開座位與叫品；尚無可信制度解釋時明示未提供驗證說明，不冒用上游SAYC語義。一般字體於375px歷史對話框完整呈現4欄，大字體保留橫捲。

來源是Nickel pinned AuctionGrid的排列／捲動／inspect契約，未複製TSX/CSS/資產。既有UI及真BEN/Chrome流程改為實際選叫品+確認。新增測試集中於非北dealer、跨列、長叫牌自動捲動、未知說明、窄對話框可見範圍；不新增每尺寸整副牌重播。實際Web初步驗證桌面與375px選取／確認及歷史；最終fresh-origin成品及CI證據見CURRENT_HANDOFF。ENGINEERING_PASS限工程範圍／LESSON_DELIVERED；不是已驗收的制度Coach或Production放行。
