# A5.3.2 — Full completed PBN [Play] section

**Date:** 2026-10-16. **Status:** IMPLEMENTED / CI PENDING.

## Player-facing change

From the existing local encrypted Deal History screen, after explicit private-four-hands clipboard consent, a **completed contract** now exports a PBN containing an additional `[Play "<opening leader>"]` section. This section has precisely 13 lines × four suit/rank tokens. It follows PBN 2.1 §3.6: the first column is the **original** opening leader; each subsequent column is the next compass seat; later rows keep the same column seats even if another player actually led the trick. Each token derives from `Bridge Core Trick.plays` by `handOwner`, never from a fabricated AI or UI state.

Pass Out emits no `[Play]`, preserving four actual Pass calls. The existing Deal / Auction / Contract / Result / Score data and explicit clipboard-consent UI remain unchanged. No unfinished, deleted or nonvalidated historical deal may be exported.

## Acceptance

- Real 13-trick finished GameState only; all tricks contain four players. Export exactly 52 card tokens, one per seat per trick, consistent with Core state.
- Compass columns remain fixed after winner changes; PBN `[Play]` header matches original `contract.openingLeader`.
- Pass Out exports no `[Play]`.
- All former A5.3.1 privacy / local encrypted history / clipboard confirmation gates remain; full-hand PBN never copied automatically.
- Flutter analyzer, widget/unit, Web build, Chrome Demo regressions remain required. Device and emulator tests are owner-deferred.

Source: `apps/bridge_academy_flutter/lib/src/completed_pbn_export.dart`, test `apps/bridge_academy_flutter/test/a5_pbn_export_test.dart`. PBN standard: https://sackab.fi/data/PBN/PBN21a_1.pdf §3.6.

**NOT in scope:** remote Gateway histories, PBN import or cross-device synchronization. One local completed-board PBN export remains a user-authorized privacy-sensitive operation, not a general release certification.
