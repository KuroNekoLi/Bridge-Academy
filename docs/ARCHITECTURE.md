# Architecture v0.1 — boundaries first

## A3 UI 延伸：工作區與牌面 adapter（2026-10-26）

`BridgeAcademyApp` 一次建立本機 `BridgeSession` 或 opt-in `GatewayGameSession`，導覽僅切呈現狀態。Play／本機 Review 共用同一個 `BridgeTable` State；Me 經 IndexedStack 保留原頁，學院以 route 返回。開始另一副未完成自由局前先要求 UI 明確選擇，取消不提交 Session command。

呈現資料流：`Core → filtered PlayerView → BridgePlayerHand/BridgeSeatPanel/BridgeCurrentTrick → BridgeCardFace → playing_cards PlayingCardView`。`displayCard` 只有 suit/rank 單向轉換；`sortedVisibleCards` 複製可見清單，不修改權威順序。叫牌時可顯示自己的牌，但不可出牌；只有 Core 投影的合法可行動牌可啟用輸入。動作仍 `onTap → session.submitCard → Coordinator/Core`，套件不取得 Deal／GameState／Token、不決定 move success。明手仍依 dummyExposed 與 handOwner。

共用 renderer 套件固定 `0.4.1+11`；所有標準 suit/rank 以字形覆寫，不呼叫內附圖像；授權頁保留 Flutter 產生的 notices。圖像打包／個別來源仍是 release gate，見 [OSS audit](OPEN_SOURCE_AUDIT.md)。Gateway 仍獨立持有伺服器 authority，不因新增導覽建立本機 fallback。

M2-F55 的 `BridgeCardStrip` 只接收上述原有 Widget，依可用寬度決定 Wrap 或水平 ScrollView，own/dummy 都不重建 Core 順序與牌權。ScrollController 由 Widget State 擁有並釋放；滑動只改 offset。卡片仍保有獨立 semantics、>=48px 目標與既有 command callback，不為 13 張扇形外觀縮小到無法點選。

## M3.6 — 真原生 BBA 約定推論接入 Bridge Core 合法出牌

最新研究流程為：`BbaResearchTablePolicy.choose(PlayerView)` 取得當前座位合法可打 `legalCards` → 私有 `/v1/precision/auction-inference` → BBA `BBABotBid.find_info` 依同一固定 Meckwell/SAYC/21GF 約定卡**推估每座位花色長度** → Dart 先嚴格驗證 16 項長度、來源及 pinned SHA，再以簡單且可測試的搭檔支持分數對 **只有 legalCards** 排序 → `CardAction` proposal → `BridgeGame.apply` 審核。終局評分仍完全由 Core 決定。

推估花色長度≠揭露隱藏手牌；不能傳全 52 張牌、只在完成合約 auction 後才允許 inference，不能將 BBA 解讀當作已學會卡牌防守的 NN。任何 native 不可用直接 fail-closed，不能 fallback 到 Demo/第一張牌/BEN 未經支援的 Precision 系統。現有研究旗標仍封鎖一般玩家選單。

[研究報告](research/M3_6_PRECISION_CONVENTION_AWARE_CARDPLAY.md) · [原生 CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40105701070)。四個固定 PBN 研究局完成是**技術驗收**；4GB VPS、專家 Goldens 和 competitively rated bot 仍未驗收。



## M3.4–M3.5：受控原生 BBA mixed-table 實驗，並非競賽級 Hybrid BEN（2026-10-24）

```text
Flutter研究建置：--dart-define=BA_M34_RESEARCH_PRECISION=true
       ↓ client submits NS/EW profile IDs only
Loopback Gateway: M34_RESEARCH_ENABLED=true; M34_RESEARCH_BBA_ORIGIN
       ↓ server validates pinned GameSystems & native /health
AuthoritativeGame → Private PlayerView (actor hand + public history)
       ↓ BbaResearchTablePolicy (uses BOTH NS/EW real BBA .bbsa)
Native sidecar POST /v1/precision/table-bid → real EPBot proposed auction Call
       ↓ Bridge Core legality + server encrypted checkpoint/replay
Research-only deterministic legal cardplay → 52 cards/13 tricks/score
```

