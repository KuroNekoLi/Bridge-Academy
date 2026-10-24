# Bridge Academy

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
