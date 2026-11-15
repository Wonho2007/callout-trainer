# First-person action playtest

This developer harness runs the **current first-person map**, shared player and
teammate mechanics, existing sensory/HUD integration, and bot executor. It is an
inherited scene, not a replacement map or the older overhead demo. Normal
`--first-person` remains unchanged. Voice/LLM are not connected by this harness;
its inputs are explicitly synthetic developer fixtures.
This developer scene turns the player's starting view 180 degrees from the
shared static spawn orientation so the blue teammate/corridor are in view.
The player position, shared camera, controls and map are unchanged; reset
reapplies that developer view orientation.

Close an old game window, then run in a normal PowerShell terminal:

```powershell
cd C:\Users\Isoto\Documents\GitHub\callout-trainer
$pythonExe = 'C:\Users\Isoto\AppData\Local\Python\pythoncore-3.14-64\python.exe'
$godotExe = 'C:\Users\Isoto\Downloads\callout-godot-4.4.1\Godot_v4.4.1-stable_win64_console.exe'
& $pythonExe validation/run_person2_tests.py --godot $godotExe --action-playtest
```

The lower-right developer panel accepts number keys while playing, or buttons
after Esc releases the mouse. WASD/mouse remain first-person controls; F resets
the round, and R reloads. Existing F6/F7/arrow/P/F8 enemy/perception tools remain
the other session's controls. No microphone input or language parser runs here.

| Key | Injected test | Expected behavior |
|---|---|---|
| 1 | Enemy report: room | Delivered after 18 ticks, then updates working knowledge; no forced push command |
| 2 | Hold home | Validated authored goal moves back to corridor and watches entry |
| 3 | Cover room | Validated authored goal navigates through hallway to cover and watches room |
| 4 | Swing now | Stages first, then runs the authored route; completion requires physical arrival |
| 5 | Prepare swing on cue | Stages, reports ready, waits |
| 6 | Go cue | References the copied active command; early cues can return not_ready |
| 7 | Follow player | Stages, then waits for actual delayed permitted player-entry perception |
| 8 | Prepare flash on cue | Routes to authored launch marker and waits; 6 releases one shared flash |
| 9 | Cancel | Cancels an active interruptible command after delivery delay |
| 0 | Repeat last comm ID | Resends the identical envelope, testing deduplication; no second action |
| - | Invalid goal / fallback | Submits malformed synthetic model output and displays the deterministic fallback |

Start with **3**, watch the blue teammate navigate and stop at coverage; use **2**
to return home. These static goal fixtures cite no enemy evidence: they use
authored destinations and own reachability in a copied context. While selected,
the harness renews them only from each new copied context. This allows travel
longer than the real 120-tick context lease without extending/altering that gate.
Another comm stops renewal; the previous goal may remain valid until its context
expires. **-** immediately tests invalid-output fallback. Commands always take
priority over these autonomous fixtures.

Then press **5**, wait for **ready**, and press **6**. Watch lifecycle results,
decision reason/evidence, and physical status separately. The small lifecycle
trail shows the last three results with request suffixes; a cue's `completed`
acknowledgment is distinct from the swing command's later physical completion.
**0** must not replay the completed route. Repeat **5**, then **9** while staging
or ready to test cancellation. Cancellation stops that command; normal coverage
can resume on a later tick.

For a real throw, press **8**, wait for ready, then **6**. Inventory should fall
from one to zero only on actual shared projectile release. **0** cannot repeat
the throw; **8** again should eventually return `rejected/no_utility`. Completion
means launch, not that a target was blinded. F starts a new round and replenishes
the synthetic scenario charge. The panel reconnects to the new runtime and
clears old replay messages/goals/history. The normal 45-second round timer still
runs, so reset between experiments.

For **7**, wait for ready and physically move into the entry while in teammate
view. No synthetic entry observation is injected. Actual FOV/LOS/smoke/blind and
delay checks govern release. The perception session owns that producer/wiring;
this harness does not claim its live acceptance from action tests. If blocked,
the command should wait/expire rather than use a hidden player transform. You
can still test the explicit **5 → 6** path independently.

The panel receives only copied contexts, results, decisions and snapshots. It
never reads an opponent, player-only minimap/scan, private archive or sensor.
Its synthetic goals appear as `local_model` inside the unchanged runtime seam;
the developer panel explicitly labels them **synthetic intent fixture**. They
are not real model decisions or actual prompt/output logging.

## Automated check and current environment limitation

```powershell
& $pythonExe validation/run_person2_tests.py --godot $godotExe --action-smoke
```

On official Godot `4.4.1.stable.official.49a5bc7b6`, the strict runner currently
exits 1 during temporary import with `Failed to read the root certificate store`
in this session's sandbox. Its error handling is intact. A separate diagnostic
run of that prepared inherited scene reached **32 functional action assertions
plus one PNG save without assertion failures** (33 in rendered mode), including
real movement, staged cue/swing completion,
cancellation, flash release/depletion/duplicates, invalid-output fallback,
reset/rebinding, and key/button callbacks. It still emitted the certificate
error, so it is **not a clean Godot/full-suite pass**. The known shared runtime
navigation-bake mesh-readback warning remains. The actual rendered PNG was
inspected: controls are inside the viewport and beside the existing information
HUD; explicit assertions enforce both. No sensor was patched for tests.

The first diagnostic fixture used a short staging sleep and failed five checks
when ordinary fallback movement made the stage farther away; the fixture now
waits for actual ready status with a deadline. No bot mechanism was changed to
make it pass. Render inspection also caught and corrected an offscreen initial
panel placement before the two layout assertions were added. No human gameplay
input, real voice/model or export playtest is
claimed. Record tester, build, keys, observed motion/status and failures when
performing the manual sequence above.

The other session approved the runner's exact new modes/copy/main-scene changes
through the user, and explicitly allowed preserving/committing its existing
`PERSON2_SHARED_OVERLAY` block. That block copies local shared player/blind-wave
scripts for its approved wave fix. Those source files and the concurrent
sensor/scene/scenario/HUD changes stay uncommitted by this action task. The
launcher continues to print frozen dependency revisions and overlay provenance.
