# M2-F09 — Real BEN declarer controls Dummy in Flutter Chrome

Initial status: IMPLEMENTED / REAL CHROME BEN DECLARER NOT RUN.

Test: apps/bridge_academy_flutter/integration_test/browser_ben_declarer_test.dart.
Runner: .github/workflows/ben-flutter-browser.yml (second distinct genuine BEN Chrome test after M2-F07).

Pinned BEN SHA 72653ec1b5c17116faea229e9b975ea5622aa1f7; native Python 3.12 on Ubuntu 24.04, PIMC disabled and smaller samples, trusted localhost HTTP port 8085; real Chrome and matching ChromeDriver.

Human selects East and Live BEN from Flutter dropdown. Human East passes during auction and plays legal defender cards. Actual BEN controls North/South/West and is expected to bid North as Declarer, South as Dummy on the synthetic fixed board. Audit wraps genuine BenBotPolicy without altering AI proposals. Exactly 13 bot actions must have Actor North and Hand Owner South; 13 human East defender turns, all 52 cards / 13 tricks, signed score, no cards remaining, version = auction.length + 52. Genuine /bid and /play responses >=1; /lead is by human East so robot /lead can legitimately be zero.

No fake fallback, no HTTP URL or private hand logs. Exact test: flutter drive --driver=test_driver/integration_test.dart --target=integration_test/browser_ben_declarer_test.dart -d web-server --browser-name=chrome --dart-define=BEN_BASE_URL=http://127.0.0.1:8085

Evidence: NOT RUN at authoring; report URL, SHA, actions and result after actual CI. M2-F04 CLI robot dummy does not prove this Flutter UI. Does not assess BEN strategy, production defaults or native Android/iOS.

