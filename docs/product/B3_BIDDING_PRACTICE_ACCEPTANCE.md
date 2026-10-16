# B3.1 — 可操作的叫牌練習

**日期：2026-10-16｜Status: IMPLEMENTED, CI PENDING**

## 玩家交付
- Flutter「開始叫牌練習」：玩家可選 N/E/S/W 座位，和本機教學 Bot 練習四家叫牌。所有行動由 Bridge Core 驗證。
- 拍賣完成（有定約或 Pass Out）後停止；不自動首攻、不打 13 墩、不偽造得分及歷史牌局。
- 顯示本手牌的示範叫品、已知叫品之教學解釋，且可以切換繁體中文／英文。
- 使用既有加密 Snapshot 儲存與恢復，依 Mode 恢復教學 Bot。不向其他座位、Bot 或 UI 洩露完整四手牌。

## 約定與明確限制
BA-NATURAL-NT revision 1 是簡化教學範本：前面只有 Pass 的 1NT 開叫為 15–17 HCP 均型；面對無插叫之搭檔 1NT，2NT 邀請進局為 8–9 HCP，3NT 進局為 10+ HCP；原 1NT 開叫者 17 HCP 接受 2NT 邀請。其他叫品保守回覆 Pass、未知解釋；不表示 Pass 必然是合適的最佳策略。

**沒有外部橋牌專家審核，不是完整 SAYC 或 2/1，也沒有宣稱 BEN 模型遵守上述約定。** 「約定說明」不等於「已驗證 AI 真實牌力」。B3.2 的完整 ConventionProfile、AI 相容性對照、專家審查、教學回饋尚未完成。

## 檢查
- `cd apps/bridge_academy_flutter && flutter test test/b3_bidding_practice_test.dart`
- `cd apps/bridge_academy_flutter && flutter analyze`
- `cd apps/bridge_academy_flutter && flutter test`

**實際提交前：NOT RUN**。執行環境無 Dart/Flutter SDK，後續需以目前提交 SHA 對應的 GitHub CI 具體結果更新驗收狀態。A4.5、A3.5、Android/iOS 裝置驗收仍依使用者決定暫緩。

## 回退
如發現相容性問題，可 revert 這次單一 Git commit；保留舊有 A5/B1/B2 checkpoint 格式與模式，無須清除舊資料。
