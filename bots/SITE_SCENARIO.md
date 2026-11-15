# Current seven-zone B site scenario

**Resolved (Kiro):** the live far-zone flash failure is fixed. "Flash B heaven" issued
while the teammate stood at Cubby used to fail with `execution_failed` without moving,
because every B Heaven aim point was occluded or beyond 20 m from there. A far-but-
reachable zone now walks into range and throws. A fresh human microphone playthrough
of the fix is still unconfirmed. See the [current handoff](../docs/PERSON2_HANDOFF.md).

```powershell
.\validation\run_voice_game.ps1
```

The default voice game now uses Person 3's `world/maps/b_site.json` from
`person-3/greybox-b-site` at `0260f28`. Main was fetched but remained at `8712f7d`;
the new map was on that teammate branch, which was merged into the working branch
at `513b2e9`. Existing local bot/voice/damage changes were checkpointed at `86a54aa`
before the merge. Nothing was merged into main.

The updated source walls, cover, platforms and CSG Pit are reused. Scenario-only
adaptations add one narrow ramp up to Upper and extend Pit's region volume down
to its -3m floor. Horizontal zone footprints and the source JSON remain unchanged.
The minimap shows C Link, Heaven, Upper, circular Pit, A Link, Cubby and Main.
This replaces the earlier custom Lotus geometry in the default game. Source scale,
within-zone actor placements and utility trajectories remain authored greybox data,
not verified professional metric coordinates.

`world/site_builder.gd` adapts runtime metadata, the access ramp and navigation bake: human starts in
Heaven, spike/ally start in Pit, unknown enemy spawn markers are removed, and
list-order region precedence is enabled. The source map's authoring/debug player
and spike positions are retained in the JSON but are not the plant scenario starts.
`scenarios/site_coverage.json` maps every bot marker, watch point and +23s arrival
onto the new zones. Navigation is checked from Pit to all seven anchors.

Pit uses the actual circle radius, not its enclosing rectangle. Upper wins the
intentional Upper/Pit overlap, matching the imported HUD and minimap. The legacy
maps retain their conservative unknown-region handling for ambiguous overlaps.

The [annotated baseline and reaction rules](LOTUS_SCENARIO.md) remain in use.
The larger map gets a four-second physical staging allowance for a utility beat;
this is not model-context expiry and does not extend message/model validity.
Movement and projectile collision still resolve physically. Exact source arrival
times and agent kits are not replicated. Enemy arrival time remains +23s; no
source deaths or outcome are forced. Boaster's earlier smoke does not spawn him.

The teammate now has **one player-commanded flash per round** as a user-requested
prototype extension to the recorded Omen kit. ?Flash C Link? turns toward C Link,
checks authored static points in that zone against world geometry and active smoke,
and throws from the current location if a point is visible within 20m. A visible
part of the region is enough; its center need not be visible. When it cannot yet
throw ? the zone is occluded, or every visible point is out of range from the current
spot ? it walks toward the zone's static fallback marker. Visibility and range are
rechecked every tick; the bot stops seeking and throws as soon as a point becomes
visible within range, and fails honestly only when navigation cannot get any closer.

?Flash C Link on my cue? prepares the same way and waits for ?go?. Cancel remains
available while turning or seeking visibility; a charge is spent only on projectile
release. All seven regions have flash targets. The bridge preserves explicit flash
speech as `throw_flash` even if a model incorrectly proposes a swing. The existing
`comms.v1` actions/schema are unchanged; visibility staging is an internal catalog
capability. No enemy positions or nodes enter these physical checks.

There is **no player-issued molly command**. The baseline Raze grenade uses the
shared molly primitive, but that does not create a teammate voice command.

Spawn heights follow the updated map: Pit -2.9m, Heaven/Upper 2.1m, A Link 0.6m.
Navigation parses synchronized static collision so the CSG pit participates.
The shared flash fuse is 0.75s and configured blind durations are 3-5s; player and
bot throws use the active fuse. Legacy profiles retain their snapshot definitions.

Controls: V talks, B dashes, F restarts, Esc releases the mouse. Rifle damage is
40 body / 160 head for everyone. Flashed enemies cannot shoot and show a white
head circle. Dead bots disappear and lose collision; restart clears old utility.

`-Lotus` is retained as a compatibility alias for the new default. Explicit
`-LegacyLotus` selects the previous custom map, and `-LegacyRoom` selects the old
three-zone integration snapshot. Running root `project.godot` is still the map
authoring scaffold, not the integrated voice game.

## Checks

```powershell
$pythonExe = "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
$godotExe = "$env:USERPROFILE\.cache\callout-godot-4.4.1\Godot_v4.4.1-stable_win64_console.exe"
& $pythonExe validation/run_person2_tests.py --godot $godotExe --site-smoke --person3-ref 57f809d
# Optional rendered capture:
& $pythonExe validation/run_person2_tests.py --godot $godotExe --site-smoke --site-capture "$env:TEMP\callout-new-site.png" --person3-ref 57f809d
```

Earlier flat-map Godot 4.4.1 results: **40 functional checks pass** after the far-zone flash
fix (36 before, +4 from the new far-zone regression). An earlier 24-check rendered
map run was inspected; it preceded the new flash command checks. Checks cover source
geometry
preservation, circular/overlap region queries, real navigation, physical ally smoke,
plant/arrival positions, flash/no-fire/head-circle expiry, death and reset. Fixture
clock fast-forward is not a real-time human playthrough. Existing navigation-bake
and ObjectDB-at-exit warnings remain; strict script/engine ERROR checks pass.
Flash cases cover no-walk visible throws, turning before occlusion-based movement,
a far-but-reachable zone walking into range before throwing, release before entering
the target zone, inventory depletion, cancel without charge loss, and on-cue release. A real local Llama typed interpretation of "flash c link"
returned `throw_flash/c_link/now` (not microphone acceptance).
The required bot suite also passes 575 assertions with shared source `76b8eaa`
and belief `57f809d`; seven Python authoring/voice tests and launcher syntax pass.
No new human microphone-to-game or export acceptance is claimed.

Updated elevated-map adaptation: 41-check rendered run passed and capture inspected.
Final headless run passes **42 checks**, including native indicator duration and
child-hitbox cleanup. Existing 575 required bot checks passed on source 0260f28.
No human voice acceptance is inferred from these checks.
