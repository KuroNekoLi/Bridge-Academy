# M2-F04 — Real BEN HTTP Acceptance

Status 2026-10-15: **GO for two fixed, real BEN + Dart integration games**, including BEN declarer controlling Dummy. True BEN server and native model were used; this is not a production/M2 overall GO.

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

## Real run 1 — PASS (actual BEN, not mock)

- GitHub Actions: https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38676215575 , commit 7e7397a5920cbb9a284bc6dcc0c4f146da8e0332, Linux Ubuntu 24.04 + Python 3.12.
- BEN readiness: GIB as on BBO.
- Actual HTTP response counts: /bid = 4, /lead = 1, /play = 25. **No MockClient, no fallback**.
- Actual auction: 3NT, PASS, 6NT, PASS, PASS, PASS. Contract 6NT, North declarer.
- Completed 13 tricks, 52 cards, terminal version 58 (6 auction events + 52 cards), final **NS −250**.
- Dart full-deal execution elapsed 8,255 ms with PIMC disabled/reduced sampling. Not BEN default SLA or performance guarantee.
- **Caveat:** North was controlled by deterministic human fixture, so this test verified live BEN opponents but not robot declarer controlling dummy.

## Real run 2 — BEN robot declarer and dummy (PASS)

- Executable: packages/bridge_ben_adapter/bin/live_ben_dummy_smoke.dart, separate full board with human East defender and BEN controlling N/S and W.
- GitHub Actions: https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38676615739 (workflow code commit 3258da785c2675f0fc26d6ffc69877f6e1e610b9). Status: SUCCESS.
- Real BEN algorithm performed auction: 1NT, PASS, 3NT, PASS, PASS, PASS. Contract **3NT North**, final **NS +460**, 13 complete tricks/52 cards.
- Real HTTP calls: /bid = 4, /play = 39. No mock, no alternative Bot. The opening lead was performed by deterministic Human East in this scenario, so /lead is correctly 0 here; previous real run proves the /lead endpoint.
- **BEN-controlled declarer performed 13 Dummy hand turns**, with checked Actor = N (declarer), Hand Owner = S (dummy). This specifically verifies the hard API edge case not covered by the first run.
- Dart second-game execution elapsed 10,274 ms under reduced sampling/PIMC disabled; not benchmark for defaults.
- Full native workflow also reran the first game: 6NT North, 13/52, NS −250; /bid 4 /lead 1 /play 25, elapsed 5,960 ms in this run.
- Result: **M2-F04 fixed-board BEN integration gate GO**, not all-gameplay/strategy-production acceptance.

## Contract test evidence

- M2-F03 Mock suite: 13/13 PASS. Separate from these real BEN acceptance runs.
- Logs must be sanitized: BEN server may print hand cards and requests carry the acting robot's original private hand.

## Release gates

Obtain a live full game first. Then test more deals, natural auctions, Dummy/declarer turns, BEN default settings, model/version/weights, operational resources, retry policy, private hand redaction and third-party licensing before production signoff.

