# Bridge Academy — Product Delivery Roadmap

**Product addendum (2026-10-24)**: Owner approved **2/1 Game Force / SAYC / Precision Club** as the initial configurable robot bidding systems, then verified custom agreements; see [Three-System AI Master Plan](THREE_SYSTEM_BIDDING_AI_MASTER_PLAN.md). This is a cross-phase convention-engine track **M1–M6**, not a replacement for Phase A delivery or an authorization to bypass device QA, production/licensing, or ranked duplicate release gates. M1.1 static+Mock capabilities CI is scoped verified, real BEN multisytem decisions remain NOT RUN; see [M1 Spike](../research/BEN_MULTI_SYSTEM_M1_SPIKE.md).

**M3.3 isolated native Precision provider (2026-10-24):** [Engineering acceptance](../research/M3_3_PRECISION_PROVIDER_ACCEPTANCE.md). New pure Dart `bridge_precision_adapter` accepts only filtered PlayerView and returns proposed CallAction; localhost native EPBot sidecar enforces pinned BEN commit, Meckwell V1 CC/native SHA, caller seat/auction and explicitly mapped BBA opponent BEN-21GF/BEN-SAYC CCs. Owner confirms BBA commercial hosting, modification and redistribution permission; exact terms/provenance notices still require separate release records. Isolated native CI PASS for provider contract/real EPBot openings, not M3.4 full-game integration; BEN has no Precision opponent reader, so **player activation and production remain blocked**. [M3.3 CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/precision-m33-provider.yml).

**M3 V1 convention decision (2026-10-24):** The sole selected third-system variant is [BBA Meckwell Precision V1](../conventions/PRECISION_BBA_MECKWELL_V1.md), `BA-PRECISION-MECKWELL/r1`, 1NT 13–15, pinned to one BBA `Meckwell.bbsa` SHA. Project owner reports BBA usage permission obtained; rights-scope proof and full M3.3/M3.4 provider/golden-fixture Gateway integration are still gated. Older "specific variant undecided" language is superseded; **do not advertise Precision as playable yet**. [ADR-031](../DECISIONS.md) · [Dart 10/10 and Gateway 44/44 CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40093845902).

