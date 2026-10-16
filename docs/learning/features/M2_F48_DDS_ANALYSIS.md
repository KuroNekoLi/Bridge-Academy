# M2-F48｜DDS3：為什麼雙明手分析只能在終局執行？

- Feature ID：M2-F48
- Milestone：C1.1～C1.3
- 類型：橋牌 AI 整合／純 Dart／可信終局分析
- 工程狀態：IMPLEMENTED（真 DDS3 CI 驗證待確認）
- 學習狀態：DELIVERED
- 原始碼：`packages/bridge_dds_adapter/lib/src/double_dummy_analysis.dart`、`lib/src/dds_python_process.dart`、`tool/dds3_worker.py`
- 驗收與測試：`test/double_dummy_analysis_test.dart`、`test/dds3_real_golden_test.dart`、[C1 workflow](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/c1-dds-analysis.yml)（先記 CI PENDING，不造假）

## 功能目的與實際情境
玩家完成一副橋牌後，未來可以在 B5 複盤頁查看「如果雙方知道所有手牌、某莊家叫某花色，理論上能拿幾墩」的表格。本階段只實作可信分析服務，不直接展示給 Flutter。DDS3 所用資料與真人出牌時的資訊完全不同，因此不能把事後的雙明手結果稱作玩家當下的最佳選擇。

## 主要程式碼導讀
`TrustedCompletedBoard.fromTrustedTranscript` 會用 Bridge Core 的 `GameTranscript.decode` 重播每個歷史事件；局面若非 13 墩已結束的完整牌局，即拒絕：

```dart
if (!state.isFinished || state.contract == null ||
    state.tricks.length != 13 || state.nsScore == null) {
  throw const DoubleDummyAnalysisException(
      DoubleDummyFailureCode.notFinished);
}
return TrustedCompletedBoard._(
  state.deal, state.dealer, state.vulnerability,
  state.historyFingerprint, false);
```

之後 `DdsPythonProcessAnalyzer.analyze` 只會將私有的完整原始牌 PBN 寫進隔離程序的 **stdin**。上游 DDS3 Python API 的 `calc_dd_table` 使用 4×4 bitmask（人 × 花色），輸出 5×4 table（花色 × 莊家），數字 0～13。結果由 `DoubleDummyTable.fromWorkerResponse` 驗證 schema、固定上游 SHA、全部 20 格與數值界線；timeout、異常、錯誤輸出一律用非敏感型別對外。

先注意 `Strain.values` 在 Bridge Core 是 C/D/H/S/NT，而 DDS3 是 **S/H/D/C/NT**；不明確映射就可能把梅花最優墩數當成黑桃。

## 為什麼這樣設計
使用 Dart `abstract interface class DoubleDummyAnalyzer`，相當於 Kotlin 的 domain `interface` + Infrastructure adapter。選擇 **單次執行一個 Python 程序**，而不是把 native DDS 放進 Flutter UI process，是因為這樣可設定逾時、關閉故障程序，且不讓帶特權的 52 張牌碰到普通 `PlayerView` 或 BEN 叫牌輸入。代價是啟動程序／初始化 DDS 有額外延遲；未來可評估可信本機工作池，但不能因此打開一般玩家存取路徑。

常見錯誤是只測一個假 `DoubleDummyAnalyzer`，卻說真 DDS 已通過，或者用雙明手得分推斷人類資訊不充分時「應該」能打出同一張牌。這份工程教材不把任何策略教學評為已經專家審核。

## 驗證與實際證據
在 `packages/bridge_dds_adapter` 執行 `dart analyze`、`dart test`、`python3 -m py_compile tool/dds3_worker.py`；**普通測試內的假 Python worker 是 API 契約測試，不是真實 DDS**。真正驗證須先從 pinned `abb1127` 生成 Python 原生 wheel，再設 `C1_DDS_REAL=1` 執行 `test/dds3_real_golden_test.dart`。該測試有三副固定、相互旋轉的完整牌，驗證 5×4 值與兩次分析一致。尚未有相同 SHA 的 CI 成功紀錄時請標記 PENDING，不以預期 PASS 取代事實。

## 練習與自我檢驗
**思考題（1 題）：** 如果玩家在第 7 墩只看得到自己與已攤開的明手，為什麼不能直接呼叫這個 DDS3 adapter 並稱其答案是公平的「最佳一手」？

**5–15 分鐘小練習（可選）：** 在 `double_dummy_analysis_test.dart` 增加「DDS 回傳 6 列、不是 5 列」的拒絕案例，並解釋為什麼要在信任邊界驗證 response schema。

**完成標準：** 能說明四手完整原牌與 `PlayerView` 兩種資料的權限不同，並辨識 5×4 matrix 的正確座位／花色映射。

## 下一步
等待真 DDS 的 Linux CI 與第三方打包權利審查；取得證據後，交由 B5／C1.5 將分析結果接到終局複盤畫面。**沒有解鎖 Android/iOS 裝置測試或正式服務部署。**
