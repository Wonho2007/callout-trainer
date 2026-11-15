# First-person teammate integration

The user confirmed the newer [Person 2 direction](../docs/PERSON2_HANDOFF.md) and [Person 3 core handoff](../docs/PERSON3_KIRO_HANDOFF.md) as authoritative: voice-only comms, grounded local LLM teammate goals, hedge-only beliefs, no trust, deterministic safety fallback, grading/debrief deferred. This scene implements the Person 2 integration slice. **Person 3 has since published local STT scaffolding at `57f809d`; its target-machine results are unfilled, and the interpreter/model service and game bridge remain dependencies. Live spoken reactions are not implemented by this change.**

## What runs

[first_person.tscn](../scenes/bots/first_person.tscn) inherits Person 1's actual main scene and uses its player, world, navigation, weapon/tracers, utility, spike and minimap unchanged. [first_person.gd](../scenes/bots/first_person.gd) spawns the reusable [bot scene](../scenes/bots/bot.tscn) at the shared teammate marker. The blue capsule is a live `ActorBase` with shared collision/health/movement. Its [runtime](teammate_runtime.gd) validates delayed comms, applies accepted reports to Person 3's hedge-only belief module, executes commands/model goals through the physical controller, and falls back to the deterministic knowledge planner. No communication menu or transcript box is shown. The HUD states that the voice service is not connected.

The owned scene explicitly selects the retained synthetic `test_room.json`, two authored coverage markers and one entry route. Person 1's shared main now defaults to its newer `b_site.json`; that evolving map is not silently assigned this fixture's region/marker semantics. It is not a Lotus reconstruction, enemy combat AI, scenario validator, fully wired perception or complete model-driven teammate. The existing target remains Person 1's stationary test target. Player-only scan/minimap truth is never passed to bot policy. Sight/hearing/flash/smoke kernels are separately tested; wiring the live registry/acoustic/utility adapters remains Person 2 work. Radio-like comm delivery is an explicit fixture assumption (all addressed player messages, 18-tick delay), not a finalized local hearing/range contract.

## Launch

From this checkout in PowerShell:

~~~powershell
$pythonExe = 'C:\Users\Isoto\AppData\Local\Python\pythoncore-3.14-64\python.exe'
$godotExe = 'C:\Users\Isoto\Downloads\callout-godot-4.4.1\Godot_v4.4.1-stable_win64_console.exe'
& $pythonExe validation/run_person2_tests.py --godot $godotExe --first-person
~~~

The runner makes a disposable project from read-only Person 1 main `233e092`, Person 3 belief files at `57f809d`, and the current Person 2 source. It copies Person 1's input settings and changes only the **temporary** entry scene. No shared main, player, project settings or teammate checkout is edited. Override `--person1-ref` / `--person3-ref` if needed; refs must exist locally. Use official Godot 4.4.1 stable. The earlier `--visual-demo` remains an overhead developer fixture and does not meet the first-person product direction.

WASD moves, mouse looks, LMB fires, R reloads, Q/E use smoke/flash, F restarts, Esc releases/recaptures the mouse. Additional utility keys remain Person 1's current inputs. Close the window to exit. There is no player comm shortcut/menu: the voice host must connect to the runtime below before speech can cause movement. Do not interpret a stationary fallback teammate as proof that a microphone/LLM path exists.

## Proposed Person 3 seam (review before production adoption)

The own scene emits `teammate_ready(runtime)` once each spawn/restart. The host must reconnect to the new instance. This is a privileged in-process hookup, **not a model input**. Connect a trusted Person 3 host to:

