# First-person teammate integration

**Original three-region module reference.** Current project/ownership/status is in
[the single handoff](../docs/PERSON2_HANDOFF.md). The default player profile is documented
in [LOTUS_SCENARIO.md](LOTUS_SCENARIO.md); old test snapshots and tool paths below are
historical where they differ. Do not resume an old implementation checkpoint from them.

**Current voice-enabled variant:** use [VOICE_GAME.md](VOICE_GAME.md) and
`validation/run_voice_game.ps1` for the new local microphone/LLM-to-game bridge.
It retains this three-region synthetic scene and delayed physical execution.
Its selected scope is LLM interpretation with scripted goals after measured goal
timeouts; full model-goal acceptance remains unestablished. The original plain
`--first-person` mode below intentionally has no voice host.

The user confirmed the newer [Person 2 direction](../docs/PERSON2_HANDOFF.md) and [Person 3 core handoff](../docs/PERSON3_KIRO_HANDOFF.md) as authoritative: voice-only comms, grounded local LLM teammate goals, fully accepted player comms without credibility scoring, deterministic safety fallback, grading/debrief deferred. This scene implements the Person 2 integration slice. **Person 3 has since published local STT scaffolding at `57f809d`; its target-machine results are unfilled, and the interpreter/model service and game bridge remain dependencies. Live spoken reactions are not implemented by this change.**

## What runs

[first_person.tscn](../scenes/bots/first_person.tscn) inherits Person 1's actual main scene and reuses its world, navigation, weapon/tracers, utility, spike and minimap. The shared player/wave include the user-requested passing-wave correction described below. [first_person.gd](../scenes/bots/first_person.gd) spawns the reusable [bot scene](../scenes/bots/bot.tscn) at a Person 2-authored corridor position from [the current-map coverage configuration](../scenarios/b_site_coverage.json). Person 1's map has no teammate marker; its geometry/spawn records are preserved. The blue capsule is a live `ActorBase` with shared collision/health/movement. Its [runtime](teammate_runtime.gd) validates delayed comms, applies accepted reports to Person 3's currently hedge-weighted belief module (alignment with the latest full-acceptance rule is pending in that lane), executes commands/model goals through the physical controller, and falls back to the deterministic knowledge planner. No communication menu or transcript box is shown. The HUD states that the voice service is not connected.

The owned scene uses Person 1's current synthetic `b_site.json` (`b_site_box`, including the walk-in divot at `487ad73`). The vocabulary is `room`, `entry`, `corridor`. Coverage data authors a teammate spawn/home at [-2, 0, 11.5] watching entry and a coverage marker at [-1, 0, 3] watching room. The bot navigates through the actual hallway/arch. Map ID and regions must match. Live sight/hearing/smoke/blind adapters now feed copied delayed observations; see [the sensor boundary and tests](../perception/README.md). The opponent uses Person 1's shared actor, moved by the owned test controls. Player-only scan/minimap data never enters policy. This remains a synthetic integration, with combat/scenario runtime and the voice/model host unfinished. Radio-like comm delivery (18 ticks) remains an explicit fixture assumption.

## Launch

From this checkout in PowerShell:

~~~powershell
$pythonExe = 'C:\Users\Isoto\AppData\Local\Python\pythoncore-3.14-64\python.exe'
$godotExe = 'C:\Users\Isoto\Downloads\callout-godot-4.4.1\Godot_v4.4.1-stable_win64_console.exe'
& $pythonExe validation/run_person2_tests.py --godot $godotExe --first-person
~~~

The runner makes a disposable project from the latest locally fetched `origin/main` (verified at `487ad73`), Person 3 belief files at `57f809d`, and the current Person 2 source. It copies Person 1's input settings and changes only the **temporary** entry scene. Shared main/project settings and teammate checkouts are untouched. The FPS launcher additionally overlays current local utility/blind_wave.gd and scenes/player/player.gd for the user-approved passing-wave correction, printing PERSON2_SHARED_OVERLAY explicitly; those two files require Person 1 review/adoption. The runner resolves and prints immutable source commit IDs at launch, so one run cannot mix revisions during a concurrent fetch. Use `git fetch origin` to pick up later main updates; launch itself is offline and does not fetch. Override `--person1-ref` / `--person3-ref` to reproduce a specific revision; refs must exist locally. Use official Godot 4.4.1 stable. The earlier `--visual-demo` remains an overhead developer fixture and does not meet the first-person product direction.

