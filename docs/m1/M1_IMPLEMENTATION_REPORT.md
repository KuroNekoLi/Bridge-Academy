# M1 — Bridge Core Implementation

Status: IMPLEMENTED, VALIDATION PENDING until CI runs successfully on PR commit. Authored 2026-10-15.

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

GO only once dart analyze and dart test pass on the exact GitHub commit, scored fixture discrepancies resolved, and the negative legality and privacy boundaries have been reviewed.

