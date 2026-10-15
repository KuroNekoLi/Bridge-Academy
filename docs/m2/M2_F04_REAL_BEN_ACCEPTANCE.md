# M2-F04 — Real BEN HTTP Acceptance

Status on initial commit: NOT RUN. Workflow and executable are created; only real run evidence may change this.

## BEN provenance

- Upstream repository: https://github.com/lorserker/ben
- Pinned SHA: 72653ec1b5c17116faea229e9b975ea5622aa1f7
- Server: src/gameapi.py, Python 3.12, native Ubuntu 24.04.
- GitHub workflow: .github/workflows/ben-real-native-smoke.yml
- Client executable: packages/bridge_ben_adapter/bin/live_ben_smoke.dart

## Fixed input and expectations

- PBN: N:AJ5.KQ7.A982.K76 32.9843.J73.Q943 QT6.AJ6.KT6.JT52 K9874.T52.Q54.A8
- Dealer N, vulnerability None. Human N starts with a fixed 3NT, afterwards Pass during auction and choose first legal card during play.
- All three other seats use true BenBotPolicy over actual BenHttpTransport, with zero fake/fallback bot decisions.
- Endpoint evidence: real successful /bid, /lead, /play calls at least once each.
- Valid 52 card / 13 trick terminal, cards exhausted, independent NS score, version equals auction count + 52.
- No production UI, production performance guarantee or convention-strength claim.

## Runtime differences from BEN defaults

PIMC disabled for declarer, defender and discarding, BBA-dependent paths disabled to avoid external .NET runtime, simulation samples reduced. These results do NOT represent BEN's default strength or throughput. The previous Work POC results apply to a separate integration/configuration.

## Evidence status

- Live server started: NOT RUN at authoring.
- Actual BEN HTTP calls: NOT RUN at authoring.
- Dart contract tests on old M2-F03: 13/13 PASS; these tests are mocks, and do not satisfy M2-F04.
- CI URL and actual status: record after execution.
- Logs must be sanitized: BEN server may print hand cards and requests carry the acting robot's original private hand.

## Release gates

Obtain a live full game first. Then test more deals, natural auctions, Dummy/declarer turns, BEN default settings, model/version/weights, operational resources, retry policy, private hand redaction and third-party licensing before production signoff.

