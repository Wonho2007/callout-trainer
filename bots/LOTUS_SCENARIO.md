# Plant-start scenario with first-known enemy arrivals

```powershell
.\validation\run_voice_game.ps1 -Lotus
```

The scenario starts **when the spike is planted**. The player is the Something/Yoru
role in Heaven; the comms teammate is the f0rsakeN/Omen role in Pit. Coordinates,
cover, ramps and scale are authored approximations using the seven annotation
callouts, not a verified Lotus reconstruction. Red actors are FNC; blue is the ally.
Hold Right Ctrl for spoken comms. F returns to a freshly planted spike. The earlier
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

## Adapted behavior and current limits

- Shared CharacterBody movement and rifle/damage execute ordinary physics. Retaker
  goals use authored static destinations. A retaker receiving its own delayed sight
  of a threat in Heaven can take an authored A-Link flank for three seconds; its
  decision cites that delivered evidence. This is an alternative, not observed pro play.
- PRX defends the plant. The player cannot defuse their own spike. Retakers can use
  the shared defuse interaction when their allowed plan reaches Pit and they are
  not engaged in combat. Elimination, defuse and detonation resolve the round;
  source kills and the recorded result are not scripted as outcomes.
- Source HP/armor are approximated as one shared health pool (150 for 100+50,
  teammate 70). This is not an armor-system replica. All use the existing placeholder
  rifle. Exact utility/cooldown reenactment and the ally's full annotated movement
  line remain unfinished. The source scenario marks reference beats explicitly;
  it never automates the human role.
- The default remains LLM interpretation with the deterministic goal planner after
  the [measured goal spike](VOICE_GAME.md). Seven names are used directly; Heaven
  is no longer an alias for the old room. The existing belief implementation and
  coordinated trust-field/full-acceptance integration remain a dependency.
- Source notes are Person 3 `b84cc93`,
  `annotations/fnc_prx_lotus_toronto2024_gf.md`. The legacy scenario identifier is
  preserved; title/channel/event/year and named annotator/team review are still
  unverified. A video lookup did not resolve metadata. Do not pitch those labels
  or source-derived positions as independently verified here.

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

Actual final Godot 4.4.1 result: **31 functional scene checks pass**, including public
elimination/HUD shutdown and restoration of source-derived health after a guarded
weapon fixture. The earlier actual-renderer run passed 28 functional checks plus
one PNG save and its layout was inspected. Checks include no guessed actors at plant,
exact +23s arrivals, no spawn testimony, real Pit-to-Heaven traversal/completion,
shared retaker rifle firing after perception, reactive evidence guards and reset.
The fixture fast-forwards its **authoring clock** to exercise +23s; normal play waits
23 real seconds. It does not simulate 23 seconds of human gameplay. Actual rendered
frame inspected; this is not a human playtest.

Person 3's unchanged Draft 2020-12 scenario validator passes the new scenario with
expected unknown-field warnings. Own consistency checks bind first-known beats to
runtime arrivals and unique region bounds; malformed earlier Boaster, duplicate
arrival, guessed start and wrong-coordinate cases fail. Seven Python tests pass
(three authoring + four voice boundary). Existing 552 owned/cross-lane assertions
and 139 live-perception checks also pass on this continuation. Known navigation
bake readback warning remains. No export, backup video, new spoken-game acceptance
or full-game/model fairness pass is claimed.
