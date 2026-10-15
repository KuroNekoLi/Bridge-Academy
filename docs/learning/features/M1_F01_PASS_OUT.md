# M1-F01｜四家 Pass Out：從橋牌規則理解狀態機

- Feature ID：M1-F01
- Milestone：M1 — Bridge Core
- 類型：橋牌規則
- 工程狀態：VERIFIED（GitHub CI 已執行）
- 學習狀態：DELIVERED（使用者尚未作答）
- 實作：[BridgeGame._applyCall](../../../packages/bridge_core/lib/src/game.dart)
- 測試：[auction_test.dart](../../../packages/bridge_core/test/auction_test.dart)；[M1 CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38672191891)

## 功能目的與實際情境
橋牌由 Dealer 開始，依序四家叫牌。如果沒有人叫出定約，四人每人各 Pass 一次，才是 **Pass Out**；不進入出牌，Duplicate 分數為 0。只有三人 Pass 時，第四個人仍有機會叫牌。

但「已經有人叫出定約、接著連續三次 Pass」又是**另一個**合法的叫牌結束條件。

## 主要程式碼導讀
入口在 packages/bridge_core/lib/src/game.dart 的 BridgeGame._applyCall，關鍵判斷：

~~~dart
final auction = [...state.auction, AuctionEntry(action.actor, action.call)];
final lastThreePass = auction.length >= 3 &&
    auction.skip(auction.length - 3).every((e) => e.call is Pass);
final isPassOut = lastBid == null && action.call is Pass &&
    auction.length == 4;
final isContractComplete = (lastBid != null || action.call is Bid) &&
    lastThreePass;
~~~

- auction 是**新建的清單**，保留舊的 state.auction；只有合法 Call 會加入事件紀錄。
- lastBid == null 表示叫牌史內沒有任何定約叫品。
- isPassOut 要求無定約而且四次 Pass，不能替第四家做決定。
- 若有人已叫 Bid，最後三次連續 Pass 則可以結束叫牌，進入出牌階段。

Pass Out 後 GameState 進入 Phase.finished，turn == null，nsScore == 0。

**Kotlin 類比**：GameState 像 immutable UI state；CallAction 是 Action；BridgeGame.apply 類似 reducer/use case。但這裡的規則核心是權威，不只是改變畫面。

## 為什麼這樣設計
**替代方案 A：三次 Pass 都算結束。** 對已有定約的叫牌通常成立；但尚無 Bid 時，第四位可能仍要開叫，直接結束會錯。

**替代方案 B：BEN API 回 PASS，就自行補第四個 Pass。** 這會偽造叫牌歷史。先前 BEN Work POC-002 中兩副自然 Pass Out 回應只有三次 Pass：可以接受 API 的終局判定，卻不能據此聲稱第四次實際事件存在。Outcome 與可回放 Transcript 必須分開評估。

**陷阱**：Core 持有四家完整手牌；不可以直接把 GameState 當作 Flutter PlayerView 傳給玩家，未來需要另建授權投影。

## 驗證與實際證據
從 Repository 根目錄可自行執行以下重現命令：

~~~bash
cd packages/bridge_core
dart pub get
dart test test/auction_test.dart --reporter expanded
~~~

測試檔案會在四種 Dealer（North、East、South、West）下測：
- 前三次 Pass：game.isFinished == false、事件數為 3。
- 第四次 Pass：game.isPassOut == true、nsScore == 0、事件數為 4。
- 終局後再叫牌：RuleViolation，沒有新事件。

**已實際執行**：[M1 GitHub CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38672191891)，Dart 3.13.5，dart analyze 與整套 dart test 成功，30/30 個測試案例 PASS（其中包含四家發牌的 Pass Out 測試）。上方單檔命令是重現示範，不宣稱已在本對話單獨執行。

這是純規則測試，**不是** BEN 真實 AI 強度評測。

## 練習與自我檢驗
**思考題：** North、East、South 都 Pass，輪到 West 時，可以叫 1♠ 嗎？為什麼？如果最初 North 已叫 1NT，後面 East、South、West 連續 Pass，結果又有什麼不同？

**5–15 分鐘練習：** 從 Dealer = West 開始，寫測試驗證前三家依序 W、N、E Pass 後，仍輪到 South；South 再 Pass 才進入 Phase.finished。測試最好同時確認舊 GameState 不被修改。

**完成標準：** 能用「是否已存在 Bid」區分四次與三次 Pass 的終止規則，並指出 _applyCall 中的實際判斷式；學習狀態須待你回答後才更新。

## 下一步
可以接著學「莊家是誰」：為什麼最後叫出 2♥ 的 South 不一定是 Declarer？這牽涉同組搭檔最早叫過該花色的位置。
