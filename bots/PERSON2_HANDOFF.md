# Person 2: resume in a new Codex window

Handoff updated November 14, 2026. The latest increment adds privileged authored-path movement and command arbitration above the earlier `04291d8` perception baseline. Current automated results and dependencies are in the continuation record at the end and [motion guide](MOTION_CONTROLLER.md). This is not a claim that the game is complete. Recheck repository state before acting; newer teammate work may change integration facts.

**Latest sync:** at the user's explicit request, merged main through `7e5e2b4` into this lane (merge `f00845f`, following `7484aad`). The earlier shared-document merge conflicts were resolved by retaining both lanes' records; that historical blocker is cleared. See the sync record at the end for the newer Person 3 direction documents, which are not on main yet.

**Direction confirmed:** the user subsequently confirmed the newer [Person 2 direction handoff](../docs/PERSON2_HANDOFF.md) as authoritative. Current requirements are voice-only player comms, local grounded LLM teammate goals, hedge-only beliefs/no trust, deterministic safety fallback, grading/debrief deferred. This supersedes older statements in this guide. The owned [first-person integration](FIRST_PERSON.md) now exists; the voice/LLM service is still Person 3's dependency. The overhead demo is only a developer fixture.

## Start here

Paste this into a new Codex window:

> Continue as Person 2 on Callout Trainer. Read AGENTS.md, the complete callout_trainer_brief.md, required team/contracts/decision/workflow documents, docs/HANDOFFS.md, and bots/PERSON2_HANDOFF.md. Inspect git status, branch, remotes and current teammate interfaces before editing. Stay in Person 2's ownership, preserve existing work, and do not merge or overwrite teammate branches. Implement the next small bot integration increment described in the handoff using the current interfaces. Run meaningful automated checks, distinguish them from manual playtests, update Person 2's handoff with actual results and dependencies, and push the existing Person 2 branch. Do not merge to main.

Repository: https://github.com/Wonho2007/callout-trainer

