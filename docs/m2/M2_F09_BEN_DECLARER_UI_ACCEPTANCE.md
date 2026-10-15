# M2-F09 — Real BEN declarer controls Dummy in Flutter Chrome

**Verified 2026-10-15: M2-F09 TRUE BEN CHROME DECLARER GO.** [First CI #38685813924](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38685813924) SUCCESS and [final post-lint CI #38685977544](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38685977544) SUCCESS (tested head SHA 506b7c124f79a0b1bc3d059bd988ad983b3738aa).

Test: apps/bridge_academy_flutter/integration_test/browser_ben_declarer_test.dart.
Runner: .github/workflows/ben-flutter-browser.yml (second distinct genuine BEN Chrome test after M2-F07).

Pinned BEN SHA 72653ec1b5c17116faea229e9b975ea5622aa1f7; native Python 3.12 on Ubuntu 24.04, PIMC disabled and smaller samples, trusted localhost HTTP port 8085; real Chrome and matching ChromeDriver.

Human selects East and Live BEN from Flutter dropdown. Human East passes during auction and plays legal defender cards. Actual BEN controls North/South/West and is expected to bid North as Declarer, South as Dummy on the synthetic fixed board. Audit wraps genuine BenBotPolicy without altering AI proposals. Exactly 13 bot actions must have Actor North and Hand Owner South; 13 human East defender turns, all 52 cards / 13 tricks, signed score, no cards remaining, version = auction.length + 52. Genuine /bid and /play responses >=1; /lead is by human East so robot /lead can legitimately be zero.

No fake fallback, no HTTP URL or private hand logs. Exact test: flutter drive --driver=test_driver/integration_test.dart --target=integration_test/browser_ben_declarer_test.dart -d web-server --browser-name=chrome --dart-define=BEN_BASE_URL=http://127.0.0.1:8085

**Actual evidence:** [GitHub Actions #38685977544](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38685977544) passed two real Flutter Chrome tests in sequence: existing M2-F07 human North and new M2-F09 robot North declarer/East human defender. Server readiness: GIB as on BBO; ChromeDriver 155.0.8059.39, matched to installed Chrome. Both stages reported All tests passed. Test assertions require exact 13 robot-controlled South Dummy actions and 13 East defender actions, 52/13 and all empty hands, signed score, legal event version, genuine /bid and /play successful responses, and no Demo fallback. The job does **not** print precise numerical final score or API counts, so no unobserved values are invented. This is a fixed synthetic board under reduced sampling/PIMC-off, not production performance or general strategy signoff. M2-F04 CLI robot dummy does not prove this Flutter UI. Does not assess BEN strategy, production defaults or native Android/iOS.
