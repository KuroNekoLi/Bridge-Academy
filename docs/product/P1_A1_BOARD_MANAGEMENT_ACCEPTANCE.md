# Phase A1 / M2-F12 — Board Management Acceptance

**2026-10-15 status: CORE + BEN ADAPTER CONTRACT + FLUTTER WEB ENGINEERING VERIFIED.** These are scoped tests, not a consumer-production release. Android emulator and real BEN fixed-board Chrome regression are independent jobs (see actual results below).

## Authority
WBF 2017 Laws of Duplicate Bridge, **Law 2**: https://www.worldbridge.org/wp-content/uploads/2017/03/2017LawsofDuplicateBridge-paginated.pdf . Boards 1,5,9,13 North dealer; 2,6,10,14 East; 3,7,11,15 South; 4,8,12,16 West. None: 1,8,11,14; NS: 2,5,12,15; EW: 3,6,9,16; Both: 4,7,10,13; repeat every 16.

## Scope and invariants

- Pure Dart immutable `BoardDefinition.forNumber(int)` rejects non-positive numbers and supplies canonical dealer/vulnerability using a 16-board cycle, never inferring from PBN/seed.
- BridgeSession receives optional `boardNumber`, defaulting to the current one (initial 1). It passes the real dealer/vulnerability into `SinglePlayerCoordinator`. Thus both DuplicateScore and BEN receive correct metadata through PlayerView.
- `nextBoard()` works **only after finishing** the current deal; increments number and generates a new fresh deck in Fresh mode. Fixed training mode deliberately retains its synthetic PBN so existing BEN E2E fixtures remain deterministic; this is explicitly a non-competitive teaching mode, not 16 unique tournament boards.
- `replaySameBoard()` is available after completion and reuses the identical underlying Deal and board metadata; it does not double-count a completed result (no persistent competition ledger yet). The current finished replay resets.
- Flutter renders localized Board Number, Dealer, Vulnerability and separate Retry Same / Next Board controls; it never receives the master Deal or all four hands.
- `newGame()` remains the existing explicit re-deal operation, keeping original UI regression semantics and the M2-F10 fresh-deal tests.

## Acceptance matrix

| Gate | Tests | Initial |
| --- | --- | --- |
| Core WBF Law 2 | boards 1–32, 17 wrap, invalid numbers | NOT RUN |
| Scoring authority | 3NT score difference from NS/EW vulnerability | NOT RUN |
| BEN wire data | fake transport records board2 E/NS and board3 S/EW, with no private hands | NOT RUN (contract test, not real model) |
| Session | human East, board2/3 dealer, Pass Out 4 calls, next only after finish, rejection of invalid number | NOT RUN |
| Same-board replay | identical 52 cards & history fingerprint, next-board fresh cards differ | NOT RUN |
| Flutter | Board 1/2 labels zh-TW/en, buttons, no hidden hands | NOT RUN |
| Regression | core, adapter, Flutter analyze/test/build, Chrome Demo, pinned real BEN default Board1 | NOT RUN |
| Android/iOS production devices | target-device app QA | NOT RUN (not a gate for pure domain engineering PASS) |

## Repro commands

- `cd packages/bridge_core && dart pub get && dart analyze --fatal-infos && dart test --reporter expanded`
- `cd packages/bridge_ben_adapter && dart pub get && dart analyze --fatal-infos && dart test --reporter expanded`
- `cd apps/bridge_academy_flutter && flutter create --platforms=web --project-name=bridge_academy_flutter . && flutter pub get && flutter analyze && flutter test && flutter build web --release`

## Executed evidence

- [Bridge Core CI #38719140398](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38719140398): **SUCCESS, 51/51 tests**, `dart analyze --fatal-infos` no issues; Law 2 BoardDefinition, Board 1–32, boundary/score tests.
- [BEN Adapter Contract CI #38719140404](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38719140404): **SUCCESS, 15/15 tests**, strict analysis no issues. Added board 2 E/NS and board 3 S/EW wire mapping; **uses a recording fake**, not a real model for those new two cases.
- [Flutter CI #38719447394](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38719447394): **SUCCESS, 23/23 Widget/Session tests**, Flutter analyze no issues, compiled Web Release, actual Chrome Demo integration PASS. This run included test repair for Board 3: South acting first bids 1NT via Demo policy, so East's Pass starts play rather than finishing Pass Out.
- [Feature Learning Gate #38719140435](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38719140435): SUCCESS on original A1 implementation code with the lesson.
- [Actual BEN Chrome regression #38719140442](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38719140442): first fixed-board genuine BEN Chrome complete-game test passed; second robot declarer/Dummy stage was RUNNING at report update, so no blanket two-test PASS claim.
- [Android emulator regression #38719140370](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38719140370): RUNNING at report update; no claim of this commit's Android PASS.
- Implementation SHA `7de5dbbce84ae3f1e34d74651ce8d630d32271fa`; Flutter test-only correction SHA `02abde0bf497d691e21aa65de888e019845a10f1`. No change to original M1 BridgeGame rules.

## Risks / next release gate

- UI Next Board uses local session state; it is **not durable** after process death (Phase A2).
- BEN GET requests still carry own-hand material to a developer-supplied service; publicly deployed BEN privacy boundary is Phase A4 and requires trusted backend.
- This gate does not establish 4-seat × 16-board real-BEN test coverage, MP/IMP field comparisons, same-board online integrity, or licensed distribution.
- Rollback: revert the A1 implementation commit; BridgeGame rules and existing PBN test fixtures were not changed.
