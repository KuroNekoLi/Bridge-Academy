# M2-F03 — BEN Robot Adapter Verification Report

**Status as of 2026-10-15:** BEN adapter **CONTRACT VERIFIED**, true BEN **LIVE INTEGRATION NOT RUN** for this specific adapter. Earlier POC-001/002 live BEN results belong to different code and cannot substitute for this test. Previously reported POC-001/002 runs are NOT proof this adapter works against the live server.

## Sources and version
BEN upstream source: https://github.com/lorserker/ben/commit/72653ec1b5c17116faea229e9b975ea5622aa1f7 (2026-10-11 commit, checked 2026-10-15).
Reference: https://github.com/lorserker/ben/blob/72653ec1b5c17116faea229e9b975ea5622aa1f7/README-api.md and https://github.com/lorserker/ben/blob/72653ec1b5c17116faea229e9b975ea5622aa1f7/WEBSITE-INTEGRATION.md .

## Scope
- Independent packages/bridge_ben_adapter, Dart SDK >=3.8, bridge_core path dependency and package:http.
- BenHttpTransport: real GET transport, http.Client injection, timeout, status/JSON validation, error-message redaction. Only /bid, /lead, /play permitted.
- BenBotPolicy implements BotPolicy, accepts only PlayerView. It serializes exactly the acting seat original hand, public auction, dealer and absolute vulnerability; after lead it also sends already exposed Dummy and chronological played card history.
- BenProtocol rebuilds a known original 13-card hand from current known cards plus publicly played cards by seat. It does not get GameState, Deal, full PBN, DDS or hidden opponents' hands.
- Conversion returns a proposed CallAction/CardAction. Bridge Core remains authority and rejects illegal actions.
- Test transport fixtures are Mock/Recording responses, not true BEN AI decisions.

## Test commands
From root:

~~~sh
cd packages/bridge_ben_adapter
dart pub get
dart analyze --fatal-infos
dart test --reporter expanded
~~~

Contract tests cover /bid /lead /play, Dummy actor/handOwner, auction P-X-XX, vuln NS/EW/Both, public played history, private hand reconstruction, illegal proposals, malformed bid/card, injected HTTP 503, malformed JSON and timeout.

**GitHub Actions contract result:** [BEN Adapter Contract CI #38675258016](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38675258016), commit 35f5d2ddb2ff9781547f415bd1047f940e41c73a, Dart SDK 3.13.5: dart pub get PASS, dart analyze --fatal-infos **No issues found**, dart test **13/13 PASS**. All tests explicitly use fake response transport/MockClient; this is not a BEN ML verification. [Feature Learning Gate #38675286627](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38675286627): PASS.
**True BEN service:** NOT RUN for this adapter; POC-002 Work runs are separate evidence.

## Important integration caveats
1. WEBSITE-INTEGRATION.md section 4.3 note and section 5 demo disagree over exact dummy turn hand/seat fields. This initial contract follows the declarer-as-actor approach and records it for a mandatory real BEN smoke replay.
2. The upstream says ctx accepts P-X-XX and 1N dash-separated format; /play played uses chronological two-character cards; vulnerability uses absolute NS/EW/Both.
3. GET URLs contain the acting robot's private hand. In production, use HTTPS or trusted local network, tightly limit log access and do not log full query strings. Http errors do not echo private hands.
4. The real BEN model weights, upstream configuration, PIMC, timeouts, concurrency and license review remain separate acceptance gates.
5. No Flutter client, public API authorization, persistent sessions or full production BEN+Human game is implemented in this slice.

## Acceptance to move to live BEN
Pin BEN model/weights/config; start real server; run /bid, /lead and /play including dummy and later trick with original-hand reconstruction; independently check every proposal with Bridge Core; preserve sanitized evidence and runtime/memory metrics. Do NOT label contractual mocks as actual BEN.

