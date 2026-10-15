# M1 — Bridge Core Implementation

Status: IMPLEMENTED; ENGINEERING TEST GATE GO; PR #2 pending merge. Updated 2026-10-15.

## CI evidence
- Tested code commit: 5833d681442c7dfec4b99c94919875e78ffaaf2d.
- GitHub Actions: https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38671869760
- Runner: Linux x64, Dart SDK 3.13.5.
- dart pub get: PASS; dart analyze: PASS; dart test: **30/30 PASS**.
- One test executes 100 fixed-seed complete non-AI deals with 52 cards, 13 tricks, mixed declarers/vulnerability/strains, scoring and deterministic replay.
- First CI attempt failed due to an invalid pubspec version range; fixed and rerun.
- This is NOT a rerun of BEN AI or a claim of production readiness.


## Scope and implementation

- Pure Dart package under packages/bridge_core; no runtime dependencies on Flutter, BEN, DDS, HTTP or SQL.
- Typed Seat/Suit/Strain/Rank/Card/Deal/Contract/Call/Doubling/GameAction/GameState/Trick/Vulnerability.
- Validated immutable state transitions: legal auction (4-pass Pass Out, 3-pass contract close, double/redouble, first-bidder declarer).
- Opening leader, declarer-controlled dummy, dummy exposure after lead, card ownership, mandatory follow suit, trump/led-suit winner, 13 trick completion.
- Duplicate scoring (signed NS): vulnerability, made, down, overtricks, slams, game/partscore, doubled and redoubled.
- Versioned chronological action log, deterministic replay, PBN round-trip and non-security history fingerprint.
- Test suites cover four dealers, auctions, invalid transitions, 13-trick fixed fixture, duplicate scoring, JSON transcript round trip and corrupted transcript rejection.

## Key limitations

- This is **rules code**, not BEN tested integration; the BEN POC results belong to the earlier Work summaries.
- A BEN Pass Out with only three recorded Pass calls is NOT a complete event log; this core cannot invent the last Pass. Any adapter may separately accept BEN terminal outcome with transcript warning.
- The full-deal archive is privileged internal information; no seat-limited serialization or multiplayer authority implemented in M1.
- Claim/concession, irregularities and WBF tournament director procedures excluded.
- No in-chat Dart SDK: package execution and static analysis depend on GitHub Actions or a configured developer machine.

## Exit gate

M1 pure-rules executable test gate: PASS at the code commit above. Code review/PR merge remains pending. Privacy filtering (PlayerView), network authority and tournament-law completeness remain future milestones.

