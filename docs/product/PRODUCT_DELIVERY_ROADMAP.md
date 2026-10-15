# Bridge Academy — Product Delivery Roadmap

**Baseline:** 2026-10-15 · **Goal:** complete BBO/新睿-inspired *playable bridge product*, not a collection of green CI badges.  
**References:** [PRD v1](BRIDGE_ACADEMY_PRD_V1.md), [benchmark](COMPETITOR_BENCHMARK.md), ../ROADMAP.md (historic engineering ledger).

## 2026-10-15 delivery alignment and current action

**Existing authority remains intact.** A1 (canonical board metadata) is scoped engineering-verified; A2 includes verified Core/Web resume and later native/Web encrypted checkpoint implementations, **not a fully validated cross-device/production recovery solution**. The next **feature-development** slice is **A3 Bridge Table UI V2 design + component decomposition**. A2 deployment security, native durability, browser concurrency, and BEN request idempotency continue as explicit P0 blockers. No device or emulator run is authorized to resolve them yet.

**Device-test hold:** owner has paused all real Android/iOS and Android emulator UI/E2E testing until a separate explicit approval. The related GitHub workflows have auto-trigger removed and jobs hard-skipped. Keep A7 device QA in release criteria, but do not schedule, re-enable, or dispatch it; use pure Dart, Flutter analyze/widget, Web builds and existing allowed browser/BEN checks meanwhile. Documentation-only changes do not count as code verification.

**Daily challenge sequencing:** B6/P1 = optional **unranked, reproducible daily practice** on fixed original board sets, with local learning feedback; **D1–D4/P3** = official async duplicate comparison and any ranked daily competition/friend PK. B6 must not claim global fairness, MP/IMP, real peer rankings or anti-cheat authority. This separates a low-cost retention experiment from the server-backed tournament product.

## 1. Status taxonomy and gates

- **VERIFIED_ENGINEERING:** a scoped component has run real tests and met stated assertions, with SHA+CI evidence.
- **FEATURE_READY:** end-to-end user journey works on named supported environments, with negative/failure cases.
- **PRODUCT_READY:** all release-specific journeys, operations, privacy and target device gates cleared.
- **IN_PROGRESS / NOT IMPLEMENTED / BLOCKED:** evidence-based; a designed interface is NOT implementation.
- **LESSON_DELIVERED** is separate from engineering status; learner PRACTICED/MASTERED requires participation.

Today's baseline: Bridge Core, Web/Chrome Demo, a pinned native BEN Chrome fixture, Android emulator and in-memory finished replay have evidence. **No publicly hosted BEN endpoint, fully release-accepted persistent session, complete mobile release, tournament server or user studies have been verified.** Scoped local Web persistence and native encryption code exist; native-device and deployed-service acceptance are pending.

## 2. Critical dependency graph

```text
M1 Bridge Core + M2 PlayerView/Coordinator/BEN prototype
                 |
      A1 Board metadata [verified]
                 |
      A2 Resume and security [scoped; outstanding release gates]
                 |
      A3 Table UI V2 [next feature slice]
                 |
      A4 Production BEN integration -- licensing/privacy/cost review
                 |
      A5 Persistent history / safe replay
                 |
      A6 Four-board golden path and A7 release/device acceptance [device QA on hold]
                 |
           SINGLE-PLAYER MVP
             /      |      \\
  B Practice/Teach  C Analysis  D Async competition (server-backed)
   incl. B6 daily    DDS/review      MP/IMP, friend challenges
   unranked practice                       |
                                 E Live multiplayer/community
```

The graph represents completion dependencies and **does not authorize Android device test execution**. Different slices may be designed or implemented concurrently; no product gate can be marked READY based on isolated CI evidence alone.

## 3. Phase A — Playable Single Player (P0; next implementation)

| Slice | Visible deliverable | Tests / exact acceptance | Existing basis | Status |
| --- | --- | --- | --- | --- |
| **A1 / P1.1 Board Management** | Board Number, Dealer, Vulnerability, Replay Same Board, Next Board and fixed/fresh labels | Canonical 16-board dealer/vul cycle and repeat at 17; four seats; scoring; BEN wire/Flutter zh-TW/en | [M2-F12 acceptance](P1_A1_BOARD_MANAGEMENT_ACCEPTANCE.md) | **CORE/FLUTTER WEB + FIXED REAL BEN VERIFIED; ANDROID REGRESSION PENDING** |
| **A2 / P1.2 Persistence** | Best-effort restore prototype with versioned transcript and read-only player projection | [M2-F13 acceptance](P1_A2_PERSISTENCE_ACCEPTANCE.md); reliable encrypted/transactional storage, real crash tests, server idempotency still required | Coordinator replay + SharedPreferencesAsync local checkpoint | **A2 Core/Web checkpoint tests and A2.7 encrypted native storage implemented; A2.8 encrypted Web archive added; [latest Flutter/Chrome CI success](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38757222196). Physical device verification, browser deployment/XSS/multitab review and real BEN exactly-once still BLOCKED/NOT VERIFIED.** |
| **A3 / P1.3 Table UX V2** | Componentized BoardHeader, four seats, current trick, player/dummy cards, and controlled BiddingBox (A3.1/A3.2); polished A3.3+ still pending | Flutter 320/375/768px + locale + dummy and bid contract tests; Chrome Demo regression; hardware accessibility and real BEN release E2E still required | [A3 component spec/acceptance](A3_BRIDGE_TABLE_V2_SPEC.md); [Flutter CI 69/69 + Chrome Demo PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38769943196) | **A3.1/A3.2 SCOPED WEB VERIFIED; A3.3–A3.5 NOT VERIFIED; device QA ON HOLD** |
| **A4 / P1.4 Real BEN client delivery** | One-click real AI in installed/distributed app; no local Python prerequisite | Authenticated HTTPS and private hand data handling; BEN no silent Demo fallback; 4-seat/16-board matrix; measured p50/p95/errors with actual model settings; fail/retry | Real pinned Python BEN Chrome fixed-board CI; local HTTP GET dev integration | PARTIAL / PRODUCTION BLOCKED |
| **A5 / P1.5 History + Same-deal retry** | Persistent finished-deal list, search/filter, replay and labeled training re-run | Survive app restart, import untrusted transcript safely, exact score replay, no original result double-count, no hidden-hand leak | In-memory finished replay exists | PARTIAL |
| **A6 / P1.6 Multi-board E2E acceptance** | Repeated four+ board playable session, automatic board metadata, recoverable errors | 4 seats × fixed/fresh boards, Pass Out, X/XX, contract game, dummy, 52/13; device/real-AI playtest; CI+human observation | Existing fixed-board CI only | NOT VERIFIED |
| **A7 / P1.7 Release readiness** | Real installable builds, privacy/license, localizations, telemetry safety, release checklist | Physical Android and iOS + Web smoke; crash/latency profiling, third-party review, device matrix | Android emulator smoke and Flutter Web build | PARTIAL |

