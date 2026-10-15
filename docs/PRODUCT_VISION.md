# Product Vision v0.1

## User promise
Bridge Academy makes contract bridge playable, understandable and eventually competitive for players on mobile and the web. The initial experience is one human + three believable AI players. Expand only after a trustworthy rules engine and repeatable bot integration exist.

## Audiences
- Beginners who need rule-guided practice, bidding explanations and no-pressure single-player games.
- Returning bridge players seeking fast hands, convention consistency and deal replay.
- Clubs, teachers and duplicate competitors (later): reliable boards, seat control, scoring, tournaments, appeals and audit logs.

## Product pillars
1. **Correct** — legal auctions and plays, reproducible scoring, seat/dealer/vulnerability handling.
2. **Learnable** — transparent convention card and explanations grounded in deterministic rules.
3. **Fair** — no hidden-hand information leaks; server-authoritative multiplayer.
4. **Accessible** — readable card UI, touch targets, left-handed considerations, localization zh-TW/en.
5. **Recoverable** — event-sourced replay, saved deals, crash/timeout recovery.
6. **Extensible** — BEN interchangeable as strategy provider; DDS isolated for analysis.

## Deliberate scope
M2 initial scope: single-player (internet-backed AI acceptable), North/East/South/West, auction box, 13-trick play, dummy exposure, restart/replay, vulnerability, contract, Duplicate score, clear Pass Out result, reconnect/retry, localization, basic accessibility and deterministic error reports. No payments, account requirement, social/chat, bidding editor, full offline AI, rankings or tournaments.

Later: teaching lessons → personalized feedback → human tables → duplicate board sharing/IMP/MP → leagues/director tools.

## Success criteria
- A full deal remains rules-correct independently of AI.
- Same PBN/actions reproduce same state and score.
- Human does not see unseen cards.
- Real BEN integration, including Pass Out, is observable with versioned raw response evidence.
- UX can finish a hand without confusion, with clear turn and legal-card affordances.
- Non-regression gate for each release; performance measured on target hardware/configurations.

## Open product decisions
Commercial licensing model; default convention card and user customization extent; deployment cost ceiling; whether offline bots are required; native versus Web prioritization; tournament formats and director policy. Record decisions in docs/DECISIONS.md, not in agent prompts.

