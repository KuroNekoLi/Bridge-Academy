# M2-F35｜A5.3.1：匯出已完成的橋牌 PBN

- Feature ID：M2-F35
- Milestone：A5.3.1
- 類型：Flutter UI／橋牌交換格式／隱私邊界
- 工程狀態：SCOPED ENGINEERING VERIFIED（Flutter 97／97 + Web Build + Chrome Demo CI PASS）
- 學習狀態：DELIVERED（未視為已練習或精熟）
- 原始碼：[CompletedPbnExport](../../apps/bridge_academy_flutter/lib/src/completed_pbn_export.dart)、[BridgeSession](../../apps/bridge_academy_flutter/lib/src/bridge_session.dart)、[History Panel](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_history_panel.dart)
- 驗收：[A5.3.1 驗收](../product/A5_3_1_PBN_EXPORT_ACCEPTANCE.md)、[Flutter 測試](../../apps/bridge_academy_flutter/test/a5_pbn_export_test.dart)

## 功能目的與實際情境

玩家在「歷史牌局」找到昨天打過的一副牌，想交給老師或其他橋牌軟體分析。現在能在**完成牌局之後**，按匯出按鈕，確認包含整副四家手牌的隱私警告，再將 PBN 複製到剪貼簿。

注意：目前 PBN 包含完整發牌、所有叫牌、定約、莊家、結果與分數，**尚未輸出每墩逐張牌的 \`[Play]\` 表格**；詳細逐步出牌仍在 App 的歷史複盤中檢視。沒有公開上傳伺服器或自動分享。

## 主要程式碼導讀

PBN 是文字交換格式，\`[Deal "N:..."]\` 會**公開完整 52 張牌**，不能和對玩家顯示的、只含自己手牌的 \`PlayerView\` 混為一談。

\`\`\`dart
String? exportHistoryPbn(String id) {
  final matching = _historyBoards.where((entry) => entry.id == id);
  if (matching.isEmpty) return null;
  final saved = SavedBoardCodec.decode(matching.first.archive);
  if (!saved.state.isFinished) return null;
  return CompletedPbnExport.encode(saved);
}
\`\`\`

這裡沒有「從 Flutter 自行猜測另外三家暗牌」。應用程式先由 \`SavedBoardCodec.decode\` 驗證已保存的完整牌局，\`CompletedPbnExport\` 再用原始 Deal 和真實叫牌事件格式化文字。Pass Out 必須忠實保留四次 Pass；有定約時 \`Result\` 指的是**莊家搭檔實際贏得的墩數**，不是南北方的分數。

UI 不會在建構時讀取 PBN，只有使用者在對話框按下確認，才透過回呼要求 \`BridgeSession\` 產生文字並呼叫 Flutter \`Clipboard.setData\`。

## 為什麼這樣設計

這是 Clean Architecture 的權限切分：在 Android/Kotlin 中，就像加密 Repository 保存敏感資料，ViewModel 只先提供匿名摘要；當使用者明確允許分享時才呼叫 Export UseCase，而不是把完整資料暴露在 Compose/List item 的參數中。

替代方案是直接在每筆 ListTile 放 \`Deal.toPbn()\` 或自動複製。這會把四家手牌意外洩漏給畫面重繪、Debug、UI 分析或未授權分享流程，因此刻意禁止。

**常見誤解：** 「遊戲結束後四家牌已經可以公開，就不需要確認」。實際上系統剪貼簿是另一個外部信任邊界，其他 App 也可能讀到。即使可以合法匯出，也應讓玩家明確選擇。

## 驗證與實際證據

\`\`\`bash
cd apps/bridge_academy_flutter
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build web --no-pub --release
\`\`\`

測試包含 Pass Out 四次叫牌、52 張牌從 PBN \`[Deal]\` 往返還原、有定約 13 墩的結果欄位、已刪除項目不可匯出，以及真正的 Widget 按取消不複製、按確認才複製。第一次 Flutter CI [#38862357907](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38862357907) 的嚴格 analyzer **FAIL（13 項純 lint）**：PBN 字串相加、測試多餘 helper、測試鍵值拼接。已修復為 Dart 字串插值，保留原本的 lint 與 PBN／隱私驗收要求；第二次 [Flutter CI #38862763069](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38862763069) 又找到測試檔第 98 行遺留的字串串接 1 項；已修成字串插值，最後 [Flutter CI #38863038248](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38863038248) 在 commit `4ac69e4` 已 **成功**，Dart analyze 無問題、**97／97** Unit／Widget 通過、Web Release Build 及 Chrome Demo/加密 Checkpoint 回歸均 PASS；[Feature Learning Gate #38863038107](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38863038107) PASS。此結果不等於完整 PBN `[Play]`、公開服務、Android 或 iOS 裝置通過。

## 練習與自我檢驗

**思考題：** 假設玩家只打完前兩墩，就想輸出 PBN 給朋友看。為什麼不能只把 \`Deal.toPbn()\` 藏在不可見的 Widget 中，卻繼續讓 Copy 按鈕可用？

**5–15 分鐘小練習：** 在 Pass Out 的測試中確認 \`[Auction]\` 真正有四次 \`Pass\`，並確認 \`[Deal]\` 能透過 \`Deal.fromPbn\` 重新構成相同的 52 張牌。

**完成標準：** 能說明合法終局、使用者同意、加密儲存與外部剪貼簿分別屬於不同的權限邊界。

## 下一步

A5.3.2 擴充標準 PBN \`[Play]\`、局後授權匯入／匯出；再開發 B1 四副牌練習及場次總成績。沒有批准前，A4.5 公開部署與裝置 UI/E2E 不啟動。
