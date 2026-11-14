# Decisions and assumptions

| Topic | Status | Decision / next action |
|---|---|---|
| Engine | Confirmed by user | Godot |
| Development team | Confirmed by user | Wonho2007 = Person 2; sn-kurup/liedwin49 choose Persons 1/3 |
| Natural language | User-directed | Flexible paraphrases; report_enemy, throw_flash, swing_together; cue/cancel support. Interpreter/provider not selected; deterministic fallback remains required |
| Product | User-confirmed objective | Clear team communication throughout play. Readiness coordination is one subskill; coach timely reports, utility planning, death reports and relevant omissions. See docs/COMMUNICATION_COACHING.md |
| Editor version | Person 1 proposal; Person 2 tested | Person 1 branch commit d742751 proposes Godot 4.4.1 stable standard GDScript. Person 2 headless checks use that exact build. Export templates and whole-team confirmation remain pending |
| Development workflow | User-directed | Agent-led, code-generated/data-driven greybox; human launch/inspection/playtesting remains required |
| Language/renderer | Proposed default | Typed GDScript / Compatibility; confirm against skills and hardware |
| Scenario | Open; all | Select public clip, map/site, takeover moment and communication opportunity |
| Initial scope | Planning default | 30-45 seconds; player + two allies vs two enemies; rifle, smoke, flash, defuse |
| Available development time | User-reported | Approximately 11 hours at the latest scope discussion; earlier 24-hour schedule is historical planning |
| Target/demo | Open; Person 1 | OS, hardware, export and presentation format |
| Schemas | Mixed | New communication boundary selected: docs/COMMANDS.md, comms.v1. Other engine contracts remain proposed v0 |
| Evaluation | Required plan; not run | VOD-only, silent, chatty, full; unseen variants and human receiver if feasible |
| Core counterfactual | Required | Belief-only replay; changed combat outcome is approximate stretch |
| License/assets | Open | Owner chooses license; verify third-party asset redistribution before use |
| Repo visibility | Public, requested by user | Invite sn-kurup and liedwin49 with write access; collaborators must accept |

Record confirmed decisions with date, context and affected interfaces. No map, agent statistic, source clip or human outcome may be invented to fill an open choice.

The PDF advice/requirements were reviewed for the brief, but PDF files are not in this repository. Brief sections 1 and 8 contain the summaries and page mapping. External papers, historical statistics and policy dates remain unverified motivation.