- `runtime.submit_comm(message)`: a normalized existing comms.v1 envelope. The trusted Person 3 wrapper assigns IDs/speaker/recipient/issued/expiry ticks; raw model output cannot invent them. Query `runtime.current_tick()` and stamp `issued_tick = tick + 1`; recipient is `ally`, speaker `player`. Current regions are `region_a`, `region_b`, `region_mid`; entry is `entry`; flash targets/inventory are unavailable. The runtime assigns observation IDs, delivery event time and fixed 18-tick delay, then the strict executor validates it. Accepted reports reach beliefs once with their original evidence IDs. Reports stay usable after player death while the teammate survives. Rejected raw testimony is omitted from model contexts.
- `runtime.policy_context_ready(context)`: copied values every 30 simulation ticks. Context keys are exactly `context_id, bot_id, tick, expires_tick, observations, belief, own_state, active_command`. Only released accepted observations enter `observations`; no scene, target transform, private archive, callback, navigation RID or utility registry enters it. The compatibility `trust` field in the belief snapshot is empty. The model host adds agreed static vocabulary and must log its exact prompt, raw response and parsed output separately in Person 3's recorder.
- `runtime.submit_intent(candidate)`: the [pure goal gate](intent_gate.gd) accepts the shape below only. The trusted host attaches context/decision/bot IDs; the model proposes only supported goal/marker/watch/evidence fields. These are static authored markers, not arbitrary coordinates or enemy IDs.
- `runtime.comm_result(result)` and `runtime.decision_recorded(record)`: copied lifecycle results and physical decision records for Person 3's UI/decision log. The latter records policy source, actual plan/physical status and the captured model context/candidate when present. It is not proof of an external model's actual prompt by itself.

~~~json
{
  "context_id": "<the issued context ID>",
  "decision_id": "<trusted unique result ID>",
  "bot_id": "ally",
  "goal": "reposition",
  "target_id": "cover",
  "watch_region_id": "region_b",
  "evidence_ids": ["<ID from that context's observations>"]
}
~~~

Supported goals: hold/cover/reposition/stop. Home watches region_a; cover watches region_b. Stop requires null target/watch. Every referenced evidence ID must have existed in the recorded context and actually been delivered by that context tick. Candidate target must be an authored/reachable affordance in that context. Contexts expire after 120 ticks; at most eight are retained. Candidates are deep-copied, cannot introduce Objects/NaNs/extra fields/coordinates, cannot replay decision IDs, and cannot affect a new round. Invalid/missing/late model output yields the same information-limited scripted fallback. Active accepted player commands have priority over autonomous model goals. No mandatory external model call runs on the physics thread.

This **proposed internal seam does not change comms.v1 or the shared observation/belief schema**. Person 3 must review it and adapt its actual voice/LLM/log implementation; coordinate any later shared schema change with both consumers. Trade/defuse/utility/combat model goals are not silently guessed or claimed supported. The existing command executor can validate flash requests, but this scene has no feasible bot flash adapter/resources. Follow-player swing release still needs permitted teammate-motion sensing.

## Validation and remaining manual gate

~~~powershell
& $pythonExe validation/run_person2_tests.py --godot $godotExe
& $pythonExe validation/run_person2_tests.py --godot $godotExe --person1-ref 233e092 --person3-ref 57f809d
& $pythonExe validation/run_person2_tests.py --godot $godotExe --first-person-smoke
~~~

The default suite includes pure intent validation. The first-person smoke loads the actual inherited scene/shared components, verifies active first-person camera and physical player movement, injects structured comms, checks delivery delay/real teammate movement, validates model goals and rejects hidden/unknown targets, checks command priority/fallback/post-death delivery, and recreates the runtime on restart. These are **automated fixture injections**, not microphone tests or actual local-model decisions. It checks copied contexts/records and recorded evidence; full nondeterministic LLM fairness still needs Person 3's actual prompt/output trace plus dependency/hidden-state audits.

No human first-person bot playtest is recorded. A human must check rendering, mouse/movement, teammate visibility/navigation/collision and restart. Once Person 3 connects voice/LLM, test spoken reports, commands, ambiguity/clarification, model timeout/invalid-output fallback, post-death voice, expiry and reset on the actual model machine. Record tester/build/scene/steps/observed outcomes. Do not report automated scene loading as a manual pass.

Person 1's navigation mesh/map cell mismatch is still accommodated only in this owned scene (map 0.2/0.1) and the check waits for the ready-signal frame to finish. Person 1 must coordinate the shared production fix. Its runtime bake still emits a mesh-readback performance warning. Source clip/year/timestamps and Lotus regions await verified notes; no pro behavior has been invented.