On this shared Windows workspace, the directory may be owned by the sandbox account. The runner uses a command-scoped `safe.directory` exception for this exact resolved checkout when reading committed files; it does not change global Git configuration. Failed reads show Git's actual stderr, with fetch guidance for missing revisions. No manual environment-variable setup is needed.

WASD moves, mouse looks, LMB fires, R reloads, Q/E use smoke/flash, F restarts, Esc releases/recaptures the mouse. Additional utility keys remain Person 1's current inputs. Close the window to exit. There is no player comm shortcut/menu: the voice host must connect to the runtime below before speech can cause movement. Do not interpret a stationary fallback teammate as proof that a microphone/LLM path exists.

## Test teammate perception in the HUD

Close an older temporary game window and rerun `--first-person` using the command above to load these changes. The **TEAMMATE INFORMATION** panel shows its action, flash inventory, own blind countdown, last delivered enemy sighting with age, recent coarse sound and accepted player comms. Last seen is memory: hiding/moving the enemy does not replace it with an unseen location. Recognition/reaction delay applies before a new sighting appears. Flashing blocks new sightings while old knowledge remains.

The red capsule labeled **TEST ENEMY** is the movable target; the blue capsule with the yellow facing marker is your teammate. Both use shared ActorBase collision/movement. The enemy label uses normal depth testing, so it does not show through walls.

