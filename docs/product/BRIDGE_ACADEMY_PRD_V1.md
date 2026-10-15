# Bridge Academy — Product Requirements Document v1

**State:** APPROVED DIRECTION / IMPLEMENTATION BACKLOG; **not** release approval  
**Date:** 2026-10-15 · **Platforms:** Flutter Android / iOS / Web · **Languages:** zh-TW + en  
**Owner:** Product roadmap; implementation follows existing AGENTS.md and Bridge Core invariants.  
**References:** [Competitor benchmark](COMPETITOR_BENCHMARK.md), [delivery roadmap](PRODUCT_DELIVERY_ROADMAP.md), ../BRIDGE_RULES_BASELINE.md, ../ARCHITECTURE.md, ../DECISIONS.md.

## Product baseline alignment (2026-10-15; additive to v1)

The five destinations remain **打牌／學院／複盤／比賽／我的**, but are staged by working player journeys rather than empty navigation. The **next UX delivery slice is the componentized Bridge Table V2 (A3/P1.3)**, in parallel with remaining P0 security and persistence hardening; a new milestone must not rebuild already verified A1 Board Management.

**Requested 12-item delivery order:** board/dealer/vulnerability (A1, scoped Core/Web verified) → recoverable local game (A2, partly verified; native security and remote exactly-once not yet signed off) → table V2 (A3) → production BEN service (A4) → durable history/redeal (A5) → four-board and declarer practice (B1/B2) → verified convention hints (B3) → **optional early fixed-board daily practice** (B6, P1, *no public rankings*) → DDS postgame (C1) → authored lessons and progress (B4/C3) → async friends (D4) → authoritative live multiplayer (E). These priorities refer to *product work*, not automatic authorization to run device QA.

**Daily challenge distinction:** early P1 local, fixed, reproducible board-of-the-day practice may ship as an unranked exercise. A real cross-player Duplicate contest, MP/IMP result, global leaderboard or friend PK remains **Phase D / P3** and needs an immutable server-held BoardSet, comparable field and anti-cheat policy. If a ranked daily challenge is intended to ship earlier, approve its backend/cost/security scope separately.

**Device QA freeze:** At the owner's request, Android emulator/physical-device UI and E2E runs remain paused until explicit later approval (workflows: `flutter-android-emulator.yml`, `android-rollback-consent.yml`). Keep device acceptance as an **outstanding release gate**, never silently run it nor call the whole MVP ready without it. Flutter/Dart unit, static analysis, Web build and current browser/real-BEN CI may continue under existing policy.

### Table UI V2 decomposition contract

```text
BridgeTableScreen
├── BoardHeader (number, dealer, vulnerability, contract)
├── BridgeTable (four seats, current trick, history, dummy ownership)
├── PlayerHand (suit grouping, legal-card state, input/keyboard semantics)
├── BiddingBox (levels, strains, Pass/Double/Redouble, explain-policy link)
└── TableToolbar (auction, last trick, settings, help)
```

Widgets render a **seat-filtered immutable PlayerView** and emit typed actions to the session/coordinator; no business-rule/Dealer/Vulnerability computation in UI. Prefer small reusable widgets over further growth of `bridge_app.dart`. Legal call hints come from Bridge Core; conventional meanings require a versioned, supported ConventionProfile; strategy hints require explicit evidence/uncertainty and must not claim BEN follows SAYC or 2/1 without verification.

## 1. Product thesis

Build a complete contract bridge product: **play → review → learn → improve → compete**. First provide a reliable **single-player one-human + three real BEN opponents** experience in an ordinary deployed application; then add learning and offline analysis; later fair duplicate challenges and fully authoritative multiplayer.

It is not sufficient to complete one fixed PBN in CI. **Engineering PASS** validates a defined component. **Product READY** requires a complete, usable, recoverable multi-board player journey on supported devices without developer tooling.

### Primary audiences
- **Beginner:** low-friction practice, safe legal-action cues, understandable rules, declarer-only lessons.
- **Returning recreational player:** fast real-AI tables, own seat, session history, replay same deal, reliable resume.
- **Club/competitive player (later):** fixed board comparisons, known partnership conventions, MP/IMP and human games.

