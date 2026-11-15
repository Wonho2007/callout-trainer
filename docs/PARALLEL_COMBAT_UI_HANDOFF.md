# Parallel Codex handoff: combat feedback UI

Prepared 2026-11-15. This is a scoped implementation assignment authorized by
the user, alongside ongoing Person 2 bot/navigation work. Implement these three
features: player kill feedback and kill count, a defeat screen, and a visible
player health bar. Do not resume unrelated tasks from older handoffs.

## Start safely

Repository: `C:\Users\Isoto\Documents\GitHub\callout-trainer`.
Integration branch: `person-2/model-capability-spike`. Gameplay baseline:
**019230e**, which removes the Upper ramp and adds physical box jumping.
Recent integration/gameplay work is local; do not substitute an older remote tip.

Inspect status, HEAD and existing worktrees. Read `AGENTS.md`, `README.md`,
`docs/PROJECT_DESCRIPTION.md`, `docs/PERSON2_HANDOFF.md`, `docs/DECISIONS.md`,
`docs/TEAM.md`, `docs/CONTRACTS.md`, then this scoped assignment. The main handoff
has historical Kiro wording; this assignment is explicitly for a Codex instance.

Create your own branch and sibling worktree from the current local integration
branch, including this handoff. Do not switch the other instance's checkout.
From the repository, for example:

```powershell
git status --short --branch
git log -1 --oneline
git worktree list
git merge-base --is-ancestor 019230e person-2/model-capability-spike
git worktree add -b person-2/combat-feedback-ui ..\callout-trainer-combat-ui person-2/model-capability-spike
cd ..\callout-trainer-combat-ui
```

Check each command's result before continuing. If that branch/path already exists,
inspect it and reuse only if it is your assignment; otherwise choose a unique name.
Never reset, clean, stash or overwrite another worker's changes. Do not pull/merge
blindly, merge into main, or push. Commit your completed scoped work locally and
report the branch, commit, changed files and validation for later integration.

## Required behavior

1. **Player kill feedback.** A brief, readable visual confirmation when the player
   kills an enemy, plus a persistent count of the player's kills this round.
   Use native Godot UI/animation; a flash/pulse and kill text are sufficient.
   It must not interrupt aiming or voice. Count a death once, only when attributable
   to the player. Teammate kills, unrelated deaths and damage to dead actors must
   not increase it. Reset both the counter and pending animation on F/restart;
   reject callbacks from a previous round. Preserve existing dead-bot disappearance.
2. **Defeat screen.** Show a clear defeat result, reason and F-to-restart instruction
   when the actual round is lost: spike defused or both player and teammate dead.
   Player death alone is not defeat while the teammate survives; death reports
   through voice remain available. Preserve victory for enemy elimination and
   handle successful spike detonation consistently. End screens must be mutually
   exclusive, clear on restart and release the mouse as the existing victory does.
   Do not change round outcome rules to make presentation easier.
3. **Health bar.** Always readable during normal gameplay, with current/max HP text
   and a bar driven by the actual player Health component. Handle damage, zero HP,
   reset and different max_hp values; do not hardcode 150. Position it without
   overlapping ammo/status, minimap, crosshair or voice/teammate panels. Integrate
   it with F1's player HUD toggle. Preserve F2 and flash/blind/smoke overlays.

Use a coherent, simple style that fits the existing HUD. Keep effects modest and
legible at common window sizes. No new services, model calls or downloaded assets.

## Project and runtime context

- Godot **4.4.1 stable**, GDScript, Compatibility renderer. Installed Python is
  3.12; do not assume the old pasted Python 3.14 environment exists.
- Launch the actual voice scenario with `validation/run_voice_game.ps1`.
  Running the root Godot project opens an authoring scaffold instead.
- Default map/shared source is **0260f28**, consumed in a temporary integration
  project; local overlays supply current bot/player/weapon behavior. Beliefs pin
  **57f809d**. Interpreter source is **b84cc93**, consumed read-only.
- Seven-zone plant hold: player in Heaven, ally/spike in Pit. Four enemies first
  materialize at +23 seconds. Do not add guessed enemies earlier for UI convenience.
- V = push-to-talk, B = dash, F = restart, Esc = release mouse;
  F1 = player HUD toggle, F2 = teammate HUD toggle.
- Rifle head/body/leg damage is 160/40/34. Preserve it and all bot/flash/jump behavior.
- AI uses delayed beliefs and local interpretation plus deterministic planning.
  HUD/damage attribution may use privileged physical results, but must never feed
  victim identities, hidden transforms or truth events into bot policy/model inputs.

## Ownership and integration seams

Own a new component such as `ui/combat_feedback.gd` and any associated UI resources,
plus dedicated tests such as `tests/person2/combat_ui_smoke.gd`. Prefer keeping
layout, animation and state presentation in that component.

