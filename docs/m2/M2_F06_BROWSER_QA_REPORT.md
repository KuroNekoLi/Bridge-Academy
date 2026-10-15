# M2-F06 — Flutter Web browser and responsive QA

**Status (2026-10-15):** Flutter static analysis, 14/14 tests and Web release **PASS**. Real ChromeDriver session started but browser interaction gate has not passed; merged browser-lifecycle rerun is pending.

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
| Flutter static analysis | PASS | [CI #38679346659](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38679346659): No issues found |
| Widget/session tests | PASS 14/14 | [CI #38679346659](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38679346659): 320/375/768px cases included |
| Flutter Web release compile | PASS | [CI #38679346659](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38679346659): Built build/web |
| Real ChromeDriver demo UI test | FAIL on earlier separated-case runner; rerun pending | [CI #38679346659](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38679346659): genuine Chrome launched, second browser case raised framework multiple exceptions; latest merged-lifecycle rerun [#38679624664](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38679624664) awaiting result |
| True BEN via Chrome UI | NOT RUN | Requires trusted BEN server with CORS and permitted host |
| Real Android/iOS QA | NOT RUN | Cannot infer from Chrome |

When run, record exact CI run URL, head SHA, complete test totals, screen widths, FAIL/GO, and remaining issues. Do not turn test scripts into PASS evidence.

## Follow-up

If Chrome Demo browser tests pass, implement a separate PINNED real BEN + actual Chrome test, with genuine /bid, /lead, /play routes, clean logging and no fake fallbacks; then cover Android/iOS devices and screen readers.
