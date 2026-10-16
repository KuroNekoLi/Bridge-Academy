# C1.5 — DDS × B5 複盤整合驗收

- Branch: `feature/c1-5-dds-review-integration`
- Status: **IMPLEMENTED — CI NOT RUN / PLATFORM CONFIGURATION PENDING**
- Scope: 玩家從已完成牌局或歷史複盤主動按「分析完成牌局」，成功時顯示官方 DDS3 adapter 回傳的 **5 花色 × 4 莊家**的雙明手墩數表。終局時間軸、回放與書籤維持 B5 既有行為。
- DDS 僅分析原始牌局 52 張、公開契約中的 double-dummy 最大可得墩數。**不是每個 ReplayStep 的最佳單張出牌，不可稱為 BEN 的最佳行動**。

## 安全與平台界線
1. `BridgeSession` 從已驗證的 `SavedBoardCodec` 或結束的受信任 `SinglePlayerCoordinator` 取得完整 transcript，轉成 `TrustedCompletedBoard`。只有 `DoubleDummyTable` 進入 Widget；不記錄或展示原始 Deal/PBN。
2. 未完成、Pass Out（未完成 13 墩）、損毀檔案、未安裝原生 DDS 時都明確失敗，不使用 mock 或硬編碼結果替代。
3. Flutter Web 不能啟動 C1 原生 Python DDS Worker，顯示 unavailable。桌面原生模式需外部安裝符合 C1 審核的 DDS3，編譯時指定 `--dart-define=BRIDGE_DDS_WORKER_SCRIPT=/absolute/path/dds3_worker.py`，並確保 Python 3.14、pinned DDS3 模組與 Worker 所需套件實際可用；未配置預設 Disabled。Android/iOS 仍不啟動實機測試。
4. 已存在外部 Gateway 路徑尚未接入終局資料解密分析，避免非受信任網路環境取得完整手牌。DDS 結果不寫回牌局或歷史，不影響分數與回放。

## 測試
- Flutter: `cd apps/bridge_academy_flutter && flutter pub get && flutter analyze && flutter test test/c1_5_dds_review_test.dart && flutter test && flutter build web`
- 真 DDS Golden: `cd packages/bridge_dds_adapter && C1_DDS_REAL=1 C1_DDS_WORKER=tool/dds3_worker.py dart test test/dds3_real_golden_test.dart`（需已安裝 DDS3）。
- 本環境無 Flutter/Dart SDK，**上述尚未執行（NOT RUN）**，需 GitHub CI 驗證後方可標記 PASS。
- Remaining: 已完成牌局的每一步 DDS SolveBoard 候選出牌，需另立 C1.6；不能拿整副原始 DD table 假裝逐步 best-move 說明。
