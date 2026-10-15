---
name: bridge-open-source-auditor
description: Audits external bridge engines, ML model weights, native solvers and dependencies for provenance, licenses, maintenance, build reproducibility and integration restrictions. Use before copying BEN/DDS/endplay code, choosing a new package, distributing binaries or asserting commercial/open-source compatibility.
---

# Bridge Open Source Auditor

## Entry
Read docs/OPEN_SOURCE_AUDIT.md, docs/ARCHITECTURE.md, docs/DECISIONS.md. State proposed mode: reference-only, API-hosted service, source reuse, statically/dynamically linked binary, mobile bundling or modified fork.

## Audit workflow
1. Identify exact repository canonical URL, immutable SHA/tag, published artifacts and model checkpoint provenance. No floating "latest" for sign-off.
2. Read license and notices at pinned revision; inventory vendored code and dependency licenses (including native/ML weight terms), authorship and attribution.
3. Distinguish code license from dataset/model weights/API terms; document download and redistribution rights separately.
4. Inspect maintainer/release activity, known security advisories, reproducible builds, architecture support (macOS ARM64/Linux/Android/iOS) and tests.
5. Evaluate obligations in specific integration scenario: modified server code, network usage, distribution, fork, linked library, SDK. For BEN GPL-3.0, do not misstate it as AGPL or claim REST automatically removes all derivative-work exposure.
6. Record performance/deployment implications: TensorFlow/solver memory, startup, PIMC sampling and hosting cost; use measurements only with provenance.
7. Recommend ACCEPT / ACCEPT WITH CONDITIONS / BLOCK / INVESTIGATE with risk owner and rollback.
8. Update docs/OPEN_SOURCE_AUDIT.md with source and date; request professional license review when consequences are material.

## Mandatory dependency record
name, URL, pinned_sha, release_date, purpose, integration_mode, license_and_url, notice_files, model_weight_license, transitive_licenses, known_cves, build_environment, supported_platforms, test_evidence, risks, decision_and_owner, next_review_date.

## Default candidates
BEN (https://github.com/lorserker/ben): GPL-3.0; DDS (https://github.com/dds-bridge/dds): source and release verification; endplay (https://github.com/dominicprice/endplay): wrapper and dependencies; bridge-engine (https://github.com/kduffie/bridge-engine): legal-rules reference, not strategic AI. No candidate marked production-approved until completed audit.

## Acceptance / evidence
Cite primary upstream LICENSE/NOTICE, exact SHA, package manifests, build/test logs and explicit integration/distribution path. Record unresolved license terms; do not allow merge or release that vendors prohibited/unreviewed code.

## Never
Never assume GitHub visibility means permissive reuse. Never commit upstream binary/weights to first-party repository absent permissions check. Never replace a missing license with an invented one. Never issue definitive legal advice beyond evidence/engineering risk framing.

