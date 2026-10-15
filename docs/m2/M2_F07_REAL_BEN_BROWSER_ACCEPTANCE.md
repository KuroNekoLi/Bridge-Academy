# M2-F07 — Real Flutter Chrome + native BEN full-deal acceptance

**Status at authoring: IMPLEMENTED / LIVE BEN CHROME NOT RUN.** Only an actual passing GitHub Actions job may advance this gate to GO.

## Environment and provenance

- BEN upstream: https://github.com/lorserker/ben, pinned SHA 72653ec1b5c17116faea229e9b975ea5622aa1f7.
- Ubuntu 24.04 + CPython 3.12 native Python BEN, TensorFlow models and DDS from pinned upstream source.
- BEN config matches M2-F04 CI: disable BBA-dependent paths and PIMC; reduce simulation samples. These results are NOT BEN default performance or strategy quality claims.
- Flutter stable + genuine installed Chrome with full-version-matched ChromeDriver.
- Workflow: .github/workflows/ben-flutter-browser.yml
- Browser UI test: apps/bridge_academy_flutter/integration_test/browser_ben_test.dart

## Synthetic fixed deal / actual player actions

- Fixture: N:AJ5.KQ7.A982.K76 32.9843.J73.Q943 QT6.AJ6.KT6.JT52 K9874.T52.Q54.A8
- Dealer North; vulnerability None; human North. Opponents East/South/West use genuine BenBotPolicy over BenHttpTransport.
- Real Chrome UI: choose Live BEN in dropdown, begin game, set 3NT and bid, Pass on later human auction turns, then click the legal human hand or exposed Dummy card on each turn.
- The injectable factory exists only to count real HTTP responses without logging hands. It rejects the Demo mode instead of providing a fake fallback.
- Acceptance: 13 finished tricks / 52 cards, four empty hands, non-null signed NS score, version = auction events + 52, own-hand clicks and Dummy clicks both observed, and real /bid, /lead, /play successful responses >=1 each.

## Security / isolation rules

The counting transport logs only route names and counts, with a strict request-field allowlist. No unseen third-party hands are intentionally sent to BEN. Public Dummy may be used only after exposure. Bridge Core is the only legality/score authority.

The request is a GET and can contain private hands in the URL. Never print/upload raw request URLs, server logs or full JSON transcripts in public CI. BEN binds to 127.0.0.1 and allows only localhost/127.0.0.1 hostnames, with its upstream Flask CORS support. Do not open it publicly for the test. Competitive secrecy would require server-owned deals (outside current scope).

## Exact reproduction commands

Start the pinned native BEN API privately on port 8085; start a ChromeDriver matched to installed Chrome on port 4444. Then:

    cd apps/bridge_academy_flutter
    flutter create --platforms=web --project-name=bridge_academy_flutter .
    flutter pub get
    flutter drive --driver=test_driver/integration_test.dart --target=integration_test/browser_ben_test.dart -d web-server --browser-name=chrome --dart-define=BEN_BASE_URL=http://127.0.0.1:8085

Actual run: NOT RUN at document creation. Enter final job URL, SHA, Flutter/Chrome/BEN versions, actual success/failure, 52/13 validation, route counts, execution time, and failures after real execution. Earlier M2-F04 native Dart BEN and M2-F06 Demo Chrome are separate evidence, not this gate.

## Limitations

One fixed game with a predetermined human opening tests compatibility and basic bridge legality, not the model's bidding skill, BEN default latency, randomized deals, Android/iOS mobile network behavior, or device UX. M2 whole-project GO remains pending.

