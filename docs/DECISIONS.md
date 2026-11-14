# Decisions and assumptions

| Topic | Status | Decision / next action |
|---|---|---|
| Engine | Confirmed by user | Godot |
| Development team | Confirmed by user | Wonho2007, sn-kurup and liedwin49; lane assignments pending |
| Product | User-confirmed objective | Clear team communication throughout play. Readiness coordination is one subskill; coach timely reports, utility planning, death reports and relevant omissions. See docs/COMMUNICATION_COACHING.md |
| Editor version | Pinned by Person 1 (2026-11-14); team confirmation pending | Godot 4.4.1 stable, Windows 64-bit standard build (Godot_v4.4.1-stable_win64, GDScript, not .NET). Matching 4.4.1-stable export templates to be installed before first export. All developers must use this exact build. |
| Development workflow | User-directed | Agent-led, code-generated/data-driven greybox; human launch/inspection/playtesting remains required |
| Language/renderer | Proposed default | Typed GDScript / Compatibility; confirm against skills and hardware |
| Scenario | Open; all | Select public clip, map/site, takeover moment and communication opportunity |
| Initial scope | Planning default | 30-45 seconds; player + two allies vs two enemies; rifle, smoke, flash, defuse |
| Deadline | Unverified inheritance | Brief assumes 24 hours; verify with event |
| Target/demo | Open; Person 1 | OS, hardware, export and presentation format |
| Schemas | Proposed v0 | Review docs/CONTRACTS.md and fixture, freeze together |
| Evaluation | Required plan; not run | VOD-only, silent, chatty, full; unseen variants and human receiver if feasible |
| Core counterfactual | Required | Belief-only replay; changed combat outcome is approximate stretch |
| License/assets | Open | Owner chooses license; verify third-party asset redistribution before use |
| Repo visibility | Public, requested by user | Invite sn-kurup and liedwin49 with write access; collaborators must accept |

Record confirmed decisions with date, context and affected interfaces. No map, agent statistic, source clip or human outcome may be invented to fill an open choice.

The PDF advice/requirements were reviewed for the brief, but PDF files are not in this repository. Brief sections 1 and 8 contain the summaries and page mapping. External papers, historical statistics and policy dates remain unverified motivation.

## Decision log

### 2026-11-14 — Godot editor version pinned (Person 1)

- **Decision:** Pin the editor to **Godot 4.4.1 stable, Windows 64-bit standard build** (`Godot_v4.4.1-stable_win64`, GDScript edition, not the .NET/C# build).
- **Context:** Person 1 owns the editor-version pin (brief §9.1, AGENTS.md). 4.4.1 is a mature stable release; chosen over the newest 4.5 to reduce newest-release risk, and over older 4.3 to stay current. Person 1 has this build downloaded locally.
- **Still pending:** the other developers (Wonho2007, sn-kurup) must install this same exact build and confirm; matching **4.4.1-stable export templates** must be installed before the first desktop export; launch must be confirmed on the actual demo/target hardware. Until the team confirms, treat this as a Person 1 proposal, not a frozen team decision.
- **Affected interfaces:** `project.godot` (config version / features), export presets, any version-specific API usage, CI editor version if added later.