### A2.3 next validation slice (2026-10-15)

Add a real Android emulator **two-launch** checkpoint test to the existing A2.2 implementation, with an explicit adb force-stop separating the first and second flutter drive. Check a nonterminal mid-trick board, identical event version/fingerprint, public Dummy, no raw private-hands projection, restored App UI, and one subsequent legal action. [Dedicated acceptance](P1_A2_3_ANDROID_PROCESS_RESTART_ACCEPTANCE.md). Actual [Android CI #38731973367](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38731973367) **SUCCESS** on process-restart acceptance (independent app launches and explicit force-stop). This does not prove write-in-progress kill or encrypted release storage. A2.4 [rollback warning](P1_A2_4_ROLLBACK_NOTICE_ACCEPTANCE.md) is verified for Flutter Web; its warning state was only in memory. **A2.5** [persisted acknowledgment marker](P1_A2_5_DURABLE_RECOVERY_CONSENT_ACCEPTANCE.md) is the current focused fix (CI pending).

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

### A2.6 in-flight device acceptance (2026-10-15)

Add a **genuine Android API 35 three-process fault-injection test** after A2.5 durable rollback consent: Process A commits two versions and corrupts latest; Android force-stop; Process B restores previous version and displays warning, blocks action; second Android force-stop; Process C must display same warning until actual acknowledgement UI action. The test must verify no fabricated action, final 4 legal Pass events and saved state. [Acceptance](P1_A2_6_ANDROID_ROLLBACK_CONSENT_ACCEPTANCE.md). **IMPLEMENTED, CI NOT YET RUN AT AUTHORING.** Existing A2.3 two-process test is not a substitute. This does not solve plaintext SharedPreferences, fsync or multi-tab CAS.

### A2.8 Browser encrypted checkpoint integration (2026-10-15)

**Implemented, new CI pending:** Close plaintext Web-hand storage by routing default Flutter Web sessions to an AES-256-GCM encrypted single-record LocalStorage adapter using flutter_secure_storage WebCrypto keys and validation-first legacy migration. Real Chrome WebCrypto reload acceptance, localized browser risk notice, and key/tamper/recovery tests. Best-effort browser persistence, **not** SQLite ACID, XSS isolation, cross-tab CAS or hardware-bound confidentiality. Native device QA is deferred per owner decision. [Acceptance](P1_A2_8_BROWSER_ENCRYPTED_CHECKPOINT_ACCEPTANCE.md).

### A2.7 secure storage (2026-10-15)

Implemented native Android/iOS encrypted SQLite checkpoint adapter, AES-GCM, key in platform secure storage, commit/recovery in one SQL row, validation-first migration. [Dedicated acceptance](P1_A2_7_SECURE_TRANSACTIONAL_STORAGE_ACCEPTANCE.md). **CI NOT RUN at drafting; user explicitly deferred physical Android/iOS device QA until larger product capabilities are complete.** Web SharedPreferences still plaintext and remains unapproved for production confidential-hand storage. Device crypto, backup/restore, fsync, concurrent sessions and remote BEN idempotency need separate release gates.

## 4. Phase B — Practice & Teaching (P1–P2; after viable play)

| Slice | Product output | Boundaries / acceptance |
| --- | --- | --- |
| B1 Four-board sessions | Session result aggregation and clear next-board UX | Finish 4 legitimate distinct boards, session summary; per-board and aggregate results not conflated |
| B2 Just Declare | Predefined legitimate teaching contract, skip ordinary auction for training only | Separate mode with explicit setup state; no fabricated auction or rules bypass in normal matches |
| B3 Bidding Practice | Pattern-based partnership bidding without forced card play | Versioned ConventionProfile, partner agreements, external expert review |
| B4 Guided training | Original curated problems and answers; simple progress metrics | One scenario per competency, proven answer rules and no hidden information leakage |
| B5 Training review | Replay same deal and explain critical decisions | Legality vs agreement vs strategic quality distinguished |

### B6 / P1 — Daily fixed-board **practice preview** (no rankings)

- Generate/version four **original** practice boards with the canonical dealer/vulnerability cycle; show the same local challenge identifier and a personal summary, subject to a clear retention/cutover policy.
- May use a signed, published board manifest once needed, but without authenticated server-supplied comparison results it is **not** a Duplicate event. Replaying for study is allowed and explicitly labeled; results are not competition entries.
- Acceptance: reproducible deal IDs and local scores, 4-board retry/restore, no private-hand leak, never show fabricated MP/IMP, opponent rank, or friend comparison; no live leaderboard.

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
