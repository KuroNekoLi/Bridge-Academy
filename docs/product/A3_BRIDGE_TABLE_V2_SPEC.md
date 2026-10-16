# A3 — Bridge Table UI V2: Component Contracts and Acceptance

**Date:** 2026-10-16 · **Owner:** bridge-orchestrator + bridge-architecture-guardian + bridge-learning-mentor  
**Scope:** Flutter UI decomposition and accessibility, not a change to Bridge Core rules, BEN protocol, archived events, or product login.  
**Device QA:** ON HOLD until explicit owner approval. Do not run emulator/physical Android/iOS UI or E2E.

## Goal / Golden journey

A new player selects a seat and practice deal, sees board/dealer/vulnerability and turn, can complete a legal auction, follow dummy ownership, play their permitted cards and review the completed game. Preserve zh-TW/en, board numbering, encrypted save/error flows and existing widget keys.

## UI topology and responsibilities

```text
BridgeAcademyApp (app shell / locale / session lifecycle)
└── BridgeTable [planned BridgeTableScreen rename] (session observer and intents)
    ├── PracticeSetup (future extraction: seat/mode/deal)
    ├── BridgeBoardHeader [A3.1 extracted] (number, dealer, vulnerability, contract, turn)
    ├── BridgeTableSurface [A3.1 extracted]
    │   ├── BridgeSeatPanel × 4 (filtered seat, count or revealed Dummy)
    │   └── BridgeCurrentTrick (public played cards)
    ├── BridgeBiddingBox [A3.2] (controlled level/strain, legal calls, hints policy)
    ├── BridgePlayerHand [A3.1 extracted] (own 13→0 cards, permitted actions)
    ├── BridgeTableToolbar [A3.3] (auction and last trick)
    ├── GameRecoveryBanner (existing; A3.4 layout)
    └── CompletedReplayPanel [A3.3] (read-only event frames)
```

### Trust and data contracts

- Core → SinglePlayerCoordinator → BridgeSession.view → **PlayerView** → presentation-only Flutter widgets. No widget receives the entire Deal, master game state, raw BEN response or SessionArchiveStore.
- UI selection produces a typed intent via `onPlayCard(Card)` or `onSubmitCall(Call)`. BridgeSession checks active turn, `legalCards`, `expectedVersion`, recovery lock and save state. Only Bridge Core applies actions.
- Dummy cards render **only when** `dummyExposed` and the public `dummyCards` projection exists. For dummy-controlled play the *actor* is the human declarer but the *hand owner* is `view.turn`, as currently enforced in Session.
- Turn indication, board number, dealer, vulnerability and contract read Core/session metadata directly; never recompute duplicate rotation in Widget.
- No full-deal `toJson` or unfiltered hidden card payload in UI, analytics, error logs or widget tests.

### A3.1 implementation slice

Extract **BridgeBoardHeader**, **BridgeTableSurface**, **BridgeSeatPanel**, **BridgeCurrentTrick**, **BridgePlayerHand**, and **BridgePlayingCardButton** to `lib/src/widgets/bridge_table_components.dart`. Preserve all existing behavior, layout hooks, screen copy and keys. This is architecture groundwork, **not** visual parity with BBO / 新睿.

Acceptance: active/passive seats; no concealed card widgets; dummy reveal; legal dummy interaction; board 2 locale metadata; prior widget & browser flows unchanged.

### A3.2 — Controlled bidding interaction (initial extraction committed; full legal-call UX pending)

Level/strain and Pass/X/XX buttons are now extracted into a controlled stateless `BridgeBiddingBox` (`widgets/bridge_bidding_box.dart`); `BridgeTable` owns the selected level/strain and `BridgeSession.submitCall` receives all intents. Existing behavior is preserved. Show Pass/Double/Redouble legality clearly; illegal calls must still be rejected by Bridge Core. Later tie meanings to verified ConventionProfile only. Keyboard/semantic labels and 320px overflow are gate conditions.

### A3.3 — Responsive table, contextual toolbar and replay (scoped Flutter/Chrome verified)

- `BridgeTableSurface` adapts at its available content width 560px: narrow screens show North, West/East as equal flexible columns, then full-width current trick and South; wider screens put West / public trick / East in one row. All four compass seats stay distinct and exposed Dummy remains in its rightful seat; no private hands are provided.
- `BridgeCurrentTrick` uses public-card Chips and a localized placeholder. `BridgeTableToolbar` offers modal public auction history and last *completed* trick with its winner, disabled until one trick exists; never expose any pending private cards.
- `BridgeCompletedReplayPanel` is a separate readonly Widget observing immutable `CompletedReplay.frames[index].view` via selected index callback. The current BridgeSession is never mutated by replay or history dialogs.
- Retain existing key and localization contracts. Automated tests cover 320/375/768 widths, Dummy, modal state nonmutation, completed-trick guard and earlier replay navigation. Full Flutter analyze/tests/Web build/Chrome + true BEN regression executed and passed; see CI evidence below. No device QA authorization.

**Not included:** human-seat auto-rotation, high-fidelity visual themes, keyboard/screen-reader release validation or domain legalCalls; these remain separate explicit decisions/slices.

### A3.4 — Accessible polish (scoped Flutter/Chrome verified)

