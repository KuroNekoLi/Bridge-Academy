# M2-F03｜BEN Adapter：只交付 AI 有權看見的牌

- Feature ID：M2-F03
- Milestone：M2
- 工程狀態：IMPLEMENTED（驗收以 GitHub CI 為準）
- 學習狀態：DELIVERED（未假設已掌握）
- 原始碼：packages/bridge_ben_adapter/lib/src/ben_bot_policy.dart、ben_transport.dart
- 測試：packages/bridge_ben_adapter/test/
- 實際證據：docs/m2/M2_BEN_ADAPTER_REPORT.md（初始提交時 NOT RUN）

## 功能目的與實際情境

橋牌有一位玩家和三位 BEN AI，輪到 East 叫牌，AI 只需要 East 本家的 13 張牌、Dealer、局況及公開叫牌；首攻後的 /play 還需要公開 Dummy 與之前打出的牌。沒有理由傳入四家完整秘密牌局。

BEN 是 stateless REST API；M2-F03 把安全的 PlayerView 轉換成 /bid、/lead、/play 的請求，BEN 只提供 GameAction 提案，Bridge Core 才是真正的遊戲規則權威。

## 主要程式碼導讀

~~~dart
final query = <String, String>{
  'hand': BenProtocol.originalHand(view, view.viewer),
  'seat': view.viewer.letter,
  'dealer': view.dealer.letter,
  'vul': BenProtocol.vulnerability(view.vulnerability),
  'ctx': BenProtocol.auction(view.auction),
};
~~~

choose 的輸入是 PlayerView，不是 GameState。originalHand 利用本家剩餘牌加上本家已公開出過的牌，重建原本 13 張。Dummy 已公開時亦可重建明手原來 13 張；其他防家的秘密手牌從來不能取用。

BenHttpTransport 管理 HTTP、timeout 和 JSON 的錯誤處理；BenBotPolicy 管理牌張及叫牌格式；SinglePlayerCoordinator 與 BridgeGame.apply 驗證 AI 提案合法性。對照 Android/Kotlin，就像 Repository 接資料、Domain UseCase 掌握規則，但 AI 的 JSON 不是可信任的領域事件。

## 為什麼這樣設計

- 替代方案：直接呼叫 /autoplay 並傳整副牌。適合全 AI POC，不適合真人與 AI 逐回合互動，也不符合最低權限原則。
- 隱私：GET query 會含機器人自己的手牌；正式部署必須使用本地可信網路或 HTTPS 代理，避免以 URL log 泄漏。
- 錯誤防護：HTTP 200 不等於合法動作，若 BEN 回非法牌，Adapter/Bridge Core 必須拒絕。
- 官方兩段文件對莊家操作明手的 seat/hand 定義不完全一致，因此 Dummy 回合仍需要真正 BEN 的整合驗證，不能把 Mock 測試冒充為真實模型測試。

## 驗證與實際證據

~~~bash
cd packages/bridge_ben_adapter
dart pub get
dart analyze --fatal-infos
dart test --reporter expanded
~~~

測試採 MockClient、RecordingTransport，包含參數編碼、首攻與明手、歷史牌重建、非法提案、timeout、非 JSON 與失敗 HTTP。這些是契約測試，真 BEN 實機測試尚待執行；結果與限制見 M2_BEN_ADAPTER_REPORT.md。

## 練習與自我檢驗

**思考題：** East 已打過 ♦2，手上只剩 12 張，為什麼能透過公開出牌歷史補上 ♦2 還原 13 張，而不必取得其他三家的全部秘密手牌？

**小練習（約 10 分鐘）：** 加一個 Both 局況 + 1NT-P-P-P 的測試，確認 vul=Both 與 ctx=1N-P-P-P；再模擬 AI 回傳不合法的牌，檢查它被拒絕。

**成功標準：** 能指出 BenProtocol 與 BridgeGame 的責任不同，及 PlayerView 為何是資訊安全的第一道保護。

## 下一步

在真正 BEN 服務上驗證 Dummy 出牌與多墩牌局，再整合 Flutter UI。