`ConventionCatalog.precisionMeckwell` pins immutable V1 but is **not** advertised in default `candidateProfiles`; it is available only behind explicit Gateway and Flutter research opt-ins. All native source .so + Meckwell card hashes are verified on sidecar startup. No client can request arbitrary .bbsa filenames or other seats' private hands. Both 2/1/SAYC sides are interpreted through BBA compatible `.bbsa` cards, not BEN neural Precision reader (unavailable). Caller-only hand, no GET hand URLs, no raw errors in client or uploaded worker logs. The developer Gateway still binds localhost. Shutdown/sidecar loss never causes fallback to a different bidding system.

[CI #40102968596](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40102968596) passed two true native BBA-arc technical 52-card/13-trick games. M3.5 1000 genuine opening proposals all succeeded with P95=12.96ms and worker RSS ~77.4MiB on isolated Linux CI. Neither implies expert convention correctness, trained precision-aware defensive decisions, Android/iOS UX validation, TLS, commercial deployment or 4GB VPS concurrency suitability. [M3.4 acceptance](research/M3_4_PRECISION_MIXED_GAME_ACCEPTANCE.md) · [M3.5 metrics](research/M3_5_PRECISION_BENCHMARK_AND_RELEASE_GATE.md).



## M3.3 — BBA Meckwell Precision native Provider (2026-10-24)

**Real native auction-proposal integration scoped PASS / M3.4 full-game pending.**

```text
Server-authorized private GameState
      └── seat-filtered PlayerView (one actor hand + public auction)
            └── bridge_precision_adapter.BbaPrecisionBiddingProvider
                  ├── validates actor/NS-EW Precision side/opponent type
                  ├── pins BA-PRECISION-MECKWELL/r1 and .bbsa SHA
                  └── BbaPrecisionLoopbackTransport
                       └── POST 127.0.0.1:18088/v1/precision/bid
                            └── Python precision_m33_sidecar.py
                                ├── pinned source, card and native .so SHA
                                ├── own Meckwell/ opponent BEN-21GF or BEN-SAYC card
                                └── ctypes -> native EPBot -> bid proposal
      └── CallAction proposal -> BridgeGame.apply (only Core mutates state)
```

The Python worker only handles **auction calls** and launches in `--research-only` mode. No BBA/EPBot native library is shipped in first-party source, no live Gateway/Flutter Precision selection is enabled, and no production VPS modifications were made. The owner explicitly reports BBA rights for commercial hosting, modification and redistribution; the precise grant document and binary/third-party notices require a separate controlled release record.

Trust boundaries: PlayerView never supplies hidden hands; POST body on literal loopback (GET query / logs forbidden), redirects and proxies disabled, 2048/4096-byte request/response limits, errors scrubbed, native source+card+binary pinned; HTTP is not a public authenticated endpoint. Bot proposals still go through Bridge Core legality. The native BBA `BEN-21GF`/`BEN-SAYC` cards enable **EPBot's** reading of opponent auctions only; BEN neural itself has no Precision opponent reader in pinned `systems.conf`. Hence mixed BEN/Precision bidding, lead/play, 52-card complete game, persistence and scale are M3.4/M3.5 and must remain fail-closed.

**Evidence:** [M3.3 CI #40095599137](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40095599137), 18 genuine EPBot HTTP bid proposals plus one Dart→EPBot→Bridge Core call; [M3.3 acceptance](research/M3_3_PRECISION_PROVIDER_ACCEPTANCE.md) and [ADR-032](DECISIONS.md).

## A4.1 optional secure Gateway Client boundary (2026-10-16)

```text
SinglePlayerCoordinator -> filtered PlayerView -> BenBotPolicy
                                  -> Dev BenHttpTransport (BEN GET; dev only)
                                  -> BenGatewayTransport (HTTPS JSON POST v1)
                                     -> [NOT DEPLOYED] Auth/rate-limited Gateway
                                     -> [NOT DEPLOYED] Private BEN Python service
Bridge Core validates all proposed moves before commit.
```

A4.1 is a reversible interface seam, **not wired into the default Flutter app**. The new transport requires HTTPS, no embedded credentials/URL query, injected ephemeral bearer provider, route and field allowlist, sanitized errors, no redirects/automatic retry and capped response. It cannot protect against a compromised server or issue its own credentials. Future A4.2 must issue short-lived anonymous credentials, validate authorization and rate limits server-side; A4.3 isolates BEN's old private-hand GET within the private network and implements stable dedup/version semantics. See [wire contract](product/A4_GATEWAY_CONTRACT_V1.md) and [MockAdapter CI 23/23](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38833132162). **No production hosting or BEN service is now available. A3.5 remains owner-deferred and device QA remains disabled.**

## A4.2 local-only first-party Gateway boundary (2026-10-16)

- Dart `services/bridge_gateway` exposes `GET /healthz`, `POST /v1/sessions/anonymous` and `POST /v1/ai/decision` on **127.0.0.1** by default; non-loopback bind is rejected. Local HTTP is not public TLS; any public reverse proxy needs a separate security decision/implementation.
- Issues 256-bit `Random.secure()` anonymous bearer capabilities; stores SHA-256 hashes in process memory, TTL default 15 minutes, no account requirement. Per-peer issuance rate limit and per-token rate/concurrency caps are in-memory and not cluster-aware.
- Filtered A4.1 v1 request schema is enforced at the boundary; unknown fields, whole `deal`, early Dummy fields and private error echo rejected. Proposals go through an injectable `GatewayDecisionBackend`; the default returns **503 unavailable**, never fabricated BEN strategy. Flutter remains unchanged and is NOT connected to this service.
- A **bearer capability is not a player, seat, or deal authorization proof**. There is no server-owned GameState here; a caller can submit a plausible hand of their choice. For formal fair-play/competitive settings, the server must bind tokens to actual game/seat and derive PlayerView server-side. A4.3 also needs durable action IDs/event-version dedup and real BEN private-network worker.
- Localhost HTTP tests inject a fake backend, not a model. Scoped engineering evidence: [Gateway CI 14/14](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38836219472); [A4.2 acceptance](product/A4_GATEWAY_A4_2_ACCEPTANCE.md). A3.5 and device UI acceptance remain owner-deferred.

## A4.3.1 private BEN-only outbound adapter (2026-10-16)

The optional `BenLoopbackBackend` implements `GatewayDecisionBackend`: it maps Gateway's POST envelope to pinned BEN GET `/bid`, `/lead`, `/play` **only on an IP-literal loopback** (`127.0.0.1` or `::1`), disables redirects and proxy, bounds response size/time, hides errors and returns only `bid`/`card`. `BEN_INTERNAL_ORIGIN` is explicit opt-in in `bin/serve.dart`; unset means unchanged 503. [Acceptance](product/A4_GATEWAY_A4_3_1_ACCEPTANCE.md).

**Important trust blocker:** Anonymous Gateway Session currently carries quota only; requester-supplied `hand/seat` is not verified against a server-owned Deal. No public deployment until server-authoritative game/seat context, stable event-version and request dedup. Localhost HTTP tests are complemented by [genuine pinned BEN bid/lead/play smoke PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38837641285) and [20/20 Gateway HTTP PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38837641317). Neither provides a 13-trick Gateway game or seat-bound authorization. A3.5/device hold unchanged.

## A4.3.2: session-owned authoritative training game (2026-10-16)

The anonymous capability now binds to **one server-random Bridge Core Deal**, with `SinglePlayerCoordinator` owning all four hands and keeping the human seat North. Only `humanView.toJson()` is returned. New authenticated POST routes `/v1/games/view`, `/v1/games/action`, `/v1/games/advance` derive every actor/hand internally; BenBotPolicy reads the acting robot's own `PlayerView`, not the caller's claimed `hand`. Core validates move legality and `expected_version`; the Session remembers bounded same-ID responses to prevent repeat human clicks (in-memory only).

**Security limitations:** The old caller-supplied `/v1/ai/decision` still exists for loopback/development and must be disabled for a public deploy. Memory-only sessions/idempotency, long-running partial Bot commits, anonymous user ownership, durable transaction log and seat authority for multiplayer remain unaddressed. No production promotion until these are resolved. [Scoped Gateway CI 27/27](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38839175287), [Acceptance](product/A4_GATEWAY_A4_3_2_ACCEPTANCE.md); owner-deferred A3.5 and all Android/iOS UI device QA remain open.

## A4.3.2b: opt-in encrypted local authoritative checkpoint

`EncryptedSessionStore` uses AES-256-GCM with an externally supplied 32-byte key and one atomic session file per SHA-256 bearer digest. Encrypted content holds the privileged `GameTranscript` + bounded request ledger and pending request identity. `SinglePlayerCoordinator.restore` replays Bridge Core actions on startup (not a blind deserialize). `AuthoritativeGame` persists pending intent **before** mutating the Core; during `runBots(afterCommittedAction: _persist)` it saves each successfully committed event and finally persists the completed request reply atomically with the latest transcript. Incomplete `advance` can resume on matching ID after restart. Wrong key/tampered checkpoint fails closed, no plaintext hand/token logging.

The opt-in durable mode disables the legacy `/v1/ai/decision` raw caller-hand route; ephemeral dev/test mode retains existing A4.3.1 true BEN smoke. Public release still blocked on multi-worker stores, mid-write SIGKILL/disk durability evidence and key operations (whole-process SIGKILL/new-process recovery is [Gateway CI verified 32/32](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38841623172)),, full real BEN game, budget/rights review and deferred A3.5/device QA. [Acceptance](product/A4_GATEWAY_A4_3_2B_ACCEPTANCE.md).

## A4.3.3 full genuine BEN game acceptance boundary

A new pinned real BEN executable test at `services/bridge_gateway/bin/live_gateway_ben_full_game.dart` drives a **server-owned full Deal** exclusively via the authenticated localhost Gateway `/v1/games/*` API, not the older raw caller-supplied `/v1/ai/decision`. Fixed trusted fixture is injected through `dealFactory` only in the dedicated test harness; client receives `humanView` only. Bot decisions are genuine pinned BEN via restricted `BenLoopbackBackend`. Terminal checks: 52 unique played cards, 13 completed four-card tricks, all counts zero, final scoring, event version equality, route invocation counts, bounded same-ID replay and privacy, with no private request logs. [Acceptance](product/A4_GATEWAY_A4_3_3_ACCEPTANCE.md). At implementation SHA `c41cbf5`, [genuine pinned BEN full-game CI #38845244764](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38845244764) **PASS** for fixed North 6NT, 52 distinct cards/13 tricks/final score/30 true BEN requests; [Gateway CI #38845244822](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38845244822) 32/32. No deployed service, no full matrix or device QA.

## A4.4 explicit Flutter Gateway mode

The Flutter App launches an independent `GatewayGameSession` and `GatewayTable` only when a `GatewayApi` is injected for tests or `BRIDGE_GATEWAY_ORIGIN` is explicitly defined. Its `GatewayHttpApi` permits only versioned POST `/v1/sessions/anonymous` and `/v1/games/view/action/advance`, with HTTPS or literal loopback HTTP for local development; redirects refused and bearer sent in authorization header, never URL. Server-filtered `PlayerView.fromJson` is typechecked and rendered with existing UI components. Lost-response recovery uses the same action ID and version, never silently switches to Demo. Tokens remain in RAM; no browser persistence/resume claim. CORS opt-in on local Gateway requires `GATEWAY_BROWSER_ORIGINS`. [A4.4 acceptance](product/A4_GATEWAY_A4_4_ACCEPTANCE.md). [Flutter 86/86, Web Build + Chrome Demo regression](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38848030915) PASS; actual browser→Gateway→BEN remains a separate gate.

## A5.1 local-only completed history (2026-10-16)

`BridgeSession` now persists terminal-only `SavedBoardCodec` snapshots in a **separate encrypted completed-history store** with bounded 12-item retention. A stable historyId is stored in the active session's optional checkpoint field; archive replay rebuilds `CompletedReplay` using a private `SinglePlayerCoordinator.restore`, and Flutter receives only `HistorySummary` or authorized `ReplayFrame`, never the raw Deal/PBN. Browser history uses the existing WebCrypto secure key provider and separate one-record key; native uses a separate SQLite file and AES-GCM with history-specific AAD. Failure in history storage never overwrites the active-session checkpoint.

This is a **player-visible local practice feature**, not an online Gateway multi-user history API, export, searchable catalog, ACID cross-tab store, or production-ready mobile implementation. [A5.1 acceptance](product/A5_1_HISTORY_ACCEPTANCE.md). A3.5 and device QA remain on owner hold.

## Components
~~~text
Flutter Android / iOS / Web (render, input, localization)
    | legal intent (seat + action + turn/version), never master deal
Game Coordinator / API (single-player local coordinator; future server authority)
    | owns full Deal, event log, turn policy; emits filtered PlayerView
    |---- Bridge Core (pure deterministic Dart candidate, decision M1)
    |          legality, auction, contract, trick, Duplicate score, event replay
    |---- AI Adapter (Python service)
    |          BEN /bid /lead /play /autoplay; strict visible-view boundary
    |---- Analysis Adapter (DDS / endplay)
    |          OFFLINE or post-game, full deal access only when authorized
    +---- Persistence (SQLite local → PostgreSQL service when needed)
~~~

## A3 UI decomposition boundary (2026-10-16)

- `BridgeAcademyApp` owns the app theme/locale and `BridgeSession` lifetime; `BridgeTable` is the temporary screen-level controller. The user-facing BoardHeader/TableSurface/SeatPanel/CurrentTrick/PlayerHand and controlled BiddingBox now live in `apps/bridge_academy_flutter/lib/src/widgets/`.
- Widgets receive only the filtered `PlayerView`, board number, locale copy, visible UI state and typed callbacks. `BridgeSeatPanel` only shows Dummy cards after `dummyExposed`. The `BridgeBiddingBox` hoists level/strain selection through callbacks and forwards `Call` intent to BridgeSession; **canSubmit means input allowed, not every bid legal**. A Domain-derived legalCalls projection is needed before call buttons can be selectively disabled.
- `BridgeSession` remains the only UI-side coordinator; it checks current PlayerView, paused/saving state and expected event version. Bridge Core decides legal auction/play actions, actor/hand owner, score, turn order. UI never owns privileged Deal, SessionArchiveStore or BEN transport.
- Scoped evidence: [Flutter CI #38769943196](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38769943196) passed 69 Widget/session tests, analyze, Web build and Chrome Demo on `d4ddfee`; [genuine BEN Chrome regression #38769943206](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38769943206) also succeeded on the same code SHA. Device acceptance is on owner hold; no release GO.
- Current Web persistence after A2.8 uses WebCrypto AES-GCM via an origin-local record, **not** the earlier A2.7 plaintext path. It remains vulnerable to same-origin malicious scripts and lacks SQLite ACID/multi-tab CAS, so deployment threat-model review is pending.

### A3.4 Flutter accessibility UI boundary

- Presentation-only playing-card buttons use minimum 48×48 logical-pixel targets and localized suit/rank semantics; the real disabled state still comes from PlayerView legality and Session busy/rollback gates, not from labels.
- Seat announcements and active-turn text consume only PlayerView metadata. Material Flutter handles default button keyboard behavior; full assistive navigation needs actual keyboard and screen-reader verification before release.
- Scoped evidence on implementation SHA `ea7ca9c`: [Flutter CI 80/80, analyze, Web build, Chrome Demo](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38819474371) and [true BEN Chrome full-game/Dummy E2E](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38819474505). **Android/iOS hardware UI test remains paused until explicit owner approval.**

### A3.3 public history and responsive table

- BridgeTableSurface uses its own LayoutBuilder constraints (breakpoint 560 logical px) to preserve four compass seats while stacking the public current trick below East/West on narrow widths.
- BridgeTableToolbar operates exclusively on PlayerView.auction and PlayerView.completedTricks. Last-trick action remains disabled until Core has completed a trick, and the dialog displays only four publicly played cards and the actual winner.
- BridgeCompletedReplayPanel receives immutable CompletedReplay, an index and an index-change callback; it cannot write BridgeSession/Bridge Core events. The parent owns only ephemeral replay navigation state.
- Scoped tests and live model evidence: [Flutter CI 74/74 and Chrome Demo](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38778610734), [true BEN Chrome](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38778352006). Device testing remains paused by owner.

## A2.7 encrypted native transaction boundary (2026-10-15)
- BridgeSession uses the existing SessionArchiveStore interface; Android/iOS default is EncryptedTransactionalSessionArchiveStore, a full SavedBoard AES-256-GCM ciphertext in a single SQLite row with atomic transaction, and secure-storage-held key. Plaintext migration happens only after authenticated and Bridge Core legal replay verification, encrypted commit, then legacy deletion.
- Atomic row commit and authenticated encryption do NOT guarantee power-loss fsync, malicious process isolation, or cross-process CAS. Physical-device validation deferred by user until complete major features; no security release GO implied.
- Web remains SharedPreferencesAsync plaintext and needs a separate browser threat model; do not silently treat it as secure. Browser frontend still possesses full local privileged Deal for solo play, so a multiplayer fairness model needs server authority.

## A2.5 persistence consent boundary (2026-10-15)
- Checkpoint restoration can fall back to a previous legally verified version. The app must not silently resume if the newest committed generation was lost.
- The local checkpoint commit marker includes an optional boolean recoveryPending that survives separate app launches. BridgeSession awaits clearing the durable-intent marker before unpausing human or AI input; failed acknowledgment stays blocked.
- Marker confirmation and slot content are still SharedPreferencesAsync writes, **not** encrypted, authenticated or fsync/ACID durable. Future transactional storage remains a separate product release requirement.

## Invariants
- One authority executes all state transitions. A BEN call is an **ActionProposal**, not truth.
- Duplicate score returns a documented perspective: NS signed integer, with declarer partnership, vulnerability and X/XX preserved.
- Dealer and vulnerability are explicit; none inferred from PBN string alone without a documented convention.
- Turn and hand privacy enforced at serialization/API boundaries, not solely hidden in Flutter widgets.
- Client action contains event/version or idempotency identifier to reject duplicate or stale actions.
- Every valid transition appends a canonical event; replay reconstructs state from initial deal and actions.
- No direct Flutter dependence in core; no model/Python dependency in scoring.

## Suggested contracts (design proposal, not implemented)
- SubmitAction{gameId, seat, expectedVersion, action} → AppliedEvent/RejectedAction with reason.
- PublicView{dealer, vul, publicAuction, contract, tricks, turn, dummyIfExposed, scoreIfTerminal}.
- PrivateView{publicView, ownCards, permittedPrompt}.
- AIProvider.propose(view, context, timeout) → Proposal + rawResponseId + providerVersion.
- AnalysisProvider.analyze(completeDeal, history) → DoubleDummyAnalysis explicitly tagged.

## M2 local foundation (initial implementation)
- packages/bridge_core/lib/src/player_view.dart builds an explicit per-seat JSON-safe PlayerView; only own hand and exposed dummy cards are included, with public auction/tricks/counts. It is a privileged projector; authorization must be enforced by the coordinator/server.
- packages/bridge_core/lib/src/single_player_coordinator.dart owns private GameState for one local human + three bots, offers humanView (no unrestricted per-seat getter), applies version-checked human actions and validates BotPolicy proposals through BridgeGame.apply.
- DeterministicTrainingBot is intentionally **NOT BEN** and has no strategy-strength claim. BEN production adapter must separately prove API mapping and privacy. This local in-process coordinator is not multiplayer server authority.

## M2-F03 — Seat-limited BEN adapter (contract-level only)
- packages/bridge_ben_adapter accepts only authorized PlayerView and implements BotPolicy; no GameState/Deal access and no use of full-deal /autoplay for seat proposals.
- Maps to BEN /bid, /lead and /play with absolute vulnerability, dash-separated auction, chronological played cards and public dummy after opening lead.
- Reconstructs original 13-card hand from known remaining cards plus each seat's publicly played cards; logs/errors redact query values.
- Uses injected package:http client; automated contract tests are mock-only. The true BEN deployment, dummy actor semantics and end-to-end integration remain separate verification gates.
- PINNED BEN reference revision 72653ec1b5c17116faea229e9b975ea5622aa1f7; details docs/m2/M2_BEN_ADAPTER_REPORT.md.

## M2-F05 — Flutter table (first functional UI slice)
- Flutter app depends on bridge_core and bridge_ben_adapter. BridgeSession (ChangeNotifier) owns SinglePlayerCoordinator; no Widget accesses privileged GameState.
- Widgets render only PlayerView: hidden opponents are counts; exposed dummy and human hand are legal-click controls; all actions use coordinator version checks.
- Demo OpponentMode uses DeterministicTrainingBot, clearly not BEN. Live mode instantiates BenHttpTransport; errors display sanitized status and do not fall back.
- AppCopy centralizes Traditional Chinese and English copy; Material 3 UI and web CI. Native device QA is a separate gate.

## M2-F06 — actual browser automation and adaptive viewports
- Flutter Web browser integration uses official integration_test + Flutter drive + ChromeDriver to test actual rendered Chrome UI (not just simulated Widget Test).
- Responsive controls derive widths from LayoutBuilder parent constraints; phone/tablet Widget Tests run at 320, 375 and 768 logical pixels.
- Current Chrome runner only uses the explicitly labelled deterministic Demo Bot. The separately verified real BEN Dart session must not be cited as proof of Chrome-to-BEN UI operation.

## M2-F07 — True BEN + Chrome full-game boundary
- The independent CI workflow ben-flutter-browser.yml starts real pinned BEN native Python 3.12 then matches ChromeDriver to runner Chrome and drives Flutter UI end-to-end.
- browser_ben_test.dart selects actual BEN mode through the visible dropdown, injects an actual BenBotPolicy backed by BenHttpTransport (route-only counting wrapper), drives a complete 52/13 human-North game and checks non-mock success counts for /bid, /lead, /play.
- Browser network/CORS and genuine asynchronous I/O are additional failure surfaces not proven by native Dart CLI tests or Demo Chrome tests. Do not log BEN private hand query URLs.

## M2-F08/F09 — Android device and robot declarer
- M2-F08 uses reactivecircus Android emulator runner API 35 x86_64 and the native integration_test driver for Flutter Android click-level smoke test; separate from browser and BEN AI inference.
- M2-F09 wraps genuine BenBotPolicy in an audit observer and verifies actual robot declarer acts for public Dummy with 13 CardAction actor/handOwner checks, using real BEN Python + Flutter Chrome.
- Genuine /lead route is not required for the robot in M2-F09: East, a human defender, leads the first trick.

## M2-F10 — training fixtures vs fresh practice deals
- Bridge Core now creates a fresh shuffled Deal from a complete standard 52-card deck; existing Deal constructor guarantees uniqueness / 13 each; optional seed is only for deterministic in-process tests.
- BridgeSession defaults to the historic fixed deal; the explicit BoardMode.fresh opt-in supplies a new shuffled local deal or test-injected deterministic factory; BEN mode remains orthogonal.
- Only PlayerView flows to the UI. Exact cross-runtime replay uses an explicit PBN rather than a seed alone; neither seed nor raw four-hand PBN appears on an active player's screen.

## M2-F11 — finished-game event replay and UI boundary
- SinglePlayerCoordinator only exposes CompletedReplay when terminal; every snapshot is PlayerView.forSeat from a BridgeGame.apply replay, not GameTranscript.encode, and verifies terminal fingerprint/score.
- BridgeSession forwards only filtered completed frames; Flutter read-only navigation steps through actual chronology, public contract/trick/winner/score and own/dummy visible information.
- A new game discards the old in-memory replay. No persistent history, export or full-hand reveal is implied.

## Data and failure handling
- Standard PBN and LIN round-trips are candidates, not assumed compatible without fixtures.
- Fixed seed and full PBN may coexist; record both, as RNG versions differ.
- Retry policy must not emit a second irreversible action; timeout logs raw request metadata without revealing other hands.
- Fallback bot play may be deterministic legal-only, clearly marked degraded; never mislabel as BEN output.
- Freeze adapter behavior around Pass Out: preserve BEN returned three-Pass transcript, terminal outcome PASS, set transcriptCompleteness=UNKNOWN; never append synthetic fourth call.

## Phase A2.2 checkpoint hardening boundary

- SessionArchiveStore retains the same JSON archive supplied by SavedBoardCodec; Bridge Core GameTranscript is the only event replay authority.
- PreferencesSessionArchiveStore v2 uses inactive slot A/B → checksum/read-back + legal replay verification → active marker last. If active is corrupt, the previous valid slot may be recovered. Valid v1 single-key archive migrates after successful commit. Repository tests can inject I/O failures through CheckpointKeyValueStore.
- SHA-256 detects **accidental corruption only**; all four private hands are STILL plaintext in SharedPreferences. Multi-key updates lack an ACID guarantee and untrusted local users may recompute hashes. This must be replaced with a reviewed encrypted transactional store before production public release, alongside true device kill/restart, migration and concurrency tests.
- Do not pass privileged archives/slot payloads to Widgets or BEN or record them in logs.

## Security/performance
- BEN runs in isolated service, not in Flutter; limit concurrent expensive requests, redact secrets.
- DO NOT pass hidden completeDeal to ordinary bot calls; separately verify BEN API needs and implement safe information boundary.
- DDS is a double-dummy omniscient oracle, not a fair-play bot.
- In M4, migrate authority to server; do not trust client state/hash/score.
- POC RSS ~2.98 GiB and latency numbers are workload/config-specific (PIMC off/reduced sample).

## A5.4 bounded history aggregate (2026-10-16)

History Statistics computes from a bounded in-memory list of authorized `HistorySummary` DTOs, **not** from `GameState` or four-hand PBN in the Widget. Declarer outcome is derived once by privileged `BridgeSession._summarize` from canonical terminal 13-trick winners. `Pass Out` is an unknown/not-applicable made outcome, never a failed contract. E/W user perspective flips the signed NS duplicate score. Search/filter only affects what summaries are aggregated. The existing AES-GCM history storage and up-to-12-record bound are unchanged. No MP/IMP, global comparison, ranked competition or server-side account statistics. [Acceptance](product/A5_4_HISTORY_STATISTICS_ACCEPTANCE.md).

## B1 local multi-board practice (2026-10-16)

`FourBoardPractice` is a player-safe, 4-result aggregate with a stable start Board Number and signed human-seat score. It is serialized as `fourBoardPractice` in the **already encrypted** active SavedBoardCodec checkpoint, alongside the canonical Bridge Core transcript. The `BridgeSession` may only advance from the current board after terminal acceptance and one recorded attempt ID; ordinary new/replay/next-board commands are held while the set is in progress. Each board creates a new Deal and normal Bridge Core Coordinator and remains separately visible in the A5 encrypted history. This is not multiplayer authority, distributed exactly-once, duplicate comparative scoring, or cloud sync. [B1 acceptance](product/B1_FOUR_BOARD_PRACTICE_ACCEPTANCE.md), [Flutter 109/109 + Web/Chrome Demo CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38880212042).

## B2.1 Declarer practice contract is NOT an auction (2026-10-16)

Explicit `GameState.justDeclareStart` starts at `Phase.play` with the requested preconfigured undoubled `Contract`; no bids/calls are inserted. The rest of the hand goes through unchanged `BridgeGame.apply` and normal scorer. `GameTranscript` uses schema v2 + `trainingContract` for this legitimate initial state while ordinary matches retain v1. Restored and finished replay follow that initial state, never fake 3 Passes. The initial local teaching UI supports North declarer/South Dummy and labels its deterministic Demo bot; BEN's real `/play` currently requires auction context. Completed PBN export refuses this nonauction practice until a truthful teaching-PBN contract exists. Encrypted local History/Checkpoint remain privileged; PlayerView remains the only rendered view. [B2 acceptance](product/B2_JUST_DECLARE_ACCEPTANCE.md).
