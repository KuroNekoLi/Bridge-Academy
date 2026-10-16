# B6 — 每日固定四副牌（非排名）

- Branch: `feature/b6-daily-practice`
- Status: SCOPED VERIFIED / Flutter 124 tests + Web + Chrome PASS
- Date: 2026-10-16
- Feature: B6.1（日期與可重現牌局）、B6.2（進度與加密本機紀錄）、B6.3（可操作 Flutter 玩家入口）

## 玩家流程
開啟 Flutter 本機單人牌桌，選擇 N/E/S/W 座位，點「開始每日挑戰」；系統以 **UTC 日期** 固定產生四副原創牌局。每副由 Bridge Core 驗證叫牌、跟牌與計分；結束後點「下一副」，完成四副顯示玩家一方的原始 Duplicate 得分總計。挑戰保留至最多 45 個日期之本機加密紀錄，顯示最近七次 UTC 練習；跨 UTC 換日不會把昨天未完成的挑戰悄悄轉成今天的新挑戰。完成後可確認重設當天進度，以完全相同的四副牌再次練習。

**不是正式比賽**：不存在 MP/IMP、好友比較、反作弊、公平排名或正式 BEN 叫牌保證。僅本機 Demo Bot，沒有雲端每日共同排行榜。

## Domain 與隱私
- `DailyPracticeManifest` challenge ID 格式 `daily_YYYY-MM-DD_v1`；固定 UTF-8 SHA-256 排序及原始牌代碼，**沒有使用 Dart Random(seed)**，避免跨 SDK RNG 變動。
- 一天四副各有不同 index salt 與 Duplicate BoardDefinition（經 Core Law 2 週期決定莊家/局況）；公開原始生成演算法及 golden PBN fixture 僅存在自動化測試/受信任 Domain，**不在活躍 PlayerView/UI 暴露四手牌**。
- `DailyPracticeProgress` 保留日期、revision、座位、依序完成的摘要與分數，使用既有 B1 的 `FourBoardPractice` 驗證遞增版號及 NS/EW 正負號。
- 進行中的 52 張 Deal 只進加密活躍 checkpoint；日誌放獨立 AES-256-GCM Authenticated record namespace，最多 45 日，憑據採既有平台金鑰。Web 僅是 origin-local best effort，無法防止同 origin 腳本與惡意擴充。
- 儲存毀損時**不以空資料覆蓋**；儲存失敗禁止進入下一副並提供重試。不能假設兩個不同加密儲存裝置跨裝置交易具備原子性。
- 今日練習只有完成當下持久化的進度可從日誌延續；若使用者在半副牌中途離開，保留該半副的主 checkpoint。未完成另一日期的活動牌不會被自動丟棄。

## 進度與退出政策
- 同一 UTC 日期的已完成項目不重複加分；四副全完成後只顯示結果，明確確認才會重設當天練習分數。
- 其他模式（B1、B2、B3）不得直接覆蓋仍在進行的四副每日挑戰。
- 換日後既有活躍牌局仍屬原挑戰，玩家必須先完成或等待既有 session 的合法結束；歷史進度顯示日期。
- 日誌是最近 45 次，本版沒有無限歷史保存或任意舊日期挑戰導航，完整牌局仍遵循 A5 歷史 12 筆限制。

## 驗收與測試
```sh
cd apps/bridge_academy_flutter
flutter analyze
flutter test test/b6_daily_practice_test.dart
flutter test
flutter build web --release
```
- Golden deterministic PBN fixture、52 張牌唯一、四家各 13 張、四副 metadata。
- 同日與跨日、Version mismatch、敵對壞 JSON、不合法結果順序、EW 得分方向。
- Pass Out 真實四副牌收束、重啟 checkpoint 恢復、結果重複處理、儲存失敗重試、雙語 Widget。
- Android emulator、Android/iOS 實機測試依先前決議暫停。

**CI VERIFIED**: [Flutter M2 Single Player](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38910655183) for source SHA `24754685`: Flutter analyze No issues found; 124/124 Flutter tests passed; Web Release build and ChromeDriver Demo E2E passed. Not real BEN nor Android/iOS device acceptance.

## 整合與回退
僅在 `feature/b6-daily-practice` 交付，沒有 PR、沒有合併 master。共用接點：`bridge_session.dart`、`bridge_app.dart`、`app_copy.dart`、`session_persistence.dart`、學習 Index 和 B6 專屬 CI branch filter。整合時逐檔評估 B3/B4 同時修改區域，建議採 rebase-free sequential cherry-pick/merge，重新跑 Flutter CI。可 revert 本分支所有 B6 commit；已保存的獨立 daily store 不會被正常一般遊戲讀取。

Known limitations: native macOS/Windows/Linux non-Web Demo composition still uses volatile Memory storage; native Android/iOS and Web use separate AES-GCM daily ledger. Public client-side deterministic dealing is predictable by technically capable players; B6 is a solo practice tool, never a fair-play competition or anti-cheat service.