### Explicit non-goals of v1 release
No official federation certification; no claim of human-level BEN strength; no simultaneous online four-person tables; no officially rated tournament; no AI-defined hidden-hand teaching during an unfinished deal; no monetization/premium tier.

## 2. Information architecture

Five conceptual destinations, **not all shipping in v1**:

| Destination | Shipping scope |
| --- | --- |
| **打牌 Play** | **P0:** free AI table, choose seat/opponent/deal, active game and subsequent board. **P1:** four-board practice, Just Declare, bidding practice |
| **學院 Learn** | **P2:** rule fundamentals, convention-based exercises, structured progress |
| **複盤 Review** | **P0:** finished-deal replay, durable history, restart same board with clear practice label. **P2:** DDS and pedagogical analysis |
| **比賽 Compete** | **P3:** async same-deal daily challenges / comparisons. **P4:** live tables, clubs, tournaments |
| **我的 Me** | **P0:** locale, accessibility, safe preferences, local sessions; **P2:** optional account/progress sync |

Do not expose empty top-level navigation destinations in release; hide or explicitly label future areas as unavailable, rather than presenting inert controls.

## 3. Golden player journeys

### GJ-01 Start-to-next-board (primary release gate)
1. Fresh install / open → Choose **AI practice** without required account.
2. Select human seat, board source (fixed training or fresh), real AI mode; display service availability.
3. Display Board Number, Dealer, Vulnerability, correct own 13 cards and current-turn information; no other private hands.
4. Player bids with legal, usable call options; BEN responses validated through Bridge Core; explicit pending/error states.
5. Play entire board (52 distinct cards, 13 tricks), including declarer controlling exposed dummy. Handle pass-out without inventing a fourth call.
6. Produce contract, declarer, tricks, signed NS scoring clearly mapped to the human seat perspective.
7. Open read-only finished replay, return to result, view saved history and optionally replay same board in clearly marked practice mode.
8. Start subsequent board with correct board definition; repeat multiple boards without restarting the app.

**Acceptance:** run >=4 consecutive different boards using actual configured BEN in deployed client, no developer localhost, no illegal actions, no hidden-hand leak, accurate scores, same-board and next-board distinction. Must pass across supported device targets.

### GJ-02 Interrupt-and-resume
During auction, after bot request, or mid-trick, pause/kill/relaunch: last **durably committed** valid event sequence is restored exactly once. An incomplete remote AI request cannot duplicate an action. Abandon/resume decisions explicit.

**Acceptance:** fault-inject kill/relaunch at 3 different phases; event history fingerprint/state match independent replay and action idempotency remains intact.

### GJ-03 Offline/error policy
If real BEN cannot be reached, show a localized recoverable error and Retry or explicitly select Demo. Never silently switch bots, claim completion, send four hands, or reveal raw request/hand/secret data. Clarify that BEN is network-backed; Demo is a distinct rules-testing mode, not equivalent strategic AI.

### GJ-04 Focused learning (post-MVP)
Launch prevalidated bidding/declarer exercise with a clear success condition; show rule-grounded solution with convention/analysis assumptions; record voluntary progress; return to normal game.

### GJ-05 Competition (long term)
Player completes a frozen comparable BoardSet under a published scoring method, with secure server ownership of hidden deals, deduplicated entries, delayed comparison and reliable rankings. Never use local in-process deck secrets as server-trusted competitor data.

## 4. Functional requirements (FR)

