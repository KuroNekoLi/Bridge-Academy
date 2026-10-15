# Bridge Academy

A contract bridge platform: start with a single human playing alongside three AI players, then expand to teaching, online tables and duplicate tournaments.

**State (2026-10-15):** Bridge Core 47/47 tests passed; M2 has a functional Flutter table, Android emulator and Chrome integration, pinned real-BEN fixed-board tests, random local deals and current-completed-game replay. **Consumer-ready single-player MVP is NOT released**: dealer/vulnerability board cycle, durable resume/history, production BEN delivery, device QA and deployment/licensing remain open. See the product release gates below. This repository is private. The phrase "open-source" in the initial description is a product aspiration, not a statement that this repository or its third-party dependencies have been released under a chosen license.

## Product scope & next implementation

- [繁體中文產品導覽](docs/product/README.md)
- [Competitor benchmark — 新睿 / BBO / BBO Trainer](docs/product/COMPETITOR_BENCHMARK.md) — official-source comparisons and non-copying boundary.
- [Bridge Academy PRD v1](docs/product/BRIDGE_ACADEMY_PRD_V1.md) — product vision, functional requirements, player journeys, release acceptance.
- [Product Delivery Roadmap](docs/product/PRODUCT_DELIVERY_ROADMAP.md) — Phase A single-player MVP → B training → C analysis → D async duplicate → E live multiplayer.

**NEXT:** Phase A2, durable event transcript persistence and crash-safe resume; Phase A1 Board Management Core/Flutter/BEN fixed-board regression is already verified, with Android regression still awaiting confirmation. The existing [engineering roadmap](docs/ROADMAP.md) remains the chronological test ledger and must not be overwritten.

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