Allowed integration edits are narrow hunks in:

- `scenes/bots/lotus_playtest.gd`: HUD setup, existing victory/result presentation,
  enemy spawn/death bindings, status refresh and round reset.
- `scenes/bots/first_person.gd`: player HUD node registration if needed for F1.
- `weapons/weapon.gd` and shared damage components only as needed for a small,
  backwards-compatible player kill attribution seam. Preserve existing callers.
- `validation/run_person2_tests.py`: narrowly copy/register new UI files/tests in
  the temporary project if needed. Verify the actual voice launcher copies them
  too; repository-only changes can otherwise appear to work but never reach play.

The primary instance retains navigation, motion, bots/policies, perception, map,
scenario data, voice/model pipeline, existing site_smoke.gd and broad launcher
changes. Do not reformat shared files or edit these areas. If a larger overlap
becomes necessary, report the concrete dependency for coordination before expanding
scope. Keep small integration hunks easy to review/cherry-pick.

Do not rewrite the primary `docs/PERSON2_HANDOFF.md` while it is being maintained
in parallel. Record your final implementation, interfaces, results and limitations
in `docs/COMBAT_UI_IMPLEMENTATION.md`; the integrator will reconcile current docs.

## Code landmarks and known traps

- Scene inheritance: `site_playtest.gd` -> `lotus_playtest.gd` ->
  `voice_playtest.gd` -> `first_person.gd` -> `scenes/main.gd`.
  The inherited Lotus filename is still on the active site path.
- `lotus_playtest.gd::_build_victory_screen`, `_show_victory` and
  `_update_round_label` own the existing result UI. Currently the overlay appears
  only for `enemies_eliminated`, although `detonated` is also a win in the label.
  `_materialize` registers late enemies; `_restart` rebuilds the round.
- `first_person.gd::_on_player_died` deliberately leaves the round running if the
  teammate lives. `_on_teammate_died` resolves team elimination. `_player_ui_nodes`
  controls F1; impairment overlays/crosshair deliberately stay visible.
- `actors/health.gd` exposes `hp`, `max_hp`, `is_dead`, `damaged(amount, remaining)`
  and `died`. **reset() emits neither signal**, so signal-only health UI will stay
  stale unless explicitly refreshed/rebound on reset. Actors may be replaced.
- `ActorBase.died` / `Health.died` do not identify a killer. Weapon.fire receives
  shooter, but `_apply_hit_damage` currently forwards only damage to the actor.
  The generic fired signal gives endpoints/hit boolean, not victim or killer.
  Do not interpret every enemy.died as a player kill or infer ownership from timing.
  Inspect utility ownership too; provide truthful attribution for supported player
  damage paths and document any remaining limitation rather than silently guessing.
- `recording/game_events.gd` is a privileged recorder, owned with shared contracts.
  Do not repurpose it as an unrestricted policy input or broadly change its schema.
- A local shared-component edit is ineffective if the temporary-project builder
  continues to use the pinned source copy. Audit the copy/overlay paths for every
  modified/new runtime dependency; avoid replacing the source snapshot wholesale.
- Godot 4 Label3D uses outline_modulate, not outline_color. cast_shadow belongs to
  GeometryInstance3D, not StandardMaterial3D. Avoid inherited member-name collisions.

## Verification and completion

Use installed tools and the exact existing runner behavior from the current main
handoff. Starting commands from your worktree:

```powershell
$pythonExe = "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
$godotExe = "$env:USERPROFILE\.cache\callout-godot-4.4.1\Godot_v4.4.1-stable_win64_console.exe"
& $pythonExe tools/check_repo.py
git diff --check
& $pythonExe validation/run_person2_tests.py --godot $godotExe --person1-ref 0260f28 --person3-ref 57f809d
& $pythonExe validation/run_person2_tests.py --godot $godotExe --site-smoke --person3-ref 57f809d
.\validation\run_voice_game.ps1
```

Baseline evidence is 575 required bot assertions and 46 headless site checks, not
the obsolete 183 total. Keep strict engine-error checks and timeouts. Godot can
fail to access the Windows certificate store inside the sandbox; use the permitted
execution mechanism rather than hiding that error. Avoid running two microphone
hosts or competing localhost voice services while the main instance playtests.

Add meaningful automated checks for player/teammate kill attribution, duplicate and
stale deaths, count reset, health damage/reset/max HP, defeat versus surviving ally,
both win reasons and restart cleanup. Use a dedicated test rather than editing the
primary site's large regression file. Validate actual integration-scene wiring,
not just a standalone UI mock. Inspect a rendered capture for layout and feedback;
report rendered/headless results separately from human voice acceptance.

Deliver all three features, local commit(s), a clean scoped diff and your component
handoff with exact commands/results and any limits. Leave merging and pushing to
the integrator/user. Do not claim human playtest or exported-build acceptance that
was not performed.
