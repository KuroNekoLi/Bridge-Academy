# Competitor Benchmark — 新睿橋牌 / BBO / BBO Trainer

**Revision:** 1.0 · 2026-10-15 · Product research · **Evidence level:** publicly documented capabilities, not hands-on exhaustive app testing.

## 1. Purpose and research method

Bridge Academy aims to become a complete contract bridge application, starting with one human plus three real AI opponents, then training, replay, duplicate competition, and multiplayer. This comparison is a **capability reference**, not authorization to copy another company's source, visual design, logos, deal libraries, explanations, robot systems, or proprietary data. Product proposals are Bridge Academy designs, not verified capabilities of competitors.

We prioritized first-party help and product pages current on 2026-10-15. Official descriptions can be incomplete or change without notice. Plan device-based competitor usability reviews separately; do not mark an unobserved UI behavior as verified.

## 2. Primary source registry

| ID | Official source | Claim supported | Research caveat |
| --- | --- | --- | --- |
| XR-01 | [新睿橋牌官方功能介紹](https://learn.xinruibridge.com/help.jsp) | AI-supported competitions, daily pair tournaments, group/friend PK, replay, replay same deal, double dummy review, bidding hints, chat/social | Product description; detailed service rules and access vary |
| XR-02 | [新睿橋牌 App Store 官方介紹](https://apps.apple.com/tw/app/%E6%96%B0%E7%9D%BF%E6%A1%A5%E7%89%8C/id946323876) | One human with three robots, bidding hints, replay, competitions, convention cards/social | Store listing; does not independently establish robot skill |
| XR-03 | [新睿官方智能社群／教學介紹](https://www.xinruibridge.com/bridge/secjsp/sec_xy.jsp) | Partnership MP/IMP competitions, recorded plays, replay and replay same board | Explanatory publication, not live product QA |
| BBO-01 | [BBO official practice catalog](https://news.bridgebase.com/about-practice/) | Bidding tables, teaching tables, constrained deals, Bridge Master, Minibridge | Some functions and subscriptions vary |
| BBO-02 | [BBO official solitaire modes](https://news.bridgebase.com/what-is-solitaire-bridge-2/) | Bridge 4, Just Declare, Bridge Master and robot-bid explanation concepts | Historical detail may change; check live UX before implementing parity |
| BBO-03 | [BBO Basic member FAQ](https://doc.bridgebase.com/membership/BBO_FAQ_Basic.html) | Guest/account entry points, daily-deal/plan distinctions, practice facilities | Commercial allowances are time-dependent; do not hard-code as policy |
| BBO-04 | [BBO official robot tournament guide](https://online.bridgebase.com/v2/doc_about_robot_tourneys.html) | One human and three robots, duplicate MP/IMP scoring | Tournament details can change |
| BBO-05 | [BBO Instant Tournament guide](https://online.bridgebase.com/v2/about_IT.html) | Anytime robot tournament on comparable boards, MP/IMP | Competitive comparison must be grounded in defined peer results |
| TR-01 | [BBO Team: BBO vs BBO Trainer (2026-05-26)](https://news.bridgebase.com/2026/05/26/bbo-trainer-infos/) | Trainer is a separate practice app: daily challenges, hand analysis, progress tracking, 1v1; BBO focuses on clubs, tournaments and robot/live play | Product positioning, not proof of pedagogy outcomes |
| BBO-06 | [BBO 2025 Year in Review](https://news.bridgebase.com/2025/12/24/a-look-back-at-2025-on-bbo/) | BBO describes introducing GIBBO as its robot in 2025 | Do not treat historic GIB behavior as current universal robot behavior |

## 2.1 Fresh official verification (2026-10-15)

- [新睿官方操作說明](https://learn.xinruibridge.com/help.jsp) explicitly describes daily pair matches, friend/group PK, bidding hints, replay/retry, double-dummy results and leaderboard comparisons. The same help page discusses convention cards, but some descriptions are historical; **do not claim its older CCBA-only sentence exhaustively describes the live 2026 client**, since the [official current landing page](https://learn.xinruibridge.com/index.jsp) advertises multiple convention-card systems.
- The specifically dated claim that 新睿 launched an **independent practice room in 2025** with designated-dealer controls was **not independently corroborated by a dated first-party announcement in this review**. Keep the idea as Bridge Academy product inspiration rather than a verified competitor release fact until first-party evidence is recorded.
- [BBO's main site](https://www.bridgebase.com/) confirms Just Play, Bridge 4, Just Declare and five Bridge Master difficulty levels. [BBO's 2026-05-26 comparison](https://news.bridgebase.com/2026/05/26/bbo-trainer-infos/) describes Trainer as a separate daily-practice/analysis/progress app, including 1v1, not as the tournament service.
- [BBO's Instant Tournament description](https://online.bridgebase.com/v2/about_IT.html) distinguishes MP from IMP, and describes how results are compared to prior players. **Bridge Academy will not label single-table duplicate points as MP/IMP without a comparison field**.
- [ACBL Duplicate Laws, Law 2](https://web2.acbl.org/documentLibrary/laws/Law02.pdf) establishes a fixed 16-board dealer/vulnerability pattern. This is a rules source, not a competitor feature.

## 3. Feature comparison (source-based; not a parity score)

Legend: **Documented** = explicitly mentioned by first-party source; **Proposal** = planned for Bridge Academy, not currently proven; **Unverified** = not asserted from sources above.

| Capability | 新睿橋牌 | BBO | BBO Trainer | Bridge Academy decision |
| --- | --- | --- | --- | --- |
| One human + AI bridge | Documented XR-01/02 | Documented BBO-02/04 | 1v1 advertised TR-01 | **P0** full-game real BEN, beyond fixed CI fixture |
| Traditional four-seat table & bidding | Documented XR-02 | Documented BBO-01/02 | Unverified | **P0** usable bidding box, card interaction and state labels |
| Declarer-only training / preselected contract | Unverified in scoped sources | Documented Just Declare BBO-02 | Unverified | **P1** native Just Declare-like original mode |
| Structured bidding practice | Hints documented XR-01/02 | Bidding Table documented BBO-01 | Trainer structured practice TR-01 | **P1** selected versioned ConventionProfile; no false AI-system alignment |
| Guided teaching / graded puzzle | Teaching publications XR-03 | Teaching Table / Bridge Master documented BBO-01/02 | Daily challenges TR-01 | **P2** original lessons and expert-reviewable fixtures |
| Post-hand replay / replay same board | Documented XR-01/03 | Review practice BBO-01, history UI known from official help | Analysis TR-01 | **P0** durable event history; current in-memory replay already exists |
| Double-dummy analysis | Documented XR-01 | Not assumed in all modes | Hand analysis advertised TR-01 (not necessarily identical) | **P2** DDS offline/post-deal only |
| Daily comparable competition | Documented XR-01 | Instant/robot duplicate BBO-04/05 | Daily challenge TR-01 | **P3** board-set version + fair comparison/scoring engine |
| Friend / group challenge | Documented XR-01 | BBO challenges/platform BBO-03 | 1v1 TR-01 | **P3** async; synchronous later |
| Clubs, tournaments, spectating | Groups/tournaments XR-01 | Clubs/robot tournaments/Vugraph BBO-03/04 | Not core TR-01 | **P4** server-authoritative live multiplayer and director tools |
| Progress tracking | Not claimed in scoped sources | Not claimed as all-mode native tracking | Documented TR-01 | **P2** opt-in mastery/progress with valid evidence |
| Guest/no-login entry | Not claimed | Guest solo modes documented BBO-03 | Not claimed | **P0 proposal** single-player without mandatory account |

## 4. What to borrow as a product principle — not an implementation

1. **From 新睿:** AI-assisted continuous play plus social reasons to return; visible match results, hand replay, replay same board, later daily comparable challenges.
2. **From BBO:** Many game intents using a shared rules engine. Just Play → four-board session → Just Declare → bidding practice → teaching and live competition.
3. **From BBO Trainer:** A short practice/review/improvement loop. End of hand → identify a specific learning opportunity → play a focused original exercise → track progress.
4. **Bridge Academy differentiation:** A single product with coherent zh-TW/en onboarding and a **provably separated** legality/convention/strategy explanation system. Coach feedback must not pretend an unsupported BEN convention was followed.

## 5. Research limitations and next validation

- We reviewed official/public documentation, **not** performance benchmarks, checkout flows, accessibility audits, current app versions on physical devices, private features or AI model weights.
- Do not copy BBO GIB/GIBBO or 新睿 proprietary robots; Bridge Academy uses separately licensed BEN with its own quality limits.
- Before designing high-fidelity table screens, conduct documented device review on at least one actual Android/iOS installation and web BBO table; capture only original observations and sketches, do not import competitor screenshots/assets into the application.
- Monetary plans and participation limits change. No monetization assumptions are approved for Bridge Academy.
- Competitive MP and IMP require a defined comparison field and method. A single signed NS duplicate score cannot become a legitimate MP percentage or IMP result by relabeling it.
- Treat any product claim without explicit first-party confirmation as Unverified, not as an absence.

**Suggested experiment:** During the Playable MVP playtest, ask five novice and five experienced bridge players to complete opening-to-next-board journeys; record task failures before adding more screens.
