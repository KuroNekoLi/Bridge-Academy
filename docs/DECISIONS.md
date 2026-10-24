# Architecture and Product Decision Log

## ADR-035 — M4.6/4.7 歷史差異與專家證據交接，不讓自訂約定繞過正式引擎（2026-10-25）

**M4 CUSTOM CONVENTION REVIEW WORKFLOW: SCOPED ENGINEERING PASS；CUSTOM AI EXECUTION: NO-GO。** 延續既有 M4.1～M4.5 的私人草稿及 SHA256 版本鏈，加入 `CustomConventionHistory.compare(archive, fromRevision, toRevision)`，只對已驗證的相同 archive 計算 rule slot 增／改／刪與公開 auction。這是使用者設定差異，不能據以聲稱 BEN/BBA 行為變了。

`CustomConventionReviewPlan.forDraft(draft)` 產生 six-scenario-per-edit 的待審清單及版本指紋（一般、競叫、passed hand、forcing/invitation、Alert、opponent reader），全部固定 `NOT_REVIEWED`／`NOT_RUN`、engineCertified=false。100 個 expert golden 是待達成**目標**，不是 AI 支援證據或模型授權。Flutter 只允許 Clipboard 複製待審 JSON，不含任何手牌，沒有「啟用為 AI」的按鈕。

正式 Gateway 不信任 `customDraft`、`fingerprint`、`runtimeSupport=SUPPORTED` 等用戶聲明。真 HTTP Session 注入測試要求不認可本機 ID、不發行 access token；不修改 `ConventionCatalog`、`GameSystems` 與既有正式 21GF/SAYC 或 Precision 研究實作。

