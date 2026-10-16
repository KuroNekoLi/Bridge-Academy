# C1 — C1 — 真 DDS 雙明手終局分析引擎

**Target branch**: `feature/c1-dds-analysis`  
**Based on**: `master 08a7fb5efcebd8538cfb70624c8975bd9b3eff88`  
**Status**: C1.1–C1.3 SCOPED IMPLEMENTED + VERIFIED (Dart/Linux native CI), C1.4 isolated service; B5/C1.5 Flutter UI intentionally pending  
**Provisional lesson ID**: `M2-F48`（在整合時必須再次檢查是否衝突）

## 目標
提供獨立的 post-game DDS analysis API：已完成牌局才可在受信任的分析邊界用 52 張牌求得 DD Table 或出牌解；任何 live session／普通 BEN／玩家視圖不得取得這份特權資訊。

## 概念與來源
- `docs/OPEN_SOURCE_AUDIT.md` 僅將上游 `https://github.com/dds-bridge/dds` 列為 Apache-2.0 **待確認候選**；不可在核對 exact commit、LICENSE、二進位平台、subdeps 與再分發條款前複製二進位／宣稱通過授權。
- `docs/BRIDGE_RULES_BASELINE.md`、`packages/bridge_core/lib/src/model.dart` 的 `Deal.fromPbn/toPbn`、`Vulnerability`、`Contract`；`CompletedReplay` 的公開 PlayerView 無法也不應逆推出四家手牌。
- 可比較獨立 native CLI/FFI、隔離式 Python/native DDS 本機端服務、或有確切授權/能力的 Web/WASM；分析必須在終局或專用教學 fixture 後才有權限輸入可信完整 Deal。切勿將 DD 庫放到一般 bot 的決策路徑。

## 分片與交付
**C1.1 審查與 adapter**：建立 `docs/product/C1_DDS_THIRD_PARTY_AUDIT.md`（上游 immutable SHA/tag、License 原文位置、平台、編譯/服務模式、模型權利、隱私、性能/limits），採用有明確可用環境的測試路徑；不把想像中的跨平台能力當實際可用。定義 `DoubleDummyAnalyzer`、`DoubleDummyTable`、`DoubleDummyAnalysisException` 與 timeout，結果附 DDS 版本、contract/seat、單位與 provenance。
**C1.2 可信終局輸入**：只能由已確認 finished 的 `SavedBoardCodec`／trusted `GameTranscript` 或明示 sandbox teaching fixture 提供 `Deal`。先嚴格驗證 schema、完整 52 張、合法座位與 terminal status；原始 Deal 不落一般 UI/log/network。取消、耗時與逾時均 Fail Closed，不留未完成快取。
**C1.3 真引擎接線 + Golden fixtures**：至少 3 副固定 PBN 與上游可重現期望值，覆蓋 NT、trump、有局/無局與不同莊家；比對真 DDS 產生的四家×五花色最多墩數，不以 mock API 冒充。合法王牌與 DDS PBN/seat mapping 需交叉檢查。原生與 Web 支援範圍要明列。
**C1.4 狀態與 UI 邊界**：此 branch **只**提供 adapter/domain 與可測試的 postgame service／獨立 example runner，B5 的 Review UI **不要修改**；合併後另開 follow-up `C1.5` 才整合 UI。如果因授權或執行環境阻擋，保留可執行的 Domain/資料合約與測試，但須標記 `INCOMPLETE`，不得宣稱 C1 真引擎通過。

## 驗收
- Unit/golden/negative tests：活躍局拒絕、無授權 PBN 拒絕、corrupt/half-deal 拒絕、正常終局可求解、座位及 C/D/H/S/NT 映射、timeout/error 不列印秘密、相同 PBN/solver version 可重現。
- 真 DDS 雙明手答案與原始實際出牌／BEN 模型決策必須分開；**不允許用 DD 最佳值評價當時資訊受限的真人決策為錯誤**。
- 非 web 執行 CI 可真跑 DDS，再保留 Flutter/Web compilation compatibility；若僅原生可用，Web 返回 typed Unsupported，不在 Web 默默算假結果。
- 文件 `docs/product/C1_DDS_ANALYSIS_ACCEPTANCE.md`、教學 `docs/learning/features/M2_F48_DDS_ANALYSIS.md`（僅真的可用後標記 VERIFIED）；中途阻擋要如實報告 NOT RUN/BLOCKED。
## 責任區
建議新 Dart package `packages/bridge_dds_adapter/` 或受信任 service `services/bridge_dds_analyzer/` 與專屬 test／scripts；**禁止修改 B5 的 replay widget、C3 學院、核心 reducer 與公開 BEN API**。


