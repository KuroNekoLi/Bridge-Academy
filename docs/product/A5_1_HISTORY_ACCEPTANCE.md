# A5.1 — Finished Deal History & Replay (player-visible vertical slice)

**Date:** 2026-10-16 · **Status:** A5.1 SCOPED ENGINEERING VERIFIED (Flutter 91/91 + Web release + Chrome Demo) · **Scope:** local training and developer BEN `BridgeSession`. Real Gateway history remains a separate A5.2 milestone.

## What a player can do now

- Finish a deal (including legal four-Pass Pass Out) and see it automatically added to a **Completed deals** list, linked from the existing Play table by a **Deal history** button.
- See the saved date/time, board number, contract/Pass Out, signed N/S score, their seat and the fixed-practice badge.
- Start the next board, open History, select an older deal, and navigate its original event-by-event replay using the existing first/previous/next/last controls, even when another board is ongoing.
- Replaying the same initial 52 cards and completing them again creates a **distinct historical attempt**, never overwrites the earlier result.
- Enjoy localized zh-TW/en labels; nothing is invented as a rank, IMP, MP or other player's score.

## Storage and privacy

`BridgeSession` has a separate `CompletedHistoryStore` dependency. It only archives **fully completed** canonical `SavedBoardCodec` snapshots, and `SinglePlayerCoordinator.restore` verifies all historical events before reconstructing `CompletedReplay`. The list/UI gets `HistorySummary` and privacy-filtered `ReplayFrame` only: no four-hand Deal/PBN or raw storage archive enters Widget props.

Web and native default app composition uses `EncryptedCompletedHistoryStore`, AES-256-GCM with a different authenticated associated-data purpose, the existing secure key provider, a **distinct** storage namespace, and one encrypted record containing up to **12** completed deals (320KiB plaintext maximum). Android/iOS uses a separate SQLite file; Web uses one explicitly named encrypted origin-local record. The live game's encrypted checkpoint remains unchanged. Desktop testing without supported secure storage uses a documented memory-only history fallback.

Each in-progress checkpoint stores an optional stable per-board `historyId`, so repeat launches do not add the same completed event twice; old-format checkpoints remain readable with a deterministic legacy ID. New attempts generate different IDs. The history store does not claim multi-tab concurrency, backup, long-term portability, storage-key recovery or protection against XSS. It never silently falls back to plaintext on crypto/key failure. Completion can still succeed if its secondary history write fails; the UI shows a localized archive error and offers Retry.

## Acceptance

| Player action | Observable assertion |
| --- | --- |
| Open History before finishing | Empty-state label, no private Deal |
| Finish a four-Pass board | Board 1, Pass Out, zero score and terminal replay are listed |
| Next board | Board 2 is live; Board 1 remains selectable with event replay |
| Reopen/restart | Completed record remains, same ID and fingerprint, no duplicate |
| Replay same cards again | New completed attempt appended with new stable ID |
| Tamper with ciphertext or key | Read fails closed, no private-card leak, active game intact |
| Toggle locale | Same history and replay rendered in English |
| Finish an unfinished board | Never archive partial transcript |

**Executed evidence:** [Flutter M2 CI #38852504246](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38852504246) **SUCCESS** on source SHA `0a64fe3a8f84287899f941edc946845f417ebc54`: `flutter analyze --no-pub` No issues found, `flutter test --no-pub --reporter expanded` **91/91 PASS** (prior 86, +5 A5.1-focused cases), `flutter build web --no-pub --release` PASS and real Chrome Demo/secure-checkpoint E2E PASS. [Feature Learning Gate #38852504261](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38852504261) SUCCESS. These are scoped local Widget/injected encrypted store tests, not a true browser reload of completed-history storage on a hosted origin, Android/iOS device evidence or server-owned Gateway history. The separate true BEN Chrome regression has its own CI result.

## Next: A5.2 and A5.3

A5.2 adds search/filter, pagination and user-managed retention/export; A5.3 unifies history for the server-owned Gateway mode, with server authorization, durable multi-session game IDs and user-owned retention. A5.1 is not the complete A5 product or P0 history gate across platforms.
