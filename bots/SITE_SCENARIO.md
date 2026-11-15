# Current seven-zone B site scenario

```powershell
.\validation\run_voice_game.ps1
```

The default voice game now uses Person 3's `world/maps/b_site.json` from
`person-3/greybox-b-site` at `76b8eaa`. Main was fetched but remained at `8712f7d`;
the new map was on that teammate branch, which was merged into the working branch
at `513b2e9`. Existing local bot/voice/damage changes were checkpointed at `86a54aa`
before the merge. Nothing was merged into main.

The 40 walls, flat floor, and seven source zone definitions are reused unchanged.
The minimap shows C Link, Heaven, Upper, circular Pit, A Link, Cubby and Main.
This replaces the earlier custom Lotus geometry in the default game. Source scale,
within-zone actor placements and utility trajectories remain authored greybox data,
not verified professional metric coordinates.

`world/site_builder.gd` changes only runtime scenario metadata: human starts in
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

Actual Godot 4.4.1 results: 23 functional checks pass; rendered run passes 24
including capture save, and the capture was inspected. Checks cover source geometry
preservation, circular/overlap region queries, real navigation, physical ally smoke,
plant/arrival positions, flash/no-fire/head-circle expiry, death and reset. Fixture
clock fast-forward is not a real-time human playthrough. Existing navigation-bake
and ObjectDB-at-exit warnings remain; strict script/engine ERROR checks pass.
The required bot suite also passes 575 assertions with shared source `76b8eaa`
and belief `57f809d`; seven Python authoring/voice tests and launcher syntax pass.
No new human microphone-to-game or export acceptance is claimed.
