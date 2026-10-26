# Bridge Academy｜研究與驗收整合報告

> 更新：2026-10-26。此檔是現行唯一研究報告，整合 BEN、Precision、自訂約定、開源／授權、平台 UX。可用 Git 歷史還原先前 190 份文件的完整驗收與教學資料；刪除 docs 文字不等於移除原始碼／測試。

## 證據定義

| 狀態 | 能證明 | 不能代表 |
| --- | --- | --- |
| IMPLEMENTED | 有程式及可追測試 | 已正式營運或已上架 |
| SCOPED VERIFIED | 指定 SHA／環境／fixture 的實測成功 | 所有裝置／長時間／完整品質已過 |
| RESEARCH ONLY | 有獨立原生或模型可行性證據 | 正式可玩制度、競賽牌力 |
| NOT RUN／BLOCKED | 尚無完成證據 | 不能自動標成 PASS |
| RELEASE NO-GO | 尚缺發行要件 | 不等於證明技術不可能 |

## 精確來源與模型雜湊（規格追溯，不構成授權）

- BEN source：`lorserker/ben@ad8608af6e6bfe095863023f344f3cb2cbafec3d`。本次多制度研究使用候選固定版；既有 BEN smoke 的舊版 pin 不得未經驗收就取代。
- 21GF bidder：`BEN-21GF-8742_2026-10-22-E30.keras` SHA-256 `33ff95fe85ed29c9b1c1cd5ac8d6f9516f7d3d4547b17384fbdfadba56f69efd`。
- 21GF info：`BEN-21GF-8742-Info_2026-10-22-E30.keras` SHA-256 `486a692d9e517fc9dd96728f55040044af5fb787c3807605665f17fff3473cec`。
- SAYC bidder：`BEN-Sayc-8730_2025-04-20-E30.keras` SHA-256 `6824fb96264d6536709b3c4d3fa989f321f5886662cfcb3a0e5c1e3c5cb67c32`。
- SAYC info：`BEN-Sayc-Info-8730_2025-04-20-E30.keras` SHA-256 `b87513a3f40fbdee65bc53977f6746c3c9cd4816de276bf3adcbbd2d44113abc`。
- BBA Meckwell V1 原生 Convention Card：`BBA/CC/Meckwell.bbsa` SHA-256 `5c2a6c8d84094a0a9efd2cefe98a93983185140e6bde81b2520086b8b27d9cbc`。
- 逐項 SHA 由 [model inventory](../../scripts/ben_m12_inventory.py) 和原生研究 CI 驗證。**雜湊辨識與模型／native binary 商用託管／再散布權利完全不同**。


## BEN：2/1 與 SAYC 兩制度

固定 BEN 上游 `ad8608af6e6bfe095863023f344f3cb2cbafec3d`，Python 3.12.15／TensorFlow 2.21.0／Keras 3.15.1。BEN `playsSystems` 有 21GF-GIB、21GF、SAYC；`BEN:` 對手設定為 read-only，Precision 不屬於其 Neural 可玩制度。

