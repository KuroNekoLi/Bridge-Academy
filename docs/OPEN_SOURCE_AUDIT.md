# Third-party components and license gate

**Audit state: preliminary research only.** Verify repository LICENSE at an immutable commit, model weights, bundled native binaries, transitive dependencies and any service/redistribution constraints before code integration or public release. This is engineering triage, not legal advice.

| Candidate | Purpose | License from upstream documentation / initial research | Decision |
| --- | --- | --- | --- |
| BEN — https://github.com/lorserker/ben | bidding/lead/play/autoplay ML service | GPL-3.0 identified; verify exact commit, weight rights, bundled packages | POC integration only; production rights review |
| DDS — https://github.com/dds-bridge/dds | double-dummy solver | Apache-2.0 identified; verify checked-out release and any bundled interfaces | Analysis candidate |
| endplay — https://github.com/dominicprice/endplay | PBN/score/deal tooling | License and DDS integration obligations must be rechecked per version | Candidate, not locked |
| bridge-engine — https://github.com/kduffie/bridge-engine | TypeScript game-engine reference | MIT identified; robot strength does not replace BEN | Reference only |
| eBridge — https://github.com/ebridge/bridge-web | multiuser architecture reference | Not independently audited | Reference only |

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

