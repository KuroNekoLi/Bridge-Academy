# A5.3.3 — Import finished PBN into encrypted local history

**Date:** 2026-10-16. **Status:** IMPLEMENTED / CI PENDING. Not a universal PBN engine or public sharing service.

## Player-visible change

In the existing **歷史牌局 / Completed deals** panel, choose **匯入已完成牌局 PBN / Import completed PBN**, paste a single complete first-party PBN, and select **檢查並匯入**. A successful import appears immediately in the normal searchable, filtered and paged history, can be replayed event by event, copied again through the existing explicit privacy-confirmed export, and survives reopening when the encrypted local store is available.

This feature imports *finished* local practice/history only. It **does not start a game, alter the active game checkpoint, submit hands to BEN, bypass Bridge Core or create a competition entry**. All four starting hands in the PBN remain in an encrypted local archive; UI only accesses filtered `HistorySummary` and terminal `CompletedReplay`.

## Supported PBN subset / strict contract

- Exactly one board with tags `Board`, `Dealer`, `Vulnerable`, `Deal`, `Auction`, `Contract`, `Score`. Contract games require `Declarer`, `Result`, `Play` and 13 rows with four suit/rank tokens; four-Pass Pass Out has no `Play`.
- `[Play]` uses PBN v2.1 **fixed original opening-leader compass columns**. The parser maps each row to a seat and replays actual chronological actions according to Bridge Core's *current turn*, including declarer control of the Dummy.
- Reapply **every** call and card with `BridgeGame.apply`: reject illegal bids, invalid Double/Redouble, duplicated or unknown cards, revoke, bad turn, wrong winners or incomplete play. Verify BoardDefinition dealer/vulnerability, result tricks, NS duplicate score and final terminal version.
- Reject unsupported vendor extensions, comments/annotations, incomplete or multi-board archives rather than guessing or silently truncating. Bounded at 65,536 input characters. Do not claim arbitrary real-world tournament PBN interoperability.
- Use `SavedBoardCodec.decode` for independent second-pass transcript integrity/board validation. Deduplicate exact existing board+canonical fingerprint, cap encrypted history at 12, preserve deletion tombstones and all existing A5.2 history controls. Never echo PBN/errors to logs or UI.

## Primary sources

- Import parser: `apps/bridge_academy_flutter/lib/src/completed_pbn_import.dart`
- Validated archive + safe summaries: `apps/bridge_academy_flutter/lib/src/bridge_session.dart`
- Paste dialog: `apps/bridge_academy_flutter/lib/src/widgets/bridge_history_panel.dart`
- Existing A5.3.2 serializer: `apps/bridge_academy_flutter/lib/src/completed_pbn_export.dart`
- Tests: `apps/bridge_academy_flutter/test/a5_pbn_import_test.dart`
- Learning: `docs/learning/features/M2_F37_COMPLETED_PBN_IMPORT.md`

## Acceptance criteria and evidence

```bash
cd apps/bridge_academy_flutter
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build web --release
```

- Export a complete demo 1NT/13-trick game, import into another local history store, open legal replay and verify final score/13 tricks and no live-state mutation.
- Import four chronological Pass calls: terminal Pass Out with no play and correct NS 0.
- Tamper board, score, declarer, play header, Deal, Result, partial auction: reject without adding history.
- Re-import identical board: fail duplicate without changing history; reopen store and confirm item still exists.
- Flutter widget: paste/cancel/import, immediate list/replay, zh-TW/en strings.
- Preserve existing Flutter Web + Demo Chrome and all prior A5 tests.

**CI status at implementation commit:** PENDING / NOT RUN. Real model and Android/iOS device tests are unchanged and not part of this slice. A3.5/device QA remain owner-deferred. Gateway-server history, PBN formats outside this strict subset, multi-board file import, and public tournament interoperability remain OPEN.
