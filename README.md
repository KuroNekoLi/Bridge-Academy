# Bridge Academy

> **2026-10-25 M4→M5**：M4 自訂約定**草稿／審查** scoped engineering 已完成，但實際可玩自訂 BEN/BBA AI 尚缺可執行版本與專家規則證據（release NO-GO）。M5 已實作 [公開叫牌證據教練](packages/bridge_conventions/lib/src/auction_coach.dart)、[雙語教學頁](apps/bridge_academy_flutter/lib/src/conventions/auction_coach_page.dart) 與 Gateway 賽後公開叫牌檢視。無真 AI 最佳叫品臆測、無隱藏手牌。詳見 [M5 Acceptance](docs/research/M5_PUBLIC_AUCTION_COACH_ACCEPTANCE.md) · [M5 CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/m5-coach.yml)。



> **M4.6–M4.7（2026-10-25）**：SAYC／2/1 自訂 Convention Card 草稿支援跨版本差異檢視、可複製的專家審查待辦包，以及真 Gateway HTTP 的偽造 `SUPPORTED`／自訂草稿准入拒絕。[M4 驗收](docs/research/M4_CUSTOM_CONVENTION_DELIVERY_ACCEPTANCE.md) · [Domain/Flutter CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40139400430)。**仍不支援將改過的約定直接交給 BEN/BBA 實際叫牌；正式競賽/上線未核准。**