| ID | Requirement | Priority / delivery | Domain acceptance |
| --- | --- | --- | --- |
| FR-001 | 52-card deal, N/E/S/W seating, legal auctions X/XX/Pass Out, suit following, dummy, 13 tricks, duplicate scoring | Core present / retain | Pure Dart golden tests and independent oracle; all errors reject mutation |
| FR-002 | Board Number 1-based, dealer/vulnerability **canonical 16-board cycle**, session next-board, initial-value override | **P0 P1.1** | Boards 1–16 and 17–32 identical metadata cycle; correct dealer and vulnerability across boundaries; fixed PBN independence |
| FR-003 | Real BEN in delivered app, not developer localhost; resilient request/error contracts | **P0 P1.4** | Four human seats, mixed dealer/vul/contract fixtures, no mock fallback, actual HTTPS/service and measured latency/errors |
| FR-004 | Reliable in-progress save, versioned event log, crash recovery and idempotency | **P0 P1.2** | Kill/relaunch at auction/mid-trick/pending request resumes with exact version; corrupt data rejected safely |
| FR-005 | Accessible table interaction, usable bidding box, hand sorting, clear visible status | **P0 P1.3** | Small/mobile/tablet layouts, touch, semantics, screen-reader smoke, legal feedback; no overflow |
| FR-006 | Finish/replay current game, durable game history with filter and metadata | **P0 P1.5** | History list survives restart, can reopen terminal snapshots, no premature other-hand reveal |
| FR-007 | Restart same board as **practice** vs Next Board with proper metadata | **P0 P1.5** | Explicitly distinguish counted historical result from redo; no duplicate competition result |
| FR-008 | zh-TW and en with no user-facing hardcoded strings | **P0** | Locale changes, labels and format tests, same logical behavior |
| FR-009 | Four-board sessions and declarer-only predefined-contract mode | **P1** | Independent fixtures, skipped-auction mode does not rewrite BridgeGame auction rules |
| FR-010 | Bidding convention version/profile and **legality vs meaning vs advice** | **P1–P2** | Explanation tied to selected agreement and BEN support; UNKNOWN/UNSUPPORTED explicit |
| FR-011 | Training lessons and original puzzles, progress and review | **P2** | Expert-reviewed fixtures and repeatability; no unsourced AI claims |
| FR-012 | DDS analysis only after terminal game (or separately-authorized teaching fixture) | **P2** | Denied for hidden live hands; clearly labeled double-dummy vs real-time probability |
| FR-013 | Comparable daily board sets and MP/IMP rankings | **P3** | Identical immutable board conditions; proper comparative baseline; server authority |
| FR-014 | Human rooms, account/seat authorization, WebSocket, reconnect, spectators | **P4** | No unauthorized card disclosure; replay/idempotency/concurrency tests |
| FR-015 | Portable history/PBN import-export (post-deal, permissioned) | **P1–P2** | PBN round-trip, version and privacy rules, imported untrusted transcript rejects tampering |
| FR-016 | Optional fixed-seed daily **practice**, unranked | **P1 B6** | Stable local board identifier across users only if distribution identical; no MP/IMP, public leaderboard, false score comparisons or claim of competitive fairness |

## 5. Current repository snapshot (2026-10-15)

| Slice | Evidence | Product interpretation |
| --- | --- | --- |
| Typed Bridge Core, board cycle + seeded hands | [A1 verified Core 51/51](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38719140398), later [A2 Core 55/55](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38723931963) | BoardDefinition cycle implemented and scoped Core/Web verified; not production sign-off |
| Fixed/fresh dealing and board management | [A1 acceptance](P1_A1_BOARD_MANAGEMENT_ACCEPTANCE.md) | Dealer/vulnerability now derive from 1-based canonical BoardDefinition (not frozen N/None); fixed teaching PBN remains a special training fixture |
| Flutter table, locale, Chrome | [M2-F11 report](../m2/M2_F11_FINISHED_REPLAY_ACCEPTANCE.md) | Functional prototype; no polished production-ready table |
| True BEN pinned Python in test env | [M2-F07](../m2/M2_F07_REAL_BEN_BROWSER_ACCEPTANCE.md) and [M2-F09](../m2/M2_F09_BEN_DECLARER_UI_ACCEPTANCE.md) | Known fixed PBN E2E succeeds, production AI hosting is absent |
| Android API 35 emulator UI | [M2-F08 report](../m2/M2_F08_ANDROID_EMULATOR_ACCEPTANCE.md) | Emulator smoke only, not physical Android/iOS |
| Completed-board replay | [M2-F11 report](../m2/M2_F11_FINISHED_REPLAY_ACCEPTANCE.md) | Replay exists; persistent multi-game history and searchable archive remain to deliver |
| In-progress checkpoints and encrypted archives | [A2.7 Web/unit scope](P1_A2_7_SECURE_TRANSACTIONAL_STORAGE_ACCEPTANCE.md), [A2.8 Web browser encryption](P1_A2_8_BROWSER_ENCRYPTED_CHECKPOINT_ACCEPTANCE.md), [Flutter CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38757222196) | Implemented with scoped CI, but native device/backup, deployment, same-origin/multitab threats, remote idempotency NOT accepted |
| Durable multi-game history/auth/online competition | No completed end-to-end product gate | **NOT VERIFIED** / not ready for release |

