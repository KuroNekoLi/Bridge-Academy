# M2-F01｜PlayerView：從 DTO 保護玩家的秘密手牌

- Feature ID：M2-F01
- Milestone：M2
- 類型：資料隔離
- 工程狀態：VERIFIED（本輪測試已由 GitHub CI 驗收）
- 學習狀態：DELIVERED（尚未實際作答）
- 實作：packages/bridge_core/lib/src/player_view.dart
- 測試：packages/bridge_core/test/player_view_test.dart
- 測試證據：[Bridge Core CI #38673888504](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38673888504)、[M2 驗收報告](../../m2/M2_FOUNDATION_REPORT.md)

## 功能目的與實際情境

四人橋牌中，每個玩家只能看自己的 13 張牌。叫牌結束、首攻後，明手才公開，所有人都能看到剩下的明手牌。M1 的 GameState 包含四家全部手牌，因此不能直接把 GameState 傳給 Flutter；即使 UI 把牌顯示為背面，原始 JSON 仍可能洩漏秘密。

M2-F01 建立可依 Seat 產生的 PlayerView。輸出的是已過濾的實際資料，而不只是把畫面遮蓋。

## 主要程式碼導讀

入口 PlayerView.forSeat(GameState state, Seat seat)：

~~~dart
final dummy = state.dummyExposed ? state.contract!.dummy : null;
final canAct = state.actorToPlay == seat && !state.isFinished;
// ...
ownCards: ordered(state.hands[seat]!),
dummyCards: dummy == null ? null : ordered(state.hands[dummy]!),
~~~

只有自己座位的牌放進 ownCards。dummyCards 在首攻前是 null，首攻後才有明手資料。其他三家的資料只有 remainingCards 張數、公開叫牌與公開出牌，不含私有卡號。toJson() 列出可輸出的欄位白名單，不能把完整 Deal 或 GameTranscript 放入 JSON。

類比 Kotlin / Android：這像 Domain Model 轉成安全的 UI/Network DTO。但要注意安全檢查必須發生在資料進入網路回應之前，不是只在 Compose 或 Flutter Widget 隱藏元件。

## 為什麼這樣設計

- 替代做法：傳完整 GameState，讓前端遮住其他座位。這只能防止「看見畫面」，不能防止 DevTools、攔截 JSON 或修改客戶端讀到秘密。
- 採用專用 DTO：明確控制可見資料，Bot 也只收到其座位資料。這是 Single-Dummy AI 與真人公平性的重要界線。
- 常見邊界：首攻後明手公開，但其他防家未出的牌仍然是私有資料。PlayerView 的投影層不負責確認 HTTP 請求者是誰，身份授權要由 Coordinator／Server 管理。

## 驗證與實際證據

~~~sh
cd packages/bridge_core
dart pub get
dart test test/player_view_test.dart --reporter expanded
dart analyze
~~~

測試涵蓋：四家各自只見本家 13 張、JSON 中沒有對方私有卡號、首攻前 Dummy 隱藏、首攻後 Dummy 公開、莊家代出 Dummy 才能取得 legalCards、集合不可直接修改。

這不是 BEN 的真實神經網路測試。GitHub Actions 真正執行 Dart 測試及靜態分析，40/40 個測試案例通過（原 M1 30 個 + 新 M2 10 個）。實際證據見上方 CI 連結。

## 練習與自我檢驗

思考題：如果 Flutter 的 Widget 沒顯示 East 的牌，但伺服器 JSON 包含了 East 全部 13 張，這算不算保護秘密？為什麼？

5–15 分鐘小練習：閱讀 player_view_test.dart，加入一個測試，確定在首攻前，North 的 PlayerView 不包含 South 牌；首攻後 North 可以看見 Dummy South。成功標準是用 JSON 卡號而不只看 UI 做驗證。

使用者回答後，才更新 PRACTICED 或 MASTERED；不因為教材產生就假定學會。

## 下一步

M2-F02 將這個視角交給單機 Game Coordinator，控制 Human/Bot 行動與版本。

