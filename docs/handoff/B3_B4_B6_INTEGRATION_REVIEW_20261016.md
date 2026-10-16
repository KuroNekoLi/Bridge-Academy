# B3.2 + B4.1 + B6.1–B6.3 — 2026-10-16 Code Review / Integration Acceptance

**Scope**: three independent feature branches merged into `integration/b3-b4-b6-review-20261016` with real two-parent Git merge commits; each parent preserves feature branch history. **This report records the reviewed integrated tree, not a new user feature.**

## Source branches and independent CI
| Feature | Branch SHA | Independent evidence | Scope |
| --- | --- | --- | --- |
| B6 deterministic daily practice | `10ca7b746efcdc1ded9a3c14976e95ec82b9fdd3` | [124/124 Flutter, Web and Chrome](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38910655183) | UTC original 4-board practice, encrypted local results, no ranking |
| B4 original Academy beginner lessons | `47237b1b4d82c9d5523e2558aa9ae82d4a341733` | [128/128 Flutter and Web](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38909904915) | 3 beginner lessons / 9 bilingual questions, session-only completion |
| B3.2 convention explanation profiles | `462eda1753f26645f712c2146066f39de4dbd19a` | [129/129 Flutter, Web and Chrome](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38909043985) | B3.1 version-preserving public-auction conventions, explicit UNREVIEWED |

## Integration review
- **Shared Flutter shell conflicts resolved, not overwritten**: `bridge_app.dart` retains B6 daily launcher/panel, B4 AppBar Academy Navigator route and B3.2 BiddingConventionPanel. Common `app_copy.dart` contains all B6, B4 and B3.2 zh-TW/en localized keys.
- **Learning ID collisions resolved**: branch-local `M2-F43` IDs were distinct features despite reusing one number. Canonical integration assigns **M2-F43 B6**, **M2-F44 B4**, **M2-F45 B3.2**; renamed lessons, repaired index links, and normalized B3.2 heading `## 主要程式碼導讀` for repository gate.
- **Privacy / domain**: B6's entire deterministic Deal stays in the trusted local session/checkpoint, not in PlayerView; B4 uses separate original fixed teaching content; B3.2 explanation accepts public auction context and no hands. Core remains rule/score authority. Neither B3.2 profile previews nor B6 Demo Bot may be represented as actual BEN bidding system or server-authorized competition.
- **Persistence**: B6 daily encrypted ledger is separate from privileged active-game checkpoint; no cross-store atomicity is claimed. B4 in-page progress is intentionally transient pending C3; B3.2 profile preview toggle is ephemeral.
- **Known intentional limitations**: B3.2 proposed Stayman/Jacoby content not expert-approved; B6 deterministic client deals are predictable and never MP/IMP-ranked; no production BEN HTTPS deployment or human app usage study. No Android emulator/physical Android/iOS QA run per owner hold.
- **Review method**: compared three branches against original common master `2a382ac2230afc8059b93f3d4271ccb9bab14c74`; reviewed touched Dart/UI modules, session/persistence, learning notes and acceptance reports. This is scoped code review and CI acceptance, not formal security audit or bridge expert endorsement.

## Actual combined verification (one integrated tree)
- [Flutter Single Player run #38913225555](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38913225555) on commit `e51e72ad3b21d69bb33afae42ecb6cbbbe32578a`:
  - `flutter analyze --no-pub` **No issues found**
  - `flutter test --no-pub --reporter expanded` **145/145 All tests passed**
  - `flutter build web --no-pub --release` **PASS**, `Built build/web`
  - **Real ChromeDriver Demo browser E2E PASS**
- [Feature Learning Gate #38913331834](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38913331834) on commit `cde8059fa76446a110934d372d5d26e807ef2751`: **PASS** after document-heading correction.
- The combined CI does **not** run real production-hosted BEN, physical devices or bridge expert review; these gates remain pending.

## Merge hygiene and rollback
- Original `master` workflows' branch filters are restored on the final integration commit; temporary integration and B6 branch-run routing is **not shipped** to master.
- Feature branches remain intact with their history. Prefer revert of integration merge chain or targeted rollback with evidence rather than rewriting master; migration/user data must be evaluated before feature removal.
- On master push, verify branch-scoped Flutter and Feature Learning Gate again against the production branch SHA and explicitly record result.
