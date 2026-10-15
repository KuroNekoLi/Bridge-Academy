# M2-F23｜A3.3：Responsive 橋牌桌、公開資訊工具列與只讀回放

- Feature ID：M2-F23
- Milestone：A3.3
- 類型：Flutter UI／狀態隔離
- 工程狀態：ENGINEERING_VERIFIED（限 Flutter/Web 與真 BEN Chrome；裝置／實機 QA 仍暫停）
- 學習狀態：DELIVERED（非 PRACTICED／MASTERED）
- 原始碼：`apps/bridge_academy_flutter/lib/src/widgets/bridge_table_components.dart`、`bridge_table_toolbar.dart`、`bridge_replay_panel.dart`、`bridge_app.dart`
- 測試：`apps/bridge_academy_flutter/test/a3_table_toolbar_test.dart`

## 功能目的與實際情境

手機螢幕窄時，West/Trick/East 不應擠成三個超窄欄位；玩家仍要容易看到四方座位、目前正在出的牌、上一墩勝方與整份公開叫牌紀錄。打完牌後可以逐步複盤，但回放不能改動正在玩的牌局。

## 主要程式碼導讀

`BridgeTableSurface` 使用 `LayoutBuilder` 按可用內容寬度切換版面，並非直接讀取實機寬度：

```dart
builder: (context, constraints) {
  final compact = constraints.maxWidth < 560;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _seat(Seat.north),
      if (compact) ...[
        Row(children: [
          Expanded(child: _seat(Seat.west)),
          const SizedBox(width: 8),
          Expanded(child: _seat(Seat.east)),
        ]),
        BridgeCurrentTrick(view: view, copy: copy),
      ] else
        // 寬螢幕：West / Current Trick / East 同列
        // 完整實作請看 bridge_table_components.dart
      _seat(Seat.south),
    ],
  );
}
```

工具列只取 `PlayerView.auction`、`PlayerView.completedTricks`，其中 `last` 只有列表不為空才可讀。完成牌局的 Replay 只接收 `CompletedReplay`（其每一幀是 seat-filtered `PlayerView`）與 `onSelectIndex`，不接收 `BridgeSession`，也沒有變更領域事件的 callback。

## 為什麼這樣設計

Android/Compose 可對應 `BoxWithConstraints` 的依寬度排版，以及 ViewModel 暴露 immutable `UiState` 的單向資料流。響應式應以元件實際 constraints 為準；只依螢幕全寬判斷，遇到側欄或分割視窗會失準。

替代方案是永遠使用三欄橋牌桌，但當 West/East 是有 13 張明手的座位時容易形成過度狹窄欄位。另一個風險是工具列若直接從完整 GameState 取四家手牌，會把暗牌穿過呈現層信任邊界；因此所有資訊從 PlayerView 已公開的欄位投影。

## 驗證與實際證據

```bash
cd apps/bridge_academy_flutter
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build web --no-pub --release
```

新增 `a3_table_toolbar_test.dart` 測試四座位、窄版面、明手、叫牌對話框、上一墩顯示前置條件與回放只讀；初次 [Flutter CI #38778352023](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38778352023) 的 analyze 有測試檔 unused import，後續已修正。最新 [Flutter CI #38778610734](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38778610734)：analyze 無問題、**74/74 Flutter Widget/Session PASS**、Web Release Build PASS、Chrome Demo E2E PASS；[真 BEN Chrome CI #38778352006](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38778352006) 成功驗證真實 BEN 對局與明手互動，測試程式版本與運行時原始碼一致（後續僅更新 test/docs）。[Learning Gate #38778610653](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38778610653) PASS。沒有執行 Android 模擬器／實機或 iOS UX 測試，後者仍由使用者暫停。

## 練習與自我檢驗

**問題：** 為何 `BridgeTableToolbar` 顯示上一墩，必須使用 `view.completedTricks.last` 而不是從牌桌上目前的四張牌推測勝方？

**實作練習（5–15 分鐘）：** 比較 `BridgeCompletedReplayPanel.onSelectIndex` 與 `BridgeSession.submitCard` 的資料流，指出何者只是改變畫面索引，何者會寫入真實遊戲事件。

**完成標準：** 能分清 UI local state、public PlayerView、Domain event authority，且能解釋不同寬度下保持 Dummy 正確控制的方式。

## 下一步

A3.4 進行字級縮放、鍵盤焦點、螢幕閱讀器語意、觸控尺寸與 high fidelity UX；裝置驗收待核准。
