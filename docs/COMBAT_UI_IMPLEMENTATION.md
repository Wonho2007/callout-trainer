# Combat feedback UI integration handoff

Implemented 2026-11-15 on `person-2/combat-feedback-ui`, in the sibling worktree
`C:\Users\Isoto\Documents\GitHub\callout-trainer-combat-ui`, based on local
`b0b8d0d` (includes gameplay/navigation checkpoint `019230e`). The original checkout
was left on its integration branch. No merge, remote fetch, push, stash, reset or
cleanup of another worker's files was performed.

## Behavior

- Player rifle and molly enemy kills show a 0.95-second native UI confirmation and
  increment a persistent per-round count. Only an alive-to-dead physical damage
  transition emits attribution. The scene checks shooter/thrower, current enemy
  membership, death state and round serial; the component deduplicates victim IDs.
  Friendly fire, teammate kills, unattributed deaths and dead-actor damage do not
  increment it. Restart cancels the tween immediately and clears the count.
- A single result overlay presents defeat for spike defuse or both friendly actors
  dying, and victory for enemy elimination or spike detonation. It gives the reason
  and F-to-restart instruction and releases the mouse. It remains visible with F1
  disabled. Player death while the ally survives keeps the existing active round
  and voice-report behavior. Outcome rules and physical death cleanup are unchanged.
- Bottom-right health panel shows actual current/max HP and a bar, plus the kill
  count. It polls the bound Health component because reset emits no signal, and
  rebinds on round initialization. Max HP is not fixed at 150. F1 toggles the panel
  and confirmation together; F2 and impairment overlays retain their existing paths.

## Files and interfaces

| File | Integration effect |
|---|---|
| `ui/combat_feedback.gd` | Owns health/count layout, kill tween, deduplication and the single victory/defeat overlay |
| `scenes/bots/lotus_playtest.gd` | Creates component, binds damage attribution per round, forwards outcome, clears/rebinds on restart; dedicated smoke entry point |
| `scenes/bots/first_person.gd` | Adds `CombatFeedback` to existing F1 node list only |
| `weapons/weapon.gd` | Adds privileged `kill_confirmed(victim, shooter)` after lethal damage; optional third shooter argument preserves two-argument `_apply_hit_damage` callers |
| `utility/molly.gd` | Adds privileged `kill_confirmed(victim)` after a lethal area-damage tick |
| `utility/utility_system.gd` | Forwards molly confirmation with existing thrower ID as `kill_confirmed(victim, thrower_id)` |
| `validation/run_person2_tests.py` | Copies new UI/test and local molly overlay; adds dedicated smoke/capture mode using actual site scene and existing strict checks/timeouts; forwards optional shot diagnostics |
| `validation/run_voice_game.ps1` | Optional `-CombatDebug` forwards the diagnostic flag to the game runner |
| `tests/person2/combat_ui_smoke.gd` | Dedicated scene integration checks; leaves `site_smoke.gd` untouched |

These signals are presentation-facing physical results, not bot observations or
model/policy inputs. No recorder schema or belief/perception interfaces changed.
No damage values, navigation, bot policy, arrival schedule or map data changed.
The small molly damage seam is necessary to count the player's existing area-damage
path truthfully; other utility does not apply lethal actor damage.

`validation/run_voice_game.ps1` selects `--site-playtest` through the same runner.
The new component and modified molly are copied by that shared preparation path,
alongside the already overlaid weapon and utility system. Thus the pinned `0260f28`
snapshot does not mask these changes. The voice launcher's normal behavior is unchanged.

## Verification and limitations

Tools: installed Python 3.12 and Godot 4.4.1 stable; shared source `0260f28`, belief
`57f809d`. Repository documentation checker and `git diff --check` pass.

**Strict Godot acceptance is pending outside this session's sandbox.** The normal
runner stops at `ERROR: Failed to read the root certificate store.` during import.
An external execution request was rejected by this session's approval policy. A
local trusted CA bundle probe did not resolve it; no settings or certificate files
in the repository/user's Godot configuration were changed. No error filtering or
relaxed runner checks were committed.

For diagnosis, a temporary external Python harness ran additional Godot processes
against the runner's actual prepared temporary projects immediately after import,
retaining all output and returning the original strict failure. These are functional
diagnostics, **not passing strict runs**:

