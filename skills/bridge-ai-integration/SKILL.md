---
name: bridge-ai-integration
description: Integrates and validates the real BEN Bridge Engine Neural API, model configuration, bidding/lead/play/autoplay actions, observable player views, timeouts and response normalization. Use for BEN adapter, AI-provider replacement, model benchmarks or diagnosing AI API behavior.
---

# Bridge AI Integration

## Before action
Read docs/ARCHITECTURE.md, docs/poc/POC_001.md, docs/poc/POC_002_BATCH_100.md, docs/DECISIONS.md and docs/OPEN_SOURCE_AUDIT.md. Pin actual BEN commit, model/weights/config, Python/runtime version and endpoint contract; don't infer these from a different release.

## Boundaries
BEN generates **proposals**. Bridge Core validates legality, applies moves and records outcome. Server/coordinator owns completeDeal. A bot receives only the information permitted by its seat/time in the deal. DDS offline analysis is segregated from live decision-making.

## A4 production network contract (2026-10-16)

- `BenGatewayTransport`: HTTPS POST v1 to a proposed first-party Gateway, Mock-only [Adapter CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38833132162). Inject a short-lived authorized session token, never compile service tokens into Flutter `--dart-define` or use URL Query for private hands.
- Gateway and anonymous credential bootstrap, server authorization and rate limiting, private BEN upstream worker, durable idempotency and real deployment remain A4.2+; DO NOT label A4.1 Mock as a deployed endpoint.
- A3.5 and Android/iOS device UI test are owner-deferred. Preserve local real BEN regression, never quietly fall back to Demo.

## Workflow
1. Capture real API request/response schema for /, /bid, /lead, /play, /autoplay using official source at pinned SHA.
2. Document required per-call state/history; validate seat, dealer, vulnerability, encoded suits/ranks and PBN mappings.
3. Establish AI-visible state serializer; build tests that unseen hands are NOT present. If BEN's API appears to require hidden holdings to operate, raise an architecture blocker rather than bypassing visibility tests.
4. Define adapter result: action proposal, model ID/version, raw response reference, elapsed time, warnings and schema errors. Preserve raw payload for audit.
5. Reject illegal bids or cards before state mutation. Report inconsistency with minimal PBN/action history and raw JSON.
6. Test at least a fixed bid, lead, play and full autoplay on real service. Clearly separate /autoplay engine-level end-to-end smoke test from per-seat fair-play service behavior; the former can operate on full deals and does NOT establish hidden-info isolation.
7. Test terminal outcomes including PASS with complete/incomplete transcript; do not synthesize missing fourth PASS. Use explicit transcriptCompleteness and outcomeStatus.
8. Measure cold start, p50/p95/max, RSS, timeout, internal solver fallback, error rate; log PIMC/sample settings and concurrency.
9. Capture model/license provenance and ask bridge-open-source-auditor before vendoring code/weights.

## Evidence and gate
Save reproducible PBN/seed, sanitized HTTP transcript, service logs, exact build command, SHA, model config, validation oracle result and latency distribution. Mark RUN/NOT RUN. Categorize AI fallback separately from model output.

## Known historical findings
Work summary reported 100 fixed seeds: 97 played deals, 1 explicit four-Pass Pass Out, 2 natural Pass Out with 3 returned PASS calls (2026101558, 2026101591). SuitC three internal 10s timeouts seed 2026101505, still played legally. Reported median 10.337s, P95 19.867s, max 39.746s, RSS ~2.98GiB with PIMC off and reduced sampling. Not representative of default or production SLA; not independently rerun here.

## Never
Never mock BEN and label it real. Never substitute a full-information DDS outcome for single-dummy AI quality. Never automatically patch third-party loop logic based only on PAD_START speculation; isolate/reproduce root cause first. Never assume an API 200 implies a legal move.

