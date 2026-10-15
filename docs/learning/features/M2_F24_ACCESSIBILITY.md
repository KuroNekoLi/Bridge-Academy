# M2-F24｜A3.4：卡牌無障礙語意與放大文字

- Feature ID：M2-F24
- Milestone：A3.4 Bridge Table UI V2
- 類型：Flutter UI／Accessibility
- 工程狀態：ENGINEERING_VERIFIED（限 Flutter/Web/真 BEN Chrome；裝置驗收暫停）
- 學習狀態：DELIVERED（非 PRACTICED／MASTERED）
- 原始碼：`apps/bridge_academy_flutter/lib/src/widgets/bridge_table_components.dart`、`lib/src/app_copy.dart`、`bridge_bidding_box.dart`、`bridge_table_toolbar.dart`、`bridge_replay_panel.dart`
- 驗收與測試：`apps/bridge_academy_flutter/test/a3_accessibility_test.dart`（[Flutter CI #38819474371](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38819474371)：80/80 PASS）

## 功能目的與實際情境

玩家使用螢幕閱讀器時，「♠A」應提供「黑桃 A」的語意；正在存檔時，畫面不應仍將按鈕讀作可執行。遊戲按鈕在系統文字放大後也不能出現無法操作的小點擊區域或橫向溢出。

## 主要程式碼導讀

`BridgePlayingCardButton` 由 `PlayerView` 的合法性與 `session.actionsPaused` 控制。卡牌並不直接擁有 Domain 規則：

```dart
Semantics(
  label: copy.accessibleCard(card.code, playable: legal && !busy),
  button: true,
  enabled: legal && !busy,
  child: Tooltip(
    message: copy.formatCard(card.code, legal: legal && !busy),
    excludeFromSemantics: true,
    child: OutlinedButton(
      onPressed: legal && !busy ? onTap : null,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
      ),
      // Visual card content, not the source of legality.
    ),
  ),
)
```

`AppCopy.cardName` 將已公開的 PBN 牌代碼轉成繁體中文／英文完整花色與牌面名稱。座位 `seatSummary` 只組合 PlayerView 允許展示的剩餘張數、輪到誰與 Dummy 角色，不會取得敵家暗牌。

## 為什麼這樣設計

Flutter 官方建議最小觸控目標為 48×48 logical pixels。這相當於 Jetpack Compose 中結合 `Modifier.semantics`、`minimumInteractiveComponentSize`、`enabled` 與 `onClick`，但不要把「有語意標籤」誤認為已強制阻止非法動作。

比較替代方案：僅將卡牌文字放大、卻保留 42×40 的點擊區域，對手指操作幫助有限；僅靠綠色框線標示目前輪到誰，對色覺差異使用者也不友善，因此加上可見文字提示。

## 驗證與實際證據

```bash
cd apps/bridge_academy_flutter
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build web --no-pub --release
```

新增單元／Widget 測試驗證：雙語完整牌張語意、禁用卡牌不能按、48×48 最小操作區域、320／375／768px 在 1.6×／2.0× 字級下的公開牌桌、Dummy 與語系切換。實際驗證（程式提交 `ea7ca9c`）：[Flutter CI #38819474371](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38819474371) **analyze 無問題、80/80 Flutter 測試 PASS、Web Release Build PASS、Chrome Demo PASS**；[真 BEN Chrome #38819474505](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38819474505) **PASS**，包含完整牌局與莊家明手控制；[Learning Gate #38819474409](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38819474409) **PASS**。這些證據不表示 Android/iOS 實機無障礙已驗收。

官方參考：[Flutter Accessibility](https://docs.flutter.dev/ui/accessibility)、[Accessibility testing](https://docs.flutter.dev/ui/accessibility/accessibility-testing)。

Android 模擬器、Android／iOS 實體裝置上的 TalkBack、VoiceOver、實際觸控及對比度檢查仍由使用者暫停；Flutter Widget 測試不是其替代品。

## 練習與自我檢驗

**思考題（1 題）：** 已經顯示「可出牌：黑桃 A」的螢幕閱讀器標籤，為什麼仍需在 Session Busy 時停用 `onPressed`？

**5–15 分鐘小練習：** 在 `a3_accessibility_test.dart` 補上 `legal: false, busy: false` 的 Widget 案例，驗證仍有正確牌名，卻不會執行 `onTap`。

**完成標準：** 可以區分顯示語意、Flutter 控制項啟用狀態與 Bridge Core 領域授權。

## 下一步

A3.5 整合與 UX 驗收，另依使用者核准進行真正的 TalkBack／VoiceOver 與裝置測試。