Note: existing docs/ROADMAP.md holds engineering chronology including historical POC/CI caveats; the new product roadmap does not delete or replace that evidence.

## 6. Security, architectural and nonfunctional requirements (NFR)

- **Rules authority:** Bridge Core owns bid/card/trick/score transitions. BEN/DDS never directly commit rules outcomes.
- **Secrecy:** actor sees own cards and dummy once exposed only; no secret hands in UI JSON, HTTP URLs, logs, analytics, crash reports, or web telemetry. Existing BEN GET is **development-only trust boundary**; evaluate a server-side authenticated POST mediation for production.
- **Client vs server:** local privileged coordinator suits solo training; any trusted competition uses server-owned hidden deck and seat-authorized projections.
- **Privacy & safe storage:** private hand histories remain local/encrypted as appropriate; schema migrations, integrity validation, explicit retention/export/delete policies before launch.
- **Reliability:** safe AI timeout, bounded retries, no double-apply on reconnect; crash-safe session recovery. Collect anonymized error/failure rates, never raw private PBN.
- **Performance SLOs (targets, not claims):** engineering proposal median visible bot turnaround <=2 s; p95 <=8 s under selected production BEN settings; 99% completed valid session transitions excluding deliberate disconnects. Measure on target hardware/service before approval and revise targets if economics require.
- **Accessibility:** scalable type, 320px phone landscape/portrait where appropriate, color-independent legality, touch targets, VoiceOver/TalkBack review. Consider BBO-style rich keyboard navigation later.
- **Testing:** unit, golden, browser integration, genuine BEN service, fault injection and privacy negative tests continue as applicable. **Android emulator and physical Android/iOS UI/E2E testing are deliberately paused until owner approval**; remain mandatory before platform release, not silently waived.
- **Legal:** review BEN GPL-3.0 license terms, model checkpoints, DDS and assets at pinned SHAs before public launch. REST separation does not automatically settle obligations; document actual delivery model.

## 7. Product READY gates (not code-only)

1. **Onboarding gate:** new player starts a game without instructions from a developer.
2. **Play gate:** four seats, board numbers, dealer/vul rotation, four consecutive boards, real BEN on a reachable supported endpoint, Pass Out/X/XX and dummy.
3. **Recovery gate:** process kill and network failure recover with no event duplication.
4. **History gate:** completed boards survive process restart, replay correct and private.
5. **Interaction gate:** player testing on Android and iOS devices, accessibility and crash/performance targets evaluated.
6. **Deployment gate:** key/host/HTTPS security, monitoring, model/dependency rights and regression evidence all signed off.
7. **Teachability gate:** engineering feature lessons continue per existing AGENTS.md; the app's own bridge lessons are separate content and require bridge-convention-reviewer.

**Release verdict today: NOT READY**. Do not equate M1/M2 CI GREEN with consumer-ready MVP.

## 8. Decision and change protocol

This PRD is the **product scope authority**, while docs/BRIDGE_RULES_BASELINE.md is the **bridge legality/scoring authority**, docs/ARCHITECTURE.md is architectural boundary authority and docs/DECISIONS.md records accepted ADRs. If a product change conflicts with domain invariants, surface for explicit review rather than silently rewriting rules.

For each executable feature: add smallest relevant acceptance tests, actual CI URL + SHA, Traditional Chinese engineering lesson and learning index per AGENTS.md; direct push master, no PR. Proposed monetization, compulsory login, BEN convention compatibility, ranked competition scoring, shared persistent accounts and production license strategy require explicit product/technical decisions.
