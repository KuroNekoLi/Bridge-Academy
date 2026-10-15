# M2-F06 — Flutter Web browser and responsive QA

**Status 2026-10-15: M2-F06 FLUTTER WEB/CHROME DEMO GO** — real Chrome integration test, 14/14 Flutter Widget/Session/Responsive tests, analysis and web release all passed. True BEN-through-Chrome and native device QA remain NOT RUN.

## Scope / decisions

- Responsive Flutter start controls use LayoutBuilder parent constraints rather than fixed-width assumptions. 320px, 375px and 768px Widget Test regressions have been added.
- Browser test invokes real Chrome through ChromeDriver and Flutter's integration_test / flutter drive, using the deterministic Demo Bot.
- Actual browser actions: switch locale, start game, confirm hand visibility, Pass Out (4 actual PASS), restart, 1NT opening, expose Dummy after opening lead, click Dummy card.
- No new score, follow-suit or hidden-card rules. Widgets continue to consume PlayerView only, state is authoritative in Bridge Core.
- **This test does not include a real BEN server**. M2-F04 had real BEN responses from Dart HTTP runner, which is separate from a real Chrome/UI BEN acceptance.
- Native Android/iOS device QA and competitive anti-cheat remain future gates.

## Exact commands

    cd apps/bridge_academy_flutter
    flutter create --platforms=web --project-name=bridge_academy_flutter .
    flutter pub get
    flutter analyze --no-pub
    flutter test --no-pub --reporter expanded

    # Install ChromeDriver matching Chrome, launch on localhost port 4444.
    chromedriver --port=4444
    flutter drive --driver=test_driver/integration_test.dart --target=integration_test/browser_table_test.dart -d web-server --browser-name=chrome

Official Flutter documentation: https://docs.flutter.dev/testing/integration-tests

## Evidence ledger

| Gate | Status at authoring | Notes |
| --- | --- | --- |
| Flutter static analysis | **PASS** | [CI #38680520652](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38680520652): No issues found |
| Widget/session tests | **PASS 14/14** | [CI #38680520652](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38680520652), includes 320/375/768px and exposed Dummy |
| Flutter Web release compile | **PASS** | [CI #38680520652](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38680520652): Built build/web |
| Real ChromeDriver demo UI test | **PASS** | [CI #38680520652](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38680520652), real Chrome 154.0.8037.97 + ChromeDriver 154.0.8037.97; all browser interactions passed |
| True BEN via Chrome UI | NOT RUN | Requires trusted BEN server with CORS and permitted host |
| Real Android/iOS QA | NOT RUN | Cannot infer from Chrome |

**Evidence:** final executed workflow [#38680520652](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38680520652), SHA `138838e9681265a9d652012e0b6319be676ad0f3`: both jobs SUCCESS. Flutter 3.47.7 stable, Chrome / ChromeDriver 154.0.8037.97, 14/14 Dart/Flutter tests, no analysis issues, web release built, real Chrome integration PASS.

**Root cause and repair:** a real Chrome click on Dummy card C2 revealed Flutter Web `TextPainter.paint` assertion (`debugSize == size`). The button changed its Text content from `♣2 ✓` to `♣2` when playability changed while its style/paint state was updated. The fix keeps card text geometry constant and uses a separate fixed-space check icon; subsequent real Chrome and 14 responsive/Widget tests passed. Prior CI failures are retained in GitHub history, not overwritten.

**Limit:** Chrome uses explicit Demo mode with DeterministicTrainingBot; no real BEN HTTP was called from Chrome in this run. Earlier native BEN tests are not evidence for this browser gap. No actual Android/iOS physical device QA, accessibility screen-reader validation, app-store acceptance or multi-game randomized testing yet.

## Follow-up

If Chrome Demo browser tests pass, implement a separate PINNED real BEN + actual Chrome test, with genuine /bid, /lead, /play routes, clean logging and no fake fallbacks; then cover Android/iOS devices and screen readers.