**M3 Precision research-only addendum (2026-10-24):** Pinned BEN/EPBot `Meckwell.bbsa` research completed, eight real native Precision openings (four strong 1C samples; zero mismatch) [CI #40092096757](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40092096757). Unlike BEN 21GF/SAYC, it is a **separate native BBA provider**, without a verified playable Precision neural bidder. The BBA Meckwell card specifies 1NT 13–15, while Meckwell Lite 2026-01-05 reference uses 13–16; this and absent upstream BBA license BLOCK player selection/release. Research-only [M3 report](../research/M3_PRECISION_SPIKE_ACCEPTANCE.md), [license audit](../OPEN_SOURCE_AUDIT.md). No Gateway or Flutter Precision toggle added; M2 unaffected. Next gate: chosen convention variant + author rights + expert-approved golden fixtures + mixed-engine full-game adapter E2E.

**M2.2–M2.5 engineering addendum (2026-10-24):** [System routing + Flutter choice + genuine BEN full-game acceptance](../research/M2_2_TO_M2_5_IMPLEMENTATION_ACCEPTANCE.md) SCOPED VERIFIED: Adapter 29/29, Gateway 44/44, Flutter analyze/Widget/Web/Chrome-demo all pass; two full genuine BEN 52-card/13-trick server-authoritative games with 21GF/SAYC reversed [CI #40087851963](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40087851963). No production go: licensed weights/third-party binaries, target 4GB machine load, expert-reviewed convention semantics, A3.5/device QA and ranked competition remain gated. Next approved direction: Precision M3 spike and rule-card expert evidence.

**M1.3–M1.4 addendum (2026-10-24):** [Real BEN A/B Acceptance](../research/BEN_MULTI_SYSTEM_M1_3_ACCEPTANCE.md) and [Isolated Capacity Report](../research/BEN_MULTI_SYSTEM_M1_4_CAPACITY.md) scoped VERIFIED in [CI #40076200888](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40076200888): 16 synthetic public/test contexts × two true BEN 21GF/SAYC models = 32 successful /bid, no basic illegal proposals or three sampled forcing violations; single process concurrent and dual process RSS measured. **No expert golden corpus, no Core replay, no 2 vCPU/4GB target-host benchmark, no default full-simulation benchmark, no model-weights license approval, no production GO.** Prefer one bounded-concurrency BEN Worker as candidate for M2; do not change production Gateway/QA hold.

**M1.2 addendum (2026-10-24):** [Pinned candidate BEN 0.9 SHA256 + genuine GET / acceptance](../research/BEN_MULTI_SYSTEM_M1_2_ACCEPTANCE.md) scoped VERIFIED: 20 tests, real 21GF/SAYC capability, CI [#40075250217](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40075250217), observed 899920 KiB process RSS. This is NOT actual /bid semantics, 4GB capacity proof, redistribution approval, or production deployment. M1.3/M1.4 remain OPEN.

**Baseline:** 2026-10-15 · **Goal:** complete BBO/新睿-inspired *playable bridge product*, not a collection of green CI badges.  
**References:** [PRD v1](BRIDGE_ACADEMY_PRD_V1.md), [benchmark](COMPETITOR_BENCHMARK.md), ../ROADMAP.md (historic engineering ledger).

## 2026-10-15 delivery alignment and current action

**Existing authority remains intact.** A1 (canonical board metadata) is scoped engineering-verified; A2 includes verified Core/Web resume and later native/Web encrypted checkpoint implementations, **not a fully validated cross-device/production recovery solution**. A3.5 was expressly deferred by the owner; next feature is **A4 Production BEN Integration**, A4.1 client scoped verified; current implementation work is A4.2 localhost Gateway. A4.3.1 BEN loopback smoke is verified, A4.3.2 server-owned training game is verified; A4.3.2b encrypted single-process restart including SIGKILL test is scoped verified. Production-grade multi-node durability, global legacy raw API removal, multiplayer seat authorization, and A4.3.3 complete pinned real BEN Gateway fixed-board game has now **passed** scoped 52-card/13-trick CI; wide scenario matrix, public TLS and A4.5 remain open; A4.4 Flutter/Web scoped CI now passes and one [genuine Chrome→localhost Gateway→BEN full board PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38849429500); public HTTPS, capacity, privacy/licensing and device gates remain OPEN. Hosted HTTPS remains blocked. A2 deployment security, native durability, browser concurrency, and BEN request idempotency continue as explicit P0 blockers. No device or emulator run is authorized to resolve them yet.

**Device-test hold:** owner has paused all real Android/iOS and Android emulator UI/E2E testing until a separate explicit approval. The related GitHub workflows have auto-trigger removed and jobs hard-skipped. Keep A7 device QA in release criteria, but do not schedule, re-enable, or dispatch it; use pure Dart, Flutter analyze/widget, Web builds and existing allowed browser/BEN checks meanwhile. Documentation-only changes do not count as code verification.

**Daily challenge sequencing:** B6/P1 = optional **unranked, reproducible daily practice** on fixed original board sets, with local learning feedback; **D1–D4/P3** = official async duplicate comparison and any ranked daily competition/friend PK. B6 must not claim global fairness, MP/IMP, real peer rankings or anti-cheat authority. This separates a low-cost retention experiment from the server-backed tournament product.

## 2026-10-16 delivery decision — A3.5 deferred; A4 begins

The owner **postponed A3.5 final UI/physical device/assistive tech acceptance** without waiving it. A3.1–A3.4 remain scoped Flutter/Web/real BEN CI verified; **A3 product/release GO is NOT VERIFIED**. Android emulator and physical Android/iOS UI/E2E remain off until separately approved.

**A4: Production BEN Integration** (do not conflate MockClient coverage with production hosting):

| Slice | Deliverable | Status |
| --- | --- | --- |
| A4.1 | Versioned authenticated HTTPS POST Gateway client, injected short-lived token supplier; no hand/token in URL; failure/safe-response tests | **SCOPED VERIFIED: [23/23 Adapter CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38833132162); no remote Gateway** |
| A4.2 | **Loopback-only** Gateway with anonymous 15m bearer capability, per-peer/per-token quotas, strict API field/schema validation and injected backend | **SCOPED VERIFIED**: [14/14 real localhost HTTP CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38836219472); **not remote BEN, not verified seat/board authorization, not public HTTPS deployment** |
| A4.3 | **A4.3.1** literal-loopback BEN GET worker behind authenticated local Gateway POST; **A4.3.2** server-controlled game/seat authority and request dedup; **A4.3.3** pinned real BEN acceptance | **A4.3.1 [HTTP 20/20 PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38837641317) + [TRUE BEN bid/lead/play PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38837641285)**; **3.2 [server-owned game/version/replay in-memory HTTP 27/27 VERIFIED](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38839175287)**; 3.2b [encrypted checkpoint + actual Dart process SIGKILL restart 32/32 CI VERIFIED](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38841623172) (single-node local only); distributed durable identity/seat competitive authority OPEN; 3.3 [genuine pinned full 52-card / 13-trick Gateway game PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38845244764) (one fixture, 6NT, NS -250); no production authorization |
| A4.4 | Explicit Flutter server-owned Gateway opt-in, typed public PlayerView, HTTPS/loopback allowlist, ephemeral bearer, same-ID lost-response retry, zh-TW/en UI | **[SCOPED FLUTTER 86/86 + Web Build + Chrome Demo PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38848030915)**; Chrome→real Gateway→BEN first test [failed 429](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38848501397); [corrected genuine Chrome→Gateway→BEN full board PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38849429500); local-only dev quota 180, default 30, **no hosted HTTPS** |
| A4.5 | Staging HTTPS deployment, weights/license, cost/latency/concurrency/privacy review, multi-board acceptance | **STATIC PREPARATION VERIFIED**: [preflight/CI PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38983766063), [release gates](A4_5_DEPLOYMENT_READINESS.md); **hosted HTTPS, licensing, observed capacity & production GO remain BLOCKED** |

[A4.1 wire contract](A4_GATEWAY_CONTRACT_V1.md). Deployment, credential issuing, server authorization and production latency are not implemented or verified.

## 2026-10-16 — A4.3.2b encrypted local restart slice

**SCOPED ENGINEERING VERIFIED — [Gateway 32/32 CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38841623172), including SIGKILL/new Dart process restart:** optional AES-256-GCM encrypted checkpoint store for the anonymous Gateway, SHA-256 bearer digests only, restored Bridge Core event replay, completed request ID results, and partial bot-batch checkpoints after every committed Bridge Core action. Startup requires a 32-byte external key and aborts on wrong key/corrupt archive. In durable mode legacy `/v1/ai/decision` with caller-provided hands is **disabled (404)**. Default ephemeral mode retains the existing local pinned-BEN smoke behavior. [Acceptance](A4_GATEWAY_A4_3_2B_ACCEPTANCE.md).

**Not full A4.3.2b production verification:** the first slice is single-process, local-only; no SIGKILL *during an atomic write*, no replicated event store, distributed exactly-once, production vault/rotation, crash-hardened fsync-directory guarantee, or service hosting. A4.3.3 real full-game BEN and deferred A3.5/device QA remain open.

## 2026-10-16 — A4.3.3 full genuine BEN through server-owned Gateway

**[PINNED REAL BEN 52-CARD PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38845244764) — fixed 6NT, 13 tricks, 52 cards, 30 true BEN calls, 10.7s elapsed, p95 996ms; Gateway 32/32 tests PASS:** A fixed, previously proven BEN 13-trick board is now driven through anonymous Gateway POST `/v1/games/view`, `/v1/games/action`, and `/v1/games/advance`, while the server keeps the four-hand Deal and BEN sees only its acting-seat PlayerView. The runner requires exactly 13 tricks, 52 distinct cards, Bridge Core terminal score and event version consistency, plus successful genuine pinned `bid`, `lead` and `play` operations. No raw hand, token, BEN URL or private debug is logged. The real model CI reuses its single Python dependency setup for both 3-route smoke and full-game tests. [A4.3.3 acceptance](A4_GATEWAY_A4_3_3_ACCEPTANCE.md).

This is *not* A4 production readiness. Remaining: multiple board/seat/vulnerability regression, mid-model/process interruption, durable multi-instance idempotency, real hosted HTTPS, user-facing Flutter integration, license/model weights, p50/p95+memory/cost and owner-deferred A3.5/device QA.

## 2026-10-16 — A4.4 Flutter Gateway opt-in

**[SCOPED FLUTTER CI PASS 86/86 + Chrome Demo](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38848030915):** `BRIDGE_GATEWAY_ORIGIN` explicitly selects `GatewayTable`, backed by a dedicated server-owned `GatewayGameSession` and strict `GatewayHttpApi`. No default URL, shared client secret, caller-supplied hand, Deal, Demo fallback or credential persistence. On a lost response after a server event, the original `request_id` and `expected_version` stay pending; the player can refresh authoritative view and retry the exact request. UI reuses the existing accessibility-aware card/table/bidding components and translates errors into zh-TW/en. Backend browser CORS Origins are separately explicit; no wildcard. [A4.4 acceptance](A4_GATEWAY_A4_4_ACCEPTANCE.md).

**Limitations:** token is volatile and page refresh loses it; no public HTTPS host, published mobile secure session or real Flutter Chrome-to-Python BEN E2E. Existing Demo/old BEN developer mode stays unchanged when Gateway is not configured. A3.5 and Android/iOS device hold remains in place.

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
      A3 Table UI V2 [A3.1–A3.4 scoped PASS; A3.5 deferred]
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
| **A3 / P1.3 Table UX V2** | A3.1–A3.3 componentized responsive table/bidding/history/replay; **A3.4 localized card/seat semantics, 48px targets, non-color turn cue, scaled text** | 320/375/768px plus 1.6–2x text, disabled states, Chrome Demo and real BEN; physical TalkBack/VoiceOver and high-fidelity UI review still pending | [A3 acceptance](A3_BRIDGE_TABLE_V2_SPEC.md) · [Flutter 80/80 + Chrome Demo](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38819474371) · [True BEN Chrome](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38819474505) | **A3.1–A3.4 SCOPED ENGINEERING VERIFIED; A3.5 RELEASE ACCEPTANCE NOT VERIFIED; device QA ON HOLD** |
| **A4 / P1.4 Real BEN client delivery** | A4.1 HTTPS POST Client + A4.2 loopback-only anonymous Gateway with bearer scope/TTL, rate limits and validated JSON; **backend defaults 503** | Localhost HTTP integration tests, 401/429/413/503, CORS and privacy; A4.3 private BEN, server game/seat authority, remote idempotency and deployed HTTPS still pending | [A4.1 contract](A4_GATEWAY_CONTRACT_V1.md) · [A4.2 acceptance](A4_GATEWAY_A4_2_ACCEPTANCE.md) · [A4.2 server](../../services/bridge_gateway/lib/src/gateway_service.dart) | **A4.1 VERIFIED; A4.2 LOOPBACK HTTP 14/14 VERIFIED; PRODUCTION BLOCKED** |
| **A5 / P1.5 History + Same-deal retry** | **A5.1** player-facing history of up to 12 locally encrypted completed boards; tap old board for canonical replay; same-deal attempts get distinct IDs | Restore finished list, reject corrupt archive, no all-hand UI leak; **A5.2 [search/filter/page/delete and encrypted tombstones Flutter 94/94 VERIFIED](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38857429965)**, **A5.3.1** player-approved local completed PBN `[Deal]` + auction + result export [FLUTTER 97/97 VERIFIED](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38863038248); **A5.3.2** local 13-trick [Play] PBN [97/97 Flutter + Web CI VERIFIED](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38866531814); **A5.3.3** first-party completed PBN import + encrypted history UI **[Flutter 101/101 + Web/Chrome VERIFIED](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38868661345)**; authorized Gateway history OPEN | [A5.1 acceptance](A5_1_HISTORY_ACCEPTANCE.md) · [History UI](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_history_panel.dart) | **[A5.1 Flutter 91/91 + Web + Chrome Demo SCOPED PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38852504246)**; A5 overall PARTIAL (local PBN export scoped PASS; remote Gateway/archive OPEN; local PBN import scoped PASS) |
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

## 2026-10-16 — A5.1 user-facing completed history (first vertical slice)

**[SCOPED FLUTTER CI PASS 91/91 + WEB BUILD + CHROME DEMO](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38852504246):** Players can open a saved history list from the local single-player table, view board/contract/score/date/seat, and reopen an old terminal deal's canonical First/Prev/Next/Last replay without interrupting the new game. History is encrypted in a separate browser/native store and bounded at 12 entries; same-board replays count as distinct practice attempts, with a persisted game ID preventing duplicated archival after restart. The first A5.1 release does **not** yet include searchable history, PBN export, or Gateway remote history. [A5.1 acceptance](A5_1_HISTORY_ACCEPTANCE.md) · [M2-F33 teaching note](../learning/features/M2_F33_COMPLETED_HISTORY.md).

## 4. Phase B — Practice & Teaching (P1–P2; after viable play)

| Slice | Product output | Boundaries / acceptance |
| --- | --- | --- |
| B1 Four-board sessions | **[SCOPED FLUTTER 109/109 + WEB + CHROME DEMO PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38880212042):** player-visible Start 4-board practice, four fresh deals, sequential WBF board numbers, signed practice score and terminal summary; practice state stored in encrypted active checkpoint | Finish 4 distinct Core-valid boards, persistent in-progress series, no MP/IMP claim; [B1 acceptance](B1_FOUR_BOARD_PRACTICE_ACCEPTANCE.md) |
| B2 Just Declare | **B2.2 IMPLEMENTED / FRESH CI PENDING:** choose 1–7 C/D/H/S/NT **and N/E/S/W declarer**, play from explicit teaching contract, see declarer/dummy, tricks won vs target and made/down result, checkpoint/history/replay | Fixes B2.1 missing Flutter Session methods; Core schema-v2 start with no fabricated auction; Demo Bot labeled (NOT BEN); [B2 acceptance](B2_JUST_DECLARE_ACCEPTANCE.md) · [M2-F41](../learning/features/M2_F41_JUST_DECLARE_FOUR_SEATS.md) |
| B3 Bidding Practice | **B3.1 SCOPED VERIFIED [118/118](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38905811936)**, **B3.2 SCOPED VERIFIED**: versioned ConventionProfile, strict public-auction UNKNOWN, bilingual teaching previews; [integrated Flutter 145/145 + Web/Chrome](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38913225555) | [B3.1](B3_BIDDING_PRACTICE_ACCEPTANCE.md) · [B3.2](B3_2_CONVENTION_PROFILE_ACCEPTANCE.md). **Independent expert review, complete SAYC/2-over-1 and BEN compatibility NOT VERIFIED** |
| B4 Guided training | **B4.1 VERIFIED**: original three beginner bilingual lessons / nine questions; **B4.2 SCOPED VERIFIED [Flutter 164/164 + Web + Chrome Demo](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38981030736)**: three original intermediate lessons / twelve questions (defense, contract planning, convention literacy); integrated with C3 opt-in progress | [B4.1](B4_GUIDED_TRAINING_ACCEPTANCE.md) · [B4.2](B4_2_ADVANCED_ACADEMY_ACCEPTANCE.md). Expert-reviewed advanced strategy NOT CLAIMED; B3.2 preview rules are UNREVIEWED |
| B5 Training review | **B5.1–B5.4 SCOPED VERIFIED**: completed replay event navigation, bounded rule/convention/unknown explanations, bilingual UI and ephemeral bookmarks | [B5 acceptance](B5_TEACHING_REVIEW_ACCEPTANCE.md) · [Flutter 152/152 + Web + Chrome Demo PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38919162697); DDS best-play, persistent bookmarks, device QA remain OPEN |

### B6 / P1 — Daily fixed-board **practice preview** (no rankings)

**B6.1–B6.3 SCOPED VERIFIED:** UTC date/manifest-version reproducible four-board original practice, encrypted bounded local results and a playable zh-TW/en flow; [integrated Flutter 145/145 + Web Build + Chrome Demo PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38913225555). See [B6 acceptance](B6_DAILY_PRACTICE_ACCEPTANCE.md). Unranked Demo only; device QA still deferred.

- **B6 SCOPED VERIFIED**: [Flutter 124/124 + Web + Chrome Demo](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38910655183). Original deterministic UTC v1 deals, separately encrypted personal progress and four playable real-Core boards. [B6 acceptance](B6_DAILY_PRACTICE_ACCEPTANCE.md). Feature branch only: not merged to master.

- Generate/version four **original** practice boards with the canonical dealer/vulnerability cycle; show the same local challenge identifier and a personal summary, subject to a clear retention/cutover policy.
- May use a signed, published board manifest once needed, but without authenticated server-supplied comparison results it is **not** a Duplicate event. Replaying for study is allowed and explicitly labeled; results are not competition entries.
- Acceptance: reproducible deal IDs and local scores, 4-board retry/restore, no private-hand leak, never show fabricated MP/IMP, opponent rank, or friend comparison; no live leaderboard.

## 5. Phase C — Analysis and Improvement (P2)

- C1 DDS post-deal analysis with visible **DOUBLE-DUMMY** label, counterfactual meaning, no live single-dummy cheating. **C1.5 SCOPED VERIFIED**: terminal Replay DDS 5×4 presentation, unconfigured Web/native Worker unavailable, true C1.5 native end-to-end NOT RUN; see [C1.5 acceptance](C1_5_DDS_REVIEW_INTEGRATION_ACCEPTANCE.md).
- C2 Versioned convention explanations and BEN compatibility notes; unsupported system must display UNKNOWN / UNVERIFIED rather than guessed claim.
- C3 Learner progress and original daily practice prompts; opt-in retention and ability to remove. **C3.2 SCOPED VERIFIED**: consent-gated local recommendations, based on existing attempt events and current catalog, [acceptance](C3_2_PERSONALIZED_RECOMMENDATIONS_ACCEPTANCE.md).
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

## 2026-10-16 — A5.2 usable history management

**SCOPED FLUTTER [CI 94/94 + WEB BUILD + CHROME DEMO PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38857429965):** The player can search board number/contract/score/seat, filter Pass Out/contract/practice, page through the 12-deal encrypted local collection 5 items at a time, and explicitly delete a selected historical deal through a confirmation dialog. Deletion removes the encrypted transcript and writes a bounded encrypted tombstone so restoring a still-finished checkpoint does not recreate a deleted entry. The active board and other history entries are unchanged. New [A5.2 acceptance](A5_2_HISTORY_MANAGEMENT_ACCEPTANCE.md), [M2-F34 learning note](../learning/features/M2_F34_HISTORY_MANAGEMENT.md). No Gateway cloud history, PBN export, production hosting or device acceptance yet.

## 2026-10-16 — A5.3.3 import completed PBN into local history

**[FLUTTER 101/101, WEB BUILD & CHROME DEMO CI PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38868661345).** The player's History screen now has a bilingual Paste PBN dialog; import is restricted to one fully completed first-party PBN board, including Board/Dealer/Vulnerable/Deal/Auction/Contract/NS Score and 13 fixed-compass Play rows (or valid Pass Out). Bridge Core replays all real calls and plays, rejects illegal or tampered input and verifies score/tricks, then stores only a validated full transcript in the existing encrypted 12-board local history. Supports history replay, duplicate fingerprint protection, no active-game mutation or BEN request. [Acceptance](A5_3_3_PBN_IMPORT_ACCEPTANCE.md) · [M2-F37 learning note](../learning/features/M2_F37_COMPLETED_PBN_IMPORT.md). Other tournament PBN variants, remote Gateway history and public multiplayer remain pending.

## 2026-10-16 — A5.3.1 completed local PBN export (new user capability)

From the **searchable encrypted history list** players can now explicitly confirm a private-hand warning and copy a finished, verified PBN to clipboard. `[Deal]` contains all 52 cards; `[Auction]`, board/dealer/vulnerability, contract/declarer, declarer-side result and NS score are serialized from canonical Bridge Core events. Pass Out keeps all four Pass calls. Cancel does not touch the clipboard; deleted and unfinished boards cannot export. A5.3.1 **does not yet include `[Play]` rows, PBN import, remote Gateway archive, public backend, or cross-device sync**. [Acceptance](A5_3_1_PBN_EXPORT_ACCEPTANCE.md) · [M2-F35](../learning/features/M2_F35_COMPLETED_PBN_EXPORT.md). [Flutter 97/97 + Chrome Demo/Web Build CI PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38863038248) and [Learning Gate PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38863038107). Only local finished-history sharing accepted.

## 2026-10-16 — A5.4 recent completed-board statistics (new player UI)

**[SCOPED FLUTTER CI 105/105 + WEB BUILD + CHROME DEMO PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38877191518):** On the existing searchable **已完成的牌局 / Completed deals** screen, display summary chips for the current search/filter: total finished boards, contracts, strictly Bridge Core-derived made ratio, Pass Outs, practice records and the locally aggregated signed duplicate score from the human seat's perspective. The aggregation uses `HistorySummary` safe DTOs only, not privileged PBN or Deal. Pass Out is not counted as a failed contract, and E/W human scores invert canonical NS score. The display is explicitly labeled as a local sample of at most 12 deals (including imports/practice), never IMP/MP/ranking. [Acceptance](A5_4_HISTORY_STATISTICS_ACCEPTANCE.md), [M2-F38 lesson](../learning/features/M2_F38_HISTORY_STATISTICS.md). B1 four-board training session still open; A4.5/device gates unchanged.

## 2026-10-16 — B1 Four-board practice session (player-facing)

**[SCOPED FLUTTER 109/109 PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38880212042).** A5.1–A5.4 local history, search, import/export and statistics are already scoped-verified (latest [Flutter 105/105](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38877191518)). Rather than prolonging server-only QA, the next visible product feature is now B1: a four-board practice flow driven by existing Bridge Core, with a Start button, progress/score per deal, Next Practice Board, terminal session summary, and persistence/restoration in the encrypted active checkpoint. It uses four separate fresh deals with canonical board definitions; it is unranked local practice and no IMP/MP comparison is implied. [B1 acceptance](B1_FOUR_BOARD_PRACTICE_ACCEPTANCE.md); [M2-F39 lesson](../learning/features/M2_F39_FOUR_BOARD_PRACTICE.md). One complete local B1 series (four legal Pass Out boards), checkpoint restore, summary UI and Web build are verified by the named CI. This does not verify BEN performance across four random boards, Android/iOS device QA or product release. A4.5 hosting, A3.5 and Android/iOS device QA remain blocked/held.

## 2026-10-16 — B2.1 Just Declare implementation

Player-facing Flutter table now includes contract level/strain selectors and a Just Declare action. Bridge Core has an explicit preconfigured contract entry to Phase.play, canonical version-2 transcript, preserved v1 normal auction behavior and core-validated score/tricks. The active encrypted checkpoint/history and completed replay can restore this practice mode. PBN export rejects a fabricated regular auction. First slice explicitly uses the Demo rules bot; true BEN without an auction must be separately supported. [B2 acceptance](B2_JUST_DECLARE_ACCEPTANCE.md) · [M2-F40 lesson](../learning/features/M2_F40_JUST_DECLARE.md). **CI BLOCKED — Jobs have runner_id=0 and 0 steps; no code test was executed.** No deployment/device claim. [B2 CI #38882515620](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38882515620).

## 2026-10-16 — B2.2 Four-seat Just Declare, visible target and missing controller repair

**IMPLEMENTED; CI PENDING** on a dedicated source commit. In review of the B2.1 code, the Flutter table actually called undefined `BridgeSession.startJustDeclare`/`isJustDeclare`; this was fixed with an explicit Core teaching-contract start, replay-same-contract behavior, and four-seat choice through existing player Seat selection. The UI now renders declarer, dummy, tricks achieved/required, and made/down result. [Acceptance](B2_JUST_DECLARE_ACCEPTANCE.md) · [M2-F41 lesson](../learning/features/M2_F41_JUST_DECLARE_FOUR_SEATS.md). GitHub Actions B2.1 jobs historically had no assigned runner (`runner_id=0`, no steps); new code has no certified Flutter/Core status until a real assigned runner executes. Do not delay other unrelated visible features solely to create redundant CI, but do not call this one PASS without evidence.
