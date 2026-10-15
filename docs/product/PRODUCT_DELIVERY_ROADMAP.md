# Bridge Academy — Product Delivery Roadmap

**Baseline:** 2026-10-15 · **Goal:** complete BBO/新睿-inspired *playable bridge product*, not a collection of green CI badges.  
**References:** [PRD v1](BRIDGE_ACADEMY_PRD_V1.md), [benchmark](COMPETITOR_BENCHMARK.md), ../ROADMAP.md (historic engineering ledger).

## 1. Status taxonomy and gates

- **VERIFIED_ENGINEERING:** a scoped component has run real tests and met stated assertions, with SHA+CI evidence.
- **FEATURE_READY:** end-to-end user journey works on named supported environments, with negative/failure cases.
- **PRODUCT_READY:** all release-specific journeys, operations, privacy and target device gates cleared.
- **IN_PROGRESS / NOT IMPLEMENTED / BLOCKED:** evidence-based; a designed interface is NOT implementation.
- **LESSON_DELIVERED** is separate from engineering status; learner PRACTICED/MASTERED requires participation.

Today's baseline: Bridge Core, Web/Chrome Demo, a pinned native BEN Chrome fixture, Android emulator and in-memory finished replay have evidence. **No publicly hosted BEN endpoint, persistent session, complete mobile release, tournament server or user studies have been verified.**

## 2. Critical dependency graph

~~~text
Existing M1 Bridge Core / M2 local Coordinator / PlayerView / BEN prototype
                         |
                   A1 Board metadata
                         |
               A2 Durable game resume
                         |
             A3 Production table UX
                         |
          A4 Real BEN delivery boundary ----- Licensing / privacy / cost decision
                         |
                A5 Durable history
                         |
              A6 Multi-board playtest
                         |
               SINGLE PLAYER MVP GO
                     /          \
       B Training & Review     C Async duplicate
               |                       |
       D DDS/learning       server-owned board sets + comparative scoring
                                       |
                             E Live multiplayer
~~~

Some tasks may be developed in parallel, but **the MVP acceptance run depends on all A gates**. Separate module PASS does not automatically prove the end-to-end player journey.

## 3. Phase A — Playable Single Player (P0; next implementation)

| Slice | Visible deliverable | Tests / exact acceptance | Existing basis | Status |
| --- | --- | --- | --- | --- |
| **A1 / P1.1 Board Management** | Board Number, Dealer, Vulnerability, Replay Same Board, Next Board and fixed/fresh labels | Canonical 16-board dealer/vul cycle and repeat at 17; four seats; scoring; BEN wire/Flutter zh-TW/en | [M2-F12 acceptance](P1_A1_BOARD_MANAGEMENT_ACCEPTANCE.md) | **CORE/FLUTTER WEB + FIXED REAL BEN VERIFIED; ANDROID REGRESSION PENDING** |
| **A2 / P1.2 Persistence** | Best-effort restore prototype with versioned transcript and read-only player projection | [M2-F13 acceptance](P1_A2_PERSISTENCE_ACCEPTANCE.md); reliable encrypted/transactional storage, real crash tests, server idempotency still required | Coordinator replay + SharedPreferencesAsync local checkpoint | **A2.1 VERIFIED; A2.2 TWO-SLOT CHECKPOINT VERIFIED; A2.3 ANDROID PROCESS RESTART TEST IMPLEMENTED / CI PENDING; encrypted/transactional storage and kill-during-write still release blockers** |
| **A3 / P1.3 Table UX V2** | Legible four-seat table, compact bidding box, sortable legal cards, hand/trick feedback, correct dummy ownership, accessible controls | Real Android/iOS/Web manual + automated tasks; 320/375/768px; no overflow; TalkBack/VoiceOver feedback; no inaccessible controls | Functional single large Flutter table exists | PARTIAL |
| **A4 / P1.4 Real BEN client delivery** | One-click real AI in installed/distributed app; no local Python prerequisite | Authenticated HTTPS and private hand data handling; BEN no silent Demo fallback; 4-seat/16-board matrix; measured p50/p95/errors with actual model settings; fail/retry | Real pinned Python BEN Chrome fixed-board CI; local HTTP GET dev integration | PARTIAL / PRODUCTION BLOCKED |
| **A5 / P1.5 History + Same-deal retry** | Persistent finished-deal list, search/filter, replay and labeled training re-run | Survive app restart, import untrusted transcript safely, exact score replay, no original result double-count, no hidden-hand leak | In-memory finished replay exists | PARTIAL |
| **A6 / P1.6 Multi-board E2E acceptance** | Repeated four+ board playable session, automatic board metadata, recoverable errors | 4 seats × fixed/fresh boards, Pass Out, X/XX, contract game, dummy, 52/13; device/real-AI playtest; CI+human observation | Existing fixed-board CI only | NOT VERIFIED |
| **A7 / P1.7 Release readiness** | Real installable builds, privacy/license, localizations, telemetry safety, release checklist | Physical Android and iOS + Web smoke; crash/latency profiling, third-party review, device matrix | Android emulator smoke and Flutter Web build | PARTIAL |

