# Decisions and assumptions

| Topic | Status | Decision / next action |
|---|---|---|
| Engine | Confirmed by user | Godot |
| Development team | Confirmed by user | Wonho2007 = Person 2; sn-kurup/liedwin49 choose Persons 1/3 |
| Natural language | User-confirmed updated direction, 2026-11-14 | Voice-only player comms; grounded local LLM interpretation and goal selection. Quick-call code remains a deterministic test/fallback helper. Existing comms.v1 report/command/cue/cancel shapes remain unchanged |
| Product | User-confirmed updated direction, 2026-11-14 | First-person comms coach with bot teammates/enemies; spoken information changes bot beliefs/goals and physical behavior; teach through in-round consequences |
| Editor version | Pinned by Person 1 (2026-11-14); team confirmation pending | Godot 4.4.1 stable, Windows 64-bit standard build (Godot_v4.4.1-stable_win64, GDScript, not .NET). Matching 4.4.1-stable export templates to be installed before first export. All developers must use this exact build. |
| Development workflow | User-directed | Agent-led, code-generated/data-driven greybox; human launch/inspection/playtesting remains required |
| Language/renderer | Proposed default | Typed GDScript / Compatibility; confirm against skills and hardware |
| Scenario | Open; all | Select public clip, map/site, takeover moment and communication opportunity |
| Video annotation | User-assigned | Person 3 owns verified source notes in annotations/; Person 2 converts them into executable scenarios/ and validates. See docs/VIDEO_ANNOTATION.md |
| Initial scope | Planning default | 30-45 seconds; player + two allies vs two enemies; rifle, smoke, flash, defuse |
| Available development time | User-reported | Approximately 11 hours at the latest scope discussion; earlier 24-hour schedule is historical planning |
| Target/demo | Open; Person 1 | OS, hardware, export and presentation format |
| Schemas | Mixed | New communication boundary selected: docs/COMMANDS.md, comms.v1. Other engine contracts remain proposed v0 |
| Player comm acceptance | Latest explicit user direction | Teammates always fully trust valid player comms, even if wrong. No credibility/history penalties or numeric hedge-based credibility discounts. Preserve explicit uncertainty as meaning. Delay, clarification, feasibility and provenance checks remain. Person 3 must align the currently hedge-weighted belief/model path; empty trust: {} is compatibility metadata only |
| Teammate AI | User-confirmed updated direction, 2026-11-14 | Person 3's free/local pretrained LLM interprets and sets goals from copied available inputs; Person 2 validates and physically executes them; deterministic fallback required. Grounding, not training |
| Model machine | Open | Capable PC with discrete GPU, specific machine TBD; measure latency on the actual target |
| Scenario source | Proposed reference; verification pending | New handoffs name FNC vs PRX / Lotus / final round from plant; Person 3 must verify exact event/year/VOD/round/timestamps. No source-derived actor data is implemented from that label |
| Evaluation | Deferred; not run | Build the core voice-to-reaction loop first; do not build/tune/compare player credibility models |
| Grading/debrief | Deferred, not cut | Build after core voice/LLM/bot integration works |
| Core counterfactual | Deferred, not cut | Belief-only replay after core; changed combat outcome remains approximate stretch |
| License/assets | Open | Owner chooses license; verify third-party asset redistribution before use |
| Repo visibility | Public, requested by user | Invite sn-kurup and liedwin49 with write access; collaborators must accept |

Record confirmed decisions with date, context and affected interfaces. No map, agent statistic, source clip or human outcome may be invented to fill an open choice.

The PDF advice/requirements were reviewed for the brief, but PDF files are not in this repository. Brief sections 1 and 8 contain the summaries and page mapping. External papers, historical statistics and policy dates remain unverified motivation.

## Decision log

### Latest user clarification - teammates fully trust player comms

The user explicitly requires full acceptance of player communication and no trust feature. This overrides the earlier hedge-only numeric weighting direction. Valid reports become the bot's working information without credibility discounts or historical penalties; wrong calls can cause bad tactical outcomes. Explicit uncertainty/last-seen language is preserved as content. Clarification, reaction delay, command validation and physical feasibility still apply. Person 3 owns aligning its belief/LLM implementation; Person 2 owns physical response and fair evidence handling. The current 0.9/0.7/0.4 implementation is a documented gap, not a claim of full acceptance. No runtime/schema change is made by this documentation update.

### 2026-11-14 — newer Person 2/3 direction adopted

The user explicitly confirmed treating the newer documents on Person 3's `b078210` as authoritative. Added their three direction handoffs to this branch and recorded the superseding decisions above and at the top of the brief. Preserve Person 1's existing mechanics/version pin and Person 2's runtime evidence. The voice/LLM model service is still Person 3's unfinished integration dependency; a structured test injection is not a microphone or a working model. Exact LLM intent/log seams remain proposed until both consumers review them; see bots/FIRST_PERSON.md.

### 2026-11-14 — Godot editor version pinned (Person 1)

- **Decision:** Pin the editor to **Godot 4.4.1 stable, Windows 64-bit standard build** (`Godot_v4.4.1-stable_win64`, GDScript edition, not the .NET/C# build).
- **Context:** Person 1 owns the editor-version pin (brief §9.1, AGENTS.md). 4.4.1 is a mature stable release; chosen over the newest 4.5 to reduce newest-release risk, and over older 4.3 to stay current. Person 1 has this build downloaded locally.
- **Still pending:** the other developers (Wonho2007, sn-kurup) must install this same exact build and confirm; matching **4.4.1-stable export templates** must be installed before the first desktop export; launch must be confirmed on the actual demo/target hardware. Until the team confirms, treat this as a Person 1 proposal, not a frozen team decision.
- **Affected interfaces:** `project.godot` (config version / features), export presets, any version-specific API usage, CI editor version if added later.
