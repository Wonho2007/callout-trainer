# Plant-start scenario with first-known enemy arrivals

The current default uses the imported teammate map; see [current site guide](SITE_SCENARIO.md).
This document describes shared baseline rules and the retained legacy custom map.
Use `-LegacyLotus` to launch that old geometry explicitly.

```powershell
.\validation\run_voice_game.ps1 -LegacyLotus
```

The scenario starts **when the spike is planted**. The player is the Something/Yoru
role in Heaven; the comms teammate is the f0rsakeN/Omen role in Pit. Coordinates,
cover, ramps and scale are authored approximations using the seven annotation
callouts, not a verified Lotus reconstruction. Red actors are FNC; blue is the ally.
Hold V for spoken comms; B dashes (V no longer also triggers dash). F returns to a freshly planted spike. The earlier
three-region demo remains available by omitting `-Lotus`.
Close an earlier voice-host console before launching another microphone session.

## Your requested spawning rule

Unknown enemies have **no actor, collider, weapon or sensory presence at plant**.
They materialize only when the annotation first supplies a known position:

| Scenario time | Actor | First known region |
|---|---|---|
| +23s / tick 1380 | Chronicle | b_heaven |
| +23s / tick 1380 | crashies | b_heaven |
| +23s / tick 1380 | kaajak | c_link |
| +23s / tick 1380 | Boaster | b_main |

Boaster's +16s smoke identifies an effect location, **not his position**, and cannot
cause early spawning. His first localized beat is his recorded death at +23s; he
is spawned alive at that location as an explicit continuation adaptation. The
recorded kill is never forced. All exact within-region spawn coordinates are
authored placement, not VOD-derived coordinates. The structural scenario retains
`start_region: "unknown"` for all four FNC actors.

Registration adds a real actor only to the privileged sensor registry. It sends no
enemy report or automatic belief update. Existing pending observations survive;
exposure, LOS, smoke, blindness and reaction delay still govern discovery. Restart
clears all spawned actors/runtimes and returns to the plant with unknown enemies absent.
Four uniform belief slots are a static scenario prior, not hidden positions.

## Annotated baseline and deviations

The source timeline in `scenarios/fnc_prx_lotus_toronto2024_gf.json` now drives the
bot baseline. `bots/annotation_policy.gd` selects authored goals; the existing
motion controller walks actual navigation paths. Beats request movement at their
annotated times; arrival is physical, not a teleport or a frame-exact VOD replay.

- Ally holds Pit, heads to Cubby at +2s, smokes C Link after staging, uses its
  initially recharging smoke on Main at +19s, heads to Main at +23s and returns
  to Cubby at +26s. Initial smoke readiness is 0/+18s; used charges recharge in 30s.
- Boaster's +16s right-Main smoke is an authored remote effect. It creates no
  caster actor or sighting. His +23s alive continuation holds Main.
- Chronicle holds Heaven, then heads toward Upper at +30s. crashies holds Heaven
  and throws a private recon orb there at +23s. kaajak holds C Link and throws
  the shared area-damage projectile toward Pit at +28s. Recon/grenade are generic
  approximations of the annotated Eye/grenade, with real projectile collision.
- Utility releases require staging, a living/unblinded caster, no active combat
  or player command, and available inventory. A beat waits at most two seconds
  for physical readiness; missed or interrupted throws are not replayed later.
  Smoke side offsets, aim points, projectile arcs and effect stats are authored.
- A valid delivered player report or accepted command ends the ally's baseline
  for that round and returns control to its existing belief/command planner.
  Own damage or a delivered sighting of an opponent outside its annotated region
  (with a two-second transition tolerance) also ends that bot's baseline.
  Enemies receive no player comms or live player transforms: only their own
  delayed observations and allowed own-state can trigger their reactive retake.
- Reactive retakers use the existing static retake goals. Their own fresh delivered
  Heaven sight can trigger the three-second A-Link flank. Baseline combat still
  interrupts travel when a real contact is acquired. No source kill is forced.
- Enemy recon creates only delayed bot-local region testimony after range, wall
  and smoke checks. It never creates exact rifle aim or player HUD/recon marks.
- Both player and bots use the shared 40-body / 160-head rifle. Current flash
  blindness blocks fire in both policy and the physical combat adapter. A white,
  depth-tested circle appears above a flashed enemy's head until blindness ends.
- Dead bots disappear, stop processing movement, and lose collision. Their dead
  records remain internally for elimination and reset. Dead enemies are removed
  from the player minimap/scan list. Restart removes old utility and revives the ally.

PRX defends the plant and cannot self-defuse it. Retakers reaching Pit on a reactive
plan can defuse when not engaged. The final annotated positions remain baseline
holds after +30s; there is no invented forced round ending. Health/armor are one
simplified pool (150 player/enemies, 70 ally). Exact agent kits, continuous source
trajectories, source kills/results and full cooldown/kit behavior are not replicated.

Source notes are Person 3 `b84cc93`,
`annotations/fnc_prx_lotus_toronto2024_gf.md`. Title/channel/event/year and named
annotator/team review remain unverified. These are source-note adaptations, not
independently verified pro facts. The pinned belief/full-report-acceptance gap
and experimental model-goal limitations remain unchanged.

## Geometry and validation

The existing builder is extended only by `world/lotus_builder.gd`; the default map
and shared builder are unchanged. Generated ramp/pit triangles have matching
collision. The hidden pit safety-cap visual is retained outside the navigation
source subtree so it does not create a second overlapping nav surface. Authored
ramp side walls stop pathfinding from choosing a ledge the shared actor cannot
step onto. Paths must start and end near the actual anchors; distant nav snapping
does not count as reachability.

```powershell
$pythonExe = "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
$voicePython = "$env:USERPROFILE\.cache\callout-voice-venv\Scripts\python.exe"
$godotExe = "$env:USERPROFILE\.cache\callout-godot-4.4.1\Godot_v4.4.1-stable_win64_console.exe"
& $pythonExe validation/check_lotus.py
& $voicePython -m pytest tests/person2/test_lotus_authoring.py tests/person2/test_voice_host.py -q
& $pythonExe validation/run_person2_tests.py --godot $godotExe --lotus-smoke --person1-ref 8712f7d --person3-ref 57f809d
# Optional real-renderer capture:
& $pythonExe validation/run_person2_tests.py --godot $godotExe --lotus-smoke --person1-ref 8712f7d --person3-ref 57f809d --lotus-capture "$env:TEMP\callout-lotus.png"
```

Current checks use Godot 4.4.1, shared source `8712f7d` with local mechanics
overlays, and belief `57f809d`. The latest baseline/flash/death continuation passed
575 default/cross-lane assertions (including 21 annotation and 46 combat checks),
139 live-perception checks, and seven Python tests. The final Lotus scene passes 53 checks (headless). Tests exercise physical smoke deployment, private
recon, grenade ignition/landing in Pit, wall/smoke recon guards, actual flash duration
with no enemy shots, indicator expiry, death/collision removal and restart.

A rendered 46-check run saved and inspected a visible white head circle. That run
preceded the extra recon/grenade boundary checks. The fixture fast-forwards the
public scenario clock, not human gameplay; normal play waits for real time. The
navigation-bake warning and an ObjectDB-at-exit warning remain in the scene fixture.
Sandboxed Godot startup cannot read Windows' certificate store; approved execution
outside the sandbox passed without weakening error detection. No human spoken-game,
export, backup-video or full-game/model-fairness acceptance is claimed.