### A2.3 next validation slice (2026-10-15)

Add a real Android emulator **two-launch** checkpoint test to the existing A2.2 implementation, with an explicit adb force-stop separating the first and second flutter drive. Check a nonterminal mid-trick board, identical event version/fingerprint, public Dummy, no raw private-hands projection, restored App UI, and one subsequent legal action. [Dedicated acceptance](P1_A2_3_ANDROID_PROCESS_RESTART_ACCEPTANCE.md). Initial status: **IMPLEMENTED / ANDROID CI PENDING**; do not conflate it with write-in-progress kill or encrypted release storage.

### A2.2 current execution slice

Implement two-slot best-effort checkpoint storage with a commit pointer and SHA-256 accidental-corruption check, validated through the existing SavedBoardCodec and replay rules. Migrate previously verified v1 single-key local saves without deleting original before v2 commit. [Dedicated acceptance report](P1_A2_2_CHECKPOINT_HARDENING_ACCEPTANCE.md). This does NOT claim encrypted disk, fsync/ACID transaction, secure delete, tamper-proofing, concurrent-tab locking, physical-device kill/relaunch or BEN remote idempotency; these remain outstanding **P0 product release blockers**.

### A1 first execution contract (historical)

**Input:** existing Bridge Core Seat/Vulnerability/Deal; current BridgeSession.newGame with N/None; fixed & fresh board selector.

**Proposed API:** immutable BoardDefinition(number, dealer, vulnerability); BoardSchedule.forNumber(n) (or equivalent) in pure Dart; coordinator accepts explicit dealer/vulnerability without changing BridgeGame legal rules. Board numbering is session metadata, not derived from PBN.

**Standard 16-board pattern:**
- Dealer repeats N,E,S,W.
- Vulnerability for boards 1–16: None, NS, EW, Both, NS, EW, Both, None, EW, Both, None, NS, Both, None, NS, EW.
- Board 17 cycles to Board 1 metadata, while deal contents may differ.
- Reject board number <=0 and invalid/dealer-vulnerability inference from bare PBN.
- Fixed training fixture remains stable for CI; clear new-board choice and repeat-same-board semantics.

**Required proof:** unit golden test boards 1–32, four dealer seats, signed duplicate scoring vs vulnerability; Flutter localized display/test and actual Chrome; no altered prior fixed BEN test fixtures; engineering note and mentor lesson per AGENTS.md. UI implementation may be split into A1.1 pure-core and A1.2 Flutter integration, each separately accepted.

**Stop condition:** if user-facing board number disagrees with coordinator dealer/vulnerability, do not ship. If fixed BEN regression requires an exception, it must be an explicit training-mode fixture decision, never silent divergence.

## 4. Phase B — Practice & Teaching (P1–P2; after viable play)

