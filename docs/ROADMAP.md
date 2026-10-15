# Roadmap and release gates

Status snapshot: 2026-10-15. Each "done" requires executable evidence, not an assertion.

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
- Human seat selectable; three AI seats; consistent public/hidden information.
- AI adapter never executes illegal state transitions; explicit retry/error/fallback policy.
- Auction, turn, hand, dummy, 13 tricks, Pass Out and score UI; zh-TW/en localized; responsive tablet/mobile.
- End-to-end seeded golden deals; UX, accessibility and crash/error validation on real target.
- Performance and hosting benchmark with intended BEN settings (do not extrapolate POC-002 timings).

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