## 通用執行契約
1. 先 `git fetch origin && git switch <本分支>`，確認 `git branch --show-current` 與 `git status --short`。只修改本分支；**禁止自行 push / merge master、禁止 PR、禁止 force-push**。完成後只推回本分支，交給 Integration Agent 審查。
2. 依序閱讀 `AGENTS.md`、`README.md`、`docs/product/BRIDGE_ACADEMY_PRD_V1.md`、`docs/product/PRODUCT_DELIVERY_ROADMAP.md`、`docs/BRIDGE_RULES_BASELINE.md`、`docs/DECISIONS.md`、`docs/ARCHITECTURE.md`、`skills/README.md` 與本任務指定來源；使用最小必要技能。
3. Bridge Core 是唯一合法叫牌、跟牌、牌墩、計分權威。一般 UI／BEN／分析摘要只接受其被允許的 `PlayerView` 與公開歷史；不得於 live play 將所有四手 `Deal`、密鑰、權杖或原始受信任 checkpoint 曝露給一般玩家、聊天 AI 或非受信任服務。終局授權分析是獨立的受信任邊界。
4. UI 文案必須繁中／英文。每片完成時有可驗證的 Domain／Widget／端對端證據與玩家可操作的結果，不得只交架構或空畫面；測試使用 deterministic fixtures。
5. 完整執行可行的 `flutter analyze`、`flutter test`、`flutter build web --release`（Flutter 專案在 `apps/bridge_academy_flutter`）。其他 Dart 套件請跑對應 tests；報告列出實際指令、SHA、CI URL、PASS / FAILED / NOT RUN，不能虛構驗收。若 branch CI 未啟動，可暫時只在本分支加入允許的 CI trigger，並在最後一個 commit 還原；不得更動 master 的長期觸發規則。
6. Android Emulator 與任何實體 Android/iOS UI／E2E **繼續暫停**；不可排程、重啟或修改其 guards。Web/Chrome、純 Dart、Flutter Widget、既有真 BEN CI 仍可按任務許可執行。
7. 每項新增玩家行為功能須在 `docs/learning/features/` 寫真實程式碼導讀、設計取捨、測試證據與一題思考題，更新 `docs/learning/INDEX.md`，編號使用本分支暫定保留號但在整合時再次檢查唯一性；不得將 LESSON_DELIVERED 稱為玩家已精通。
8. 最後提交 `docs/product/` 專屬驗收報告，交代玩家流程、實際測試、證據、已知限制、隱私／授權及 rollback。結束前刪除根目錄臨時 `AGENT_TASK.md` 並提交刪除，但保留 `docs/handoff/` 完整任務；若尚未完工勿刪。
9. 除非本分支所需的最小接線，避免改 `bridge_app.dart`、`app_copy.dart`、`bridge_session.dart`、`docs/learning/INDEX.md` 等共用檔案；需要時限縮修改，將可能衝突的 hunk 列在交接報告。不得把其他三個分支合併進來。

## 完工交接格式
請回報 branch 與 HEAD SHA、分段完成情況、實作檔、測試與 CI URL、教學檔、對使用者可見的操作、剩餘風險、與其他分支的衝突風險，最後留一題繁體中文學習題。**測試通過不等於正式產品 Release Gate 通過。**

## 實作完成交接（2026-10-16）
- 程式碼：`packages/bridge_dds_adapter/lib/src/{double_dummy_analysis.dart,dds_python_process.dart,dds_python_process_stub.dart}`、`tool/dds3_worker.py`，無 DDS binary/vendor 程式碼。
- 資料流程：加密可信存檔（授權由 caller 負責）→ `GameTranscript.decode`（逐行動重播驗證，未終局拒絕）→ `TrustedCompletedBoard` → Python DDS3 stdin → 20-cell DD table。Web 依條件匯出返回 `unsupportedPlatform`。
- 真 DDS3 upstream 固定 `abb1127ba096676a4849f341f300c9827a732342`（Apache-2.0），原生 CI 採 Python 3.14、`calc_dd_table`；無商用打包授權批准／手機支援聲明。
- Dart 6 tests + Web compile：[證據](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38919732769)；真 DDS3 3×20 Golden：[證據](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38919422293)。最後整合 Commit 使用 `[dds-golden]` 觸發同版重驗。
- 交由 C1.5／B5 後續整合玩家畫面，不要在本分支修改 replay/widget 或讓 live BEN 拿到 52 張。
- 未驗證：Android/iOS（使用者暫停）、Flutter App 完整回歸（未改 Flutter）、真實 DDS 重發行權與 Web/WASM。追蹤 `docs/product/C1_DDS_ANALYSIS_ACCEPTANCE.md`。
