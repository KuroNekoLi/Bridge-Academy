# A4.4 — Flutter authoritative Gateway integration

**2026-10-16. Status: SCOPED FLUTTER/WEB ENGINEERING VERIFIED — 86/86 tests + Chrome Demo regression PASS.** No public HTTPS service has been deployed; A3.5, Android emulator and Android/iOS physical UI/E2E testing are owner-deferred.

## Scope and startup

The existing Demo and direct-local BEN developer modes remain unchanged **when no Gateway is explicitly configured**. To use the new server-authoritative table:

```bash
# Terminal 1 — start trusted BEN Python on 127.0.0.1:8085.
# Terminal 2 — run localhost Gateway with approved browser origin.
cd services/bridge_gateway
GATEWAY_BROWSER_ORIGINS=http://localhost:8000 \
  BEN_INTERNAL_ORIGIN=http://127.0.0.1:8085 \
  dart run bin/serve.dart
# Terminal 3 — run Flutter Web from apps/bridge_academy_flutter:
flutter run -d chrome --web-port=8000 \
  --dart-define=BRIDGE_GATEWAY_ORIGIN=http://127.0.0.1:8086
```

For any non-local environment the Flutter client *only* allows HTTPS. The Dart development Gateway still binds `127.0.0.1`, and a remote/public HTTPS deployment with approved certificates, private BEN and CORS remains **A4.5**, not a result of this command. Never add a production API key or access token to a Dart define. The Gateway now accepts an explicitly configured `GATEWAY_BROWSER_ORIGINS` list, with no wildcard or implicit remote HTTP origin. Use a fixed Flutter web port so this list is predictable.

The Flutter `BridgeAcademyApp` accepts a test-injected `GatewayApi` or an explicit `BRIDGE_GATEWAY_ORIGIN` compile-time origin. The absence of configuration retains the old UI. Invalid configured origins fail closed and display localized errors, **never** open a Demo game.

## Architecture and contracts

- `GatewayHttpApi`: strict allowed POST paths, trusted HTTPS / local development loopback origin, never a bearer/hand/deal in URL; redirects are disabled, server HTTP exceptions or error bodies never shown to player. No generic freeform route method.
- `GatewayGameSession`: holds a server-issued 15-minute anonymous Bearer **in volatile memory only**, not SharedPreferences, local encrypted archives or Dart defines. No silent new-session bootstrap on expired token. `startNewGame` uses `/v1/sessions/anonymous` then `/v1/games/view`; `submitCall` and `submitCard` send `expected_version`, stable `request_id` and action only. When robot turn begins, `/v1/games/advance` asks server to use acting-seat filtered `PlayerView`. No client-supplied Deal, seat, card holdings, PBN or local Bot.
- `PlayerView.fromJson`: constrained public view decoder in Bridge Core; rejects extra fields including four-hand archives, invalid cards and inconsistent exposed dummy/legal hand. Only an authorized North view is accepted in this A4.4 slice.
- On unknown network outcome, `GatewayGameSession` retains **exactly the original endpoint, request ID and expected event version**. The user may first refresh the server projection, then **explicitly** retry the original request; never invent a new ID or revert to Demo after a timeout. HTTP 401/409/429/unreachable/5xx/invalid JSON have distinct zh-TW and English messages.
- `GatewayTable` uses existing responsive `BridgeBoardHeader`, `BridgeTableSurface`, `BridgeBiddingBox`, `BridgeTableToolbar` and `BridgePlayerHand`, retaining accessible controls and two locales. No optimistic local GameState or public hand inference is created.

## Acceptance

