# Phase A2 / M2-F13 — Local Checkpoint Acceptance

**INITIAL STATUS: IMPLEMENTED / CI NOT RUN.** Best-effort restore prototype, not production durability sign-off.

## Scope
- Trusted Coordinator exports GameTranscript.encode of its privileged GameState and reconstructs through GameTranscript.decode, which reapplies all historical actions via BridgeGame.apply.
- Session checkpoint includes schemaVersion=1, boardNumber, human seat, bot mode, deal source, committed eventVersion, regression fingerprint and legal Transcript. Schema/board/Dealer/Vulnerability/version/fingerprint checked on restore.
- Human actions await local checkpoint before bot decisions. Bot runBots callback awaits checkpoint per validated action; write errors freeze further progression until explicit Retry Saving.
- Default Flutter-created BridgeSession uses a cross-platform SharedPreferencesAsync adapter; tests inject SessionArchiveStore memory fake, and no GameState/complete PBN is sent to normal player UI or BEN.
- Restored current finished replay or unfinished mid-trick is available through PlayerView. Partial remote BEN proposal is NOT committed before the app records its legal action.

## Initial acceptance matrix

| Gate | Expected assertions | Initial |
| --- | --- | --- |
| Core | rehydrate mid-auction and partial trick; reject stale version / corrupted events | NOT RUN |
| Bot | save callback after each real validated bot event | NOT RUN |
| Session | Pass Out, Board 2 East NS, fresh deal, terminal replay round trip | NOT RUN |
| Midtrick | exposed dummy, legal cards, current trick, version and fingerprint match | NOT RUN |
| Fault injection | failed local write blocks player/bot until retry succeeds | NOT RUN |
| Tamper rejection | invalid schema, altered Board Number, eventVersion, human seat, AI mode | NOT RUN |
| Flutter | restored terminal board visible; no other private hands displayed | NOT RUN |
| Chrome and Android | prior regressions and real app restart tests | NOT RUN |
| BEN remote | zero duplicate GameState events; HTTP exactly-once not yet supported | NOT RUN |

## Security / limitations
SharedPreferencesAsync is suitable for noncritical data and supports Android, iOS and Web but **does NOT promise write fsync/critical-data durability**. It is also plaintext/accessible to privileged local users. Flutter maintainers expressly caution against storing critical data in it: https://pub.dev/packages/shared_preferences . Thus the implementation is an engineering prototype, not encrypted release storage, tournament anti-cheat, or transactional power-loss recovery. Fingerprint is a noncryptographic check only, not an HMAC.

No multi-tab concurrency, tamper-proofing, critical schema migration, server idempotency or recovery of a previously requested but uncommitted BEN HTTP action. Web browser storage can be evicted. Do not claim device/process-kill verification merely from FakeStore unit tests.

## Reproduction
- cd packages/bridge_core && dart pub get && dart analyze --fatal-infos && dart test --reporter expanded
- cd apps/bridge_academy_flutter && flutter create --platforms=web --project-name=bridge_academy_flutter . && flutter pub get && flutter analyze && flutter test --reporter expanded && flutter build web --release

**Observed CI: NOT RUN at authoring.** Record exact GitHub runs and code SHA after execution.
