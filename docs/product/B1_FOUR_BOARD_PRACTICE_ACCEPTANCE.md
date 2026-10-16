# B1 — 四副牌練習賽（本機可操作產品功能）

**2026-10-16 · Status: SCOPED FLUTTER ENGINEERING VERIFIED — 109/109 tests + Web + Chrome Demo · Scope: Flutter 本機單人 Demo 或已明確設定的開發 BEN 模式**

## 玩家可操作的成果

玩家在本機牌桌按「開始四副牌練習賽」，自選當前玩家座位和對手。系統以連續四個 WBF Board Number 和四副新隨機 Deal 執行**正常**叫牌／出牌／計分（不是假定約、不會修改 Bridge Core 規則）。每完成一副可按「下一副」，畫面即時更新已完成 1/4～4/4、每副定約與個人視角正負分，四副完成顯示明確結算。原本的 A5 加密終局歷史與回放維持可用。

## 行為契約

- B1 第一輪刻意不做雲端場次、公開比賽、IMP／MP 或排名。加總不同牌例的 Signed Duplicate Score 只代表非競賽的練習帳面分數，畫面以 zh-TW/en 標示。
- 每組共四個有序 Board Number，正常使用 BoardDefinition 16 板局況/Dealer cycle。中途禁止普通 New Game、Replay Same Board、普通 Next Board 偷跳板；只有當前已完成，才啟用 B1 Next Practice Board。
- 每副獨立使用現有 canonical `SinglePlayerCoordinator` 驗證四家牌張、四 Pass 與合法 13 墩；只從終局 `PlayerView` 取得 Contract／NS Score。
- `FourBoardPractice` 只保存人類座位及每副終局摘要。完整四手牌仍留在現有加密 checkpoint/歷史儲存，Widget 只取得既有 `PlayerView` 和安全摘要。
- B1 場次資料與現有 encrypted local active checkpoint 同筆儲存，重啟時透過 SavedBoardCodec 還原；每副以歷史 attempt ID 去重，不會因恢復重播而另計結果。
- 每副完成仍進入 A5 歷史；A5 清理／匯入不構成 B1 權威場次來源。若加密 checkpoint 儲存失敗，必須先重試成功才能繼續下一副。
- 使用原本 Board Mode=fresh 強制真正新發牌，不會用同一固定教學牌例重複四次。真 BEN 仍無 Demo 自動回退。

## 程式與驗證

- `apps/bridge_academy_flutter/lib/src/four_board_practice.dart`
- `apps/bridge_academy_flutter/lib/src/bridge_session.dart`
- `apps/bridge_academy_flutter/lib/src/session_persistence.dart`
- `apps/bridge_academy_flutter/lib/src/bridge_app.dart`
- `apps/bridge_academy_flutter/lib/src/app_copy.dart`
- `apps/bridge_academy_flutter/test/b1_four_board_practice_test.dart`

```bash
cd apps/bridge_academy_flutter
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build web --release
```

**Executed evidence:** [B1 source commit 1a52cf1](https://github.com/KuroNekoLi/Bridge-Academy/commit/1a52cf1f2d7c1f93a6a05fb6eb3fad40135ca75f), Flutter lint fix [56162ba](https://github.com/KuroNekoLi/Bridge-Academy/commit/56162ba7d5d727ceca2aadc6b8eb84e73a1e2e92); [Flutter CI #38880212042](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38880212042) **SUCCESS** with `flutter analyze --no-pub` **No issues**, `flutter test --no-pub --reporter expanded` **109/109 passed** (105 prior + four B1), and `flutter build web --release` PASS; headless Chrome Demo secure-checkpoint regression also SUCCESS. The Feature Learning Gate on the **lint-only** commit initially failed because that commit did not change lesson + index; this documentation acceptance commit restores same-commit lesson/index evidence. Real BEN Chrome E2E is a separate regression and **not** evidence of four-board BEN practice.

 Test scenarios include initial start, all four legitimate Pass Out boards, retained result IDs and board order, cross-restart continuation, disabling illegal restart/next actions, local A5 history and visible dual-language UI. This is scoped Flutter/Web engineering, not Android/iOS hardware, deployment, full four-board genuine BEN or product READY.

## Open gaps

B1 practice session is stored in a **single** local active checkpoint; older completed series are not a permanent multi-session tournament archive. No server-authoritative multi-account competition, peer comparison or cross-device sync. The currently running game must have ended before a new series starts. Four-player online tournament and MP/IMP require Phase D/E rules and comparative field. A3.5/device QA remains expressly held; A4.5 public service deployment not approved.
