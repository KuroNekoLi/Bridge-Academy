# A4.4 — Flutter authoritative Gateway integration

**2026-10-16. Status: FLUTTER/WEB SCOPED VERIFIED; genuine Flutter Chrome→Gateway→BEN E2E pending.** No public HTTPS service has been deployed; A3.5, Android emulator and Android/iOS physical UI/E2E testing are owner-deferred.

## Scope and startup

The existing Demo and direct-local BEN developer modes remain unchanged **when no Gateway is explicitly configured**. To use the new server-authoritative table:

```bash
# Terminal 1 — start trusted BEN Python on 127.0.0.1:8085.
# Terminal 2 — run localhost Gateway with approved browser origin.
GATEWAY_BROWSER_ORIGINS=http://localhost:8000 \
  BEN_INTERNAL_ORIGIN=http://127.0.0.1:8085 \
  dart run services/bridge_gateway/bin/serve.dart
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
- This A4.4 test suite **does not** prove live Flutter browser-to-real-BEN full-game E2E or a deployed HTTPS server; those require separately named browser acceptance and A4.5.
- **[Flutter CI #38848030915](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38848030915), code SHA `dc571be3050a5a81cc27cdc81a3cabbc312efb8f`: SUCCESS.** `flutter analyze --no-pub` no issues; `flutter test` **86/86 PASS**; `flutter build web --release` PASS; real ChromeDriver Demo/secure checkpoint regressions PASS. [Learning Gate #38848030896](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38848030896) PASS.
- **New genuine browser acceptance being added:** [browser_gateway_real_test.dart](../../apps/bridge_academy_flutter/integration_test/browser_gateway_real_test.dart) exercised by the pinned real BEN Chrome workflow, with real first-party loopback Gateway and explicit CORS origin. Unlike the 86 widget tests it uses real Browser HTTP, first-party Gateway and actual Python BEN and checks 13 tricks/52 cards. **CI not yet run at authoring**; do not mark this live chain PASS until run evidence is known. Public HTTPS/deployed server and devices remain out of scope.

## Release blockers (not waived)

No Flutter persistent bearer across browser restarts (deliberately memory-only), no universal identity/seat authority for ranked play, no multi-instance transactional request ledger, no authoritative deployed origin, no production token refresh/secure storage, no verified real Flutter Chrome-to-Python BEN replay, no 16-board matrix, no installed mobile UI/assistive QA, no weights/licenses/operating-cost acceptance. The backend's legacy raw caller-hand API must remain disabled for any public deployment. A3.5 remains deferred.

## Rollback

Remove the optional Gateway composition in BridgeAcademyApp; the old local Demo/previous BEN modes were not changed. Delete `gateway_http_api.dart`, `gateway_game_session.dart`, `gateway_table.dart` and the opt-in environment flag if the Gateway contract changes.