| Diagnostic | Result |
|---|---|
| Required bot scripts, 11 suites | All 575 assertions report their pass markers; certificate error remains in each process |
| Unmodified site smoke | All 46 assertions report pass; certificate error remains |
| Dedicated UI smoke, headless with live-damage extension | All 36 assertions report pass; certificate error remains |
| Rendered UI smoke before live-damage extension | All 35 checks including 3 captures report pass; certificate error remains |

Dedicated checks cover real hitscan and overlapping molly damage, owner filtering,
duplicate/stale death rejection, friendly fire exclusion, count/tween reset,
damage/max HP/silent health reset, F1/F2, both orders of friendly elimination, a
surviving ally/player, actual spike defuse/detonation, elimination victory, mouse
release and restart cleanup. Inputs and scenario timing are synthetic.

Inspected 1280x720 rendered captures in `%TEMP%`: `combat-ui-kill.png`,
`combat-ui-defeat.png`, `combat-ui-victory.png`. The health/count panel is clear of
the teammate panel, minimap, ammo/status and aiming area; kill text appears below
center; result reason and restart prompt are readable. The existing canvas stretch
scales the layout with the window. Other window sizes and human aiming/voice feel
still need human acceptance. Captures/logs are temporary, not committed assets.

Full diagnostic logs remain in `%TEMP%`: `combat-ui-required.log`,
`combat-ui-site-smoke.log`, `combat-ui-combat-ui-smoke.log` and
`combat-ui-combat-ui-smoke-render.log`. The temporary harness is
`callout-combat-ui-diagnostic.py`; it is not part of the patch or acceptance runner.
No microphone host was started, and no human voice, exported-build or offline
acceptance is claimed.

## Follow-up: reported inability to take/deal damage

The user reported firing/tracers with no apparent damage in the UI worktree, with
no intervening smoke, before trying a restart. The game log had no script errors.
This report has **not yet been reproduced or claimed fixed**. Diagnostic scene
probes at authored Heaven positions measured real camera shots taking Chronicle
from 150 to 110 to 0 HP, and a bot-rifle shot taking the player from 150 to 110 HP.
A second probe enabled live bot perception/combat and normal player physics: bots
killed the player within 180 physics ticks; after restart, held-fire input from the
actual camera killed the authored enemy. The committed dedicated test now covers
these live incoming/outgoing paths and health/count updates (four extra checks).

Optional `-CombatDebug` on the voice launcher enables `--combat-damage-debug` on the
game. The shared rifle logs `COMBAT_SHOT` with shooter, collider path, impact and
smoke-block status, plus `COMBAT_DAMAGE` with victim, hit part, damage and HP before/
after. Misses log `collider=none`. Logs stay in the existing ignored run directory;
no additional data enters bot policy, models or the recorder schema. Damage values,
spread, smoke behavior and combat rules were deliberately left unchanged without
a reproduction identifying the failure. The next failing run's `game.log` is needed
to identify the actual hit blocker rather than guessing from visible tracers.

## Integration and strict rerun

Review/cherry-pick the local branch's implementation commit onto the current local
`person-2/model-capability-spike` when ready. At final inspection that original
checkout had independently advanced to `a60e09b` (persistent player-order positioning).
Do not replace current navigation work
with this worktree's older base. Potential overlaps are the narrow Lotus HUD/reset
hunks, F1 node list, shared damage scripts and runner copy lists. Bring both the
molly script and its utility forwarding/runner overlay together. The integrator
should reconcile the current Person 2 handoff; it was deliberately not rewritten.

From this worktree in a normal PowerShell window (each invocation is one line):

```powershell
$pythonExe = "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
$godotExe = "$env:USERPROFILE\.cache\callout-godot-4.4.1\Godot_v4.4.1-stable_win64_console.exe"
& $pythonExe tools/check_repo.py
git diff --check
& $pythonExe validation/run_person2_tests.py --godot $godotExe --combat-ui-smoke --person3-ref 57f809d
& $pythonExe validation/run_person2_tests.py --godot $godotExe --person1-ref 0260f28 --person3-ref 57f809d
& $pythonExe validation/run_person2_tests.py --godot $godotExe --site-smoke --person3-ref 57f809d
& $pythonExe validation/run_person2_tests.py --godot $godotExe --combat-ui-smoke --person3-ref 57f809d --combat-ui-capture "$env:TEMP\combat-ui-final"
```

After strict reruns, coordinate a human voice playtest using the existing
`validation/run_voice_game.ps1`; avoid competing microphone hosts.
