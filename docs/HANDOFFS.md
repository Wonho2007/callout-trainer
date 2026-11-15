# Current integration status

Fetched and locally merged Person 3/shared updates through **0260f28** on the
existing integration branch. New-source bot regression: 575 pass; existing live
profile with compatibility overlays: 40 pass. The voice scenario now selects 0260f28 with height-correct anchors, bidirectional existing-box jump links and CSG collision navigation. Latest no-ramp jump version passes 46 scene checks and
575 required bot assertions; the earlier 41-check capture predates jumping.
These automated results are not human playtest acceptance.
No remote push is authorized by the latest handoff. See the current Person 2 handoff.

Updated 2026-11-15. **Resolved: the user-reported flash failure is diagnosed and
fixed (far-but-reachable zones now walk into range instead of failing in place).
A fresh human microphone playthrough of the fix is still unconfirmed; automated
passes are not human acceptance.** This is a current index, not an append-only journal.

| Work area | Implemented / evidence | Next or unresolved |
|---|---|---|
| Person 2 / PC | Local model and mic setup; five standalone spoken calls confirmed; delayed voice/game bridge; Person 3 seven-zone map as default; annotated movement/utility baseline with observation-based deviations; flash firing gate/head icon; dead bots disappear | Human voice-to-Lotus/baseline acceptance, exact-kit fidelity, coordinated belief changes and final delivery |
| Person 3 supplied code | Interpreter/vocabulary/log/pipeline/audit and first-pass annotation at `b84cc93`; consumed read-only. Scene still uses belief `57f809d` | Source review, working-belief acceptance and paired snapshot/planner field-removal integration |
| Inherited Person 1 work | Existing world, player, shared weapons/utility/navigation and root scaffold reused. Person 1 is no longer active | Person 2 owns remaining engine/world/export work; no dependency on Person 1 returning |

Current branch: `person-2/model-capability-spike`. Bot checkpoint: `86a54aa`; map merge: `513b2e9` (source `76b8eaa`).
Previous checkpoints `156c581` (voice/game bridge) and `2a33eda` (GPU/live mic).
PR #4 was already merged before this branch; no current-main merge is claimed.

## Read next

Teammate positioning now persists: "play Heaven with me" navigates and holds Heaven
until a new position/cancel or round/death reset. Enemy reports and short action
expiry no longer restore spike coverage. A live follow-up found that "Let's push
A Link together" still completed a swing then returned to Pit; push positioning
and completed-swing destination retention now cover that path. Latest checks:
575 required, 47 site, 24 positioning and 10 completed-movement checks pass.
The implementation stays in the primary
runtime/voice lane; the combat UI worktree remains separate. Current site guidance
documents the focused --position-orders-only regression.

- [Parallel combat UI assignment](PARALLEL_COMBAT_UI_HANDOFF.md): separate Codex
  worktree for player kill feedback/count, defeat screen and visible health bar.
  This is a scoped parallel task; the primary bot/navigation lane stays here.

Current local rifle tuning is 40 body / 160 head damage for player and bots;
the integration runner overlays the shared weapon script onto its pinned source.

- [Project description](PROJECT_DESCRIPTION.md): product, current scope and deferred work.
- [Person 2 handoff](PERSON2_HANDOFF.md): authoritative continuation state, exact tools,
  test scopes, remaining dependencies and next sequence.
- [New Kiro prompt](KIRO_RESUME_PROMPT.md): paste into a fresh window.
- [Current site guide](../bots/SITE_SCENARIO.md): imported map, circular-zone precedence, plant starts and +23s arrivals.
- [Voice/game guide](../bots/VOICE_GAME.md): transport, measured goal failures, selected fallback.
- [Historical index](ARCHIVE.md): earlier implementation records and planning snapshots.

## Evidence to preserve

Current teammate flash: one extra charge per round, all seven region targets; turn,
check static world/smoke LOS, throw in place if a point is visible within range,
otherwise walk toward the zone and throw as soon as a point opens in range — whether
it was occluded or just too far — failing honestly only when navigation cannot get
closer. Cancellation before release preserves inventory. There is no teammate molly
voice command. This is a user-requested kit extension.

Preparation commands now enforce `on_cue` at the engine bridge: "get ready to swing"
waits for a separate "swing"/"go". A real TCP 35-check regression verifies a wrong
model `now` proposal cannot release early; delivery/readiness/expiry stay intact.

Current imported map: 36 functional checks pass with visibility-first flash commands;
earlier 24 rendered map checks passed and capture was inspected before that update;
voice launcher syntax passes. Main was already included at `8712f7d`; new map
arrived from `person-3/greybox-b-site` at `76b8eaa`. Existing bot/voice/damage changes
were checkpointed before the merge. Source geometry/zones remain unchanged.

575 current default/cross-lane assertions; 139 live-perception checks; 53 current functional scenario
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
