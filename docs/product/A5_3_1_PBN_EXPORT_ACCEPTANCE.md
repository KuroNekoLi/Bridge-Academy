# A5.3.1 — Player-confirmed completed-history PBN export

**Date:** 2026-10-16 · **Status:** IMPLEMENTED / FLUTTER CI PENDING · **Local history only**

## What a player can now do

Open **歷史牌局 / Deal history** from the local Flutter tabletop, choose any completed archived board, tap the share/export icon, and explicitly approve the warning that PBN includes **ALL FOUR HANDS**. The app copies a portable PBN text to the device clipboard and displays an accessible zh-TW/en success/failure message. Cancel causes no clipboard write. Deleted or unfinished boards have no export capability.

The PBN includes the original 52-card \`[Deal]\`, duplicate board number, actual dealer/vulnerability, complete chronological auction, contract, declarer, declarer's trick result (when contracted), and NS score. Four Pass calls are preserved for a Pass Out (never fabricated or shortened). **First slice deliberately omits the \`[Play]\` record**; chronological trick-by-trick replay remains available inside the app. Do not imply that the text is an entire play transcript or automatically imports into every third-party PBN application.

## Source and permissions

- \`lib/src/completed_pbn_export.dart\`: pure postgame PBN serializer using the **validated** \`SavedBoardCodec.decode\` result. Only the trusted local history layer can retrieve \`SavedBoard\`; the Flutter widget cannot obtain a privileged archive.
- \`BridgeSession.exportHistoryPbn(id)\`: only accesses an existing, undeleted, already-terminal historical item; returns null for absent records. Does not accept arbitrary Deal/Seat/hand input.
- \`BridgeHistoryPanel._confirmExport\`: two-stage UI confirmation. It does not fetch the PBN before consent. \`BridgeTable\` copies to clipboard with Flutter \`Clipboard.setData\` only inside the post-confirmation callback; sensitive text is **never written to URL, log, exception, BEN payload, local clipboard automatically, or analytics**.
- The existing AES-256-GCM history archive and current game checkpoint remain untouched. Clipboard content **is plaintext** and may be read by the OS and other apps; the user receives this warning before any hand leaves the encrypted storage boundary.

## Acceptance

| Gate | Requirement | Evidence |
| --- | --- | --- |
| Visible interaction | Accessible per-item export icon in searchable/paged local history, zh-TW/en confirmation and toast | \`test/a5_pbn_export_test.dart\` widget |
| Cancel | No clipboard mutation before/after cancel | Widget |
| Completed-only | Missing/deleted/uncommitted game cannot export PBN | Session unit test |
| PBN data | \`Deal\` roundtrip, board/dealer/vulnerability, Pass Out with four Pass, contract/declarer/Result and NS score | Unit tests |
| Privacy | Consent required before private 52-card Deal copied to external OS clipboard | Widget assertion |
| Regression | Existing Flutter tests, Web release build and Chrome Demo checkpoint E2E | **PENDING CI** |

## Known limitations and next slices

- The feature applies to **local BridgeSession encrypted finished history** only. Gateway server-owned sessions do not yet expose approved finished archives to the client, and no cloud synchronization or cross-device identity exists. Public BEN hosting remains blocked.
- It exports the deal and auction/result for external review, **not the complete play table**. A5.3.2 can add standard PBN \`[Play]\` rows and/or carefully authorized local PBN import with privacy validation and Core score checks.
- Clipboard sharing is intentionally non-revocable once approved. Warn users not to paste private deals into public chats or analyses unless that is intended.
- A3.5 and Android/iOS emulator/physical-device UX QA remain paused; this scoped local Web feature is not release approval.
