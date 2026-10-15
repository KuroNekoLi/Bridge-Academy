# M2-F11｜牌局歷史與逐步回放：Event Sourcing、Replay 和 PlayerView

- Feature ID：M2-F11
- Milestone：M2
- 類型：Bridge Core 規則重播／Flutter 唯讀 UI
- 工程狀態：IMPLEMENTED（CI 尚待驗證）
- 學習狀態：DELIVERED（尚未實際作答）
- 原始碼：packages/bridge_core/lib/src/single_player_coordinator.dart、apps/bridge_academy_flutter/lib/src/bridge_session.dart、bridge_app.dart
- 測試與驗收：packages/bridge_core/test/completed_replay_test.dart、apps/bridge_academy_flutter/test/completed_replay_test.dart、docs/m2/M2_F11_FINISHED_REPLAY_ACCEPTANCE.md

## 功能目的與實際情境
玩家完成一副橋牌後，希望查看「叫了什麼定約、哪個座位出了哪張牌、為何這墩由誰贏」。M2-F11 新增只在**終局**顯示的歷史回放，支援逐一查看每個真實叫牌與出牌事件。Pass Out 要保留完整四次 PASS，不能只用「四家不叫」一張結算圖片代替。

## 主要程式碼導讀
SinglePlayerCoordinator 在終局時從原本的 Deal、dealer 與 vulnerability 起始，依序交給 BridgeGame.apply 重做每個 GameEvent，而非在 Flutter 上自己重新判定勝負。精簡程式碼導讀：

    if (!_state.isFinished) return null;
    var history = GameState.start(
      _state.deal, _state.dealer, _state.vulnerability,
    );
    frames.add(ReplayFrame(PlayerView.forSeat(history, humanSeat), null));
    for (final event in _state.events) {
      history = BridgeGame.apply(history, event.action);
      if (history.version != event.version) {
        throw const RuleViolation('Replay event version mismatch');
      }
      frames.add(ReplayFrame(
        PlayerView.forSeat(history, humanSeat), event.action,
      ));
    }

接著還要比對 historyFingerprint 與 NS score 才能公開 frames。Flutter 收到的是 ReplayFrame 裡的 PlayerView（顯示自己可見的手牌、公開明手與出牌紀錄），而不是包含四家完整起手牌的 GameTranscript。

## 為什麼這樣設計
- **Event Sourcing（事件溯源）**：保存實際發生過的「事件」，重新套用既有 Reducer 後得到每一步的「狀態」。它不是單純保留畫面截圖。可比喻 Kotlin 的 immutable state reducer + StateFlow，但還多出可審核、可回放的事件鏈。
- **Source of Truth**：Bridge Core 是正式對局和回放的同一裁判。Flutter 不應獨自重新算每墩勝負或 Duplicate 分數。
- **最小權限**：GameTranscript 是全資訊歸檔，內含完整 PBN，遊戲期間傳給前端或一般 BEN 決策器將洩漏暗牌；因此只有結束後的過濾視圖可以回放。這個 MVP 即使終局也不直接展示所有暗牌。
- **替代方案**：儲存每回合的畫面截圖雖容易，卻不能依規則驗證、不能重算狀態，也不適合將來的 PBN 分析。
- **常見錯誤**：只留每一墩的贏家，會遺失該墩四次出牌的時間序與 Actor / Hand Owner 的區別。

## 驗證與實際證據
    cd packages/bridge_core && dart test test/completed_replay_test.dart
    cd ../../apps/bridge_academy_flutter
    flutter test test/completed_replay_test.dart
    flutter analyze

文件建立時為 NOT RUN；通過後需記錄新 Commit 的 GitHub CI、測試數量、回放 52 張／13 墩、Pass Out 四次 PASS 與真 Chrome／Android 的驗收界線。不能拿過往真 BEN 對局成功冒充這次回放 UI 已驗收。

## 練習與自我檢驗
**思考題：** 在第七墩第二張牌出現錯誤時，為什麼只儲存「第七墩誰贏」仍無法重現 BUG？至少要保存哪些原始事件資訊？

**5–15 分鐘小練習：** 比較 completed_replay_test.dart 的 version 0 與 version 1，列出玩家初始手牌、叫牌事件、尚未公開的 Dummy 各應處於哪種狀態。

**完成標準：** 能分辨 Event 與 State Snapshot、重播與重新執行 AI 的差別、PlayerView vs GameTranscript 的權限界線。

## 下一步
未來可以再做跨 App 重啟的歷史儲存和合法 PBN 匯出，但這些都要先確認持久化、終局暗牌揭露、玩家隱私與分享授權。