- Unit/mock HTTP: Origin scheme restrictions and query/credential path rejection; JSON fields, bearer only in `Authorization`, no card data in URL; new session and server-only view; lost response **after server commit** followed by refresh + same-ID replay; token invalidation has localized error and no Demo fallback.
- Flutter Widget: opt-in Gateway table and North hand after start, language toggle in English, no Demo/BEN selector in Gateway mode.
- Existing Flutter unit/widget, Web release build and ChromeDriver demo/secure-checkpoint regressions must pass. Existing pure Dart Gateway suite and pinned real-BEN full-game test retain their independent separate evidence.
- **Separate real Flutter Chrome→localhost Gateway→pinned BEN full-game E2E is now VERIFIED**, but this still does not prove public HTTPS deployment, production auth or device acceptance.
- **Executed Flutter evidence:** [Flutter M2 Single Player CI #38848030915](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38848030915) **SUCCESS** on Flutter sources/test correction commit [`dc571be`](https://github.com/KuroNekoLi/Bridge-Academy/commit/dc571be3050a5a81cc27cdc81a3cabbc312efb8f): `flutter analyze --no-pub` **No issues found**, `flutter test --no-pub --reporter expanded` **86/86 PASS** (prior baseline 80, +6 new A4.4 tests), `flutter build web --release` **PASS**; **real ChromeDriver Demo tabletop and browser secure-checkpoint E2E both PASS**. These Chrome tests still run original Demo UI (not Gateway).
- **Pure Core evidence:** [Bridge Core CI #38847678253](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38847678253) **SUCCESS** after `PlayerView.fromJson` canonical-layout restoration. [Learning Gate #38848030896](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38848030896) **SUCCESS**.
- **True BEN evidence remains separate:** [Gateway full 52-card pinned true BEN #38845244764](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38845244764) PASS before this Flutter change; it validates server+model, not browser-to-Gateway. Latest real Flutter Chrome BEN regression is independently run; exact latest status must be checked separately.
- **Scope boundary:** A4.4 certifies **localhost** real Chrome→Gateway→pinned true BEN for **one full board**, not hosted TLS, token refresh, platform storage, representative load/cost, licensing or mobile devices. These remain A4.5/release gates.

## Actual Chrome→Gateway→BEN full-game run (scoped PASS after 429 fix)

[First full-browser CI #38848501397](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38848501397): **FAIL at HTTP 429 `gatewayRateLimited`**, rather than a BEN routing or browser CORS failure. A real 52-card UI journey can exceed the default per-token 30 requests per minute, since every human action and bot advancement consumes Gateway quota. The loopback-only development executable now accepts bounded explicit `GATEWAY_DEV_DECISION_LIMIT` (1–240), and the real Chrome CI opts into **180**; the production default remains **30**. **[Corrected genuine Chrome CI #38849429500](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38849429500) SUCCESS**, run on source commit `17ef3fc13ca7a9fd9f687e6f61b2693429e2d77a`. It ran the original true BEN Chrome full-game, declarer/Dummy game, then started the loopback first-party Gateway with explicit CORS and an opt-in 180 requests/minute dev quota and executed `browser_gateway_real_test.dart` with real Python BEN. The Widget asserts finished 13 tricks, all 52 cards played, terminal event version and score. CI recorded `REAL_BEN_READY`, `LOCAL_GATEWAY_READY`, and **All tests passed** for the new browser job. The result is scoped to this one unseeded local test board, not a repeatable 16-board matrix. This does not approve a production quota or capacity policy; A4.5 must measure model cost, abuse and multiuser fairness. [Engineering lesson M2-F32](../learning/features/M2_F32_REAL_BROWSER_GATEWAY.md).

## Release blockers (not waived)

No Flutter persistent bearer across browser restarts (deliberately memory-only), no universal identity/seat authority for ranked play, no multi-instance transactional request ledger, no authoritative deployed origin, no production token refresh/secure storage, one scoped real Flutter Chrome-to-Python BEN board (no multi-board or production acceptance), no 16-board matrix, no installed mobile UI/assistive QA, no weights/licenses/operating-cost acceptance. The backend's legacy raw caller-hand API must remain disabled for any public deployment. A3.5 remains deferred.

## Rollback

Remove the optional Gateway composition in BridgeAcademyApp; the old local Demo/previous BEN modes were not changed. Delete `gateway_http_api.dart`, `gateway_game_session.dart`, `gateway_table.dart` and the opt-in environment flag if the Gateway contract changes.
