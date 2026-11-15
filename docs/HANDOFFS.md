# Current integration status

Updated 2026-11-15. This is a current index, not an append-only journal.

| Work area | Implemented / evidence | Next or unresolved |
|---|---|---|
| Person 2 / PC | Local model and mic setup; five standalone spoken calls confirmed; delayed voice/game bridge; separate seven-region plant adaptation; physical late-spawn combat/navigation/reset checks | Human voice-to-Lotus acceptance, exact ally/utility baseline, coordinated belief changes and final delivery |
| Person 3 supplied code | Interpreter/vocabulary/log/pipeline/audit and first-pass annotation at `b84cc93`; consumed read-only. Scene still uses belief `57f809d` | Source review, working-belief acceptance and paired snapshot/planner field-removal integration |
| Inherited Person 1 work | Existing world, player, shared weapons/utility/navigation and root scaffold reused. Person 1 is no longer active | Person 2 owns remaining engine/world/export work; no dependency on Person 1 returning |

Current branch: `person-2/model-capability-spike`. Gameplay checkpoint: `608cae7`.
Previous checkpoints `156c581` (voice/game bridge) and `2a33eda` (GPU/live mic).
PR #4 was already merged before this branch; no current-main merge is claimed.

## Read next

- [Project description](PROJECT_DESCRIPTION.md): product, current scope and deferred work.
- [Person 2 handoff](PERSON2_HANDOFF.md): authoritative continuation state, exact tools,
  test scopes, remaining dependencies and next sequence.
- [New Codex prompt](CODEX_RESUME_PROMPT.md): paste into a fresh window.
- [Scenario guide](../bots/LOTUS_SCENARIO.md): plant start, +23s first-known spawning.
- [Voice/game guide](../bots/VOICE_GAME.md): transport, measured goal failures, selected fallback.
- [Historical index](ARCHIVE.md): earlier implementation records and planning snapshots.

## Evidence to preserve

552 default/cross-lane assertions; 139 live-perception checks; 31 new functional scenario
checks; seven Python authoring/voice-boundary tests; Person 3 schema validation with
expected unknowns; real-model typed engine response/movement and a scoped recorded-
boundary audit. Rendered captures were inspected. Five standalone human mic calls were
confirmed; new human voice-to-Lotus, export/offline acceptance and backup video are not.

Full model-goal attempts are **not passing**. The selected sprint scope is LLM
interpretation with deterministic goal selection. Do not silently enable experimental
goals, lengthen context expiry or add failed/older test totals to claim completion.

Update the current handoff and relevant component guide after a real change. Record
changed paths, interface effects, commands/results, unresolved work and the next step.
Replace outdated status rather than appending contradictory resume directions. Git history
preserves previous records, including teammate contributions and original attribution.