**證據**：[M4 Domain/Flutter CI #40139400430](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40139400430) 30/30 + 6/6、[Gateway HTTP CI #40139293120](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40139293120) 49/49。仍缺 signed/trusted operator artifact mapping、足量 expert golden、真 native 自訂卡 bid/play、授權及 VPS/裝置 Release gates。[M4 驗收](research/M4_CUSTOM_CONVENTION_DELIVERY_ACCEPTANCE.md)／[M4-F06](learning/features/M4_F06_CUSTOM_CONVENTION_REVISION_DIFF.md)／[M4-F07](learning/features/M4_F07_EXPERT_REVIEW_AND_ROUTING_GUARD.md)。



## ADR-036 — M4.3～M4.5：自訂約定可預覽、可移轉，但不可偽裝 AI 支援（2026-10-25）

**DRAFT TOOLS IMPLEMENTED；PLAYABLE CUSTOM AI MODEL STILL NO-GO.** 玩家可從固定 SAYC/2/1 草稿編輯有限規則、檢視公開叫牌的「作者定義」與明確的 `engineEvidenceRequired`，並把已驗證的 revision chain 複製到剪貼簿，另一裝置必須確認才能 fast-forward 匯入。對現有版本較舊、base 不符、同一 revision 分岔、任意 JSON 欄位或 hash 篡改皆失敗且不覆蓋。此資料僅為本機個人草稿，並非密碼學簽章、雲同步或正式引擎憑證。

新 `CustomConventionReviewer` 永不提供玩家可控制的 `SUPPORTED` 欄位。`CustomAuctionPreview` 的 `USER_DRAFT` 意義只來自使用者修改，對未設定的叫品回報「未驗證／未知」，不得作為原生 BEN/BBA 真正會出的叫品。原有 `ConventionCatalog`、`GameSystems`、Gateway 的服務端制度版本及 Precision 研究旗標都不因本地編輯而改變。

此階段交付：[M4 domain reviewer](packages/bridge_conventions/lib/src/custom_convention_review.dart) · [Flutter editor](../apps/bridge_academy_flutter/lib/src/conventions/custom_draft_page.dart) · [M4 驗收](research/M4_CUSTOM_CONVENTION_DELIVERY_ACCEPTANCE.md) · [M4-F03](learning/features/M4_F03_CUSTOM_ENGINE_CAPABILITY_REVIEW.md) / [F04](learning/features/M4_F04_PUBLIC_AUCTION_MEANING_PREVIEW.md) / [F05](learning/features/M4_F05_CUSTOM_DRAFT_BACKUP_IMPORT.md)。

**實測驗收（2026-10-25）**：[M4 CI #40137806806](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40137806806) completed/success；`bridge_conventions` Domain **25/25**、Flutter 本機草稿 Editor **4/4**，兩者 analyzer PASS，皆不包含任意自訂卡真 BEN/BBA 推論。此結論僅授權 **M4.1～M4.5 草稿工具 scope**，不解禁模型或正式發布。

正式可玩自訂卡仍須引擎逐規則測試/權限核對、雙方 convention reader、100+ goldens、部署和裝置 QA。**不要為了把 M4 標成完成而虛構模型訓練或修改生產 Gateway**。

## ADR-035 — M4 自訂約定分為「本機草稿」與「已驗證可執行制度」（2026-10-24）

**APPROVED IMPLEMENTATION BOUNDARY / M4.1–M4.2 DRAFT SCOPE; M4 EXECUTABLE ENGINE NO-GO.**

在三制度 M1→M6 路線中，M4 指自訂 Convention Card（舊版 `docs/ROADMAP.md` 的 M4=多人連線屬另一套歷史分期，不能混為一談）。M3 Precision 的工程研究已通過 native BBA、Gateway、四個 52-card 技術局，但**M3 產品級牌力／專家 Golden／VPS／裝置 QA 尚未完成**。本決策允許先實作完全獨立的 M4 草稿，不因未完成的 AI 品質驗收全面停滯；但**不宣告 M3 Product GO 或 M4 Playable GO**。

M4.1 新增 `CustomConventionDraft`，只可複製固定 BEN 21GF/SAYC Base，且只能在 enum allowlist 編輯 1NT HCP、Stayman／自然 2♣、2♦／2♥ transfer/natural 的有限選項；JSON 白名單、每次修改 revision+1、SHA-256 順序正規化、前版 fingerprint、同個 slot 意義衝突阻擋。SHA 代表資料版本完整性，非 AI 支援證書／密碼簽章。

M4.2 `CustomConventionArchive` 驗證版本相連，Flutter app bar 提供雙語本機編輯頁；`SharedPrefsCustomDraftStorage` 只保存可驗證草稿，不加密、不跨裝置、不宣稱具備伺服器一致性。錯誤存檔不得被靜默重設。無論怎麼改，`isPlayableCustomSystem=false`；任何規則不為原始 base 都是 `ENGINE_UNVERIFIED`。不得透過 JSON 的 `SUPPORTED` 宣稱繞過驗證，也不得進入 `ConventionCatalog`、`GameSystems`、BEN/BBA model 或比賽配置。**即便草稿沒改，`UNCHANGED_BASE_ONLY` 也只表示可以沿用原生 base profile，不產生新的 AI model。**

M4.3～M4.5 想要真的「自訂系統可玩」需獨立引擎證據：真 BEN/BBA convention compatibility、每個已授權版本的 artifact SHA、雙方對手 reader、golden forcing/competition/alerts、可恢復 AI 路由、專家簽核／公平性、非授權卡拒絕以及正式部署驗收。使用者直接編輯 UI **不是**這個證據。

**完成的工程證據**：[M4 專用 CI #40108357113](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40108357113) SUCCESS：Dart Convention Domain 20/20、Flutter editor Widget 2/2、兩者 analyzer 皆無 issue，沒有裝置測試、原生 AI 改卡或正式部署。

[驗收與待辦](research/M4_CUSTOM_CONVENTION_DELIVERY_ACCEPTANCE.md) · [M4-F01](learning/features/M4_F01_CUSTOM_CONVENTION_DRAFT_DOMAIN.md) · [M4-F02](learning/features/M4_F02_CUSTOM_CONVENTION_EDITOR.md) · [CI Workflow](../.github/workflows/m4-custom-convention-drafts.yml)。不開 Android emulator 或 iOS/Android device QA，遵守既定 owner hold。

## ADR-034 — Precision 合作制度推論導入出牌；真 BBA `find_info`，保留神經牌力 NO-GO（2026-10-24）

**M3.6 SCOPED TECHNICAL PASS / COMPETITIVE CARDPLAY NOT YET VALIDATED.**

固定 BEN `ad8608af6e6bfe095863023f344f3cb2cbafec3d` 內的 BBA `BBABotBid.find_info(auction)` 能在**當前 actor 原始 13 張手牌＋公開 auction、兩邊固定 .bbsa 卡**的資訊邊界下推估 N/E/S/W 四家 C/D/H/S 花色長度；但固定原生 BBA interface 無正式 `choose_card` API，BEN NN 也沒有 Precision opponent reader。因此不實作虛假的 `BEN:PRECISION` 或 DDS 偷看四手牌出牌。

Bridge Academy 的研究版改為 `BbaResearchTablePolicy` 在 `Phase.play` 呼叫 `/v1/precision/auction-inference`；sidecar pin source / Meckwell card / EPBot .so，僅回傳完整 schema 和每座位 4 花色 **0..13 預測值（非真實手牌）**，不回傳任何對手實際私牌。Policy 僅以 `PlayerView.legalCards` 中合法牌按 `己方剩餘花色張數*2 + 搭檔預估張數*3 - 敵方預估張數合計` 探索性排序，同分保留低點；不憑 native 模型直接改 GameState。推論失敗、schema 或 SHA 不匹配回錯誤，不回退到 `DeterministicTrainingBot`、錯誤 BEN model 或所有牌可見的 DDS。

**真實技術證據**：[CI #40105701070](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40105701070) 實際讀取原生 BBA 的 4 種 NS/EW 合約叫牌推論，拒絕非完成 auction／額外私牌，4 組 Precision 對 21GF/SAYC 的固定公開牌局各完成 52 unique cards／13 tricks，出牌不再是舊 deterministic：最終 NS score 由前階段的 -100 改為 +130（**不能據此推論牌力提升**，固定單一 PBN、沒有公平對照）。Dart unit 使用相同合法牌 + 不同搭檔預估花色證明會選不同合法出牌；惡意估值 fail-closed。正式測量式 native inference 次數以後續 CI 記錄為準。

**非目標**：沒有真正的 Precision-aware BEN NN play model，沒有 single-dummy 機率抽樣訓練、訊號判讀、專家防禦牌例、同種子大樣本 MP/IMP 勝率、4GB VPS/併發驗收。因此 **產品 ranked/正式發布繼續 NO-GO**。僅保留 Gateway `M34_RESEARCH_ENABLED=true`、Flutter `BA_M34_RESEARCH_PRECISION=true` 的雙重 opt-in。BBA 商業託管、修改與再散布權已由使用者確認，正式散布文件/notice 留在 Release audit。

**語義限制新增證據（2026-10-24）**：[CI #40106500046](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40106500046) 真 BBA 6/6 推論 schema PASS，其中 2 次是完成的人工強 1♣ 叫牌。然而同一牌例中兩種配對設定的 16 個 `probable_length` 值全相同（差異 0）；這意味著尚不能用此訊號證明強梅花語義區辨力。HCP 範圍、Alert/meaning、花色 min/max 與 expert golden 仍必須另行驗證。不可聲稱完成競賽級 Precision NN cardplay。

[M3.6 工作和證據](research/M3_6_PRECISION_CONVENTION_AWARE_CARDPLAY.md) · [M3-F17 教學](learning/features/M3_F17_PRECISION_CONVENTION_INFERRED_CARDPLAY.md)。



## ADR-033 — M3.4 混合制度研究牌局與 M3.5 真原生效能評估（2026-10-24）

**M3.4 SCOPED ENGINEERING PASS / M3.5 PERFORMANCE RESEARCH PASS; RELEASE NO-GO.** Bridge Academy 採用 `BA-PRECISION-MECKWELL/r1` 搭配 SAYC 或 2/1。由於 pinned BEN 神經模型沒有 Precision opponent reader，本次選擇**整桌 BBA 原生約定卡協作叫牌**，絕不讓 BEN 靜默把人工強 1♣ 理解為天然梅花。`BbaResearchTablePolicy` 是 private PlayerView → BBA proposal adapter，出牌使用**明確標示非競賽級的 DeterministicTrainingBot**。其目的是證實安全 Gateway、immutable GameSystems、52 張合法牌與 13 墩計分，而非證明競技強度。

Gateway 的 Precision 必須顯式 `M34_RESEARCH_ENABLED=true` 且原生 worker pinned ready；Flutter 必須用 `--dart-define=BA_M34_RESEARCH_PRECISION=true` 編譯研究版才提供選項。一般正式建置不顯示 Precision；使用者看見雙語研究／非競賽提示。系統不可在局中變更、未知版本拒絕、不能 fallback Demo 或 BEN 21GF-GIB。

**執行證據**：[M3.4/M3.5 CI #40102968596](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40102968596)：雙方向 Precision/SAYC 真原生 BBA 完成兩局 52 cards/13 tricks；Gateway 47/47 tests、Domain/Adapter 10/10。M3.5 在 GitHub Ubuntu runner 以固定種子測 **1000 個 native bid requests（NS/EW 各 500）**，1000 成功／0 失敗、P50 9.46ms、P95 12.96ms、RSS 79,220 KiB。**這不是 1000 場完整橋牌對局，亦不是 4GB VPS SLA 或橋牌專家叫牌正確性。**

使用者已確認 BBA 商業託管、修改及再散布權利，正式授權文件和第三方 notices 應私下歸檔。尚未滿足 100+ expert golden auctions、具 Precision 解讀的真 AI cardplay、1,000 randomized full deals、同種子 MP/IMP 公平性、併發/VPS/TLS/裝置 QA，**PRODUCTION/RANKED 仍 NO-GO**。

[完整 M3.4 驗收](research/M3_4_PRECISION_MIXED_GAME_ACCEPTANCE.md) · [M3.5 效能／Release Gate](research/M3_5_PRECISION_BENCHMARK_AND_RELEASE_GATE.md) · [M3.4/5 CI Workflow](../.github/workflows/precision-m34-m35-research.yml)。**最新驗收追加（2026-10-24）**：[CI #40103865733](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40103865733) 完整通過 Flutter 研究旗標 Widget、Gateway 47/47、Python schema 3/3、1000/1000 native 開叫（P95 10.03ms），並將全局測試擴充為 **Precision 分別對 SAYC 和 21GF、南北／東西互換的 4 種配置，全部各 52 unique cards／13 tricks 完成**。以上仍是單一固定牌例與研究用合法策略出牌，不能聲稱正式 Precision 橋牌品質、4GB VPS 或 Production GO。



## ADR-032 — M3.3 採隔離 EPBot PrecisionBiddingProvider，而非偽裝成 BEN Neural（2026-10-24）

**IMPLEMENTED / AUCTION-PROPOSAL SCOPE / NOT FULL-GAME READY.**

Bridge Academy 第三種叫牌制度沿用已核准之 [BBA Meckwell Precision V1](conventions/PRECISION_BBA_MECKWELL_V1.md)（`BA-PRECISION-MECKWELL/r1`、1NT 13–15、固定上游 native library 與 card SHA）。使用者已明確說明 **取得 BBA 商業託管、修改、再散布授權**；權利確認記錄為 `OWNER_REPORTED_GRANTED`，不再宣稱「未取得授權」。原始契約與元件清冊可存非公開合規紀錄，正式散布仍要核對授權的具體第三方/二進位版本、notice 和作業義務。

**技術決策：** 不將不存在的 `BEN:PRECISION` 網路或 `ourSystem=PRECISION` 加入既有 BEN Adapter。獨立 `bridge_precision_adapter` 提供 `BbaPrecisionBiddingProvider`（只從 seat-filtered `PlayerView` 提出 CallAction），由 `BbaPrecisionLoopbackTransport` 以 127.0.0.1 POST body 與 `precision_m33_sidecar.py` 溝通。Native service 啟動時必須驗證 BEN source SHA、Meckwell.bbsa SHA、EPBot native binary SHA；以 actor NS/EW 決定「我方 Meckwell」和敵方 `BEN-21GF.bbsa`／`BEN-SAYC.bbsa`，不得傳完整 Deal 或接受任意 `.bbsa` 路徑。只啟用 `--research-only`，錯誤碼不洩露原生 stack/URL/hand。

**安全與非目標：** Bridge Core 仍是唯一合法性權威。此階段只處理 Precision 方的 `/bid` 出價，**不是全局 BotPolicy 出牌**，也不構成真 BEN 21GF/SAYC 對 Precision 的雙向理解。M3.4 前繼續禁止正式 `ConventionCatalog` 登錄、Gateway/Flutter 開局及 production release，避免中途默默切回不相容模型。M3.4 必須選擇並證明對手 reader 策略或如實標示「全桌 BBA 模式」，再用完整牌局／golden fixtures 驗收。

**執行證據：** [M3.3 Scoped CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/precision-m33-provider.yml) · [研究驗收](research/M3_3_PRECISION_PROVIDER_ACCEPTANCE.md) · [工程學習 F13](learning/features/M3_F13_PRECISION_BIDDING_PROVIDER.md) / [F14](learning/features/M3_F14_BBA_NATIVE_SIDECAR.md)。真原生 16 次開叫 + 2 次人工強梅花續叫共 **18/18 PASS**，Dart→EPBot→Core **1/1 PASS**（[CI #40095599137](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40095599137)）。這是叫牌 Provider 的限定驗收，不是 M3.4 完整對局。

## ADR-031 — Precision 單一正式約定版本：BBA Meckwell Precision V1（2026-10-24）

**CONVENTION SPEC SELECTED; PLAYER RUNTIME NOT APPROVED.** 第三套制度正式選定 BBA Meckwell Precision V1（1NT 13–15），產品 ID `BA-PRECISION-MECKWELL/r1`。唯一版本資料來源是 BEN commit `ad8608af6e6bfe095863023f344f3cb2cbafec3d` 的 `BBA/CC/Meckwell.bbsa`，SHA-256 `5c2a6c8d84094a0a9efd2cefe98a93983185140e6bde81b2520086b8b27d9cbc`，BBA type 3。與 Meckwell Lite v1.13.0 的 1NT 13–16 **非同一制度**。變更來源卡的規則或 hash 需要新增 revision，不能靜默覆寫歷史牌局。

**授權紀錄**：使用者於 2026-10-24 明確表示已取得 BBA 使用授權，標記 `OWNER_REPORTED_GRANTED`。尚未收到授權文字及涵蓋元件／hosted/commercial/redistribution 等範圍，標記 `SCOPE_UNVERIFIED`；不能由此推論所有用途已批准。授權原文可保留私有，不應隨意提交 GitHub。

**驗收限制**：此前 native BBA 8 個開叫情境中 4 個強 1♣ 預期均回 1♣，僅為 isolated probe，不是全套橋牌規則與正式 Gateway/BEN 混合出牌驗收。選定制度 **不等於**在 ConventionCatalog 注册可玩的 Precision；M3.3 Provider、專家 goldens、M3.4 Gateway/Flutter、部署仍 NO-GO。這份 ADR 取代 ADR-030 中關於制度變體待決的部分，其他工程阻擋維持。

[正式 V1 SoT](conventions/PRECISION_BBA_MECKWELL_V1.md) · [研究驗收](research/M3_PRECISION_SPIKE_ACCEPTANCE.md) · [開源／授權](OPEN_SOURCE_AUDIT.md)。

## ADR-030 — Precision M3 隔離 BBA／EPBot Spike 與正式制度釋出封鎖（2026-10-24）

**APPROVED FOR RESEARCH; PRECISION PLAYABILITY/PRODUCTION NO-GO.**

Bridge Academy 在 BEN 釘選 commit `ad8608af6e6bfe095863023f344f3cb2cbafec3d` 中確認 `BBA/CC/Meckwell.bbsa` 的 `System type = 3`，並以實際 native EPBot 在 Ubuntu 24.04 Python 3.12 隔離 CI 執行 **8 組 Precision 開叫情境**：4 個高牌點強 1♣ 候選全部回 1♣，研究工程驗收 `SCOPED PASS`（[CI #40092096757](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40092096757)）。這不是 BEN 可玩的 Precision neural 模型；不得宣稱 8 組牌例已驗證完整競賽叫牌品質。

**規格不相容：** 實際 BBA Meckwell 卡選擇 1NT `13–15`，Meckwell Lite v1.13.0 (2026-01-05) 公開參考文件採 `13–16`。先不決定哪套是本產品正式 Precision，建立獨立 research-only `PrecisionResearchCatalog` 保留來源、native type、backend/expert/license gates；**不加入 `ConventionCatalog`、Gateway `ourSystem` 或 Flutter 選單**，現有 M2 的 21GF/SAYC 完全維持。

**授權封鎖：** BBA 上游沒有明確 license，未取得商業／hosted／再散布、約定卡及原生庫明確使用權前，只在 disposable CI 以既存 pinned upstream 研究，不能 copy native binary 到 repo、手機或正式 VPS。下一步須先選定精準制 variant＋取得權利，再審定是 BBA、規則器或新 neural model，完成 1♣ 回應、競叫、專家 golden fixture 及 full game 驗證。

[研究報告](research/M3_PRECISION_SPIKE_ACCEPTANCE.md) · [授權稽核](OPEN_SOURCE_AUDIT.md) · [M3 原生 CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40092096757)。此決策不變更 Bridge Core 或 QA hold。



## ADR-029 — 2/1／SAYC M2.2～M2.5 對局制度切換已通過限定驗收（2026-10-24）

**SCOPED ENGINEERING PASS / PRODUCTION NO-GO.** M2.2 的 BEN request-scoped 21GF/SAYC 由 PlayerView.viewer.isNS 推出 ourSystem/theirSystem，lead/play 亦帶正確搭檔配置，不改 Bridge Core。M2.3 的 Gateway 只接收 allowlisted NS/EW profile IDs，要求 operator pin upstream Git SHA、真實 BEN GET / plays/reads capabilities；失敗 503，絕不隱形降級。M2.4 Flutter 以兩個雙語選單讓用戶新局前選擇 NS/EW，且回核伺服器生成的 fingerprint。M2.5 真 BEN pinned candidate ad8608af 在隔離 runner 測試兩種互換制度配置，各完成 13 墩、52 unique cards、分數及冪等回放（[CI #40087851963](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40087851963)）。

**保留的硬門檻**：沒有專家 100+ 黃金制度牌例、真人遊玩比較、完整版 BEN 品質檢查、權重/native binary 授權、4GB VPS 正式壓測、TLS/部署與暫緩的 Android/iOS 裝置 QA，故不得宣稱正式可上線。Precision／自訂制度先 M3 授權和語義研究。紀錄：[M2 整合驗收](research/M2_2_TO_M2_5_IMPLEMENTATION_ACCEPTANCE.md) · [M2.5 真模型](research/M2_5_REAL_BEN_MULTISYSTEM_ACCEPTANCE.md)。



## ADR-028 — M2.1 GameSystems 雙搭檔不可變版本釘選（2026-10-24）

**ACCEPTED ENGINEERING DIRECTION / NOT SYSTEM SWITCH GO.** 使用獨立純 Dart `bridge_conventions` 的 `PartnershipSystem`、`GameSystems` 封裝南北與東西的 profile ID、revision、BEN model ID/upstream commit 及 deterministic SHA-256 指紋。僅接受 allowlisted `LEGACY_UNVERIFIED/r1`、`BA-21GF/r1`、`BA-SAYC/r1`；Precision 和任意自訂約定暫不開放。由可信任 Gateway 建局時指定並寫入既有 encrypted checkpoint；重啟還原必須保持同一組版本。舊 checkpoint 未含欄位時設為 `LEGACY_UNVERIFIED`，有欄位而遭竄改／未註冊則 fail closed。

**重要安全門檻：** M2.2 尚未完成真正 BEN `ourSystem/theirSystem` 路由，因此任何釘選為新 21GF/SAYC 的遊戲在 Action/Advance 阶段回 503 `system_router_unavailable`；不得默默繼續用舊 BEN/GIB 並顯示新制度已生效。現有 LEGACY_UNVERIFIED 對局保留既有行為。此狀態為 scoped M2.1，不代表正式部署或 Dart Bridge Core 玩法改變。

[實作與驗收](research/M2_1_GAME_SYSTEMS_ACCEPTANCE.md) · [教學](learning/features/M3_F05_GAME_SYSTEMS_VERSION_PIN.md) · [M2.1 CI](../.github/workflows/game-systems-m21.yml)。下一步 M2.2 真模型路由與模型權重相容性驗證。


## ADR-027 — M1 Feasibility Scoped GO / Production NO-GO（2026-10-24）

**ACCEPTED TECHNICAL DECISION, NOT DEPLOYMENT APPROVAL.** M1.1 靜態能力、M1.2 真 BEN GET /、M1.3 兩制度實際 /bid A/B（32/32）、M1.4 GitHub Runner 單／雙 Worker 容量抽樣皆為 scoped PASS。強制保持真模型／Mock／模型配置／人類專審／目標主機實測的證據界線。推薦 M2 先採**單 BEN Worker 多模型 + 有界請求併行**、Server-owned profile ID/hash/version；Precision 另開 BBA 授權與語義 Spike。**4GB OVH VPS 正式多制度服務維持 NO-GO**，直到本機容量、完整版模擬、長時壓力、授權/權重、Gateway production 安全、裝置 QA 等 gate 通過。[M1.3 Evidence](research/BEN_MULTI_SYSTEM_M1_3_ACCEPTANCE.md) · [M1.4 Benchmark](research/BEN_MULTI_SYSTEM_M1_4_CAPACITY.md) · [CI #40076200888](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40076200888)。

## ADR-026 — 三制度 AI 與逐步開放自訂約定（2026-10-24）

**ACCEPTED PRODUCT SCOPE / ENGINEERING DIRECTION, NOT MODEL RELEASE APPROVAL.** 首批產品制度為 **2/1 Game Force、SAYC、Precision Club**；玩家未來可複製基本制度並修改經支援的約定。必須同時保證 AI 依制度做決策、解釋叫品及更新搭檔／對手的牌型與牌力估計，而不只是 UI 顯示。

技術優先順序：原生 BEN `21GF/SAYC` 證據優先 → 另做 Precision BBA 隔離 PoC，若權利或品質不符合要求則改採自有規則器／專用模型 → verified-only 自訂約定 → 教練／競賽。**Meckwell Lite Precision 是推薦研究候選，非使用者批准的唯一精準制版本；所有具爭議的點力範圍及競叫細節仍需專家審核。**

完整規格：[三制度正式主計畫](product/THREE_SYSTEM_BIDDING_AI_MASTER_PLAN.md)。M1.1 scope / CI：[BEN 多制度技術 Spike](research/BEN_MULTI_SYSTEM_M1_SPIKE.md)。既有 M2/B3、B6、A3.5/device hold、production release gates 保留；BEN 模型宣告 `playsSystems` 不等於 AI 真實叫牌通過，BBA 未明確授權不得視為可正式發行。


Each item has status and rationale. Proposed choices are not approved simply because they appear here.

## ADR-025 — Product delivery split and device acceptance freeze (2026-10-15)

**ACCEPTED PRODUCT DIRECTION; NOT RELEASE APPROVAL.** Continue Bridge Academy as one-person + three BEN AI first, with reusable five-entry product information architecture and replay/learning loop. Preserve M1/M2 history. A1 canonical BoardDefinition is already scoped engineering-verified; A2 checkpoint/security work has partial Core/Web evidence and later encrypted backends but remains missing full deployment, native hardware and remote request idempotency acceptance. The next UI feature slice is **A3 Bridge Table UI V2**, componentized around player/seat-filtered presentation rather than augmenting one monolithic `bridge_app.dart`.

**Daily challenge decision:** Early B6/P1 may be a local, reproducible, **unranked original practice** set (with no public comparison, MP/IMP percentages, prize or leaderboard). Authentic ranked daily Duplicate and async friend comparisons remain D/P3, dependent on server-generated immutable board sets, trust boundaries, comparative scoring and fair-play controls. DDS remains post-game analysis, not omniscient in-play AI.

**QA owner hold:** Do **not** auto-trigger, manually dispatch, schedule or re-enable Android emulator/physical Android/iOS UI/E2E tests until the owner explicitly approves a separate test plan. Both existing Android AVD workflows were disabled on master; treat platform acceptance as deferred but mandatory before release. Preserve quick static/unit/Widget/Web build checks and currently permitted Chrome/real BEN regression; do not claim device GO based on them. This is a workflow decision, not cancellation of final mobile validation.

Authoritative product references: [PRD v1](product/BRIDGE_ACADEMY_PRD_V1.md), [delivery roadmap](product/PRODUCT_DELIVERY_ROADMAP.md), [official-source benchmark](product/COMPETITOR_BENCHMARK.md). No application source was modified by this ADR.

## ADR-024 — A2.8 encrypted Web local checkpoints, not a transaction guarantee (2026-10-15)

**ACCEPTED FOR IMPLEMENTATION; CI PENDING.** Web must not continue persisting four private hands in plaintext SharedPreferences. Reuse SavedBoardCodec and AES-256-GCM, browser WebCrypto-backed key via flutter_secure_storage and a **single origin-local record** in SharedPreferencesAsync, with validated-then-committed legacy plaintext migration. On HTTPS/localhost failures **fail closed** and never silently write plaintext. Surface localized browser-security notice. Web key handling is experimental; same-origin XSS/hostile extensions, cross-tab CAS and crash durability remain open. Not SQLite ACID or release approval. [Acceptance](product/P1_A2_8_BROWSER_ENCRYPTED_CHECKPOINT_ACCEPTANCE.md).

## ADR-023 — A2.7 authenticated native transactional checkpoints (2026-10-15)
**ACCEPTED FOR IMPLEMENTATION, CI PENDING.** Use AES-256-GCM with fresh nonce for complete four-hand transcript, 256-bit secret in native secure storage, atomic SQLite row commit containing encrypted active and prior generation with durable recoveryPending, and validated legacy SharedPreferences migration. BridgeSession still depends on SessionArchiveStore and never emits privileged transcripts to UI. Web intentionally retains legacy storage and is **not production confidential**. The owner requested delaying Android/iOS physical-device QA until major product features are complete; fake database/crypto tests cannot prove native power-loss behavior. Key-loss, backup policy, browser threat model, cross-process CAS and BEN network exactly-once remain open. [Report](product/P1_A2_7_SECURE_TRANSACTIONAL_STORAGE_ACCEPTANCE.md).

## ADR-022 — A2.5 consent survives restart (2026-10-15)
**ACCEPTED AND FLUTTER WEB ENGINEERING VERIFIED ([CI #38738604483](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38738604483), 50/50 PASS).** After two-slot checkpoint rollback, requiring explicit acknowledgment only in BridgeSession memory is unsafe: a second application launch makes the previous valid checkpoint appear ordinary. Include optional recoveryPending in the active commit marker; persist it with the marker repair, and clear only after awaited explicit player consent. A write error leaves human/bot actions paused. Existing v2 markers without the field default to false for migration compatibility. This is a best-effort local UI safeguard, **not** encryption/ACID/fsync, anti-cheat or remote BEN exactly-once. Follow-up: evaluate secure transactional storage and physical device failures.

## ADR-001 — Incremental product
**ACCEPTED 2026-10-15**: Single-player three-BEN-bot MVP first; later teaching and multiplayer/duplicate. Reason: isolate AI and correctness risks before spending on real-time infrastructure.

## ADR-002 — Backend AI initially, mobile UI later
**ACCEPTED IN PRINCIPLE**: BEN runs as an isolated Python service for POC/M2. Fully offline AI is deferred; never imply single-player = offline.

## ADR-003 — Independent authoritative rules
**ACCEPTED**: an implementation-independent Bridge Core owns rules, turn, outcome and scoring; BEN suggests actions. For multiplayer, server takes authority.

## ADR-004 — POC-002 Pass Out policy
**ACCEPTED 2026-10-15**: three visible PASS calls plus BEN reported PASS outcome count as outcome-level pass with TRANSCRIPT_WARNING; do not assert the fourth actual call occurred. Full transcript replay requires explicit chronological calls. Do not forge missing PASS.

## ADR-005 — POC status taxonomy
**ACCEPTED**: POC-001 GO (one real deal; evidence cited from user Work summary). POC-002 outcome GO (97 completed deals, 3 PASS outcomes) but full-transcript audit 98/100 and production sign-off CONDITIONAL. All findings bound to measured BEN configuration.

## ADR-006 — Core implementation language
**PROPOSED**: pure Dart bridge_core for initial Flutter compatibility. Reassess before M1 execution; avoid coupling domain core to Flutter widgets.

## ADR-007 — Convention cards
**PROPOSED**: versioned ConventionProfile separate from legality; do not claim BEN obeys arbitrary agreements.

## ADR-008 — Licensing
**OPEN**: first-party project license and commercial mode undecided. BEN GPL obligations and weight licenses must be cleared before publishing or distributing an integrated binary.

## ADR-009 — Learn While Building: feature teaching deliverables
**ACCEPTED 2026-10-15**: Each independently testable, accepted functional feature requires a dedicated Traditional-Chinese Feature Learning Note, an index entry and a short interactive concept/question at completion. Explain actual source and tests, engineering trade-offs and accessible Android/Kotlin parallels; keep engineering approval separate from learner mastery. See docs/learning/README.md and skills/bridge-learning-mentor/SKILL.md. Routine chores without new behavior do not require fabricated lessons.

## ADR-010 — M2 filtered views and local game authority
**ACCEPTED FOR M2 ENGINEERING IMPLEMENTATION 2026-10-15**: Bridge Core maintains full privileged GameState. External player/Bot access must pass through a seat-filtered PlayerView; dummy cards are publicly visible only after opening lead. SinglePlayerCoordinator is private-state local authority, rejects stale human versions and validates BotPolicy proposals. DeterministicTrainingBot is a rules smoke-test substitute, never BEN. True BEN Adapter and Flutter UI are separate future features. See docs/m2/M2_FOUNDATION_REPORT.md.

## ADR-011 — BEN per-seat HTTP adapter, independent live gate
**ACCEPTED FOR M2 IMPLEMENTATION 2026-10-15:** adapter depends on PlayerView only and uses real HTTP transport with mockable client; BEN /bid /lead /play are individual proposals, Bridge Core is authority. Only own/known dummy and public history may be sent. Official dummy seat documentation differs; real BEN smoke replay is mandatory for production acceptance. Prior POC real 100-deal runs do not automatically prove this new adapter works.

## ADR-012 — Direct pushes and native BEN validation
**ACCEPTED 2026-10-15:** User requested no more PRs; push to master directly, preserving CI, learning notes and revertability. M2-F04 uses pinned BEN Python 3.12 native runner and a full-game Dart test; PASS requires a real successful CI run, not Mock or pre-existing POC reports.

## ADR-013 — M2-F05 local Flutter UI shell
**ACCEPTED FOR FIRST UI SLICE 2026-10-15:** A small ChangeNotifier BridgeSession sits on SinglePlayerCoordinator and PlayerView. Never replicate legality inside Widgets; explicitly separate Demo and real BEN modes without silent fallback. Fixed PBN enables deterministic GUI tests; zh-TW/en UI copy is centralized. Web CI and Widget Tests do not replace native/device testing.

## ADR-014 — Browser QA is a distinct integration gate (2026-10-15)
M2-F06 adds browser-level ChromeDriver and responsive Flutter testing, independently of existing Dart Widget Tests. Keep model mode explicit: Demo tests cannot be called BEN integration. Device/browser target acceptance and real BEN UI interaction must use evidence from the matching executable, not inferred CLI results.

## ADR-015 — Native BEN + Flutter Chrome UI gate (2026-10-15)
M2-F07 must use pinned upstream BEN on localhost with matching actual ChromeDriver and Flutter integration_test. A route-counting transport must delegate to real HTTP; no mock/fallback acceptance. Full 52-card/13-trick and score verification are mandatory. Do not call this gate GO until GitHub Actions truly passes. BEN reduced sampling/PIMC-off remains an integration fixture, not production strategy/latency approval.

## ADR-016 — M2-F10 separate deterministic fixtures from fresh local practice (2026-10-15)
**ACCEPTED FOR SINGLE-PLAYER M2 ENGINEERING:** Keep the original training deal as the default to preserve reproducible benchmarks and true BEN integration tests. Offer explicitly selected fresh local deals via pure-Dart shuffled Deal; test random behavior with injected freshDealFactory and fixed seeds. Exact replay requires PBN, not only a seed. Do not expose raw four-hand deals through Flutter PlayerView or claim client-owned randomness ensures multiplayer fairness.

## ADR-017 — M2-F11 Replay from canonical events, filtered to PlayerView (2026-10-15)
**ACCEPTED FOR M2 IMPLEMENTATION:** No replay access before terminal state; construct historical player snapshots using BridgeGame.apply from the private starting Deal and authoritative GameEvent log, cross-check version/fingerprint/NS score. Return only immutable frames with seat-authorized PlayerView and publicly played action (never GameState, unfiltered GameTranscript, or full PBN). Flutter replay is read-only and limited to the current completed deal, without persistence, undo, DDS, or BEN re-evaluation.

## ADR-018 — Product journey first; official-source benchmark and product gate (2026-10-15)

**ACCEPTED PRODUCT DIRECTION.** The user approved evaluating 新睿橋牌 and Bridge Base Online as product benchmarks and writing docs/product/COMPETITOR_BENCHMARK.md, docs/product/BRIDGE_ACADEMY_PRD_V1.md and docs/product/PRODUCT_DELIVERY_ROADMAP.md before advancing functional implementation.

1. Prioritize a **complete single-player one-human + three real AI experience** (play, durable resume, score, history, next board) before tournaments or human multiplayer. Adopt five delivery phases A Playable → B Training → C Analysis → D Async Duplicate → E Live Multiplayer.
2. Distinguish MODULE ENGINEERING PASS from FEATURE READY and PRODUCT READY; reproducible fixed-board BEN CI is **not** evidence of production AI service or human-usable App.
3. Product scope and sequencing live in docs/product; existing docs/ROADMAP.md remains historical engineering CI evidence. Bridge rules and security boundaries remain owned by docs/BRIDGE_RULES_BASELINE.md and docs/ARCHITECTURE.md.
4. Next prioritized slice A1 is canonical 16-board Board Number/Dealer/Vulnerability plus localized presentation, with all existing replay, privacy and score rules preserved.
5. Competitor functionality informs original design but does **not** authorize source/asset/puzzle/convention copying. BEN GPL, model weights and service privacy remain release blockers until reviewed.
6. Proposed performance targets, revenue/account requirements, tournament method, actual default AI convention compatibility and launch platform eligibility are **NOT YET APPROVED** as technical facts; they need their own review and observed acceptance.

No Bridge Core gameplay implementation was changed in this documentation-only decision commit.

## ADR-019 — Phase A1 board metadata is Domain-owned (2026-10-15)
**ACCEPTED FOR IMPLEMENTATION (Core/Flutter engineering tests verified).** WBF Duplicate Law 2 defines 1-based Board Numbers, dealer order N/E/S/W and the 16-board vulnerability cycle. A pure-Dart BoardDefinition supplies metadata; BridgeSession passes it to the coordinator, so UI, Bridge Core score and BEN protocol all share the same source of truth. Current game re-deal keeps board number, replaySameBoard preserves physical cards, nextBoard is permitted only for terminal boards and advances sequence. The fixed teaching PBN may repeat with new board metadata only when explicitly chosen as a fixture, never marketed as a fair multi-board tournament. Persistence and server-authoritative competition are future separate gates. No existing legality/scoring reducer rule changed.

## ADR-020 — A2 checkpoint prototype: event validation before trusting local saves (2026-10-15)

**ACCEPTED FOR ENGINEERING PROTOTYPE, NOT PRODUCTION DURABILITY (Core+Web CI verified).** Store a versioned event transcript plus board metadata in an injectable local SessionArchiveStore. Validate every restored move with GameTranscript.decode + BridgeGame.apply and compare 1-based BoardDefinition metadata, event version and noncryptographic fingerprint. Commit each player action before bot execution; persist each legal bot event before requesting the next action. If write fails, stop and require explicit retry.

Initial Flutter adapter uses SharedPreferencesAsync only to validate cross-platform restoration. The official library is not for critical data and does not promise fsync/durability, encryption or security against device access. This remains a release blocker until replaced with atomic, encrypted, migration-tested storage and real device kill/relaunch QA. An in-flight BEN HTTP request may be repeated after crash; no remote exactly-once guarantee until backend idempotency exists. Complete four-hand PBN stays in privileged local storage only, never ordinary UI or playing AI.

## ADR-021 — A2.2 two-slot rollback checkpoint before encrypted release store (2026-10-15)

**ACCEPTED FOR ENGINEERING HARDENING; release encryption gate remains OPEN.** Replace the single SharedPreferencesAsync checkpoint key with two independently validated slots plus a last-written active marker. Preserve the last committed checkpoint across a failed pending-slot write or marker write; after corruption, permit rollback to the previous fully validated legal transcript, never fabricate events. Support validation-led v1 migration; do not remove the old key before v2 commits. Use SHA-256 as a non-secret corruption checksum, **never call it encryption/HMAC**. SharedPreferences is not ACID or crash-durable; true encrypted local transactional storage, concurrency protection, truthful recovery warnings, physical-device kill/relaunch and BEN server idempotency remain release blockers. See docs/product/P1_A2_2_CHECKPOINT_HARDENING_ACCEPTANCE.md.

## ADR-021 — Distinguish real Android app process restart from durability under power loss (2026-10-15)

**ACCEPTED FOR ENGINEERING QA; CI PENDING.** Before treating A2 SharedPreferences checkpoints as a viable player-resume feature, test two distinct Android app launches with OS force-stop in between, validate exact event version/fingerprint after restoring an unfinished legal game and submit a new action without duplicate committed events. Keep the A2.2 checkpoint/Bridge Core rules unchanged. This is not proof of fsync, transactional or encrypted disk, process kill during pending writes, concurrent writers, real BEN exactly-once, or app release readiness. These remain separate P0 gates.

## Future ADR required
Persistence event format, AI fallback policy, identity/multiplayer authority hosting, offline model strategy, baseline conventions, PBN serialization, terminal claim/concession rules.

## ADR-020 — Local rollback must be visible to the player (2026-10-15)

**ACCEPTED FOR ENGINEERING; Flutter/Chrome CI VERIFIED.** A2.2 previously recovered an older legal two-slot checkpoint silently when the current committed generation was corrupt. A legally valid earlier snapshot is not proof of full data durability, so the store now reports a nonsecret recovery flag and the Session blocks human/Bot actions until the user acknowledges possible lost actions. Flutter offers localized warning and continuation, not an implicit decision. This is for unranked local training only; preserve A2 product blockers for encrypted/fsync-safe storage, concurrent-writer control, release migration, remote AI request deduplication and device QA. [A2.4 acceptance](product/P1_A2_4_ROLLBACK_NOTICE_ACCEPTANCE.md).

## ADR-026 — Owner-deferred A3.5 and A4 HTTPS gateway-client seam (2026-10-16)

**ACCEPTED FOR DEVELOPMENT, NOT RELEASE.** Owner explicitly postpones A3.5 final UI/physical device/assistive UX acceptance, and authorizes proceeding to A4. A3.1–A3.4 scoped Flutter/Web/true BEN CI remains valid, but A3 product acceptance and all physical Android/iOS or Android emulator UI/E2E are **NOT VERIFIED / HELD** until an explicit later approval.

For A4.1 adopt an optional, reversible `BenGatewayTransport` implementing the existing `BenTransport` interface, but sending **HTTPS POST** with a versioned JSON envelope, allowlisted fields, sanitized errors, no redirects, bounded response, no implicit retry and injected short-lived credential provider. Existing `BenHttpTransport` GET remains for trusted development/native BEN CI only; never make it public. Compiled-in bearer tokens are forbidden. Domain Bridge Core, not a Gateway/BEN response, always commits and validates an action.

Alternatives rejected: direct public BEN GET (private hands exposed in URL and no authorization/quotas), bundling BEN model with mobile application before weights/runtime/license audit, and client-side embedded API secrets. Authentication, anonymous session bootstrap, rate limiting, server-side replay deduplication, hosting and BEN private upstream/service logs belong to A4.2+ and **are not implemented or hosted by A4.1**. BEN GPL-3.0/model weights need formal release review. [A4 contract](product/A4_GATEWAY_CONTRACT_V1.md).

## ADR-027 — A4.2 loopback-only anonymous Gateway prototype (2026-10-16)

**ACCEPTED FOR LOCAL DEVELOPMENT; NOT A DEPLOYMENT AUTHORIZATION.** Build the smallest reversible Dart Gateway that implements the A4.1 versioned decision envelope behind an anonymous, expiring bearer **capability**. It binds loopback only and is safe to use for local HTTP contract tests. It is deliberately not a public identity provider or a BEN orchestration layer.

A4.2 issues 256-bit cryptographically random opaque tokens, retains only SHA-256 digest mappings in memory, enforces per-TCP-peer bootstrap and per-token decision rate limits, one in-flight decision per token, CORS allowlist, request-size and payload allowlists and safe response shaping. **Default upstream is 503 unavailable**; tests inject a fake decision backend. This stage does not claim HTTPS public hosting, production authentication/seat ownership, multi-instance durable quota, action idempotency or real BEN. Exposing it on the Internet is prohibited without separate threat-model, auth/deal authority and deployment sign-off.

Chosen over a new permanent account system (contradicts MVP no-login direction) and a shared Flutter API key (extractable and not individually rate-limited). Memory-only tokens simplify local validation but invalidate after restart and must be replaced/strengthened for deployed operation. A4.3 adds isolated BEN worker and stable request identity; A4.4 integrates Flutter after authorized TLS hosting; A4.5 reviews measured costs, licensing and physical device gate. [A4.2 acceptance](product/A4_GATEWAY_A4_2_ACCEPTANCE.md). Owner-deferred A3.5 remains OPEN.

## ADR-028 — A4.3.1 BEN Worker permits only literal loopback network access (2026-10-16)

**ACCEPTED FOR LOCAL DEVELOPMENT, NOT PUBLIC HOSTING.** Preserve the A4.1 POST boundary and A4.2 anonymous capability quota. BEN's pinned Python `gameapi.py` continues to use GET with the current robot's original 13 cards; that query may contain private data. Therefore the new outbound `BenLoopbackBackend` accepts ONLY a literal `127.0.0.1` or `::1` HTTP origin; no DNS hostnames, proxies, redirects, credentialed URI, custom path or query. Validate request field allowlist, bound response and timeout and project only one `bid`/`card` proposal. Errors and debug payload never reach the public response. Default backend still 503 unless explicitly configured with `BEN_INTERNAL_ORIGIN`. An optional private GET is **not** a public authenticated BEN API.

**Deferred A4.3.2:** Bind each anonymous/session credential to a server-owned game and acting seat, derive PlayerView server-side and implement expected version + stable request identity/durable dedup, instead of trusting a user-supplied hand. **Deferred A4.3.3:** exact pinned BEN Python/model CI and performance/resource measurements. An A4.3.1 fake HTTP test does NOT prove model quality or external service deployment. [Acceptance](product/A4_GATEWAY_A4_3_1_ACCEPTANCE.md).

## ADR-029 — Server-owned, session-bound single-player authority before public deployment (2026-10-16)

**ACCEPTED FOR DEVELOPMENT ONLY.** Build `AuthoritativeGame` on existing `SinglePlayerCoordinator` and `BenBotPolicy`, not another duplicate bridge engine. Each anonymous token binds exactly one server-generated training Deal (human seat N), with only `humanView` serializable. Human requests provide `kind/call` or `kind/card` plus `expected_version` and `request_id`, but never seat/hand/PBN/Deal. A mismatched version or conflicting request identity is rejected (409); a repeated successfully committed event may use an in-memory cached response. BEN is asked using the robot's real filtered PlayerView.

The reply ledger is bounded and volatile. Crash-safe replay, exactly-once semantics, partial interrupted Bot batches, durable game ownership, public TLS, distribution rights and disabling legacy raw caller-hand route are **not solved**. Existing dev-only raw `/v1/ai/decision` cannot be exposed on the Internet. [A4.3.2 acceptance](product/A4_GATEWAY_A4_3_2_ACCEPTANCE.md). A3.5/device QA remain deferred, not waived.

## ADR-030 — A4.3.2b optional encrypted local checkpoint and bot-event recovery (2026-10-16)

**ACCEPTED AS LOCAL DEVELOPMENT SLICE, NOT DEPLOYMENT APPROVAL.** An opt-in `EncryptedSessionStore` uses AES-256-GCM with a 32-byte external key and atomic per-session rename of the snapshot, where the filename is SHA-256 of bearer capability and the ciphertext contains the privileged replayable Bridge Core archive, token expiration, pending request ID and bounded completed request replies. This avoids plaintext four-hand PBN or bearer token on disk/logs. Wrong key, malformed store or failed persistence fails closed; a newly issued bearer is not acknowledged until its checkpoint exists.

Bot batches commit and checkpoint after every validated Bridge Core event, so an interrupted request can resume using the **same request ID**, bypassing the *initial* version check only for its exact pending payload; all subsequent Bot proposals still pass through Bridge Core. New requests during pending fail 409; successful retries return persisted responses without reapplying. Legacy caller-submitted `/v1/ai/decision` is disabled in encrypted durable mode, while ephemeral localhost development regressions remain available. New `cryptography` dependency is the pure-Dart AES-GCM package; review pinned license/dependency locks before distribution.

**Not solved:** process power-loss fsync-directory guarantees, external key vault/rotation/backup, durable per-IP limits, multi-node locks/idempotency, indefinite reply ledger (bounded at 128), response after a key is lost or expired, production HTTPS, true full-game BEN resource validation, and owner-held A3.5/device QA. [Acceptance](product/A4_GATEWAY_A4_3_2B_ACCEPTANCE.md).

## ADR-031 — Full pinned real BEN Gateway game as a separate acceptance gate (2026-10-16)

**ACCEPTED FOR SCOPED DEVELOPMENT, NOT RELEASE.** Earlier full-game real BEN native adapter tests and three-route Gateway real BEN smoke both passed, but neither alone verifies a full game through the newer session-owned Gateway route. Add `live_gateway_ben_full_game.dart` using the same fixed non-secret native BEN full-game fixture, injected ONLY into the server by an explicit test-only `dealFactory`; keep the client limited to `/v1/games/view/action/advance`. Human North opens synthetic 3NT for repeatability, then passes/chooses legal cards. BEN genuinely proposes all other acting seat decisions. Termination requires exactly 52 unique cards, 13 tricks, scoring, version consistency and bid/lead/play route coverage; negative/failure diagnostics must not print private cards, PBN, bearer or BEN GET URLs. CI reuses the pinned model environment in the A4.3.1 smoke to avoid repetitive expensive downloads.

Alternatives rejected: (1) treating MockClient or 3 API smoke as full-game evidence; (2) calling the native BEN adapter directly and bypassing Gateway authorization; (3) feeding the entire Deal to BEN to simplify testing (privacy violation). True full-game CI evidence must be recorded before claiming SCOPED PASS. Full hosted, license, operations/cost, memory, cross-seat and A3.5/device QA remain blockers. [Acceptance](product/A4_GATEWAY_A4_3_3_ACCEPTANCE.md).

## ADR-032 — A4.4 separate Flutter Gateway state controller with explicit opt-in (2026-10-16)

**ACCEPTED FOR LOCAL/CONTROLLED ENGINEERING, CI PENDING.** The existing `BridgeSession` owns an in-process `SinglePlayerCoordinator` and is kept intact for Demo and direct local BEN development. Introduce `GatewayGameSession` and `GatewayTable` instead of making the Flutter client pretend it is still the authoritative owner of the four-hand Deal. The app selects this mode ONLY via explicit `BRIDGE_GATEWAY_ORIGIN` or injected test API; invalid configured origin does not fall back. HTTPS is mandatory except for local loopback development; server-side CORS is explicit, not '*'. Credentials remain only in memory. Lost response after server commit is handled by querying authority and reissuing **the original ID/expected version**, never a new action.

The first A4.4 release does not persist bearer or guarantee refresh resume, does not deploy public TLS, and does not allow arbitrary player seat selection or competitive ranking. A4.5 reviews secure infrastructure/model rights/operating budget. Continue owner-deferred A3.5 and mobile/emulator QA freeze. [Acceptance](product/A4_GATEWAY_A4_4_ACCEPTANCE.md).

## ADR-030 — A5.1 encrypted terminal-only history, separate from active checkpoint (2026-10-16)

**APPROVED DEVELOPMENT SLICE.** Keep the current Bridge Core / SinglePlayerCoordinator as history replay authority. Persist only completed canonical session snapshots to an AES-256-GCM encrypted secondary history collection with separate native DB/browser key and purpose-bound AAD, maximum 12 records and 320KiB plaintext. Expose only player-safe HistorySummary and CompletedReplay frames to Flutter. An optional per-session historyId is persisted in SavedBoardCodec for restart dedup and distinct same-board attempts; legacy checkpoints remain readable. Completion/archive failure leaves the active checkpoint intact and is explicitly retriable.

Alternative (rejected): plaintext JSON list of full four-hand GameState in SharedPreferences or passing privileged snapshot to Flutter UI. Search, deletion, portability, gateway server history, multi-tab arbitration and certified native/web persistence remain separate A5.2/A5.3 work. [A5.1 acceptance](product/A5_1_HISTORY_ACCEPTANCE.md).

## ADR-034 — Explicit declarer-training starting state, no synthetic auction (2026-10-16)

**ACCEPTED FOR LOCAL TEACHING:** create a separate `GameState.justDeclareStart` for preconfigured valid contract (level 1–7, no doubling), with the opening lead as first action, zero auction calls and v2 Canonical Transcript preserving trainingContract. Ordinary `GameState.start` is unchanged; Core action legality and duplicate scoring remain single-source. No PBN export as ordinary auction if none occurred. Flutter offers North declarer, South Dummy and a clearly marked rules-demo Bot until actual no-auction BEN compatibility is established. This is local practice only, not competition, hosted AI, ranking or Android/iOS device acceptance. [B2 acceptance](product/B2_JUST_DECLARE_ACCEPTANCE.md).

## ADR-035 — B2.2 non-auction Just Declare respects the selected declarer seat (2026-10-16)

**ACCEPTED FOR LOCAL PRACTICE; NOT A REAL BEN BIDLESS CLAIM.** Retain ADR-034's independent `GameState.justDeclareStart` and v2 transcript. Extend the Flutter entry point from North-only to the four actual Seat values using the existing player-seat selector. The `Contract.declarer`, `Contract.dummy`, opening leader, game progression and contract target belong to Bridge Core, not an inferred UI string. An explicit `justDeclareContract` is handed to `SinglePlayerCoordinator`, and replaying the identical teaching deal preserves it instead of reverting to a normal auction. Just Declare is isolated from an unfinished ordinary game and B1 practice. Display declarer-side tricks and completed target outcome; do not treat NS score sign as everyone's made/down verdict. Never make up an auction to call BEN or export a standard PBN. [Acceptance](product/B2_JUST_DECLARE_ACCEPTANCE.md).
