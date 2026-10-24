# M3 Precision Club — delivery backlog and release gates

> Created: 2026-10-24. Baseline: master + [M3 Precision research evidence](M3_PRECISION_SPIKE_ACCEPTANCE.md).  
> Engineering research is **not** product activation. Owner has chosen Precision Club as the third *future* base system; specific variant is now DECIDED: BBA Meckwell Precision V1; scope of license and release remain unverified.

## M3.1 — Source / license / variant discovery
Status: **VARIANT SELECTED / PERMISSION REPORTED / LICENSING SCOPE OPEN**

- BEN pinned ad8608af only advertises 21GF-GIB, 21GF, SAYC as native playable bidders.
- Pinned BBA/CC/Meckwell.bbsa is native EPBot system 3, one-notrump 13–15. Public Meckwell Lite v1.13.0 dated 2026-01-05 says 13–16; do not conflate.
- BBA/EPBot upstream README lacks explicit public license; **project owner reports obtaining BBA permission on 2026-10-24**, but hosted/commercial/redistribution scope remains to be reviewed. Do not assume broader rights.
- Exact upstream hashes and concern recorded in [OPEN_SOURCE_AUDIT](../OPEN_SOURCE_AUDIT.md), [ADR-030](../DECISIONS.md).

Product variant and exact source card revision are **decided**: [BBA Meckwell Precision V1](../conventions/PRECISION_BBA_MECKWELL_V1.md), ID `BA-PRECISION-MECKWELL/r1`, 1NT 13–15, SHA pinned. User reports BBA permission has been obtained; detailed written rights matrix and expert meaning checklist remain OPEN for release.

## M3.2 — Isolated true BBA/EPBot native probe
Status: **SCOPED VERIFIED / REAL NATIVE 8 CASES**

- [Python research tool](../../scripts/precision_m3_probe.py), [public fixture](../../scripts/fixtures/precision_m3_cases.json), [7 contract tests](../../scripts/test_precision_m3_probe.py), [reproducible isolated CI](../../.github/workflows/precision-m3-research.yml).
- [CI #40092096757](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40092096757) PASS: eight real EPBot openings, four strong-1C test hands all returned 1C. Not full precision semantics.
- No native libraries/CCs vendored; no user-facing runtime route.

Exit for **complete system semantics** still requires 1C forcing continuation, natural positive/negative, 1NT range, doubles, competitive interference, opening leads/play; system-by-system expert review, alert consistency and license.

## M3.3 — Engine replaceability and gameplay contract

**2026-10-24 update: M3.3 AUCTION-PROVIDER IMPLEMENTED, scoped native CI ACCEPTANCE.** Isolated `bridge_precision_adapter` has an immutable, seat-aware `BbaPrecisionBiddingProvider` and strictly private loopback POST; `scripts/precision_m33_sidecar.py` loads pinned EPBot after source/native/card SHA checks, understands opposing 21GF/SAYC via distinct BBA `.bbsa`, and only returns auction proposals. [M3.3 acceptance](M3_3_PRECISION_PROVIDER_ACCEPTANCE.md), [real EPBot CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/precision-m33-provider.yml). **Not whole-game routed yet**; BEN cannot read native Precision opponent model through its current `systems.conf`. M3.4 requires explicit mixed-engine policy and 52-card game validation.

**Owner permission update**: project owner explicitly confirmed BBA **commercial hosting, modification and redistribution** authorization. Record permission as granted by owner; underlying grant/version/notice review is separate administrative evidence and does not prevent isolated engineering.


Status: **RESEARCH-ONLY TYPE IN PLACE / INTEGRATION BLOCKED**

- [PrecisionResearchCatalog](../../packages/bridge_conventions/lib/src/precision_research.dart) models separate source profiles and backend/license/expert approval. It cannot be selected by ConventionCatalog or Flutter.
- With V1 variant selected, after grant scope and semantics evidence: define `PrecisionBiddingProvider` returning only a proposed CallAction from safe PlayerView, actor seat and immutable GameSystems; BBA native, own rules engine, or separately trained neural backend must be swappable.
- For mixed pairs BBA must interpret both own and opponents' system, not send `PRECISION` into unavailable BEN /bid; cardplay compatibility is independently required.
- Add loopback-only protocol with no hidden cards, bounded concurrency, sanitized errors, request idempotency; reject all unsupported calls/versions rather than fallback.

Exit: exact card/version + provider implementation, 100+ expert reviewed golden bid fixture set, Bridge Core action validation and full NS/EW test matrix.

## M3.4 — Real Gateway / Flutter opt-in
Status: **BLOCKED / NOT IMPLEMENTED**

- After licensed provider, register a new `BA-PRECISION/<revision>` in the *server* allowlist with backend ID/version and model/artifact fingerprint.
- Extend Gateway's available capability negotiation and server-owned NS/EW pairing to support different provider protocols; preserve legacy checkpoints.
- Only then add bilingual Precision choice in Flutter; show exact variant name, stop editing once game begins.
- Keep existing BEN 21GF/SAYC fully unchanged and run separate end-to-end Android/iOS device QA only when owner lifts the existing hold.

Exit: both mixed NS/EW configurations, real full 52-card/13-trick test per configuration, error/timeout/restart/replay and model version consistency.

## M3.5 — Benchmark / production go-no-go
Status: **NOT RUN / RELEASE NO-GO**

- Real distribution: 1000 seeded games, auction/convention agreement rates, BBA native availability, error and illegal proposal rate, MP/IMP fairness with common card, reports with revision-specific data.
- Source, model, original third-party binaries and research data licensing separately approved; no unlicensed redistribution or use for model training.
- Benchmark actual target 2-vCPU/4-GB VPS with Gateway, MySQL, current services, TLS, memory isolation, startup RSS, CPU, p50/p95 and multiuser rate.
- Ranked robot tournaments remain D/P3 gated on comparable seeds/engine versions and fairness.
- Android/iOS QA is owner-deferred; no automatic dispatch.

**Current release judgment:** V1 convention specification CHOSEN; native M3 research feasibility GO; license scope and full-play expert verification PENDING; player-facing Precision and production Precision NO-GO. Use [M3 report](M3_PRECISION_SPIKE_ACCEPTANCE.md) as SoT for observed evidence.
