# Bridge BEN Adapter (M2-F03)

A small Dart package converting seat-filtered PlayerView to BEN's documented stateless /bid, /lead and /play calls. It contains an actual HTTP transport, but its automated tests run against MockClient/RecordingTransport; no BEN model or weights are bundled.

## Execute contract tests
    cd packages/bridge_ben_adapter
    dart pub get
    dart analyze --fatal-infos
    dart test --reporter expanded

## Usage (BEN must already be running)
Call BenBotPolicy(BenHttpTransport(baseUri: Uri.parse('http://127.0.0.1:8085'))) as the BotPolicy injected into SinglePlayerCoordinator; always close the underlying transport on shutdown. The coordinator still validates all proposed actions.

## Important
1. Only PlayerView is supplied; no full Deal/GameState or hidden opponents' cards.
2. /autoplay is not part of per-seat play.
3. Real BEN integration is a separate gate; test mocks are not actual neural outputs.
4. A GET query includes the AI player's known private hand, so do not log whole URLs or send via untrusted networks.
5. Follow docs/m2/M2_BEN_ADAPTER_REPORT.md for the upstream pinned SHA and dummy-seat semantic caveat.

