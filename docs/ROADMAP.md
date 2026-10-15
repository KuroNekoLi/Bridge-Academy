# Roadmap and release gates

Status snapshot: 2026-10-15. Each "done" requires executable evidence, not an assertion.

## Product sequencing (separate from this historical CI ledger)

The user approved a complete-playable-product roadmap inspired by 新睿 / BBO / BBO Trainer on 2026-10-15. See [PRD v1](product/BRIDGE_ACADEMY_PRD_V1.md), [Product Delivery Roadmap](product/PRODUCT_DELIVERY_ROADMAP.md), and [official-source competitor benchmark](product/COMPETITOR_BENCHMARK.md).

**Next actionable feature = Phase A1 canonical Board Number / Dealer / Vulnerability;** preserve documented M1/M2 engineering history below. Passes on fixed BEN fixtures, Android emulator and 47/47 Core tests do not establish production AI, durable session resume or a release-ready product.

## POC-001 — real BEN, single fixed deal (reported GO)
Acceptance reported from Work: native Python 3.12 BEN server; true JSON for /, /bid, /lead, /play, /autoplay; E declarer at 3NT, 8 tricks, NS +50; all 52 cards and 13 tricks; independent legality and score check. Source = user-supplied Work summary. Raw responses and versions are **not yet imported into this repository**. See docs/poc/POC_001.md.

## POC-002 — 100 fixed deals (outcome-level GO; transcript caveat)
97 contract deals completed 52/13; one four-Pass Pass Out; two Pass Out outcomes with only 3 returned PASS entries; outcome reported 100/100 but verifiable full transcript only 98/100. BEN performance measured with PIMC off and reduced sampling (not production default). Raw evidence not imported. See docs/poc/POC_002_BATCH_100.md.

## M1 — Bridge Core (RULES CI GO; PR #2 UNDER REVIEW)
- Executed GitHub Actions: https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38671869760
- Dart 3.13.5 / dart analyze PASS / 30 of 30 tests PASS (one test covers 100 fixed-seed non-AI complete deals).
- Core-only acceptance: M2 must create privacy-filtered PlayerView and a separate BEN adapter; this result does not establish production AI reliability.
- Typed Card/Suit/Rank/Seat/Partnership/Vulnerability/Call/Contract/Trick/GameAction/GameState.
- Pure deterministic transition function: validate action, apply auction, compute contract/declarer, expose dummy, enforce suit following, score duplicate.
- Complete Pass Out = four chronological passes starting with dealer; after any non-pass, auction ends only on three consecutive passes. Double/Redouble rights checked.
- Persist canonical event log with versions; allow deterministic replay and state hashes.
- Unit/property/golden tests incl. 4 dealers, 4 vul states, 5 strains, X/XX, made/down, overtricks/slams, trump, voids, revoke rejection and Pass Out.
- GO gate: independent golden score oracle; no illegal action changes state; complete deterministic replay; no UI/AI/network required.