- Local checkout: `C:\Users\Isoto\Documents\GitHub\callout-trainer`.
- Branch/upstream: `person-2/bot-perception` / `origin/person-2/bot-perception`.
- Existing draft PR: [#4](https://github.com/Wonho2007/callout-trainer/pull/4), “Add bot perception, knowledge planning, and validated command execution”. Continue this PR rather than creating a duplicate.
- Resume baseline was `4e0e67e` (guide) above implementation `04291d8`; the motion increment follows it. The working tree was clean at the start of this continuation.
- Person 3's separate checkout: `C:\Users\Isoto\Documents\GitHub\callout-trainer-person3`, branch `person-3/comms-belief`. Last compatibility test used clean commit `7a5375c`; inspect before reusing it. Never edit it from the Person 2 task.
- Person 1's remote branch: `origin/person-1/world-scaffold`; fetched/inspected `0fd1285`. Person 3's fetched branch is now `ff2a6d7`; this continuation tests those refs read-only without altering the older local Person 3 checkout.

## Product and ownership

The product practices **clear communication** in a small playable retake, including timely enemy reports, utility coordination before entry, readiness/swing timing, and useful death reports. Natural-language paraphrases normalize to structured commands; fast bot decisions remain deterministic. A trained model is not required. Do not move language parsing or grading into Person 2.

Feedback about omitted callouts must respect what the player could know, what the teammate lacked, usefulness and feasible timing. Unknown killer identity, hidden facts, parser/delivery failures, or an already-delivered equivalent message are not player mistakes. A player's death position is not necessarily the killer's position. Training benefit and transfer remain unmeasured.

- Person 2 owns `perception/`, `bots/`, `scenarios/`, `validation/`, `scenes/bots/`, and `tests/person2/`.
- Person 1 owns shared actors, world/maps/navigation, weapons, utility, main/player scenes, root Godot settings and exports.
- Person 3 owns communication, beliefs, grading, recording, debrief/evaluation, shared schemas, and verified video annotations. Person 2 converts verified notes into executable baseline/reactive scenario data; do not invent pro actions.
- Change only Person 2's row and append Person 2 notes in `docs/HANDOFFS.md`. Coordinate shared contracts; do not silently replace them or rewrite other lanes' records.
- Policy may read copied delayed observations, local beliefs, own-state allowlists and permitted public signals. Only privileged sensing/actor adapters may query live world nodes, transforms, physics and navigation. Keep those handles out of policy.

## What exists

| Component | Paths and current scope |
|---|---|
| Plain values / private inbox | `perception/plain_data.gd`, `perception/observation_inbox.gd`: strict copied envelopes, delayed release, deduplication, bot ownership and actual delivery-time provenance |
| Player-command executor | `bots/command_executor.gd`, `validation/comms_validator.gd`: validated swing/flash commands, staging/readiness/cue lifecycle, expiry/cancel/failure, accepted reports and actor intents |
| Knowledge planner | `bots/knowledge_planner.gd`: hold/cover/reposition/stop or yield to an accepted command; fresh local evidence, role/objective/reachability, deterministic ties and hysteresis |
| Privileged sensor | `perception/perception_sensor.gd`: real raycast FOV/LOS, multi-point exposure, smoke blockers, blind-status suppression, seeded reaction delay and navigation-path-distance hearing |
| Privileged movement | `bots/motion_controller.gd`: authored-path movement/watch angles, stage/swing arbitration, physical feedback and safe stops; [API/limitations](MOTION_CONTROLLER.md) |
| Synthetic data | `scenarios/synthetic_coverage.json`: authored coverage markers and test tuning, explicitly not a pro reconstruction |
| Automated runners | `validation/run_person2_tests.py`, `tests/person2/`: disposable Godot projects, fake actor demo, real physics/nav fixtures, optional read-only integration with Person 3 |

Detailed APIs: [executor guide](../docs/PERSON2_EXECUTOR.md), [planner guide](README.md), [sensor guide](../perception/README.md), [command contract](../docs/COMMANDS.md), and [communication coaching](../docs/COMMUNICATION_COACHING.md).

These components are **not yet wired into a playable shared bot scene**. The optional integration harness now turns autonomous goals into actual movement through Person 1's actor and generated room. No complete aiming/combat implementation, pro baseline/branches, live speech integration, scenario safety suite or human playtest is claimed by Person 2.

## Integration rules that must survive

1. Sample the sensor once per physics tick using a trusted opponent registry and current poses/sounds. Create a fresh sensor per bot per round. Raw target descriptors and physics handles never leave the privileged boundary.
2. Enqueue successful sensor observations and normalized communication into the bot's existing inbox/executor. Do not expose observations before `available_tick` or backdate their actual delivery.
3. Step the executor once for the tick with its own physical state and actor feedback. Forward only accepted report IDs from its `reports` output to Person 3; rejected raw testimony must not update beliefs.
4. Apply due valid visual observations to the real belief module, preserving IDs. Query the belief snapshot, then call the planner with the same bot's inbox and executor `active_command_snapshot()`.
5. Use `motion.step` as the sole movement dispatcher after executor/planner, then drain its feedback into the next executor step. A planner `command` goal yields control; it must not re-dispatch the command. Do not also dispatch those intents through another actor adapter. Report actual physical completion/failure.

Person 3's tested snapshot is `{bot_id, tick, enemies: {enemy_id: {region_id: probability}}, trust, evidence_ids}`. Planner evidence must actually have been delivered by the snapshot tick. Freshness uses the original event time; prediction or unrelated reports must not refresh stale enemy knowledge. Planner scores average enemy-slot regional mass, not the probability of any enemy being present.

Sensor visual content `{type: "enemy_seen", enemy_id, region_id}` is compatible with Person 3's tested belief handler. Proposed hearing content `{type: "sound_heard", sound_kind, distance_class}` carries no actor identity, coordinates or exact region. **Person 3 does not yet consume hearing**; keep it for logging/future likelihoods rather than inventing belief updates.

Inspected Person 1 physics layer bits: world=1, player=2, bots=4, regions=8. Smoke bit 16 and vision mask 23 are test/proposed settings; coordinate before production use. Flash mechanics must supply `blind_until_tick`. Nonquiet hearing requires synchronized navigation plus walkable sound/listener anchors. No straight-line fallback, PVS filter or full-region-clear evidence exists. Example timing values are placeholders, not measured Valorant behavior.

## Movement increment status and next integration

Inspected fetched Person 1 `0fd1285` and Person 3 `ff2a6d7`. `ActorBase.set_move_dir`, `move_toward_point(point) -> float`, `is_alive`, `navigation_ready`, `navigation_is_ready` and `query_path -> PackedVector3Array` remain available. The new adapter consumes those actual APIs; it does not replace shared mechanics. Person 3 has quick-call model/UI but live shared bootstrap wiring remains pending.

Implemented/tested the smallest movement adapter in isolated owned fixtures: autonomous coverage navigation/watch angle, command stage/swing priority, physical completion/failure, cancellation/expiry/death/error stops, deduplication and progress failure. `throw_flash` explicitly fails because the shared atomic launch/inventory adapter is not connected. Configure no feasible flash inventory/targets until that dependency is implemented. Full OOD/entropy/circuit-breaker UI and combat remain undone.

Automated acceptance for this slice passes in a disposable project using real teammate modules: delivered report changes coverage goal/movement/watched angle, command overrides routine movement, one physical swing, cancellation/expiry/death stop, available provenance and actual unseen-node perturbation. Existing planner tests cover stale observations and new motion tests reject unavailable evidence. **The shared synthetic-room human visual gate is still unperformed.** Headless assertions do not satisfy it.

Next: Person 1 must align its nav map and bake cell settings and coordinate bootstrap/marker IDs. Person 2 then wires this controller and trusted scene registry/flash/smoke/audio adapters; Person 3 connects quick-call delivery, belief updates and visible physical failure reasons. Run a human synthetic-room playtest, implement remaining combat/fallback/scenario checks, convert verified annotations and rehearse the demo. The nav mismatch and temporary fixture adjustment are explained below and in the motion guide.

## Reproduce automated checks

Run from the Person 2 checkout in PowerShell. Local tools already installed:

```powershell
$pythonExe = 'C:\Users\Isoto\AppData\Local\Python\pythoncore-3.14-64\python.exe'
$godotExe = 'C:\Users\Isoto\Downloads\callout-godot-4.4.1\Godot_v4.4.1-stable_win64_console.exe'
& $pythonExe tools/check_repo.py
& $pythonExe validation/run_person2_tests.py --godot $godotExe
& $pythonExe validation/run_person2_tests.py --godot $godotExe --person3-root '..\callout-trainer-person3'
& $pythonExe validation/run_person2_tests.py --godot $godotExe --person1-ref 0fd1285 --person3-ref ff2a6d7
& $pythonExe validation/run_person2_tests.py --godot $godotExe --demo
git diff --check
```

Use official Godot **4.4.1 stable** (`4.4.1.stable.official.49a5bc7b6` locally). Other machines must supply their own executable paths. The optional Person 3 command requires the three current belief/report source files in that checkout; the runner copies them read-only into a temporary project and edits neither teammate source nor root project settings.

Results actually recorded for implementation `04291d8`:

| Automated check | Result |
|---|---|
| Command/inbox suite | 174 checks pass |
| Planner suite | 72 checks pass |
| Real physics/navigation perception suite | 92 checks pass |
| Optional real Person 3 belief/planner integration | 10 checks pass |
| Optional real raycast -> delayed inbox -> Person 3 belief -> planner | 9 checks pass |
| Total with optional integrations | **357 checks pass** |
| Original synthetic command demo | Pass: one swing, mid-action report, one flash |
| Documentation checker / whitespace | Pass |

GitHub checks passed for the pushed implementation: [docs](https://github.com/Wonho2007/callout-trainer/actions/runs/43649637592/job/132615005739) and [Person 2](https://github.com/Wonho2007/callout-trainer/actions/runs/43649637574/job/132615005793). CI covers the default 338 checks and synthetic demo; the optional 19 cross-checkout checks were local. These historical results must not be presented as a fresh run after future changes.

**Manual playtests: none.** No rendered shared-scene gameplay, live voice, exported-build playtest, full-game fairness proof or user-training benefit has been established by these checks.

## Git and environment cautions

- Preserve unrelated changes. Inspect status before staging; stage explicit owned paths. Push `person-2/bot-perception` to its existing upstream; leave PR #4 draft and do not merge to main unless separately instructed.
- A previous non-working-tree merge check found shared-document conflicts against main in `README.md`, `docs/DECISIONS.md`, and `docs/HANDOFFS.md`. No merge was started. Recheck current status; resolving shared content is a separate integration dependency, not permission to overwrite teammates' documentation.
- Windows sandbox Godot runs previously hit a certificate-store error. The same checks passed with approved execution outside the sandbox. Report environment failures honestly; do not weaken runner error detection. Follow the new window's approval rules if this recurs.
- Git and GitHub CLI are at `C:\Program Files\Git\cmd\git.exe` and `C:\Program Files\GitHub CLI\gh.exe`. Network operations previously needed approved sandbox escalation. If elevated Git reports dubious ownership, verify the checkout path/owner and use a process-only `safe.directory` entry for this exact checkout; do not change global trust settings.
- No secrets, raw participant recordings, ripped assets or unverified pro facts belong in commits. No additional engine download is needed on this machine.

After each increment update this guide and append Person 2's actual commands/results, changed interfaces, remaining dependencies and next step to `docs/HANDOFFS.md`. Preserve the distinction between implemented kernels, integrated gameplay and manual evidence.

## November 14 continuation: actual results

Changed only `bots/motion_controller.gd`, `bots/MOTION_CONTROLLER.md`, `bots/README.md`, this guide, `validation/run_person2_tests.py`, four `tests/person2/motion_*.gd` files, and Person 2's row/appended record in `docs/HANDOFFS.md`. No teammate source, shared schema/fixture or project setting was edited. The adapter's internal config/status shapes are documented for both consumers in the motion guide; comms.v1, observation and belief shapes are unchanged.

Before edits, the existing 357 checks passed against local Person 3 `7a5375c`, and the original swing/report/flash demo and documentation checker passed. The sandbox certificate-store error initially failed the strict runner; approved execution outside the sandbox passed without weakening error detection.

Final full command above, Godot `4.4.1.stable.official.49a5bc7b6`: **174 command + 72 planner + 92 perception + 57 motion + 10 belief + 9 sensor/belief + 28 shared physical integration = 442 checks passed**, exit 0. Shared integration ran 149 physics ticks. Default CI now runs the 395 owned checks through the existing workflow; the optional 47 cross-lane checks are local only. A preceding 52-check motion version and shared integration passed three consecutive runs after synchronization was corrected; the five added fault/arbitration assertions also pass in the final run. Synthetic command demo, documentation and whitespace checks passed for this increment.

**Discovered dependency:** Person 1 `0fd1285` bakes cells at 0.2/0.1 but its project leaves nav map cells at default 0.25/0.25. The initial integration was rejected for actual Godot errors even with passing assertions. The fixture explicitly aligns only its disposable map; Person 1 must fix/verify production alignment. It also waits for the signal-emitting physics frame to finish before the first query. The shared runtime bake emits a mesh-readback performance warning; no script/engine errors remain in the passing run.

**Manual playtests: none.** No rendered shared scene, UI input, exported build, live voice, full-game fairness or training benefit is established. Concrete manual steps are in the motion guide. Remaining dependencies: production nav settings/bootstrap, agreed marker IDs/reachability, atomic utility execution and flash/smoke/audio/registry inputs, Person 3 live quick-call/belief/failure display, and verified annotations. No teammate merge or main merge was performed; previously reported shared-document conflicts remain an integration dependency.

## Standalone visual testing follow-up

Added `scenes/bots/motion_visual_demo.gd` and `.tscn`, plus `--visual-demo`/`--visual-smoke` modes in the owned runner. The [motion guide](MOTION_CONTROLLER.md) has the exact local launch command and manual expectations. `--visual-demo` uses a disposable project and opens the normal Godot runtime; the editor is not required. It defaults to read-only teammate refs `0fd1285` and `ff2a6d7`. The overhead room shows a blue actor/yellow facing marker, authored destination pads, lifecycle/evidence/physical status and buttons/shortcuts for report, swing, prepare/cue, cancel, death and reset. It injects structured messages into the actual delayed executor/belief/planner/motion path; it is not the final FPS, live speech or Person 3's UI. Shared world/mechanics/settings remain untouched.

Actual automated check: `validation/run_person2_tests.py --godot <same4.4.1_console> --visual-smoke` passed, exit 0: scene loads, navigation bakes, report causes real movement, swing dispatches, cancellation/death stop, evidence is available and reset clears/revives. This is a headless callback/lifecycle check, **not a rendering or input playtest**. The existing bake performance warning remains. Default 395-check suite, original synthetic command demo, docs checker and whitespace checks also pass for the follow-up. Manual visual/input playtests remain **unperformed**, with steps now runnable by the user. Existing full shared-game dependencies remain as above.

## Main sync and new direction document review

User explicitly requested pulling main and rereading updated project/handoff documents as Person 2. Main through `7e5e2b4` is now merged into `person-2/bot-perception`; teammate actor/world/utility/main files were brought in unchanged. Main now supplies first-person movement, rifle/tracers, smoke/flash/molly, spike, dash/blind-wave, minimap and player-only scan snapshots. This does not yet integrate Person 2's teammate into that first-person scene. Earlier README/DECISIONS/HANDOFFS conflicts were reconciled without dropping Person 2's records or main's Person 1/annotation records. Main's README/top-level historical handoff status still contain stale planning statements; appended implementation records and actual source establish the implemented scope.

Read the complete merged brief, AGENTS, README, team/contracts/commands/decisions/workflow/annotation docs, shared handoffs and this guide. Also inspected the new `docs/PERSON2_HANDOFF.md` and both Person 3 Kiro/Antigravity handoffs read-only on `origin/person-3/comms-belief`: added at `ce991a2`, then brief/decisions/ownership aligned at `b078210`. Those updates are **not on fetched main `7e5e2b4`**. They direct a voice-only player path, local grounded LLM teammate decisions, hedge-only beliefs without trust, deterministic safe fallback, deferred grading/debrief, Person 3 annotation and Person 2 physical execution/scenario runtime. This conflicts with the older main brief's quick-call/trust/rule-based defaults. Clarification requested on treating those unmerged direction documents as authoritative; no Person 3 source/branch was merged or rewritten. The source round still needs a verified VOD/timestamps/notes; no pro facts were invented.

Actual automated check on Godot `4.4.1.stable.official.49a5bc7b6`: `validation/run_person2_tests.py --godot <same console> --person1-ref 7e5e2b4 --person3-ref ce991a2` passed **442 checks**, exit 0, including the new hedge-only Person 3 belief model copied read-only. Existing `trust: {}` compatibility field is accepted without changing the shared snapshot shape. Documentation checker and working-tree whitespace check pass. The known mesh-readback bake warning remains. No new manual playtest or first-person teammate integration is claimed.

## Confirmed direction and first-person teammate slice

Adopted the three direction handoffs from Person 3 `b078210` into `docs/`; updated AGENTS/brief/README/DECISIONS/TEAM/COMMANDS to record the user's explicit precedence decision while preserving Person 1's mechanics/version and earlier implementation records. No Person 3 source or teammate branch was merged. Exact reference VOD/year/timestamps and Lotus regions are unverified dependencies; no pro behavior/data was invented.

Added `scenes/bots/bot.tscn`, `first_person.tscn` and `first_person.gd`, `bots/teammate_runtime.gd`, `bots/intent_gate.gd`, `bots/FIRST_PERSON.md`, `tests/person2/intent_gate_tests.gd` and `first_person_smoke.gd`; extended the owned runner with `--first-person` and `--first-person-smoke`. The first-person scene inherits Person 1's main and spawns the real shared actor at the teammate marker. Shared player/world/settings/weapons/utility/main source is unchanged. The runner copies actual shared assets/settings read-only into a disposable project and overrides only its temporary entry point.

Proposed Person 3 consumers: `teammate_ready(runtime)`, `submit_comm(comms.v1)`, `policy_context_ready(copied context)`, `submit_intent(copied candidate)`, `comm_result` and `decision_recorded`. Exact shapes, timing, evidence validation, ownership and unsupported actions are in the first-person guide. **This is an internal proposed seam for review, not a changed/frozen shared schema.** No comms.v1 or belief snapshot fields changed. Trust is empty compatibility metadata. Accepted delayed reports drive actual movement; model goals require captured context, known/reachable authored markers and context-available evidence; commands take priority; invalid/missing/late model output yields deterministic fallback; old-round contexts are rejected. Rejected raw testimony never enters model contexts. Public round completion stops the bot; player death alone keeps comms usable while a teammate survives.

Actual automated validation on official Godot 4.4.1: **418 default checks** (174 command, 72 planner, 92 perception, 57 motion, 23 pure intent gate); optional integrations against main `7e5e2b4` and Person 3 `b078210` pass another **47** (10 belief, 9 sensor/belief, 28 shared motion); first-person scene smoke passes **21**. Total **486 checks**. Default/cross-lane runner and first-person smoke exit 0. Docs checker, whitespace checks and original synthetic command demo pass. UID-copy/navigation-ready ordering warnings found in the first FPS run were fixed only in the owned runner/scene; the existing runtime mesh-readback bake performance warning remains.

**Manual playtests: none for this first-person slice. Voice/LLM end-to-end: unavailable.** Person 3's fetched branch has belief/menu helper code and the new plans, but no microphone/STT/interpreter/model service yet. The scene has no comm menu and explicitly displays voice unavailable/fallback; only the smoke test injects structured comms/candidates. No real local-model decisions, voice accuracy/latency, human rendering/input success or full model fairness are claimed. Sensor kernels remain separate; actual scene registry/sound/flash/smoke adapters, broader combat/utility/defuse intents, real scenario runtime/branches and full fallback telemetry remain undone.

Next: Person 3 reviews/connects the comm/goal/log seam and delivers voice/LLM capability results plus verified annotations; Person 1 coordinates adopting the bot host in the shared bootstrap, production nav alignment and final marker/region IDs. Person 2 wires real sensors and remaining physical intents/scenario checks. A human must verify first-person movement, bot visibility/behavior and reset, then real spoken reports/commands/model failures/post-death comms on the chosen model machine. Launch and checklist: [FIRST_PERSON.md](FIRST_PERSON.md).
