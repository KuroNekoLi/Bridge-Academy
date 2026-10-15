# M2-F17｜A2.5：App 重開後仍必須記住存檔回退警告

- Feature ID：M2-F17
- Milestone：Phase A2.5 / P1.2
- 類型：Flutter 存檔儲存庫、Recovery UX 與失敗注入測試
- 工程狀態：ENGINEERING_VERIFIED（[Flutter #38738604483](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38738604483)：50/50、Analyze、Web Build、Chrome Demo PASS；Android／BEN 另驗）
- 學習狀態：DELIVERED
- 原始碼：apps/bridge_academy_flutter/lib/src/session_persistence.dart、bridge_session.dart
- 驗收與測試：apps/bridge_academy_flutter/test/checkpoint_recovery_notice_test.dart；docs/product/P1_A2_5_DURABLE_RECOVERY_CONSENT_ACCEPTANCE.md

## 功能目的與實際情境

玩家在第八墩完成出牌，最新存檔損壞，系統只能恢復到第七墩。A2.4 已會提醒玩家「有進度可能遺失」，但若玩家沒有按確認又把 App 關掉，下次打開時**不可以直接讓電腦繼續出牌**。因為玩家仍未接受進度可能倒退這件事。

這次修復的是「跨 App 重啟的確認狀態」，不是重寫 Replay Engine，也不是加密完整手牌。

## 主要程式碼導讀

現有雙槽存檔用 `active` Marker 記錄目前被承認的代數。現在加入可選的 `recoveryPending`：

~~~dart
if (committed != null && committed.generation == active.generation) {
  _recoveredOlderCheckpoint = active.recoveryPending;
  return committed.archive;
}
~~~

這樣再次啟動也會重新得到尚待確認的狀態。只有玩家按確認時，`BridgeSession` 才呼叫 `await store.acknowledgeRecoveredCheckpoint()`；成功後才清除 `_recoveryNeedsConfirmation`，允許 Bot 或人類出牌。

寫入若出錯，程式**不能先清掉記憶體警告再試著存入磁碟**。否則 UI 可能允許一次不應發生的動作。

Dart/Flutter 實作補充：`_archiveStore` 的原始型別是 `SessionArchiveStore?`。初次 Flutter Analyze 指出直接呼叫可能為 null；修正採用 Dart 3 Pattern Matching：`if (_archiveStore case RecoveryAwareSessionArchiveStore recoveryStore) { ... }`，在區塊內取得明確非空的介面實例。這與 Kotlin `is` 型別檢查及 Smart Cast 的概念相近。

## 為什麼這樣設計

這是「Fail Closed」和「事件提交（Commit）先於 UI 狀態轉換」的概念。

對 Android/Kotlin 工程師來說，可類比 `Repository.confirmRecovery()` 是一個 `suspend` 操作；`ViewModel` 必須等它成功才將 `StateFlow` 從 `ConsentRequired` 改成 `Playing`。

替代方案是將 `recoveryPending` 存在獨立的 preferences key，但會讓 Marker 與確認狀態需要跨兩次儲存寫入，新增掉電時的不同步風險。放入既有 Commit Marker，使回退版本和待確認資訊維持同一份紀錄；仍不代表具有資料庫 ACID/加密保證。

常見錯誤：把 `recoveredOlderCheckpoint` 當成「這一次讀取是否發生回退」，並在下一次讀到合法版本時設回 `false`。實際產品需要的是「**目前這一版是否仍有尚未同意的回退風險**」。

## 驗證與實際證據

~~~bash
cd apps/bridge_academy_flutter
flutter pub get
flutter analyze
flutter test test/checkpoint_recovery_notice_test.dart
flutter test
~~~

測試包含重啟兩次、拒絕未確認的操作、儲存確認失敗、Marker 型別錯誤、玩家明確重新開始新牌局，以及舊 A2.4 正常恢復與 Bot 行為回歸。

實際 [Flutter CI #38738604483](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38738604483) 成功：50/50 測試、Flutter Analyze、Web Build、真 Chrome Demo 全 PASS。Commit `3456ed5` 增加持久標記與負面測試，Commit `8de76f7` 修正可空介面呼叫。Android／真 BEN 另驗；真正交易、加密、掉電持久性尚未證明。

## 練習與自我檢驗

**思考題：** 為什麼玩家按了「我了解」後，我們要先 `await` Marker 寫入成功，才能解除 `BridgeSession` 的出牌暫停？

**5–15 分鐘小練習：** 在確認失敗測試中，再多呼叫一次 `restoreSavedGame()`，驗證警告是否依然存在，並說明如果是先清除記憶體狀態，這段測試會如何失敗。

**完成標準：** 能區分 1) 合法事件重播、2) 回退進度通知、3) 確認持久化、4) 真正的原子性／加密等不同的可靠性承諾。

## 下一步

Phase A2.6：選擇具交易與加密能力的 Android/iOS 儲存實作、保留 Web 存儲政策；或先做 A2.5 Android 二次重啟警告實測，再進入存儲遷移。
