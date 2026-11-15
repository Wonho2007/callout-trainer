# Decisions and assumptions

| Topic | Status | Decision / next action |
|---|---|---|
| Engine | Confirmed by user | Godot |
| Development team | Confirmed by user | Wonho2007 = Person 2; sn-kurup/liedwin49 choose Persons 1/3 |
| Natural language | User-directed, revised 2026-11-14 | Player input is **voice only**; no quick-call menu (menu code retained as a deterministic test/fallback helper). A local LLM interprets free speech into the structured comm schema; deterministic keyword/fallback remains as the circuit breaker |
| Product | Confirmed direction, revised 2026-11-14 | **VALORANT comms coach.** Player controls one character first-person in a VALORANT-like sandbox; bots play all other teammates/enemies; player speaks voice comms that teammates hear, interpret and react to; teaching is through in-round consequences of good/bad comms |
| Editor version | Open; Person 1 | Pin exact stable Godot 4 editor and matching export templates |
| Development workflow | User-directed | Agent-led, code-generated/data-driven greybox; human launch/inspection/playtesting remains required |
| Language/renderer | Proposed default | Typed GDScript / Compatibility; confirm against skills and hardware |
| Scenario | Open; all | Select public clip, map/site, takeover moment and communication opportunity |
| Initial scope | Planning default | 30-45 seconds; player + two allies vs two enemies; rifle, smoke, flash, defuse |
| Available development time | User-reported | Approximately 11 hours at the latest scope discussion; earlier 24-hour schedule is historical planning |
| Target/demo | Open; Person 1 | OS, hardware, export and presentation format |
| Schemas | Mixed | New communication boundary selected: docs/COMMANDS.md, comms.v1. Other engine contracts remain proposed v0 |
| Trust model | User-directed, 2026-11-14 | **Removed.** Overrides brief §6.7. Bots no longer keep per-speaker trust τ and do not discount or "scar" a player for wrong calls. A callout updates belief using the player's own hedge only (sure/think/unsure → strength 0.9/0.7/0.4); the consequence of a bad call is a bad in-round outcome (the bot commits and can die), not a hidden trust penalty. Affects belief/region_belief.gd (τ, confirm/refute, verification window all dropped) and its tests. Cross-lane: Person 2's planner/controller is where "punish by dying" actually plays out. |
| Evaluation | Required plan; partially revised 2026-11-14 | VOD-only, silent, chatty, full; unseen variants and human receiver if feasible. The symmetric-vs-asymmetric trust arm (brief §7.3) is dropped with the trust model; other arms stand |
| Teammate AI | User-directed, 2026-11-14 | Teammate decisions are made by a **local LLM, non-deterministically**, using only information the bot is allowed to have (delayed observations, own state, local beliefs, public signals). A deterministic policy/behavior-tree fallback is the required circuit breaker (hierarchical: LLM interprets/sets goals, deterministic executor acts) |
| LLM approach | User-directed, 2026-11-14 | **Grounding, not training.** A free pre-trained local model is given the game vocabulary (regions/agents/abilities/weapons from valorant-api.com) and a strict output schema at runtime. No fine-tuning: there is no VALORANT comms→intent dataset; adaptable generic intent/slot corpora (Fluent Speech Commands, SLURP/MASSIVE) still need hand-written VALORANT examples plus GPU time for a likely worse result, so they are recorded only as fallback/justification and an optional later few-shot source |
| Model/run machine | User-directed, 2026-11-14 | A capable PC with a discrete GPU runs the LLM and simulation (specific machine TBD, not finalized). Model weight files are portable: run once anywhere with the same runtime; no per-machine training |
| Scenario source | User-directed, 2026-11-14 | One real round reconstructed by **hand-annotating a public VOD** (GRID Open Access gives schedules/pre-post-match only, not positions). First round: FNC vs PRX, Masters Toronto 2024 Grand Final, Lotus, final round, from the bomb plant. Person 3 annotates; Person 2 converts to executable scenario; no pro positions/facts invented |
| Grading/debrief | Deferred, 2026-11-14 | Post-round grading (bot belief vs truth; which comms were wrong/late) and the belief-only counterfactual are deferred until the core voice→LLM→reaction loop works. Not cut |
| Core counterfactual | Required | Belief-only replay; changed combat outcome is approximate stretch |
| License/assets | Open | Owner chooses license; verify third-party asset redistribution before use |
| Repo visibility | Public, requested by user | Invite sn-kurup and liedwin49 with write access; collaborators must accept |

Record confirmed decisions with date, context and affected interfaces. No map, agent statistic, source clip or human outcome may be invented to fill an open choice.

The PDF advice/requirements were reviewed for the brief, but PDF files are not in this repository. Brief sections 1 and 8 contain the summaries and page mapping. External papers, historical statistics and policy dates remain unverified motivation.
