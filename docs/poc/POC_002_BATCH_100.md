# POC-002 — Real BEN batch of 100 fixed seeds

**Status:** outcome-level GO / **production CONDITIONAL GO**. Based solely on user's Work result summary supplied 2026-10-15; original ZIP (bridge-poc-001-batch-100-evidence.zip), raw per-board JSON and logs have not been imported or independently audited here.

## Reported outcomes
- 100 / 100 requests returned BEN JSON; no HTTP failure, API-level timeout or server crash.
- 97 boards played 52 cards / 13 tricks; legality of card ownership/follow suit and Duplicate scoring reportedly passed.
- 1 explicitly designed Pass Out returned four PASS calls.
- Natural Pass Out seeds **2026101558** (South dealer) and **2026101591** (West dealer): BEN reported terminal PASS and no play, **but returned only three PASS calls**.
- Dealer coverage N/E/S/W 25 each; vulnerabilities None, NS, EW, Both; suits C/D/H/S/NT; Double, Redouble, small/grand slam, doubled slam, down contracts covered in some tested boards.
- Seed **2026101505**: three internal SuitC subprocess 10s timeouts; BEN aborted those subcalculations but completed that deal and score verification.

## Outcome vs transcript contract
| Metric | Reported | Meaning |
| --- | --- | --- |
| Completed playable boards | 97/97 | Full legal 52/13, scoring |
| Explicit complete Pass Out | 1/1 | Four recorded passes, terminal |
| BEN-outcome Pass Out with truncated transcript | 2/2 | Terminal PASS accepted for API outcome, transcript incomplete |
| Outcome/API acceptance | 100/100 | **Not** equal to full event-log audit |
| Transcript completeness | 98/100 | Fourth PASS not independently established for 2 natural Pass Outs |
| Production readiness | conditional | SuitC warnings, stress and license review remain |

Do not assert the last actor actually passed if the raw transcript does not show it. No need to patch upstream solely because the API contracts terminal PASS unless strict replay requirements require it. Keep a warning and preserve raw response exactly.

## Reported performance (configuration-bound)
- Completed deals median **10.337 s**, P95 **19.867 s**, max **39.746 s**.
- BEN server peak RSS **~2.98 GiB**.
- PIMC **disabled** and sampling **reduced** for batch throughput. These are not default settings nor production SLA.
- Internal SuitC timeouts on seed above are degraded compute, not API-level timeouts.

## Remaining release gates
1. Import immutable evidence ZIP, provenance, exact BEN commit, model and config.
2. Reproduce two natural PASS transcripts; trace root cause without assuming PAD_START is definitively responsible.
3. Distinguish accepted outcome from replayable event log in Bridge Core.
4. Benchmark intended settings, multiple concurrency levels and stress conditions.
5. Validate strategies/conventions and human-quality outcomes separately from legal-rule testing.
6. Confirm deploy/distribution licensing and privacy boundary.