- Give playing-card controls minimum 48×48 logical pixels, localized spoken suit/rank and actual enabled state, avoiding duplicate Tooltip semantics.
- Keep the visual active-seat indicator as text, not just a colored border; include role and publicly available card counts in seat semantics. Use theme colors for the table.
- Use reading-order traversal grouping for bidding controls, and 48px minimum targets for bidding, public history, and replay actions.
- Tested 320/375/768px with increased text scale, zh-TW/en descriptions, touch targets and disabled actions. The Flutter official [accessibility checklist](https://docs.flutter.dev/ui/accessibility) and [testing guide](https://docs.flutter.dev/ui/accessibility/accessibility-testing) are the baseline.
- Release limitations: do not infer TalkBack/VoiceOver, full-screen contrast compliance or physical touch acceptance from Widget tests. Android/iOS hardware and emulator UI/E2E remain on owner hold.

### A3.5 — Integration and release gate

`flutter analyze`, full `flutter test`, release Web build, existing real Chrome Demo + BEN browser flows if triggered; privacy/failure negative cases. Target real Android/iOS UX and physical device remain **BLOCKED BY OWNER HOLD**, so even green CI cannot mark A3 PRODUCT READY.

## A3.4 actual CI evidence (2026-10-16)

- [Flutter CI #38819474371](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38819474371) at implementation commit `ea7ca9c199214d60ff615ea6c5e113fb3be60dd7`: **flutter analyze: No issues found; 80/80 Widget and Session tests PASS; Flutter Web release build PASS; Chrome Demo E2E PASS**.
- [Real BEN Chrome CI #38819474505](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38819474505) on the exact same commit: **SUCCESS**, including the full BEN game and declarer/Dummy flow. No Demo substitution.
- [Feature Learning Gate #38819474409](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38819474409): **SUCCESS**; the M2-F24 Traditional Chinese lesson is delivered, not learner-mastered.
- **A3.4 scoped engineering acceptance: PASS. A3.5 and device accessibility/release acceptance: NOT VERIFIED.** These tests do not certify TalkBack, VoiceOver, real device ergonomics, contrast ratio across all themes, or screen reader navigation. Owner device QA hold remains active.

**Owner decision 2026-10-16:** A3.5 is DEFERRED, not accepted or canceled. A3.1–A3.4 retain scoped engineering results; Android/iOS device QA, visual approval, VoiceOver/TalkBack and A3 release gate remain explicitly OPEN while A4 proceeds.

## Compatibility / non-goals

- Do not modify Bridge Core/BoardDefinition, BEN transport, storage migration, score contracts, replay event format, nor enable device workflows.
- Avoid gratuitous new packages or copying competitor visuals.
- Preserve keys: `bridge_board`, `game_status`, `seat_N/E/S/W`, `dummy_revealed`, `dummy_card_*`, `hand_card_*`, `auction_controls`, `make_bid`, `pass`, `double`, `redouble`, `replay_panel`.
- Abort/fix if a refactor breaks Chrome, hidden-hand privacy, Pass Out, Dummy ownership, or checkpoint restoration.

## Status and actual evidence (2026-10-16)

**A3.1–A3.3 component extraction: SCOPED FLUTTER/CHROME VERIFIED**, not A3 release GO.
- [Flutter CI #38769943196](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38769943196) on code commit `d4ddfee5c0c43b571f4e99cfcbac7c4229f74b52`: `flutter analyze --no-pub` **No issues found**, **69/69 Widget/Session tests PASS**, **Flutter Web release built**, Chrome Demo E2E **SUCCESS**.
- [Feature Learning Gate](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38769943094) completed for the code commit; separate lessons M2-F21 and M2-F22 are delivered.
- First extraction [A3.1 initial CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38768161432) had 3 interpolation lints; resolved. A3.2 initial [CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38769224189) had Flutter/Bridge Core `Card` import conflict; resolved. [CI #38769481251](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38769481251) caught a 320px Row overflow; resolved using independent Wrap selector children, then 69/69 passing.
- Genuine BEN Chrome regression on the **same latest code commit**: [run #38769943206](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38769943206) **SUCCESS** at latest A3.2 code SHA `d4ddfee5c0c43b571f4e99cfcbac7c4229f74b52`, including genuine BEN complete-game and declarer/Dummy Chrome flows. Earlier A3.1 [real BEN run](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38768532549) passed; this is not proof of a later commit.
- [A3.3 Flutter CI #38778610734](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38778610734) at `d0c62b92db2f2a7a79a1a73340450aad0f4ef96e`: **No analyzer issues, 74/74 Widget/Session tests PASS, release Web build PASS and Chrome Demo E2E PASS**. [Genuine BEN Chrome CI #38778352006](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38778352006) **SUCCESS** at production code SHA `1b1e2e6d708a74c72071f0df116d496e049cfa21`; later commit `d0c62b9` changes only test/documentation (not app implementation). [Feature Learning Gate #38778610653](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38778610653) **SUCCESS**.
- **Outstanding:** Core-origin `legalCalls` projection for enabling only legal bids; A3.4 device screen-reader/contrast and high-fidelity user study evidence; A3.5 final cross-platform device acceptance. Fixed compass positions are retained; optional player-relative table orientation is a future explicit UX choice. Android emulator and physical Android/iOS UX checks remain ON HOLD until owner approval.
