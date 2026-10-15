# M2-F11｜牌局歷史與逐步回放：Event Sourcing、Replay 和 PlayerView

- Feature ID：M2-F11
- Milestone：M2
- 類型：Bridge Core 規則重播／Flutter 唯讀 UI
- 工程狀態：ENGINEERING_VERIFIED（Bridge Core 47/47、Flutter 19/19、Web Build、真 Chrome 回放點擊 PASS；Android Emulator 回放觸控 PASS，實機另驗）
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

實測 [Bridge Core #38692682476](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38692682476) 44/44 PASS，完整 Pass Out、52 張／13 墩、回放規則與身份驗證均通過；[Flutter #38692937055](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38692937055) 19/19 PASS、flutter analyze 無問題、Web Build PASS、舊版 Demo Chrome 回歸 PASS。新增的 Chrome 回放 First／Next／Last 已在 [CI #38693616403](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38693616403) 真實執行並 PASS。Android Emulator 回放觸控 [CI #38693616421](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38693616421) **已完成 SUCCESS**：在原生 App 點擊 First → Next → Last，檢查回放狀態並於重開後清空；實體 Android 手機仍尚未驗收。

實際踩到的 Dart/Flutter 問題：onPressed callback 預期回傳 void，直接 return session.newGame() 是回傳 Future<void>，編譯被拒絕；改為在 callback 內呼叫 session.newGame 而不回傳 Future，Flutter 回歸遂成功。專案 Learning Gate 亦要求每次改功能程式，都同步更新這份教材與索引。

### M2-F11.1 補強：不可變快照、X／XX 與破損歸檔

現有 Core 已經能回放；此次不另建一個 Replay Engine，而是擴充 [replay_domain_hardening_test.dart](../../../packages/bridge_core/test/replay_domain_hardening_test.dart)：讓四個 Dealer 與四種局況各跑完整四 Pass Out；用 1♠–X–XX–Pass–Pass–Pass 進入真正 52 張出牌，驗證每張明手牌都是 North 做決定、South 持有。

另一個重點是**驗證外來歷史資料並不是因為長得像 JSON 就可信任**。測試把已經合法的 Transcript 中一筆 version 改成 99、把加倍者 E 改成 W，或把 East 首攻的牌持有人改成 North。重建時應由事件序列／Bridge Core 的規則拒絕，而不是默默顯示錯的牌局。這相當於 Kotlin 透過 immutable State + reducer 驗證歷史 Command，不是直接信任反序列化結果。

`GameTranscript` 仍然含有**四家完整手牌**，只能留在受信任的 Domain 或離線測試；Flutter 畫面拿到的是 `PlayerView`，不能從 `toJson()` 取回 PBN、未公開的暗牌或完整事件歸檔。

**新測試確實執行成功：** [Bridge Core CI #38714671479](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38714671479)，Commit `7a9e331`，`dart analyze --fatal-infos` 無問題、**47/47 PASS**（原 44 筆＋3 個補強案例）。[Learning Gate #38714671483](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38714671483) PASS。四種起叫座位、X／XX 13 墩、三次 Pass 未結束、違法事件拒絕與 Immutable snapshot 均屬這次實測。

## 練習與自我檢驗
**思考題：** 在第七墩第二張牌出現錯誤時，為什麼只儲存「第七墩誰贏」仍無法重現 BUG？至少要保存哪些原始事件資訊？

**5–15 分鐘小練習：** 比較 completed_replay_test.dart 的 version 0 與 version 1，列出玩家初始手牌、叫牌事件、尚未公開的 Dummy 各應處於哪種狀態。

**完成標準：** 能分辨 Event 與 State Snapshot、重播與重新執行 AI 的差別、PlayerView vs GameTranscript 的權限界線。

## 下一步
未來可以再做跨 App 重啟的歷史儲存和合法 PBN 匯出，但這些都要先確認持久化、終局暗牌揭露、玩家隱私與分享授權。