> **M4.3～M4.5（2026-10-25）**：自訂卡新增 [引擎支援審核](packages/bridge_conventions/lib/src/custom_convention_review.dart)、[公開叫牌草稿含義預覽](apps/bridge_academy_flutter/lib/src/conventions/custom_draft_page.dart) 與需確認、只接受 fast-forward 的剪貼簿備份／匯入。[M4 CI #40137806806](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40137806806) Dart Domain 25/25、Flutter Widget 4/4、analyzer PASS。所有已編輯的自訂卡 **ENGINE_UNVERIFIED**，不能進入 AI 對局；真正的可玩引擎相容性、專家測試、雲同步仍 NO-GO。
 
> **M4 自訂約定草稿**：SAYC／2/1 可在 Flutter 頁面編輯少量受控約定、保存不可變版本及本機歷史；完成保存**不會**改變任何 AI 制度。已修改的卡永遠明確標示 `ENGINE_UNVERIFIED`，不可在真實 Gateway 使用。[M4 驗收範圍與待辦](docs/research/M4_CUSTOM_CONVENTION_DELIVERY_ACCEPTANCE.md)。M3 Precision 研究階段技術 PASS，但產品級牌力與部署仍 NO-GO。



> **M3.6 Precision 卡牌出牌研究（2026-10-24）**：已讓原生 BBA `find_info` 讀取 Meckwell V1／SAYC／2/1 約定，推估每座位花色長度，協助研究版 AI 從 **Bridge Core 合法牌**中選擇；不再固定第一張。真原生 [CI #40105701070](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40105701070) 已完成四種混合配置的固定牌局（52 張／13 墩）。[技術報告](docs/research/M3_6_PRECISION_CONVENTION_AWARE_CARDPLAY.md)／[工程教學](docs/learning/features/M3_F17_PRECISION_CONVENTION_INFERRED_CARDPLAY.md)。**這不是競賽級 Precision 神經牌力，正式發布仍未核准。**



> **M3.4/M3.5 (2026-10-24):** [Precision/SAYC true native BBA Gateway research](docs/research/M3_4_PRECISION_MIXED_GAME_ACCEPTANCE.md) & [1000 opening-bid performance evaluation](docs/research/M3_5_PRECISION_BENCHMARK_AND_RELEASE_GATE.md) scoped PASS. Experimental only: BBA interprets both sides of the auction; the full bridge game uses explicitly noncompetitive legal cardplay. It is NOT a production Precision-aware BEN robot, and requires explicit private Gateway/Flutter opt-in. Target-VPS, expert goldens, actual match quality and device QA remain release blockers.



> **M3.3 (2026-10-24):** Implemented an [isolated BBA Meckwell Precision V1 bid provider](packages/bridge_precision_adapter/lib/src/precision_bidding_provider.dart) and [native loopback sidecar](scripts/precision_m33_sidecar.py). [Engineering evidence](docs/research/M3_3_PRECISION_PROVIDER_ACCEPTANCE.md); owner confirms BBA commercial hosting/modification/redistribution rights. **Precision is not yet selectable in Gateway/Flutter** until M3.4 full-game compatibility is proven.



**Precision V1（2026-10-24）**：第三套制度的唯一規格已選定 [BBA Meckwell Precision V1（1NT 13–15）](docs/conventions/PRECISION_BBA_MECKWELL_V1.md)，固定上游 Meckwell.bbsa 與 SHA。專案擁有人已告知取得 BBA 授權，但具體商業託管／再散布範圍待核對；正式 Gateway/Flutter Precision 尚未開放。
A contract bridge platform: start with a single human playing alongside three AI players, then expand to teaching, online tables and duplicate tournaments.

**State (2026-10-15):** Bridge Core 47/47 tests passed; M2 has a functional Flutter table, Android emulator and Chrome integration, pinned real-BEN fixed-board tests, random local deals and current-completed-game replay. **Consumer-ready single-player MVP is NOT released**: dealer/vulnerability board cycle, durable resume/history, production BEN delivery, device QA and deployment/licensing remain open. See the product release gates below. This repository is private. The phrase "open-source" in the initial description is a product aspiration, not a statement that this repository or its third-party dependencies have been released under a chosen license.

## Product scope & next implementation

- [繁體中文產品導覽](docs/product/README.md)
- [Competitor benchmark — 新睿 / BBO / BBO Trainer](docs/product/COMPETITOR_BENCHMARK.md) — official-source comparisons and non-copying boundary.
- [**2/1 / SAYC / Precision 三制度 AI 完整開發計畫**](docs/product/THREE_SYSTEM_BIDDING_AI_MASTER_PLAN.md) — 分層設計、自訂約定、M1–M6 交付、測試與授權門檻。
- [BEN 多制度 M1 能力探針與 CI 紀錄](docs/research/BEN_MULTI_SYSTEM_M1_SPIKE.md) — M1.1 靜態/Mock 已通過；M1.2 真 BEN 啟動與 GET / 已通過；真模型多制度 /bid 尚未驗證。
- [M3 Precision Club 原生 BBA／EPBot 隔離研究](docs/research/M3_PRECISION_SPIKE_ACCEPTANCE.md) · [實際 CI #40092096757](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40092096757) — 真 BBA 8 組開叫已驗證；1NT 約定差異與授權未核准，**研究-only，正式選單尚未開放**。
- [**M2.2～M2.5 真 BEN 2/1／SAYC 混合制度整合驗收**](docs/research/M2_2_TO_M2_5_IMPLEMENTATION_ACCEPTANCE.md) — Adapter、Gateway、Flutter 開局選擇及兩場完整真 BEN 牌局已在 CI 通過；Production/Precision 仍未核准。
- [M2.5 真實 52 張牌／13 墩 E2E 證據](docs/research/M2_5_REAL_BEN_MULTISYSTEM_ACCEPTANCE.md) · [真 BEN CI #40087851963](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40087851963)。
- [**M2.1 GameSystems 不可變版本／加密 checkpoint 驗收**](docs/research/M2_1_GAME_SYSTEMS_ACCEPTANCE.md) — 純 Dart Convention Domain、伺服器固定 NS/EW、校驗還原與 Fail Closed（BEN 實際切換由 M2.2 接續）。
- [M1.3 真 BEN 2/1／SAYC A/B 驗收](docs/research/BEN_MULTI_SYSTEM_M1_3_ACCEPTANCE.md) · [M1.4 單／雙 Worker 容量研究](docs/research/BEN_MULTI_SYSTEM_M1_4_CAPACITY.md) — Scoped CI PASS；**不是正式 4GB VPS 或產品上線核准**。
- [M1.2 真 BEN 隔離啟動驗收](docs/research/BEN_MULTI_SYSTEM_M1_2_ACCEPTANCE.md) · [Pinned 模型/Native SHA256](docs/research/BEN_M12_PINNED_ASSETS.md) — 研究環境，不代表正式部署或權重授權核准。
- [Bridge Academy PRD v1](docs/product/BRIDGE_ACADEMY_PRD_V1.md) — product vision, functional requirements, player journeys, release acceptance.
- [Product Delivery Roadmap](docs/product/PRODUCT_DELIVERY_ROADMAP.md) — Phase A single-player MVP → B training → C analysis → D async duplicate → E live multiplayer.

**CURRENT (2026-10-15):** A1 canonical board metadata is scoped Core/Web/BEN verified. A2 includes versioned recovery, rollback consent, encrypted native SQLite implementation and encrypted Web checkpoint work, with [scoped Flutter/Chrome CI success](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38757222196); this does **not** prove physical-device security/durability, fully deployed Web threat controls or real BEN remote idempotency. A3.1–A3.4 are scoped Flutter/Chrome verified and **A3.5 has been owner-deferred but remains a release gate**. **A4.1 HTTPS Client 23/23** and **A4.2 localhost Gateway [14/14 HTTP CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38836219472)** are scoped verified; next A4.3 private BEN worker/dedup, with no hosted service yet; A2 security gaps remain open. **Android emulator and real Android/iOS UI/E2E tests are paused until the owner's explicit later approval.** Phase B may prototype unranked daily practice; ranked Duplicate stays Phase D. The existing [engineering roadmap](docs/ROADMAP.md) is the historical test ledger and must not be overwritten.

## Product progression
1. **POC-001**: BEN API and one fixed deal — GO based on a Work execution report.
2. **POC-002**: 100 fixed seeds — outcome-level GO with two Pass Out transcript warnings; not production sign-off.
3. **M1**: standalone, deterministic Bridge Core with legality, scoring, event replay and property tests.
4. **M2**: Flutter single-player experience with three BEN bots (online AI service initially).
5. **M3**: convention-aware practice, replay, DDS post-game analysis and tutoring.
6. **M4**: server-authoritative human multiplayer and duplicate tables.
7. **M5**: competitive operations, tournament integrity, accessibility and scale.

## Source of truth
- [Bridge Core implementation](packages/bridge_core/README.md) and [M1 CI report](docs/m1/M1_IMPLEMENTATION_REPORT.md)
- [M2 single-player foundation](docs/m2/M2_FOUNDATION_REPORT.md): filtered PlayerView and local Coordinator.
- [M2 BEN Adapter contract](docs/m2/M2_BEN_ADAPTER_REPORT.md): stateless per-seat HTTP /bid, /lead, /play.
- [M2-F04 True BEN end-to-end](docs/m2/M2_F04_REAL_BEN_ACCEPTANCE.md): real BEN full-deal and Dummy smoke passed.
- [M2-F05 Flutter single-player table](apps/bridge_academy_flutter/README.md): first functional interactive UI slice, zh-TW/en, Demo/real BEN selection. [Acceptance](docs/m2/M2_F05_FLUTTER_TABLE_REPORT.md).
- [M2-F06 Chrome + responsive QA](docs/m2/M2_F06_BROWSER_QA_REPORT.md): real browser Demo UI and responsive tests.
- [M2-F07 True BEN + Flutter Chrome](docs/m2/M2_F07_REAL_BEN_BROWSER_ACCEPTANCE.md): dedicated real-Python-BEN + browser test and exact CI evidence; mobile hardware gate separate.
- [Product vision](docs/PRODUCT_VISION.md)
- [Roadmap and acceptance gates](docs/ROADMAP.md)
- [Technical architecture](docs/ARCHITECTURE.md)
- [Bridge rules baseline](docs/BRIDGE_RULES_BASELINE.md)
- [Conventions](docs/CONVENTION_SYSTEM.md)
- [Open-source audit](docs/OPEN_SOURCE_AUDIT.md)
- [Development standards](docs/DEVELOPMENT_STANDARDS.md)
- [Decision log](docs/DECISIONS.md)
- [POC-001 status](docs/poc/POC_001.md) and [POC-002 batch evidence summary](docs/poc/POC_002_BATCH_100.md)
- [AI instructions](AGENTS.md) and [specialized skills](skills/README.md)
- **Learn While Building**: [Developer learning workflow](docs/learning/README.md), [feature lessons](docs/learning/INDEX.md), and [learning mentor skill](skills/bridge-learning-mentor/SKILL.md)

## Current engineering entry point
Do **not** fabricate new BEN test results or substitute DDS's omniscient play for real imperfect-information AI. M1 is merged; M2 uses PlayerView, local Coordinator and verified BEN Adapter. M2-F05 adds the first Flutter interactive table; verify Flutter CI and device QA before overall M2 sign-off. User-approved Git policy is direct master pushes without PRs. See the roadmap for test gates. The original Work artifacts and raw batch JSON are not currently committed here; documented POC figures are attributed to the user's reported Work acceptance summary.

## Third-party sources
BEN: https://github.com/lorserker/ben (GPL-3.0, verify precise commit and dependencies before distribution).
DDS: https://github.com/dds-bridge/dds (verify exact checked-out release and license).
endplay: https://github.com/dominicprice/endplay (version/license review pending).
Agent Skills specification: https://agentskills.io/specification .
