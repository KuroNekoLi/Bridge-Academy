# Bridge Academy

A contract bridge platform: start with a single human playing alongside three AI players, then expand to teaching, online tables and duplicate tournaments.

**State (2026-10-15): Phase 0 merged; M1 pure Dart rules core implemented on PR #2, with 30/30 CI tests passing (one test covers 100 deterministic full deals). No production Flutter client or multiplayer server exists.** This repository is private. The phrase "open-source" in the initial description is a product aspiration, not a statement that this repository or its third-party dependencies have been released under a chosen license.

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
- [M2 single-player foundation](docs/m2/M2_FOUNDATION_REPORT.md): filtered PlayerView and local Coordinator; BEN/Flutter not yet integrated.
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
Do **not** fabricate new BEN test results or substitute DDS's omniscient play for real imperfect-information AI. M1 is implemented on [PR #2](https://github.com/KuroNekoLi/Bridge-Academy/pull/2), awaiting review and merge. Before M2, design a private PlayerView and prove it cannot leak other hands. See the roadmap for test gates. The original Work artifacts and raw batch JSON are not currently committed here; documented POC figures are attributed to the user's reported Work acceptance summary.

## Third-party sources
BEN: https://github.com/lorserker/ben (GPL-3.0, verify precise commit and dependencies before distribution).
DDS: https://github.com/dds-bridge/dds (verify exact checked-out release and license).
endplay: https://github.com/dominicprice/endplay (version/license review pending).
Agent Skills specification: https://agentskills.io/specification .