| 階段 | 實測與證據 | 判斷 |
| --- | --- | --- |
| M1.1 | systems.conf／模型／Mock 靜態驗證 | 靜態通過，不是 API |
| M1.2 | 真 BEN `GET /`、模型 SHA；[CI #40075250217](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40075250217) | 開機 9.03 秒、RSS 輪詢約 879MiB；當時尚未跑 /bid |
| M1.3 | [真 BEN CI #40076846012](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40076846012)，16 組情境 × 21GF／SAYC | **32/32 /bid**、基本合法性與未知制度 400 檢查通過、3 個抽樣 forcing 未出現 PASS、1 組差異 |
| M1.4 | 同版本單 Worker 並行 1／2／4、雙 Worker 監測 | GitHub Runner 限定小樣本，非 VPS |
| M2.1～M2.5 | 不可變 NS/EW `GameSystems`、Gateway/Adapter/Flutter 選型、[真雙局 CI #40087851963](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40087851963) | 兩種相反配對各完整 52 張／13 墩，有效計分；不是專家制度品質認證 |

## M1.4 效能觀察

[CI #40076200888](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40076200888)，單 Worker 每組 16 requests：c1/c2/c4 p50 = 26.0／35.3／78.7 ms，p95 = 89.2／98.2／126.1 ms，throughput = 28.6／38.3／42.3 req/s。兩個 Python Worker 合計輪詢 RSS 約 **1.95 GiB**，單 Worker 約 **1.01 GiB**。較新 [CI #40076846012](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40076846012) 也 success，c1/c2/c4 p95 約 110.3／130.5／161.0ms；顯示短時測量會波動，不能拿來推定穩態 SLO。CPU 時間主／次約 2.25／1.71 CPU-seconds（不是實機 CPU %）。

測試使用降低模擬負擔的 NN-biased BEN 配置，BBA/PIMC/SuitC 停用；不是 2vCPU／4GB VPS 實測，亦不是完整版 BEN。研究初步傾向**單 Worker 多模型＋有界 queue**；公開服務仍 **NO-GO**。

## 限制與重現

16 組情境未經橋牌專家逐一審核，兩制度只有 `1S–P–2H–P` 情境回應不同（曾觀察 21GF `4H`，SAYC `3H`）。**不同不等於更好或正確**。100+ expert golden、完整服務成本、長時真 bid/lead/play、模型權重與 native binaries 的商用再散布權利仍是 release gate。

工具：[benchmark](../../scripts/ben_multisystem_benchmark.py)、[fixtures](../../scripts/fixtures/ben_multisystem_m13.json)、[CI](../../.github/workflows/ben-m13-m14.yml)。原始詳表可查前一版 Git 歷史／Actions artifact。

## Precision Club 研究

**ENGINEERING RESEARCH PASS／COMPETITIVE PRODUCT NO-GO**。

## 已確認的制度與引擎

產品唯一釘選變體 `BA-PRECISION-MECKWELL/r1`，原生 BBA／EPBot `Meckwell.bbsa`，**1NT＝13–15 HCP**。這與外部 Meckwell Lite 13–16 不相容，不得混版。BEN Neural `playsSystems` 不含可玩 Precision，也沒有經證明的 Precision neural opponent reader；本研究透過獨立 [bridge_precision_adapter](../../packages/bridge_precision_adapter/) 與 [原生 sidecar](../../scripts/precision_m33_sidecar.py) 提出叫牌，再交 Bridge Core 判合法。

## 真實測試

| 測試 | 實際證據 | 限制 |
| --- | --- | --- |
| 原生 Precision spike | [CI #40092096757](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40092096757)：8 次開叫、4 個強 1♣ 候選 | 非整局，不是正式最優叫牌 |
| 原生 Provider | [precision-m33-provider](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/precision-m33-provider.yml) | 只在固定真 BBA artifacts 且白名單下執行 |
| mixed partnership | [CI #40103865733](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40103865733)：SAYC／Precision 及 21GF／Precision 配對研究，固定整局 52/13 | 出牌是合法訓練策略，不代表高牌力 |
| 原生開叫效能 | [CI #40102968596](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40102968596)：1000/1000 次原生 **開叫 API**，p50 9.46ms、p95 12.96ms、約 77MiB RSS；[重測 #40103865733](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40103865733) p50 7.05ms、p95 10.03ms | **不是 1000 副完整牌局**，也不是 BEN 全模型記憶體 |
| 出牌推論研究 | [CI #40105701070](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40105701070)：使用真 BBA `find_info` 推估各座位花色長度，再只在 `PlayerView.legalCards` 選牌 | 研究啟發式，非訓練好的 Precision-aware neural cardplayer |

## 證據不足之處

尚無專家審核的充分 forcing／競叫／Alert Golden corpus、同牌同種子 MP/IMP 對照、1000 副完整隨機牌局、目標 VPS 長時負載、Android/iOS QA 或完整發布授權檔。使用者已表示 BBA 許可涵蓋必要使用，**仍須逐一保存原始許可條款、版本、SHA 和 notices**；不以口頭授權自動推定所有其他原生 binary 與模型 weights 可再散布。

相關 [固定 Precision 規格](RESEARCH_REPORTS.md)、[產品下一階段](../planning/ROADMAP.md)、[發布門檻](../planning/ROADMAP.md)。

## 自訂約定與公開叫牌教練

**工程功能已實作，完整可玩自訂 AI／最佳叫品教練未完成。**

## M4：安全的本機草稿

已實作 SAYC／2/1 有限 Convention Card 編輯、碰撞／Schema 驗證、不可變 SHA 鏈結 revision、版本 diff、fast-forward-only 備份匯入、公開 auction 上的使用者規則意義預覽、專家審查待辦。Gateway 對 `customDraft`、偽造 `SUPPORTED`、不符合法定 allowlist 的 profile 明確拒絕；已編輯卡標 `ENGINE_UNVERIFIED`，**不能改 BEN/BBA 的真實模型決策**。

實測：[M4 Domain 30/30 + Flutter 6/6 #40139400430](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40139400430)；[Gateway 49/49 #40139293120](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40139293120)。專家審查包的所有情境 **NOT REVIEWED／NOT RUN**，不是 100 個 expert Goldens。

## M5：來源可核對的公開叫牌教練

已實作 `PublicAuctionCoach`、雙語 Flutter 頁面、Gateway 完局公開 auction review。根據 dealer、公開叫品、NS/EW 固定 profile 與 fingerprint 顯示來源；無已驗證規則回 `UNKNOWN`，本機草稿標 `USER_DRAFT`。不讀別人的隱藏手牌，不宣稱解釋 BEN 內部推理。

[真 M5 CI #40154923631](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40154923631)：Conventions 36/36、Flutter Widget 5/5、analyzer PASS。真 AI 候選比較、來源專家核准、使用者手機完整 E2E 尚 **NOT RUN**。

## 仍未解決

需要可信的自訂約定引擎能力白名單、雙向 opponent-reader、artifact hash、迫叫／競叫／Alert 100+ 專家 Golden，才能准入可玩自訂制度。AI Coach 若要提供最佳叫品，須有可重現 BEN/BBA 及專家評分，不能虛構。

下一步與發行障礙見 [Roadmap](../planning/ROADMAP.md)／[Release](../planning/ROADMAP.md)。

## 模型／原生授權與目標 VPS

截至 2026-10-26，**研究通過 ≠ 正式商業發布授權**。

| 元件 | 目前用途／版號 | 未通過的發行條件 |
| --- | --- | --- |
| [BEN](https://github.com/lorserker/ben) | NN，候選 `ad8608af6e6bfe095863023f344f3cb2cbafec3d`，source GPL-3.0 | 模型 weights／native binaries 權利逐項審核 |
| BBA／EPBot | Meckwell Precision V1 本機 native 研究 | 使用者說明已取得許可；仍需留存原文、再散布/託管許可及 notice |
| DDS | 完局雙明手分析 | 終局視角、元件來源與發布 license |
| `playing_cards 0.4.1+11` | Flutter 牌面 render-only，registry SHA256 `392d5e42317ec657f6814a282e6bb70942c6599d22dac89cdc741a8b2b095d09`，package Apache-2.0 | bundled Wikimedia 圖像可能被打包；需逐張查授權或排除 |
| `card_game 2.0.0` | 動畫套件候選 | **未安裝／未核准** |

## 模型身份與核驗

[SHA inventory](../../scripts/ben_m12_inventory.py) 對模型與 native 依賴逐項計算 SHA256；[真 BEN CI #40075250217](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40075250217) 已成功開機與宣告 systems。21GF bidder `33ff95fe85ed29c9b1c1cd5ac8d6f9516f7d3d4547b17384fbdfadba56f69efd`；SAYC bidder `6824fb96264d6536709b3c4d3fa989f321f5886662cfcb3a0e5c1e3c5cb67c32`。**Hash 只能證明檔案身份，不能當作商用授權**。完整 info/native 清單在整理前 Git 歷史的 `BEN_M12_PINNED_ASSETS.md`。

## 真 4GB VPS 尚未驗證

[CI benchmark](RESEARCH_REPORTS.md) 是 Ubuntu Runner、短時 NN-biased、BBA/PIMC/SuitC disabled。單 Worker 觀測約 1.01 GiB RSS、雙 Worker 約 1.95 GiB，**不能推定**目標 2vCPU/4GB VPS 可行或不可行。

發布前在目標主機逐組測 concurrency 1/2/4/8、整局 bid/lead/play、冷啟與長時 CPU/RSS/p50/p95/p99/429/5xx、重啟與備援。成本還需 DAU、每局 requests、供應商實際報價（日期／幣別）、TLS、儲存、備份與監控。不假設免費。

**Production NO-GO**：TLS、identity、模型權利、隱私、VPS 真測、A3.5/Android/iOS hold 均未解除。發行準則：[RELEASE_CHECKLIST](../planning/ROADMAP.md)。

## 平台與 UX 真實測試

將零散 Flutter／Chrome、A1～A6、B1～B6、C1～C3 驗收濃縮為玩家體驗與平台研究。完整功能清單在 [FEATURES](../implemented/FEATURES.md)。

## 已觀察到的進展

| 面向 | 受控證據與解讀 |
| --- | --- |
| Bridge Core | [CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/bridge-core.yml) 覆蓋 Auction、合法出牌、終局及計分；歷史 Pass Out 三次紀錄缺口不可自動補造 |
| 真 AI 完整牌局 | [Chrome → localhost Gateway → 真 BEN #38849429500](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38849429500) 有一副固定 52 張、13 墩端到端成功；不是公開主機多使用者 |
| 牌桌與工作區 | [Flutter Web／Chrome #40255094253](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40255094253)：198 個測試、Web build／Chrome scoped PASS，新增打牌/學院/複盤/我的工作區、牌面 renderer 和叫牌手牌 |
| 窄屏牌列 | [後續 #40256171652](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40256171652)：200 個測試、Web／Chrome scoped PASS，手牌可橫向捲動、保留點擊大小；不是全桌動畫 UX 完成 |
| 本機持久化／歷史 | 有加密 checkpoint、replay、PBN 輸入輸出、搜尋統計及練習；不能當成 remote durable history |
| 練習與教學 | 四局、Just Declare、叫牌練習、非排名每日練習、學院、DDS 事後複盤已逐步有 scoped 工程驗收 | 

## 重要限制

Flutter Web 受控測試、Android 模擬器、Android/iOS 實機各是不同驗收層級；**使用者目前要求暫緩 A3.5 與裝置 QA**，不可在未明確批准前啟動，也不能稱為發行已通過。

`playing_cards 0.4.1+11` 已用於可見牌渲染，來源與 Apache-2.0 package license 已初審；未使用的內建 Wikimedia 圖像仍可能被打包，公開二進位檔發行前須逐項排除／查核。Flutter Widget 不接管發牌、Bridge Core 法則、完整暗牌或網路認證。

## 後續 UX 研究題目

U3：單屏佈局、可中止出牌/收墩動畫、合法目標與錯誤重試、320/375/768/1280px、2×字體及輔助科技。U4：持久 Gateway session/雲端 history，不能冒用本機 checkpoint 的測試成果。正式準入規格見 [產品路線](../planning/ROADMAP.md)。

## Precision V1 制度身分（不可默默更換）

- 唯一 profile：**BBA Meckwell Precision V1**，`BA-PRECISION-MECKWELL/r1`，native `System type=3`，上方固定 `Meckwell.bbsa`，不可冒充 BEN 的可玩 Neural `PRECISION` 模型。
- **1NT 開叫＝13–15 HCP**；不是 Meckwell Lite 的 13–16 HCP。外部 Meckwell Lite 文章只能做差異參考。
- 來源卡已確認的設定 flag：`Precision 2D=1`、`1M-3M blocking=1`（inviting=0）、`Jacoby 2NT=1`、`Drury=1`、`Blackwood 0314=1`、`Weak natural 2M=1`。**卡片設定不等於專家已核准所有策略語義**。
- 1♣、1♦、1NT 13／15／16 邊界、競叫、迫叫、Double/Redouble 與 Alert 尚須 ≥100 專家 Golden 牌例及對手 reader 能力證據。版本與 card SHA 變更需要新修訂版，不可破壞既有 GameSystems 重播。
- 專案擁有人表示 BBA 使用權涵蓋商業託管／修改／散布；repo 仍需留存逐元件授權原文與正式 notices。**原生研究 ≠ 精準制度競賽級牌力或正式發布許可**。
- 相關程式：[PrecisionBiddingProvider](../../packages/bridge_precision_adapter/lib/src/precision_bidding_provider.dart)、[EPBot sidecar](../../scripts/precision_m33_sidecar.py)。


## 代表性 CI 與範圍

| 局部驗收 | 實際 CI | 未驗證的延伸 |
| --- | --- | --- |
| Core 規則／計分 | [Bridge Core CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/bridge-core.yml) | WBF 認證競賽／正式裝置 |
| 真 BEN 52 張／13 墩 | [Chrome→Gateway→BEN #38849429500](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38849429500) | 公網安全／持久多人服務 |
| 21GF／SAYC 兩側不同制度 | [兩局真 BEN #40087851963](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40087851963) | 專家 100+ goldens 與進階競叫牌力 |
| BEN M1.3/M1.4 A/B 和容量 | [真 BEN CI #40076846012](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40076846012) | 實際 OVH 4GB VPS 與完整模擬 SLO |
| 原生 Precision 開叫 | [CI #40092096757](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40092096757) | 所有 Precision 叫牌分支 |
| 1000 次 native 開叫 benchmark | [CI #40102968596](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40102968596) | 1000 副完整 13 墩比賽 |
| Precision 混合合法整局 | [CI #40103865733](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40103865733) | 競賽級神經出牌實力 |
| Flutter 工作區／牌面 | [198 測試 #40255094253](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40255094253) | 手機真人測試／完整動畫 |
| Flutter 窄屏手牌 | [200 測試 #40256171652](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40256171652) | 全牌桌 320px UX 完工 |
| M4 本機自訂草稿與 Gateway 防注入 | [CI #40139553945](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40139553945) | 可執行自訂 AI／專家 Goldens |
| M5 公開叫牌 Coach | [CI #40154923631](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40154923631) | 真 BEN/BBA 最佳叫品解釋 |

**來源規範**：GitHub Actions 必須看明確 SHA、環境、fixtures、status 和 logs；舊成功 run 不等於最新 commit 的端到端全面放行。完整版的歷史逐檔報告在刪除前的 Git 歷史中仍可檢索。

## 競品與技術借鑑的著作權界線

### Reuse First 核對（2026-10-26）

### Reuse First 實作核對（2026-10-26）

| 候選／immutable identity | 使用與實際結論 |
| --- | --- |
| [Nickel Bridge](https://github.com/brannondorsey/nickel-bridge/tree/92a81b5e81cb7aac2eabc147e82f18e0040b512e)，SHA `92a81b5e81cb7aac2eabc147e82f18e0040b512e`，commit 2026-09-26 | 已讀 HandFan、PlayingCard、AuctionGrid、BidBox 的互動契約，追查 Board 與 TrickArea 的 staging／legalCards／motionOK。React TSX 不能直接充作 Flutter Widget；其 selected/confirm、public projection 可借鑑；inFlight／staged myTurn false 的演出鎖不能照搬，因本專案動畫不應延遲合法回合。此輪不複製程式／CSS／素材，不使用其 AI／計分。Owner 完整修改授權聲明仍有效，實際移植另記對應檔案／notices；上游 README 的 glossary CC BY-SA 與模型／DDS 權利不由 UI 授權推定。 |
| `playing_cards 0.4.1+11`，既有 registry archive SHA256 `392d5e42317ec657f6814a282e6bb70942c6599d22dac89cdc741a8b2b095d09`；FlatCardFan source SHA256 `c0c6e35f95fcfafc648a299340e49c982ca159811797e74e32ff621bda6c6717` | **ACCEPT_SCOPED／M2-F60**：直接呼叫已安裝 package 的 FlatCardFan，不 vendoring 原始碼；Apache-2.0 LICENSE 已讀，保留 package notices 與 Flutter license registry。只在可見步距 ≥48px 的寬度使用；窄屏／大字體退回可及捲動。正式 app 無新依賴，原有 Wikimedia 資產發行核對仍開放。 |
| [card_game 2.0.0](https://pub.dev/packages/card_game/versions/2.0.0)，published 2025-04-28，archive SHA256 `d5f0720c3f320fda8adc17f02f155f94fea799efa6dd557091fc60ca4f8055d9`，repository [JLogical-Apps/card_game](https://github.com/JLogical-Apps/card_game) | **ISOLATED RESEARCH／正式採用 BLOCKED**：archive checksum 已自行核對，MIT LICENSE（Copyright 2025 JLogical）已讀；不修改／複製上游 source。獨立 experiments package 釘選版本與 lockfile；app 不依賴它。三項 probe 測試保留重現，不代表上游已修復。 |

**Nickel 來源檔案（上述 SHA）：** `web/src/components/game/{HandFan.tsx,PlayingCard.tsx,BidBox.tsx,AuctionGrid.tsx,TrickArea.tsx,fanLayout.ts}`、`web/src/pages/Board.tsx`；`docs/design-brief.md` 明示其舊狀態描述不能取代已出貨 source。M2-F61 參照 `TrickArea.tsx` 的 seat compass、public state diff glide 與 collect sweep 互動概念，依本專案 PlayerView 在 Flutter 實作；沒有複製 TSX／CSS／素材，亦未採用上游延遲操作的 staging。這是來源／契約核對，沒有宣稱逐行移植或完成其整個 app 授權 inventory。

**card_game 真實相容性結果：**

1. `CardLinearGroup.getDraggableCardValues` 以尾端 stack 長度判定 maxGrabStackSize；設 1 時非最後一張回 null，不能直接當橋牌「任意合法單張」。PoC 以公開 API subclass 改成只提議一張允許牌，沒有自訂橋牌法則。
2. 實際拖放後同步鎖住同版本提案，上游 `lib/src/cards/card_game.dart:200` 在 drag-end 重新呼叫已停用的 grab getter 並 `!`，重現 TypeError。測試先驗證只送一次 proposal、Core version 仍為 1，並明確捕捉這個既知錯誤；沒有把測試綠燈說成產品可玩。
3. `card_game.dart` 的 AnimatedPositioned／DateTime 判定使用固定 300ms；MediaQuery disableAnimations=true 時 probe 仍觀察到非零 duration。尚無可用的上游 public duration override，因此必須有受測 upstream fix／明確 patch 才能通過我們的取消／reduce-motion gate。

PoC custom style 只顯示已授權 Card.code，沒有匯入 52 張 SVG 到主 app；上游 package 自帶 assets，未逐張驗證其獨立授權，正式 binary 採用前仍需 inventory／排除。直接相依 collection（BSD 類 LICENSE）、equatable、flutter_svg、provider 及 nested（MIT LICENSE）已讀 installed LICENSE；完整 transitive list／版本／hash 在 [probe lockfile](../../experiments/card_game_probe/pubspec.lock)。CVE／全平台與長期維護評估 **NOT RUN**，不推論沒有問題。保留原 package LICENSE 義務，不宣稱 GitHub 公開即任意授權。

**可重現命令／環境：** Windows、Flutter 3.47.8／Dart 3.13.7；在 `experiments/card_game_probe` 已執行 `flutter pub get --enforce-lockfile`、`flutter analyze --no-pub`、`flutter test --no-pub --reporter expanded`；analyze 無問題、probe 3/3 PASS＝已重現 gate，不是正式採用 PASS。主 app 最終 220/220、Web release PASS；新 SHA Chrome／probe CI 待 push。後續先決定是否做小型 upstream patch（必須保留 exact source/license/patch/test），再考慮接管拖放；暫不為替換而重寫全部現有 UI。

Owner 已授權 Reuse First 與 Nickel Bridge 修改；實際釘選、授權界線、相容性探查及 M2-F60／F61 結論以上表為準。[Flutter 官方 card template](https://github.com/flutter/games/blob/main/templates/card/README.md) 可作後續參考，bridgegui 尚未釘選或複製；bridge_game 不因 UI 需要引進第二套規則。Nickel 完整依賴／素材 inventory、card_game package SVG 獨立權利與發行核對仍未完成。

驗收 PoC：只餵公開固定 fixture 或 seat-filtered PlayerView → 自訂牌面 adapter → 點擊／拖曳 action intent → 原 Session／Gateway → Core validation → 新投影驅動動畫。保留 BEN 制度、計分與 server action ID。四人隱藏手只顯示數量／牌背，不把真暗牌塞進 isCardFlipped。Web 52 unique／13 tricks、明手控制、非法動作無 mutation、stale drag／取消、同 ID 重試與 reduced-motion 必測；裝置 QA 不在此 PoC 自動解除。來源、版本／SHA、license、notice、使用邊界及實測結果寫本節，沒有合適方案才記理由自製。

BBO、新睿、BBO Trainer 可以當作練習分類、牌桌操作與玩家旅程的比較對象，不授權複製其程式、API 私有協定、素材或教材。Flutter `playing_cards 0.4.1+11` 採用於可見牌面渲染，Apache-2.0 package 仍有未使用的內附 Wikimedia 圖像可能被打包，正式釋出要排除或逐項查核；`card_game 2.0.0` 僅是備選，未正式採用。