## M2 — Flutter single-player MVP
- M2-F05 Flutter table source with interaction/zh-TW/en under apps/bridge_academy_flutter; **Flutter Web CI PASS, 11/11 tests and release web build** at https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38678356482. Report: docs/m2/M2_F05_FLUTTER_TABLE_REPORT.md. Native-device acceptance and whole M2 GO are still pending.
- **M2-F04 FIXED-BOARD REAL BEN GO:** two live Dart/BEN games on Ubuntu 24.04 / Python 3.12, both 52 cards/13 tricks; second game completed **13 BEN-controlled Dummy turns**. Real CI https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38676615739 ; see docs/m2/M2_F04_REAL_BEN_ACCEPTANCE.md. Reduced sampling/PIMC off, not full M2 GO or production SLA.
**IN PROGRESS:** M2-F01 PlayerView and M2-F02 SinglePlayerCoordinator are implemented with 40/40 combined Dart tests passing at [CI #38673888504](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38673888504); feature PR review remains open. This is **not** BEN-powered MVP or Flutter UI; see docs/m2/M2_FOUNDATION_REPORT.md. Learn While Building: each completed feature has a separate note in docs/learning/features/.
- Human seat selectable; three AI seats; consistent public/hidden information.
- M2-F03: first BEN Adapter HTTP + data boundary contract implementation (see docs/m2/M2_BEN_ADAPTER_REPORT.md). A real BEN server integration is still required; do not call mock contract tests a real model acceptance.
- AI adapter never executes illegal state transitions; explicit retry/error/fallback policy.
- Auction, turn, hand, dummy, 13 tricks, Pass Out and score UI; zh-TW/en localized; responsive tablet/mobile.
- End-to-end seeded golden deals; UX, accessibility and crash/error validation on real target.
- Performance and hosting benchmark with intended BEN settings (do not extrapolate POC-002 timings).

- **M2-F06 REAL CHROME DEMO GO:** [CI #38680520652](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38680520652) — Chrome 154 with matched ChromeDriver, actual browser-clicked Pass Out/restart/bid/dummy play; 14/14 Flutter tests at 320/375/768px; Flutter Web release built. Real BEN from Chrome and Android/iOS hardware QA are separate requirements. [Report](m2/M2_F06_BROWSER_QA_REPORT.md).
- **M2-F07 TRUE BEN + CHROME FIXED-BOARD GO:** [latest CI #38682472896](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38682472896) succeeded: real BEN native Python 3.12/TensorFlow, Chrome 154, actual Flutter UI complete game 52/13 and /bid /lead /play all real successful. Reduced samples/PIMC off, not full M2 production/native GO. [Acceptance report](m2/M2_F07_REAL_BEN_BROWSER_ACCEPTANCE.md).

- **M2-F08 NATIVE ANDROID EMULATOR GO:** [CI #38689747773](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38689747773) SUCCESS; Android 15 (API 35) emulator, debug APK built/installed, Flutter integration_test exercised localization, Pass Out, restart, bid and Dummy card touch. Fixed Demo Bot only. Physical devices and Android true-BEN HTTP remain separate. [Report](m2/M2_F08_ANDROID_EMULATOR_ACCEPTANCE.md).
- **M2-F09 TRUE BEN ROBOT DECLARER CHROME GO:** [CI #38685977544](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38685977544) PASS, genuine BEN bids North declarer and makes 13 legal South Dummy actions, 13 human East defender actions, 52 cards / 13 tricks; no mocks. See docs/m2/M2_F09_BEN_DECLARER_UI_ACCEPTANCE.md.
- M2-F10: explicitly selectable fixed training PBN vs fresh shuffled 52-card local practice, deterministic seed tests and PBN round-trip. UI still consumes private PlayerView; M2-F07/F09 BEN fixed-board acceptance stays default. [Core 42/42 PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38690024308), [Flutter 16/16 + Chrome Web PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38690212528). Web engineering GO; Android and random BEN quality are separate. See docs/m2/M2_F10_SHUFFLED_DEALS_ACCEPTANCE.md.
- **M2-F11 REPLAY CORE / FLUTTER WEB / ANDROID EMULATOR GO:** [latest Core 47/47](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38714671479) and [Flutter 19/19 + Web Build + pre-existing Chrome Demo](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38692937055) PASS. Terminal-only canonical event replay via BridgeGame.apply and authorized PlayerView; Flutter read-only First/Previous/Next/Last. [real Chrome replay navigation CI #38693616403](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38693616403) passed actual First/Next/Last interactions; [Android emulator replay touch #38693616421](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38693616421) PASS: real First / Next / Last clicks and reset after restart. Physical devices remain pending. [Report](m2/M2_F11_FINISHED_REPLAY_ACCEPTANCE.md).
- M2-F11.1 domain replay hardening: four dealers/vulnerability states, redouble 52/13 history, tampered event rejection and immutable player frames ([Core CI 47/47 PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38714671479)). Existing replay UI/Domain implementation remains the Source of Truth.

- **Phase A1 / M2-F12 BOARD MANAGEMENT IMPLEMENTED, CI PENDING:** WBF Law 2 BoardDefinition 16-board cycle, real session dealer/vulnerability, 1-based number, same-board replay vs next-board, localized UI and fake BEN wire contract. [Acceptance](product/P1_A1_BOARD_MANAGEMENT_ACCEPTANCE.md). Do not mark GO until current CI verifies.

## M3 — teaching and analysis
- Versioned ConventionCard contract, SAYC/2-over-1 as separately testable profiles where supported.
- Rule-grounded hints and full replay; DDS results tagged "double dummy" and gated to post-deal.
- Instructor review, explanation uncertainty, benchmark practice boards.

## M4 — multiplayer
- Server-owned hidden state, authenticated player/action identity, WebSocket fan-out filtered by seat.
- Rejoin/idempotency, network partitions, spectator restrictions, anti-collusion/privacy, audit events.
- Club tables and duplicate board administration, IMP/MP accuracy and concurrent-load tests.

## M5 — operations and scale
- Director tools, ranked/tournament reliability, monitoring, cost controls, moderation and privacy compliance.
- Dedicated security, licensing and user-testing gates before public/commercial distribution.

## Stop conditions
Block rollout on information leakage, illegal move acceptance, wrong duplicate scoring, unreplayable state, unexplained mismatch between BEN and Bridge Core, unreviewed third-party license obligations or untestable production reliability.