The panel now distinguishes **IN SMOKE — sight blocked** (teammate's eyes inside active smoke) from **SMOKED OFF — watched angle blocked** (smoke crosses its own forward watch ray). The Vision line becomes blocked/restricted in amber. Throw Q at the floor by the teammate to test inside-smoke status, or farther ahead at the entry while the teammate remains outside to test smoked-off status. Both clear on actual smoke expiry. Falling/inactive smoke does not count. During a flash the blind countdown remains visible; a forward smoke assessment is unknown while blinded. Smoked-off describes that angle, not every direction or an entire cleared region. Existing last-seen memory remains labeled and ages instead of refreshing through smoke.

| Control | Test action |
|---|---|
| F6 | Move/revive the enemy at the entry, visible from the teammate's initial corridor position |
| F7 | Move/revive it into the room behind the initial corridor wall |
| Arrow keys | Move the enemy relative to your view, using real collision/gravity/run speed |
| P | Aim at open floor and place/revive the enemy there; walls, obstructed/off-nav ground and overlapping actors are rejected |
| F8 | Spawn a stationary shared test flash two meters ahead of the teammate; its real fuse, LOS/facing and duration determine blindness |
| Esc | Release the mouse to click the equivalent panel buttons; press again to resume mouse look |
| F | Reset the round, teammate knowledge/blind state and enemy position |

Quick manual sequence: press **F6**, wait for `Last seen: enemy in entry`, then **F7** and watch that the last-seen region remains entry while its age grows. Press **F8** and watch `Vision: BLINDED` count down to `ready`; then use F6 again to reacquire. Use arrows or aim down at floor + P for your own sightline experiments. Q/E still throw the player's normal smoke/flash. F8 is a repeatable test effect, not a teammate command, and does not consume the teammate's one command charge. If the spike ends the round or the teammate has moved away, press F to repeat from the initial setup.

These are privileged **test tools** in the owned inherited scene. Placement changes world state only; it does not submit a report, force perception or update beliefs. The HUD receives only the runtime's copied delivered snapshot and own blindness. No pending samples, hidden target pose, live visibility query or player-only recon data enters its knowledge display or policy.

If the teammate dies while the player survives, the panel says **teammate down** and marks vision inactive. Last-seen information remains aged memory. This uses existing copied physical status; it does not infer an enemy kill or end the surviving player's round. Restart restores normal live status.

Automated controls/HUD check:

~~~powershell
& $pythonExe validation/run_person2_tests.py --godot $godotExe --hud-smoke
# Optional actual-renderer PNG (opens a temporary game window):
& $pythonExe validation/run_person2_tests.py --godot $godotExe --hud-smoke --hud-capture "$env:TEMP\callout-teammate-hud.png"
~~~

This tests the real controls, delayed HUD updates, stale memory after hidden movement, invalid placement, arrow movement/release, shared flash blindness/recovery, button callbacks and reset. A rendered PNG is automated rendering evidence; human game feel/input/playtesting remains separate.

## Sight recovery, waves and player-entry delivery

Current sighting recovery: physically visible enemies in unnamed/overlapping map regions are no longer discarded. The HUD says `unknown region`; it never guesses a region or exposes a live coordinate. Actual smoke still blocks every covered sight sample, and reacquisition retains exposure/reaction delay. If the 45-second spike round has ended, the panel now explicitly says perception is inactive and to press F to reset; controls moving the enemy after round completion do not restart sensing.

The user explicitly selected **"Blind as it passes actors"**. The wave now affects both teammate and player during actual travel, once per viewer/wave, using its existing radius, facing, through-wall behavior and extra blackout second. Actors behind the launch plane are excluded (including the caster on release). G uses the real player controller/utility path; it no longer requires the wave to reach the distant endpoint before blinding. This user-approved fix touches shared `utility/blind_wave.gd` and `scenes/player/player.gd`; no bot decision logic was changed here. The FPS runner prints and overlays those two local files until Person 1 adopts the change upstream.

For the concurrent action session, the live producer now delivers `seen` content exactly `{type: "player_entry", actor_id: "player", entry_id: "entry"}` through the existing inbox. Own scenario `player_entry_sensing` maps the static entry to its region/direction. Real forward progress and velocity into that region must pass actual FOV/LOS/smoke/blind and continuous exposure checks; teleports/stationary actors do not create cues. It uses an independent seeded sensor and ordinary delayed availability. Anonymous footsteps remain coarse sounds, never identified player-entry evidence. The existing executor alone checks readiness, matching speaker/entry and actual delivery, and the HUD's Player entry line shows only delivered cues. The action controller owns staging/watch orientation; sensing respects its actual facing.

## Full acceptance rule and current implementation gap

The teammate must always fully trust valid delivered player comms, including wrong calls, without credibility/history scoring, required corroboration or numeric hedge-based credibility discounts. Preserve explicit uncertainty as content, and keep clarification, delay, provenance and physical checks. Person 3's imported belief module still uses 0.9/0.7/0.4 hedge strengths; Person 2 does not rewrite that owned source or claim runtime alignment. Person 3 must align the belief/interpreter/model behavior when connecting the existing seam. An empty `trust: {}` compatibility key has no feature or scoring semantics.

## Proposed Person 3 seam (review before production adoption)

The own scene emits `teammate_ready(runtime)` once each spawn/restart. The host must reconnect to the new instance. This is a privileged in-process hookup, **not a model input**. Connect a trusted Person 3 host to:

- `runtime.submit_comm(message)`: a normalized existing comms.v1 envelope. The trusted Person 3 wrapper assigns IDs/speaker/recipient/issued/expiry ticks; raw model output cannot invent them. Query `runtime.current_tick()` and stamp `issued_tick = tick + 1`; recipient is `ally`, speaker `player`. Regions are `room`, `entry`, `corridor`; swing target is `entry`; flash target is `flash_entry` with one synthetic per-round charge. The runtime assigns observation IDs, event time and 18-tick delay, then the executor validates it. Accepted reports reach beliefs once with original evidence IDs. Reports remain usable after player death while the teammate survives. Rejected testimony is omitted from contexts.
- `runtime.policy_context_ready(context)`: copied values every 30 simulation ticks. Context keys are exactly `context_id, bot_id, tick, expires_tick, observations, belief, own_state, active_command`. Only released accepted observations enter `observations`; no scene, target transform, private archive, callback, navigation RID or utility registry enters it. The compatibility `trust` field in the belief snapshot is empty. The model host adds agreed static vocabulary and must log its exact prompt, raw response and parsed output separately in Person 3's recorder.
- `runtime.submit_intent(candidate)`: the [pure goal gate](intent_gate.gd) accepts the shape below only. The trusted host attaches context/decision/bot IDs; the model proposes only supported goal/marker/watch/evidence fields. These are static authored markers, not arbitrary coordinates or enemy IDs.
- `runtime.comm_result(result)` and `runtime.decision_recorded(record)`: copied lifecycle results and physical decision records for Person 3's UI/decision log. The latter records policy source, actual plan/physical status and the captured model context/candidate when present. It is not proof of an external model's actual prompt by itself.
- `runtime.observation_delivered(observation, delivery_tick)`: a deep copy after actual promotion, including due sightings/heard sounds and accepted comms. `decision_recorded` also has `errors`, retaining executor/belief/sensor diagnostics. `snapshot()` includes copied `observations`, `own_perception: {blind_until_tick, inside_smoke, view_smoked_off, smoke_view_known}` and own `flash_count`. Own smoke status is cached at sampling: local eye occupancy plus a forward ray clipped at the first solid wall, with no target dependence; forward assessment is unavailable while blinded/down. Context keys remain unchanged and this does not add a new model input or change a shared schema. Person 3 should log original event/availability and actual delivery ticks separately. Hearing is available to context/logging but the imported belief module does not consume it.

~~~json
{
  "context_id": "<the issued context ID>",
  "decision_id": "<trusted unique result ID>",
  "bot_id": "ally",
  "goal": "reposition",
  "target_id": "cover",
  "watch_region_id": "room",
  "evidence_ids": ["<ID from that context's observations>"]
}
~~~

Supported goals: hold/cover/reposition/stop. Home watches entry; cover watches room. Old test-room region_a/region_b messages are rejected by this scene. Stop requires null target/watch. Every referenced evidence ID must have existed in the recorded context and actually been delivered by that context tick. Candidate target must be an authored/reachable affordance in that context. Contexts expire after 120 ticks; at most eight are retained. Candidates are deep-copied, cannot introduce Objects/NaNs/extra fields/coordinates, cannot replay decision IDs, and cannot affect a new round. Invalid/missing/late model output yields the same information-limited scripted fallback. Active accepted player commands have priority over autonomous model goals. No mandatory external model call runs on the physics thread.

This **proposed internal seam does not change comms.v1 or the shared observation/belief schema**. Person 3 must review/adapt its voice/model/log consumer; Person 1 retains shared mechanics/bootstrap ownership. Trade/defuse/utility/combat model goals remain unsupported. Follow-player swing release still needs permitted teammate-motion sensing.

## Physical flash command

`throw_flash` targets `flash_entry` with `now` or `on_cue`. On-cue preparation navigates to `home` through the sole motion controller, reports ready from actual arrival, then waits for a valid delayed cue. `now` requires the actor already within 0.75 m of that authored launch position; physical displacement produces a recorded failure. The privileged [flash adapter](flash_controller.gd) uses shared `UtilitySystem.throw_flash` from own eye height and scenario-authored velocity [4,2,-8]. This is a synthetic test throw, not a verified tactical lineup. One scenario charge resets with the bot each round; Person 1's player utility implementation is unchanged.

Inventory reservation and physical launch are synchronous. Null spawn refunds the charge and records failure; replayed/reentrant command IDs cannot launch twice. Completion means a real projectile was released, not that an opponent was blinded. Detailed physical failure stays in the decision record; comms lifecycle uses the existing reason codes. Cancel/expiry before release preserve inventory; shared fuse/LOS/blind behavior runs normally after release, including self/team blindness. Reports remain independent of commands. Model utility goals have not been added.

## Validation and remaining manual gate

~~~powershell
& $pythonExe validation/run_person2_tests.py --godot $godotExe
& $pythonExe validation/run_person2_tests.py --godot $godotExe --person1-ref 487ad73 --person3-ref 57f809d
& $pythonExe validation/run_person2_tests.py --godot $godotExe --first-person-smoke
& $pythonExe validation/run_person2_tests.py --godot $godotExe --perception-smoke
~~~

The default suite includes pure intent validation. The first-person smoke loads the actual inherited scene/shared components, verifies active first-person camera and physical player movement, injects structured comms, checks delivery delay/real teammate movement, validates model goals and rejects hidden/unknown targets, checks command priority/fallback/post-death delivery, and recreates the runtime on restart. These are **automated fixture injections**, not microphone tests or actual local-model decisions. It checks copied contexts/records and recorded evidence; full nondeterministic LLM fairness still needs Person 3's actual prompt/output trace plus dependency/hidden-state audits.

The user previously confirmed the correct map and a visible teammate; this is startup evidence only. No new human perception/flash/navigation or voice playtest was performed. A human must check mouse/movement, teammate navigation/collision, real sight/hearing, smoke/flash/blind recovery and restart. Once Person 3 connects voice/LLM, test spoken reports/commands, ambiguity, model failures, post-death speech and reset on the actual model machine. Record tester/build/scene/steps/observed outcomes. Automated loading does not establish a manual pass.

Person 1's navigation mesh/map cell mismatch is still accommodated only in this owned scene (map 0.2/0.1) and the check waits for the ready-signal frame to finish. Person 1 must coordinate the shared production fix. Its runtime bake still emits a mesh-readback performance warning. Source clip/year/timestamps and Lotus regions await verified notes; no pro behavior has been invented.
