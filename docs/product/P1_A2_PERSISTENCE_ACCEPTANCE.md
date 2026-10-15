# Phase A2 / M2-F13 — Local Checkpoint Acceptance

**STATUS 2026-10-15: CORE + FLUTTER WEB/CROME PLATFORM RESTORE ENGINEERING VERIFIED; ANDROID QA PENDING.** Best-effort restore prototype, not production durability sign-off.

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

## Actual executed evidence (2026-10-15)

- [Bridge Core CI #38723931963](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38723931963): **55/55 PASS**, dart analyze --fatal-infos clean. Includes four new Coordinator restore tests (mid-auction, partial trick, per-bot-event awaited snapshots, bad version rejection), commit 4e6a23098a91ff02f8121729208875c6cb053080.
- [Flutter CI #38724474420](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38724474420): **28/28 PASS**, flutter analyze no issues, Flutter web release build PASS; actual ChromeDriver integration **All tests passed**, including a real SharedPreferencesAsync Web backend read/write across two fresh BridgeSession instances. Code commit f959665904fed6625fbb930f6cc5d713e4fcf463.
- Earlier Flutter CI #38723931935 failed solely because a legacy pure Widget starter test created the default native plugin without platform registration. [Fix #7b76554](https://github.com/KuroNekoLi/Bridge-Academy/commit/7b76554f848d2d0bcddbd238380e16e85650ecbe) injected a platform-independent BridgeSession in that test, leaving actual backend coverage to Chrome/Android.
- [Feature Learning Gate #38723931932](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38723931932) PASS.
- [Real BEN Chrome regression #38723931934](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38723931934) SUCCESS on initial persistence commit, testing original fixed-board BEN flows, not restart/idempotency.
- [Android emulator backend #38724474457](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38724474457) was IN PROGRESS at this report update; do not claim Android persisted-backend PASS until completed.

No genuine process kill, reboot, storage encryption, fsync or remote exactly-once guarantee has been verified.
