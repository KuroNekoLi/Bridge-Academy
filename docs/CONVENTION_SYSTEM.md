# Convention System — initial design contract

> 2026-10-24 update: The user approved three first-class target bidding systems — **2/1 Game Force, SAYC, Precision Club** — and eventual custom agreements. The definitive *delivery plan* is [Three-System AI Master Plan](product/THREE_SYSTEM_BIDDING_AI_MASTER_PLAN.md), with actual first-step evidence in [M1 Spike](research/BEN_MULTI_SYSTEM_M1_SPIKE.md). This initial contract and B3.2 display-only implementation remain valid boundaries; neither constitutes verified BEN three-system behavior.

**Status:** proposed design, not proof BEN supports arbitrary bidding profiles.

## Separate three layers
1. **Legality**: Bridge Core knows legal calls only; it does not embed SAYC/2-over-1 semantics.
2. **Meaning**: a versioned ConventionCard represents partnership agreements and context-sensitive meanings (opening range, stayman, transfers, responses, competitive auctions).
3. **Strategy**: BEN chooses a call, subject to legality; BEN's learned/loaded system is **not** assumed equivalent to a user's ConventionCard.

## Model proposal
- ConventionProfile{id, revision, locales, partnership, agreements, alertRules, ranges, references}
- BidExplanation{call, auctionContext, ruleId, prerequisites, partnershipAssumptions, confidence, unresolvedConflicts}
- CompatibilityReport{selectedProfile, aiProfileOrModel, supportedRules, mismatches, unsupportedCalls}

## Start narrow
M2: display default AI system (must be identified from exact BEN configuration), allow user to view documented conventions but not arbitrarily change AI rules.
M3: introduce verified profiles, first SAYC and/or 2/1 only after reproducible expert-reviewed examples. No unsupported claim that changing a UI switch retrains BEN.

## Acceptance
- A call's meaning must depend on position, vulnerability where applicable, partnership history, interference and forced/nonforced context.
- Example tests include 1NT ranges, Stayman, Jacoby transfers, overcalls, takeout double and slam inquiries only for activated agreements.
- Explain agreement **only if a matching rule exists**; "unknown or ambiguous" beats hallucinated certainty.
- User-facing explanations in zh-TW/en; convention labels remain stable IDs.
- Never use DDS's full-hand solution to justify what an information-constrained player "should have known" during live play.

## Governance
Convention changes are approved decisions with tests and review by knowledgeable bridge players. Document systemic mismatch with BEN; do not silently modify AI output to fit a preferred convention.

