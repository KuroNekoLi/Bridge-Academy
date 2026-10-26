# Bridge Academy Agent Skills

These are repository-local Agent Skills in the open SKILL.md layout. Open **AGENTS.md** first; choose only the skill for the requested domain. Every skill has YAML frontmatter (name = directory, description = trigger), workflow, safety boundary and evidence required. Skills are task instructions, not a running background multi-agent system or an automatic permission grant.

**Product baseline:** Start with [PRD v1](../docs/planning/ROADMAP.md), [Delivery Roadmap](../docs/planning/ROADMAP.md) and [Competitor Benchmark](../docs/research/RESEARCH_REPORTS.md) when choosing the next user-visible slice. Do not derive product completion from the engineering milestones alone.

| Task | Skill |
| --- | --- |
| Plan/coordinate constrained milestones | [bridge-orchestrator](bridge-orchestrator/SKILL.md) |
| Review bridge rules, bidding legality and scores | [bridge-rules-reviewer](bridge-rules-reviewer/SKILL.md) |
| Connect BEN/API, test AI actions and visibility | [bridge-ai-integration](bridge-ai-integration/SKILL.md) |
| Batch-test, QA, performance, reproduce boards | [bridge-playtest](bridge-playtest/SKILL.md) |
| Enforce architecture & isolation boundaries | [bridge-architecture-guardian](bridge-architecture-guardian/SKILL.md) |
| Describe/test bidding conventions and explanations | [bridge-convention-reviewer](bridge-convention-reviewer/SKILL.md) |
| License/version/third-party audits | [bridge-open-source-auditor](bridge-open-source-auditor/SKILL.md) |
| **Teach engineering after each completed feature** | [bridge-learning-mentor](bridge-learning-mentor/SKILL.md) |

Reference formats and examples:
- https://agentskills.io/specification (canonical format)
- https://github.com/anthropics/skills/tree/main/template
- https://github.com/openai/codex/blob/main/codex-rs/skills/src/assets/samples/skill-creator/SKILL.md

**Required for feature tasks:** coordinate the domain skill with bridge-learning-mentor, append one section per feature to docs/implemented/ENGINEERING_NOTES.md, update docs/implemented/FEATURES.md, then include one brief interactive teaching checkpoint in the completion message. See docs/implemented/ENGINEERING_NOTES.md. This does not mean each trivial commit needs a lesson.

Original instructions written for this project. Do not confuse the public examples' licensing with our own repository or BEN's GPL-3.0. No placeholder scripts are included; add executable scripts only when required and tested.
