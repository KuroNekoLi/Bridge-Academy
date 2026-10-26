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

`BBA/EPBot` 的 `Meckwell.bbsa` 被釘選為 `BA-PRECISION-MECKWELL/r1`。1NT 範圍 13–15 HCP，不能偷換外部 Meckwell Lite 13–16。研究可完成整局合法牌，但沒有受測的競賽級 Precision neural cardplayer。[研究](../research/PRECISION.md)。練習：為什麼 1000 次原生開叫 PASS 不代表 1000 局比賽通過？

## M4-F01～M5-F03｜本機約定草稿與來源可追的教練

原有規格允許編輯本機約定規則、sha256-linked revision、差異、匯入、審查包，但**草稿不是可執行 AI**。`PublicAuctionCoach` 只解釋公開資訊：無已驗證規則時返回 `UNKNOWN`，草稿標 `USER_DRAFT`。程式：[Conventions](../../packages/bridge_conventions/)；[研究](../research/CUSTOM_AND_COACH.md)。練習：何時允許草稿進入 Gateway playable system whitelist？

## M2-F53～M2-F55｜工作區與可見牌

Flutter 將打牌、學院、複盤、我的分開；現有遊戲跨頁保留。牌面套件只顯示 `PlayerView` 允許的牌，窄屏水平捲動不改 GameState。程式：[Flutter](../../apps/bridge_academy_flutter/)；[198/198](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40255094253)、[200/200](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40256171652)。練習：為什麼排序玩家手牌時不能直接 mutate Core 的清單？