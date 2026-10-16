# M2-F40｜Just Declare：從指定定約直接練莊家

- Feature ID：M2-F40
- Milestone：B2.1
- 類型：Bridge Core + Flutter Gameplay + Session Persistence
- 工程狀態：IMPLEMENTED，CI PENDING
- 學習狀態：DELIVERED（非 PRACTICED 或 MASTERED）
- 原始碼：packages/bridge_core/lib/src/game.dart、transcript.dart、single_player_coordinator.dart；apps/bridge_academy_flutter/lib/src/bridge_session.dart、bridge_app.dart
- 驗收與測試：packages/bridge_core/test/just_declare_test.dart；apps/bridge_academy_flutter/test/b2_just_declare_test.dart；docs/product/B2_JUST_DECLARE_ACCEPTANCE.md

## 功能目的與實際情境
玩家現在能在打牌介面選擇 1～7 線的 C/D/H/S/NT 定約，點下 Just Declare 後直接練習莊家打法。東家首攻、南家明手公開，玩家北家操作自己和明手的牌直到 13 墩結束，不需要先模擬叫牌。這是一個有畫面和可操作控制的真玩法。

## 主要程式碼導讀
入口 BridgeSession.startJustDeclare(level, strain) 將 Contract(宣告者北家) 傳入 _beginBoard，再到 SinglePlayerCoordinator 與 GameState.justDeclareStart。Core 的首個遊戲狀態設為 Phase.play、turn = contract.openingLeader、auction = []、events = []。之後所有 CardAction 仍通過原本的 BridgeGame.apply；首攻過後公開 Dummy、跟牌檢查、13 墩與計分未另寫一套程式。

GameTranscript.encode 在一般對局寫 schemaVersion: 1；在教學模式寫 schemaVersion: 2 和 trainingContract。decode 必須驗證教學起點後才逐張套用 Bridge Core 事件，任何錯誤線位、非法定約或不合法出牌都拒絕。CompletedReplay 從相同教學起點回放，因此不可能憑空多出叫牌。

## 為什麼這樣設計
這類似 Kotlin Domain Reducer 的不同合法 initialState，共用相同的 reduce(action)。替代方案是 UI 自動點出 3NT+3Pass，但那是在事件紀錄中偽造從未發生的操作，也會污染複盤與 PBN。另一替代方案是另外寫教學規則引擎，卻會分叉合法跟牌與計分規則。此切片只用明確標示的規則示範 Bot；BEN /play 要求真實 auction，所以不可把隨意捏造的上下文丟給它。

## 驗證與實際證據
可重現：cd packages/bridge_core && dart pub get && dart analyze --fatal-infos && dart test；cd apps/bridge_academy_flutter && flutter pub get && flutter analyze && flutter test && flutter build web --release。
新測試涵蓋起點無 Auction、首攻後公開 Dummy、52 張／13 墩、跨重啟加密 checkpoint、複盤、歷史標記、Flutter zh-TW/en 按鈕和 v2 變造拒絕。撰寫當下 CI 尚未執行，不可宣稱測試成功。這是本機 Demo 規則練習，非真正 BEN 教學 AI 的品質測試。

## 練習與自我檢驗
思考題：為什麼不能只在 Flutter 畫面保存 isJustDeclare=true，卻不在 Canonical Transcript 保存 trainingContract？
5–15 分鐘小練習：將測試中的 trainingContract.level 設為 8，追蹤 GameTranscript.decode 如何在恢復前拒絕。
完成標準：能區分 Domain 初始狀態、可驗證的版本化事件、UI 顯示與加密持久化。

## 下一步
B2.2：先調查 BEN 在沒有叫牌紀錄下的合法進入方式，再加入難度／教材牌型／其他莊家座位。之後才是 B3 ConventionProfile 與叫牌教學。A4.5、A3.5 和裝置測試保持原先限制。