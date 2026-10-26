# Third-party components and license gate

## 2026-10-26 — Flutter 撲克牌呈現套件（M2-F54）

| 必要欄位 | 實際紀錄 |
| --- | --- |
| name / version | `playing_cards 0.4.1+11`，pubspec 精確版本，pubspec.lock 釘選 archive SHA |
| URL / immutable artifact | [pub.dev](https://pub.dev/packages/playing_cards)、[repository](https://github.com/bedardjo/playing_cards)、[精確 archive](https://pub.dev/api/archives/playing_cards-0.4.1%2B11.tar.gz)；以 registry archive 釘選，不把浮動 master 當審核版本 |
| pinned_sha | **archive SHA256** `392d5e42317ec657f6814a282e6bb70942c6599d22dac89cdc741a8b2b095d09`；本輪不宣稱對應未查證的 Git commit |
| release_date | registry `2023-08-02T10:59:56.478688Z`；發版較久，未宣稱持續活躍維護 |
| purpose / integration_mode | Flutter presentation package dependency；只映射已授權 Card 至 PlayingCardView；不使用 deck generation、規則器、AI、完整四手牌或外部網路服務 |
| license_and_url / notices | archive `LICENSE` 為 Apache License 2.0；[同版本 license](https://pub.dev/packages/playing_cards/versions/0.4.1+11/license)。archive 無獨立 NOTICE；保留 package LICENSE 並透過 Flutter notices＋App「我的 → 開源授權」提供。未修改上游 source |
| imagery / model_weight_license | 不涉及模型。上游註解指向 Wikimedia SVG playing cards 類別，未提供各 court/suit/back 圖像唯一來源。App 使用全 rank/suit 字形 style，測試無 Image widget。**Flutter 可能仍打包 package 宣告的未使用圖像，公開 binary 前需排除或補完逐圖授權**；不能把 Apache code license 自動當逐圖 sign-off |
| transitive_licenses | runtime pubspec 只依賴 Flutter SDK；未增加 provider/svg 等 runtime 套件。Flutter 既有授權沿用 notices，不因此聲稱全 repo 已稽核 |
| known_cves | 本輪未執行完整 CVE／供應鏈掃描；不宣稱零漏洞 |
| build_environment / supported_platforms | 本機 Windows Flutter 3.47.8／Dart 3.13.7；pub.dev 宣告 Android/iOS/Linux/macOS/Web/Windows，不等於這些平台都驗證 |
| test_evidence | [52 張映射／投影／鍵盤／停用測試](../apps/bridge_academy_flutter/test/m2_card_presentation_test.dart)；完整結果見 [本輪驗收](product/UX_WORKSPACE_ACCEPTANCE.md)。Android/iOS UI/E2E 依 owner hold 未執行 |
| risks | 舊版維護、畫面相容、上游 bundled imagery 來源／打包問題；依賴替換不應改 Core 或資料 schema |
| decision_and_owner | **ACCEPT WITH CONDITIONS，開發整合**；公開發行仍受影像排除／來源、完整依賴稽核與 owner release sign-off 約束。工程責任範圍為 renderer adapter；產品發行由 owner 決定 |
| next_review_date / rollback | 最遲公開 binary 發行前重審；SDK／套件／資產有變更立即重審。可 git revert 本輪 source/pubspec/lock；無資料遷移 |

比較候選 `card_game 2.0.0`：[pub.dev](https://pub.dev/packages/card_game)、[上游](https://github.com/JLogical-Apps/card_game)，registry 發版 `2025-04-28T00:16:16.048749Z`，archive SHA256 `d5f0720c3f320fda8adc17f02f155f94fea799efa6dd557091fc60ca4f8055d9`。pub.dev 標示 MIT，支援拖放／翻牌／移動動畫，runtime dependencies 包含 collection/equatable/flutter_svg/provider。**REFERENCE ONLY／未安裝／未複製**，尚無本專案 pinned source、資產及 transitive 授權／CVE 相容性 sign-off。U3 若導入另行審查，不把目前比較當成准入。

**Audit state: preliminary research only.** Verify repository LICENSE at an immutable commit, model weights, bundled native binaries, transitive dependencies and any service/redistribution constraints before code integration or public release. This is engineering triage, not legal advice.

| Candidate | Purpose | License from upstream documentation / initial research | Decision |
| --- | --- | --- | --- |
| BEN — https://github.com/lorserker/ben | bidding/lead/play/autoplay ML service | GPL-3.0 identified; verify exact commit, weight rights, bundled packages | POC integration only; production rights review |
| DDS — https://github.com/dds-bridge/dds | double-dummy solver | Apache-2.0 identified; verify checked-out release and any bundled interfaces | Analysis candidate |
| endplay — https://github.com/dominicprice/endplay | PBN/score/deal tooling | License and DDS integration obligations must be rechecked per version | Candidate, not locked |
| bridge-engine — https://github.com/kduffie/bridge-engine | TypeScript game-engine reference | MIT identified; robot strength does not replace BEN | Reference only |
| eBridge — https://github.com/ebridge/bridge-web | multiuser architecture reference | Not independently audited | Reference only |

## M3.3 BBA rights confirmation — owner statement (2026-10-24)

The Bridge Academy owner explicitly confirmed: **BBA usage permission includes commercial hosting, modification and redistribution**. The previous status "permission obtained; usage scope unknown" is therefore **superseded for these three categories** and should not be presented as if the user had not obtained permission.

| Use | Owner statement | Independently verified grant / source artefact |
| --- | --- | --- |
| Use BBA | GRANTED (reported by owner) | Exact agreement not provided in repo |
| Commercial hosted API / SaaS | GRANTED (reported by owner) | Document not independently reviewed |
| Modify BBA / EPBot | GRANTED (reported by owner) | Document not independently reviewed |
| Redistribute BBA / EPBot | GRANTED (reported by owner) | Document not independently reviewed |
| Grant covers this exact native binary and third-party assets | NOT DOCUMENTED IN REPO | Verify in release review |
| Model weights, transitive licenses, attribution, terms/expiry | NOT DOCUMENTED IN REPO | Separate dependency audit |

The product direction can proceed with **native BBA Provider engineering** without asking the owner to re-confirm these rights. This update is a faithful record of user-provided authorization, not a representation that the assistant inspected the contract or that all unrelated production gates were met. Do not upload private correspondence to a public repository.

M3.3 implementation uses a pinned native EPBot only in disposable CI, with provenance checks. Confirm all redistribution manifests, binary ownership, terms and required notices **before constructing a distributable production container/image**.

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

