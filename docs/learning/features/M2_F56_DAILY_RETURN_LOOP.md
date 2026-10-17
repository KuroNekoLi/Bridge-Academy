# M2-F56｜UX-04 每日回訪：公開狀態投影與存檔保護

- Feature ID：M2-F56
- Milestone：UX-04
- 類型：Domain projection／Flutter presentation
- 工程狀態：SCOPED VERIFIED（Flutter 179/179、Web、Chrome Demo）
- 學習狀態：DELIVERED
- 原始碼：`apps/bridge_academy_flutter/lib/src/experience/daily/daily_return_summary.dart`、`widgets/ux_daily_return_panel.dart`
- 驗收：`test/ux_04_daily_return_test.dart`，[Flutter CI 179/179 PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38990454977)；[Feature Learning Gate PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38990454982)

## 功能目的與實際情境
玩家回訪時想知道今天的四副固定牌局是否完成、能否安全接續。UX-04 把已存在的 B6 本機加密進度與盤面狀態投影為 UI，而不是另造資料庫。畫面永遠顯示 UTC 日期、0–4/4、非排名標示與空狀態。

## 主要程式碼導讀
`DailyReturnSummary.from` 依 `DailyPracticeManifest.forDate(now)`、`DailyPracticeProgress` 與 Session 公開旗標，建立 immutable UI State；完全不取得 `Deal`、原始 PBN 或 C3 未授權學習嘗試。

```dart
if (recoveryNeeded) {
  state = DailyReturnState.recoveryPending;
} else if (errors) {
  state = DailyReturnState.storageProblem;
}
```

`UxDailyReturnPanel` 只依 state 提供開始、接續、下一副、確認重練與已完成後練叫牌 CTA。真正開始／繼續透過 `BridgeSession.startDailyPractice`、`nextDailyBoard`，仍讓 Bridge Core 決定合法行動；「返回牌桌」只是捲動定位，不重發牌。

## 為什麼這樣設計
類似 Android ViewModel 將資料層 truth 映射成 Compose UI State。UTC 是每日牌局 ID 的一部分，台北本地午夜不一定等於 UTC 換日。舊日期未完成、其他未完成牌局或讀寫失敗都不默默覆蓋紀錄。近期只展示最多三個本機已有日期及完成副數，不推測勝率、連勝、MP、IMP 或玩家弱點。

## 整合測試的設計教訓
新增 UX-04 摘要不能與 B1／B6 原有的「已完成副數」Text 完全重複，否則原本的 Widget finder `find.text` 會找到兩個元件，造成錯誤回歸；UX-04 改用「今日挑戰進度」獨立文案，保留 B1／B6 正式文字與既有測試契約。另因 Dart 的 collection if 新 lint，建議在 `Map` 完成建立後才依 `active != null` 明確寫入，保持資料投影一致。

## 驗證與實際證據
```bash
cd apps/bridge_academy_flutter
flutter analyze
flutter test
flutter build web --release
```
程式碼提交時 **NOT RUN**；需等此分支 GitHub Actions 的實際結果，不能以存在的測試檔案取代 PASS。

## 練習與自我檢驗
**思考題：** 玩家台北時間 10 月 18 日 01:00 開啟遊戲，為何每日挑戰可能仍顯示 10 月 17 日 UTC？
**5–15 分鐘練習（可選）：** 增加「昨天完成、今天沒有紀錄」的測試，證明不會顯示假 streak。
**完成標準：** 能解釋 Domain 進度、公開 DTO 和 Widget 如何保護隱私及避免錯誤重發。

## UX-02 與 UX-04 交互整合：單一下一副按鈕
在本分支中，完成一副 B6 每日練習時，UX-02 結果卡已經提供受 Core Session 控制的「下一副」主要操作；若 UX-04 也顯示可點擊的下一副，就會有兩個入口，使用者可能不知道要選哪一個。整合後 `UxDailyReturnPanel.showNextAction` 預設為 `true`（保持單獨元件可重用與歷史測試意圖），但 `BridgeTable` 根據 `!session.finished` 暫時隱藏 UX-04 的重複按鈕，終局由 UX-02 的 `next_daily_board` 負責。測試要檢查只有一個 CTA，並以 bounded `scrollUntilVisible` 存取長列表中尚未掛載的 Widget。這是 UI 單一操作責任（single action owner）的案例，且不修改 B6 每日挑戰儲存模型。