| Slice | Product output | Boundaries / acceptance |
| --- | --- | --- |
| B1 Four-board sessions | Session result aggregation and clear next-board UX | Finish 4 legitimate distinct boards, session summary; per-board and aggregate results not conflated |
| B2 Just Declare | Predefined legitimate teaching contract, skip ordinary auction for training only | Separate mode with explicit setup state; no fabricated auction or rules bypass in normal matches |
| B3 Bidding Practice | Pattern-based partnership bidding without forced card play | Versioned ConventionProfile, partner agreements, external expert review |
| B4 Guided training | Original curated problems and answers; simple progress metrics | One scenario per competency, proven answer rules and no hidden information leakage |
| B5 Training review | Replay same deal and explain critical decisions | Legality vs agreement vs strategic quality distinguished |

## 5. Phase C — Analysis and Improvement (P2)

- C1 DDS post-deal analysis with visible **DOUBLE-DUMMY** label, counterfactual meaning, no live single-dummy cheating.
- C2 Versioned convention explanations and BEN compatibility notes; unsupported system must display UNKNOWN / UNVERIFIED rather than guessed claim.
- C3 Learner progress and original daily practice prompts; opt-in retention and ability to remove.
- C4 Safe permissioned PBN/history import-export with schema/fingerprint/score validation.

## 6. Phase D — Asynchronous duplicate (P3)

- D1 Server-generated, immutable time-scoped BoardSet ID and deal authority.
- D2 MP comparison from an explicit real comparison field and proper IMP reference datum; never rebrand NS score as MP/IMP.
- D3 Repeat/submit policy, score audit, fair-play/hidden-card controls, regional policy and leaderboard.
- D4 Friend/group async challenge and replay comparison.

## 7. Phase E — Live multiplayer & club ecosystem (P4+)

- E1 Identity, authenticated seats, authoritative server game state, seat-filtered WebSocket fan-out and idempotent actions.
- E2 Presence, spectators with delayed private state, invitations, reconnect & abandonment adjudication.
- E3 Teaching tables/partner convention cards, moderation and accessibility.
- E4 Clubs, tournaments, director tools, fraud/collusion controls, scale/observability and policy compliance.

## 8. Release decision gates and metric proposals

| Milestone | Must prove | Evidence / decision |
| --- | --- | --- |
| A1 done | Correct BoardDefinition across 32 numbers; no hidden-info/scoring regression | CI+lesson |
| A2 done | Replay persists mid-board and survives crash; corrupt data rejected | kill/relaunch tests, schema migration |
| A4 done | Deployed authorized AI reachable by actual phones; license/weights reviewed; error handling and latency measured | security/privacy, real BEN performance benchmark |
| Single Player MVP READY | GJ-01/02/03 on Android/Web and target iOS, >=4 consecutive genuine AI deals, history and resume, no unhandled leak/crash | human acceptance + device QA + operational evidence |
| Phase B READY | Independent validated teaching fixtures and novice exercises | reviewer + accessibility test |
| Phase D READY | Same board/robot settings/comparison methodology, anti-cheat and fair MP/IMP | server audit + multi-user soak tests |
| Phase E READY | Server game rules, multiplayer reconnect and isolation at concurrent scale | privacy/security QA and director playtest |

**Proposed telemetry targets, not measured facts:** session start success >=99%; legal-action accuracy 100%; median BEN decision <=2 s, p95 <=8 s under selected actual deployment settings; crash-free session >=99.5%. Benchmarks and thresholds may be revised after production model profiling and device QA. No false claims of meeting them.

## 9. Ownership, workflow and documentation

- Product sequencing: bridge-orchestrator, docs/product PRD and this roadmap.
- Pure rules, board cycles, score: bridge-rules-reviewer and Bridge Core.
- AI, server, fair-play, idempotency: bridge-ai-integration + bridge-architecture-guardian.
- Convention semantics: bridge-convention-reviewer.
- External model/license/weights: bridge-open-source-auditor.
- QA, true AI vs mock evidence: bridge-playtest.
- After each real feature: bridge-learning-mentor and one Traditional-Chinese lesson / docs/learning/INDEX.md update.
- All implementation work pushed directly to master with safe commits, tests and actual CI evidence (no PR per approved workflow).
- Preserve historic engineering gates in ../ROADMAP.md; update this roadmap only when player-facing acceptance actually passes.
