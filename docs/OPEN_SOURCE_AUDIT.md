# Third-party components and license gate

**Audit state: preliminary research only.** Verify repository LICENSE at an immutable commit, model weights, bundled native binaries, transitive dependencies and any service/redistribution constraints before code integration or public release. This is engineering triage, not legal advice.

| Candidate | Purpose | License from upstream documentation / initial research | Decision |
| --- | --- | --- | --- |
| BEN — https://github.com/lorserker/ben | bidding/lead/play/autoplay ML service | GPL-3.0 identified; verify exact commit, weight rights, bundled packages | POC integration only; production rights review |
| DDS — https://github.com/dds-bridge/dds | double-dummy solver | Apache-2.0 identified; verify checked-out release and any bundled interfaces | Analysis candidate |
| endplay — https://github.com/dominicprice/endplay | PBN/score/deal tooling | License and DDS integration obligations must be rechecked per version | Candidate, not locked |
| bridge-engine — https://github.com/kduffie/bridge-engine | TypeScript game-engine reference | MIT identified; robot strength does not replace BEN | Reference only |
| eBridge — https://github.com/ebridge/bridge-web | multiuser architecture reference | Not independently audited | Reference only |

## Updated BBA permission status — owner statement (2026-10-24)

**Permission received (user-reported): YES.** The Bridge Academy owner explicitly stated "我已經取得BBA使用授權" on 2026-10-24. Treat the former blanket "not obtained" statement as outdated. Current status is **OWNER_REPORTED_GRANTED / SCOPE_UNVERIFIED**, not "no permission" and not a fully reviewed legal release approval.

**Selected convention variant**: [BBA Meckwell Precision V1](conventions/PRECISION_BBA_MECKWELL_V1.md), 1NT **13–15**, pinned BEN source and exact .bbsa SHA. Do not mix with Meckwell Lite 13–16.

For an auditable GO decision, review these permission details privately (without disclosing private correspondence in GitHub):
- Rightsholder / licensor identity and grant recipient; dates, duration, geography.
- Whether permission covers **native EPBot binaries**, `Meckwell.bbsa`, BBA application, associated dependencies, source edits, and notices.
- Whether **hosted API/SaaS and commercial gameplay** are permitted, and what attribution/limits are required.
- Whether redistributing copies (server image, mobile, binaries, model training or convention card) is permitted; do not assume permission for one mode grants all.
- Renewal, revocation, support/version upgrades, or terms that require specific original files.

Until the scoped grant is reviewed, **external release/redistribution approval remains pending**. Internal research and definition of immutable V1 continue, without copying unreviewed binaries into this first-party repo. This update records the user's factual assertion rather than independently verifying the underlying agreement.

## M3 Precision BBA／EPBot research-only audit (2026-10-24)

**Decision: INVESTIGATE FOR RESEARCH / BLOCK PRODUCTION & REDISTRIBUTION.**

| Field | Verified scope and open risk |
|---|---|
| name / supplier | Bridge Bot Analyzer (BBA) and native EPBot by Edward Piwowar |
| canonical URL | https://github.com/EdwardPiwowar/BBA |
| upstream BBA ref | Public repository main observed at `ad2f8880e3ba557d745ef44d18ff1bcfa7acda1d` on 2026-10-24; **this is NOT an attested source for the embedded BEN binary** |
| integration mode | **Transient, isolated, non-distributed research only**; use native `libEPBot.so` from separately pinned BEN checkout; no binary or third-party CC committed to Bridge Academy |
| bundled BEN provenance | https://github.com/lorserker/ben pinned `ad8608af6e6bfe095863023f344f3cb2cbafec3d` |
| actual convention card | `BBA/CC/Meckwell.bbsa`, SHA256 `5c2a6c8d84094a0a9efd2cefe98a93983185140e6bde81b2520086b8b27d9cbc` |
| observed native path / hash | `bin/BBA/linux/x64/libEPBot.so`; M1.2 inventory listed `c35d00b7aacdb5fe7bd4a5aeb1f5cdacef9856f9fc7b4ff4048368b6827777b4` (reverify binary SHA at future actual release checkpoint) |
| license / notices | BBA README: **no explicit license in repository**; author requests contact for commercial use or redistribution. No authoritative positive grant for production, hosting, modifications, derivatives, output redistribution or packaging in BEN release yet |
| native/transitive licensing | `libEPBot.so`, `Meckwell.bbsa`, and native dependencies do not inherit BEN GPL-3.0 approval. Review each right and any NOTICE separately |
| reference system mismatch | Upstream EPBot `Meckwell.bbsa` 1NT **13–15**, separate Meckwell Lite v1.13.0 (2026-01-05) reference **13–16**; further agreements need itemized expert review |
| known CVE status | **NOT REVIEWED** (no claim of absence). Native EPBot was not subjected to code audit; treat as untrusted in disposable CI |
| build/runtime scope | Ubuntu 24.04, Python 3.12, local ephemeral vendor checkout, `ctypes` native load |
| test evidence | [M3 Research CI #40092078930](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40092078930) **success**, eight native openings, four strong-club candidates had zero deviations; see [M3 report](research/M3_PRECISION_SPIKE_ACCEPTANCE.md) |
| decision owner/date | Bridge Academy project owner / 2026-10-24; no publication approval inferred |
| recheck trigger / date | On written authorization, chosen Precision card version, EPBot update or 2026-11-24, whichever comes first |
| rollback | Keep BBA checkout only in disposable CI; remove `precision-m3-research.yml` and research files without touching live Gateway |
| release blockers | Written commercial/hosted/redistribution permission, card ownership and edits, ABI/runtime, 100+ expert fixtures, real complete game, privacy, deployment and load tests |

Do not distribute binaries, train new models on EPBot outputs, or expose a remote Precision API **until rights for those uses have been reviewed**. This is engineering risk triage, not legal advice.

## Mandatory audit record (per dependency)
Source URL, exact commit/tag, copy/use mode (REST service, dynamic link, fork, code copy), license text location, copyright notices, subdependencies and models, platform compatibility, known CVEs, last CI/test evidence, release restrictions, decision owner/date, and rollback path.

## Obligations and separation
- GPL-3.0 software may be used commercially, subject to its conditions. Internal/server execution and distribution are materially different scenarios. A mere REST boundary is not an automatic legal safe harbor for a derivative work. Review architecture and distribution facts, especially any modified or redistributed BEN code.
- GPL is not AGPL: ordinary remote access alone does not automatically trigger AGPL-like source-offer provisions. Do not generalize beyond the exact license and actual service design.
- Keep BEN as an independently deployed service until reviewed. Do not vendor model checkpoints or binaries into the mobile app without permission review.
- DDS omniscient analysis must be segregated from fair-play bot decisions irrespective of license.
- The repository is private and has no chosen first-party open-source LICENSE file; do not describe its content as automatically MIT/Apache or publicly redistributable.

## Reference specification for skills
https://agentskills.io/specification
https://github.com/anthropics/skills
https://github.com/openai/codex/tree/main/codex-rs/skills/src/assets/samples/skill-creator

References were used for structural conventions; no upstream skill text was copied.

