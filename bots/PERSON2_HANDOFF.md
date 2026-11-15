# Person 2: resume in a new Codex window

**Latest user priority (2026-11-15):** the six-hour final-sprint handoff at
`4c85f39:docs/FINAL_SPRINT_PERSON2.md` supersedes older assignments. Person 2 owns this
GPU PC's model/STT runtime and inherits Person 1's world work. PR #4 is already merged
on main `8712f7d`. Current work branch: `person-2/model-capability-spike`.
[First-step measurements and exact commands](../docs/CAPABILITY_SPIKE.md): local
Llama 3.1 8B, 100% GPU, IPv4 warm median 0.590s, 8/8 semantic smoke checks; known
broader-run prompt limitations recorded. Next are goal-selection timing and live
mic/STT/bridge; neither is claimed tested. No Person 3 source/schema was changed.

**PC voice setup continuation:** [LIVE_VOICE.md](LIVE_VOICE.md) now provides the
launcher and actual checks. small.en CUDA speech + local Llama passed a synthetic
speech-file check (0.668s STT, 1.298s audio-to-proposal), 47 Person 3 wrapper/glue/audit
checks pass at `b84cc93`, and the live Razer-default-mic push-to-talk window is open.
User confirms the first human sample, “two on heaven”: correct count/region, 0.285s
STT, 0.881s total after release. Final five-call manual smoke: all five semantic
outputs correct, one cue -> queue spelling error confirmed by user; median STT
0.138s, median after-release total 0.718s, zero fallback. Broader accuracy is pending.
No game dispatch, goal-selection timing
or full-acceptance fix is claimed. Environment/weights remain outside Git; Python
environment is `~/.cache/callout-voice-venv`. No cross-lane source/schema changes.

**Current map:** the FPS scene inherits Person 1's default `b_site.json` at main `487ad73`, merged as `28950f4`, with no map override. The launcher follows latest locally fetched main and freezes/prints its commit per run. Bot spawn/coverage comes from `scenarios/b_site_coverage.json` using room/entry/corridor. Older integration records below are historical. See [FIRST_PERSON.md](FIRST_PERSON.md) for launch and [the current continuation result](../docs/PERSON2_HANDOFF.md) for tested live sensing/physical flash status.

Handoff updated November 14, 2026. The latest increment adds privileged authored-path movement and command arbitration above the earlier `04291d8` perception baseline. Current automated results and dependencies are in the continuation record at the end and [motion guide](MOTION_CONTROLLER.md). This is not a claim that the game is complete. Recheck repository state before acting; newer teammate work may change integration facts.

**Latest sync:** at the user's explicit request, merged main through `7e5e2b4` into this lane (merge `f00845f`, following `7484aad`). The earlier shared-document merge conflicts were resolved by retaining both lanes' records; that historical blocker is cleared. See the sync record at the end for the newer Person 3 direction documents, which are not on main yet.

**Latest player-comm rule:** teammates always fully trust valid delivered player comms, even when wrong. No credibility/history scoring, corroboration gate or numeric hedge-based credibility discount. Preserve explicit uncertainty as content; keep clarification, delay, provenance and physical checks. This supersedes historical hedge-only/trust discussions below. The imported Person 3 belief implementation still needs alignment; no runtime change is claimed by this docs update.

**Next Person 2 task:** live delayed follow-player entry sensing/release is now verified with the action session. Finish coordinated action-harness acceptance and human information tests, then shared defuse/combat with an agreed delayed aim payload. Person 3 owns the voice/model bridge and full-acceptance belief alignment; scenario validation/branches follow using verified notes and structural helpers. The current, ordered acceptance plan is [docs/PERSON2_HANDOFF.md](../docs/PERSON2_HANDOFF.md).

**Direction confirmed:** the user subsequently confirmed the newer [Person 2 direction handoff](../docs/PERSON2_HANDOFF.md) as authoritative. Current requirements are voice-only player comms, local grounded LLM teammate goals, fully accepted player comms, deterministic safety fallback, grading/debrief deferred. This supersedes older statements in this guide. The owned [first-person integration](FIRST_PERSON.md) now exists; the voice/LLM service is still Person 3's dependency. The overhead demo is only a developer fixture.

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

## Teammate updates received during the first-person increment

Fetched/merged new main `233e092` (merge `16affb7`) after Person 1 published its brighter synthetic box-room map and defuse movement lock. Preserved both appended handoff blocks in the sole documentation conflict; shared source is unchanged from main. The owned first-person scene explicitly selects the retained `test_room.json` so its synthetic region/coverage configuration cannot silently operate in the new `b_site.json`. Its launcher now tests actual Person 1 main `233e092` and Person 3 belief code from `57f809d`.

Person 3 `57f809d` now contains `voice/stt.py`, `voice/push_to_talk.py`, voice README and scenario schema/structural validator/coordinate helper. Inspected them read-only. This supersedes the earlier no-STT-at-`b078210` snapshot: STT scaffolding exists, but the voice README's target-machine accuracy/latency/offline-results table is still empty; the grounded interpreter, model-goal host and live game bridge remain absent. No model/dependency downloads, microphone tests or edits to Person 3 code were performed. Person 2 still owns physical scenario feasibility/baseline checks; use Person 3's structural schema/helpers when integrated rather than duplicating them. The FPS scene continues to state voice is not connected.

Final verification after this update: default/cross-lane runner against Person 1 233e092 and Person 3 57f809d passed 465 checks; first-person smoke passed 21, total 486, both exit 0. Docs/whitespace checks pass. The known bake performance warning remains; no manual/voice/model test is claimed.

## Launcher Git ownership fix

User's first-person launch failed at `git show 57f809d:belief/plain_values.gd`. Reproduced as the normal Windows user: Git rejected the sandbox-owned checkout as dubious ownership; the commit/file were present. Updated `validation/run_person2_tests.py` so both show/ls-tree read paths use a process-only `git -c safe.directory=<exact resolved checkout>` exception. No global trust setting, repository ownership or teammate source was changed. Real Git stderr is now included when a read fails, with fetch guidance for unavailable refs.

Actual checks as the normal Windows user, without manually supplied Git trust environment variables: first-person smoke passed 21 assertions on Godot 4.4.1, exit 0; separate launcher checks passed binary blob read, textual tree listing and an intentionally missing ref's actionable error. Docs/whitespace checks pass. The known bake performance warning remains. These are automated checks; no human gameplay/voice pass is claimed.

## Current Person 1 map adoption (user-requested)

Confirmed work stayed on `person-2/bot-perception`. Fetched Person 1's deeper-room update on main `82434b6` (same map/builder content as its `person-1/map-deeper-room` branch) and merged main as `a31c649`. No Person 1 source/map/settings were edited after import. Removed the old-room selection from the owned FPS integration: it now loads `world/maps/b_site.json` and displays `b_site_box` in the status HUD.

Added owned `scenarios/b_site_coverage.json` with current `room`/`entry`/`corridor` vocabulary, a teammate spawn at [-2,0,11.5] in the corridor, and authored navigation/coverage markers through the hall/arch into the room. The new map supplies no teammate spawn, so this placement is scenario data rather than a shared-map edit. The scene checks map ID/region compatibility, uses current-map navigation anchors, and no longer hard-codes old test-room actor/region data. Existing comms.v1 and copied policy boundary are unchanged; the model host must use the new region vocabulary documented in FIRST_PERSON.md.

The FPS launcher now defaults to latest locally fetched origin/main, resolves each dependency to one immutable commit per launch and prints the source hashes. This avoids sticking to an obsolete hard-coded map commit or mixing files during a simultaneous fetch. Launch remains offline; users fetch updates explicitly. Close the prior temporary game window and rerun --first-person to see changed source; restarting an already-running old temporary project cannot load new repository files.

Actual automated checks on Godot 4.4.1: default/read-only integrations at Person 1 82434b6 and Person 3 57f809d passed 465 assertions; FPS smoke passed 29 (494 total), exit 0. FPS assertions verify current map path/id, deeper-room/divot data, actual region vocabulary, authored teammate placement without modifying the map registry, delayed report-driven hallway traversal, actual room-marker arrival/hold, stale-region rejection, model/command/fallback behavior and correct map/spawn after reset. Docs checker and whitespace checks pass. Known runtime-bake mesh-readback warning remains.

Manual evidence: user confirmed the PREVIOUS first-person window opened with a teammate and reported that it was the old map. New-map human movement/rendering/playtest is still pending; headless assertions are not a manual pass. Voice/model bridge and other remaining dependencies are unchanged.

## Full player-comm acceptance and refreshed next steps

Latest explicit user rule: the teammate always fully trusts valid, delivered player comms, even when wrong. Updated the canonical brief and current Person 2 work plan; removed the old trust arithmetic, credibility/history/scarring tuning and trust-comparison tasks from the brief. Updated active instruction/decision/consumer guides to match. Preserve explicit uncertainty as meaning; do not use it as a numeric player-credibility penalty. Delay, clarification, message validity, provenance and physical limitations remain. The empty compatibility field is not a feature or a cleanup priority.

Documentation-only change: no runtime code, shared schemas/fixtures, Person 1 source or Person 3 source changed. Person 3's imported belief module still has numeric hedge weights; the new rule is not claimed implemented there. Person 3 owns aligning working beliefs/model prompts when connecting voice/LLM. The next independent Person 2 task is to connect existing perception kernels to current FPS opponent/utility/audio adapters; voice/model seam work runs in parallel with Person 3, then physical actions and verified scenario/enemy branches. docs/PERSON2_HANDOFF.md now gives current status, ordered work, dependencies and concrete acceptance criteria instead of the obsolete no-bot-spawning work list.

Manual evidence received: the user confirms the current map is correct and the teammate is visible. That establishes this startup/visibility check only, not navigation feel, utility/voice/LLM interactions or a full playtest. Prior 494 automated assertions remain historical; no Godot suites were rerun for these documentation-only edits. Documentation and whitespace checks passed.

## Person 2 continuation checkpoint - 2026-11-14

User requested a handoff for a new Codex window. Main `487ad73` is merged locally as `28950f4` on `person-2/bot-perception`; both lane handoff records were retained. The latest divot changed navigation near the old coverage point. Moving only the owned marker to `[-1,0,3]` restored 29/29 FPS smoke checks on Godot 4.4.1 **before** live-sensor wiring.

Uncommitted, **not compiled/tested** work now includes new untracked `perception/scene_sensor.gd`, runtime sensory delivery/belief integration, adapter attachment in the inherited FPS scene, seeded scenario sensing settings, FPS context-test adjustments and runner copying. Preserve these files. No live-perception acceptance, new human playtest or voice/model result is claimed. Existing 494-check results are historical, not a result for this worktree.

The complete resume checklist, exact commands, adapter review issues, test requirements, interfaces and dependencies are in [the current Person 2 handoff](../docs/PERSON2_HANDOFF.md#continuation-checkpoint---2026-11-14-unfinished-live-sensing). First inspect/compile/test existing changes; then add an actual inherited-scene perception fixture before more intelligence. Person 3 knows the no-trust/full-acceptance rule and retains ownership of its implementation. Continue on the existing lane branch/draft PR #4; do not discard dirty work or replace Person 1's scene/map. No commit/push of this checkpoint is claimed.

## Continuation results - live sensor gate and physical flash

Retained and compiled the entire dirty checkpoint, including `perception/scene_sensor.gd`, above main `487ad73` merged as `28950f4`. Before edits, the existing 29 FPS assertions passed after outside-sandbox Windows certificate access; the first sandbox import failure was not counted as a pass. Fixed the four review items: run velocity plus displacement, off-nav listener suppression, explicit blind-wave registry and exact sensor errors in decision telemetry. Added a real inherited-scene fixture and `--perception-smoke`, then continued to authored physical flash release through shared mechanics. Changed only owned runtime/scene/scenario/tests/runner/guides plus Person 2's shared handoff row/notes. All original checkpoint content is retained above.

Final automated results on official Godot 4.4.1 (`49a5bc7b6`), read-only Person 1 `487ad73` / Person 3 `57f809d`: **430 owned + 47 optional integrations + 45 live perception + 40 FPS = 562 assertions pass**, exit 0. Exact executable paths/commands and check coverage: [shared lane record](../docs/HANDOFFS.md) and [current handoff](../docs/PERSON2_HANDOFF.md). Default CI now picks up the 12 atomic flash assertions automatically; inherited-scene/optional results are local. Known bake mesh-readback warning remains; no engine/script errors or fixture timer leak warning in passing runs.

Interfaces: due sight observations use unchanged enemy_seen content and original availability/evidence IDs. Hearing remains coarse/logged, unsupported by current beliefs. New proposed delivery signal, decision errors and copied sensory/own resource snapshots are documented for Persons 1/3 in [FIRST_PERSON.md](FIRST_PERSON.md). One authored flash charge stages through the sole movement owner and atomically releases an actual shared projectile on delayed cue/now-at-launch-position; completion means release. No shared schemas, teammate mechanics/source, root settings or voice/model system changed.

**Human/voice/model/export tests: none newly performed.** Previous user correct-map/visible-teammate report remains startup evidence only. Current Person 3 full-acceptance dependency is concrete: imported likelihood multiplication can leave a new report outweighed by earlier sight, and hedge weights remain. The passing uncorroborated wrong-call test starts with a fresh belief; it is not proof that this Person 3 gap is fixed. Person 3 knows/owns alignment.

Continue on the same branch/draft PR #4. Next: permitted delayed follow-player entry sensing, shared defuse/combat after an agreed delayed last-observed aim payload, then physical scenario/baseline/branch validation using Person 3 structural helpers/verified notes. Person 3 voice/model/log host and full-acceptance alignment, Person 1 production bootstrap/nav/mechanics and human perception/utility playtests remain dependencies. No merge to main or full-game fairness claim.

## User-requested HUD and enemy controls follow-up

Added a teammate information panel inside the owned FPS scene using existing copied runtime snapshots: own blind countdown, action/flash charges, delivered last-seen memory/age, last coarse sound and accepted comms. It never reads the opponent or shows pending sensory samples. Added a red normally occluded TEST ENEMY label, F6 entry/F7 room presets, camera-relative arrow movement, P safe floor placement and F8 real shared test flash. These privileged controls do not inject testimony or sensor flags. Esc releases the mouse for equivalent buttons; F resets. Exact launch/manual steps: [FIRST_PERSON.md](FIRST_PERSON.md#test-teammate-perception-in-the-hud).

Changed only owned FPS scene/new panel, scenario test-position data, runner/new HUD smoke and own handoffs. Existing runtime/comm/policy/schema interfaces and shared/Person 3 source are unchanged. Actual Godot 4.4.1 results: **477** default/cross-lane + **45** live perception + **40** FPS + **18** HUD = **580 assertions pass**, exit 0, Person 1 `487ad73` / Person 3 `57f809d`. Optional actual-renderer HUD capture passes **19** (same 18 plus PNG save); captured layout inspected. Known bake warning remains. No new human input/playtest, microphone/model or export pass is claimed. Full-acceptance/voice/model/shared-mechanics and next physical/scenario dependencies remain unchanged.

## Smoke assurance and own smoke awareness HUD follow-up

User asked to prevent through-smoke sightings and explicitly show inside/smoked-off awareness. Preserved interrupted natural-smoke regression edits, then added cached own smoke flags in the privileged adapter and separate IN SMOKE / SMOKED OFF HUD labels plus amber Vision restriction. Smoke status uses own eye occupancy and own forward ray ending at the first world wall, never live target coordinates. Forward assessment is unknown while flashed/down; last-seen memory stays aged. No model inputs/shared schema/Person 1 mechanics or Person 3 code changed. New snapshot `own_perception` fields and consumer limitations: [FIRST_PERSON.md](FIRST_PERSON.md), [perception guide](../perception/README.md).

Actual official Godot 4.4.1 at Person 1 `487ad73` / Person 3 `57f809d`: **477** owned/cross-lane + **83** real scene perception + **40** FPS + **22** functional HUD checks, with two additional rendered PNG saves (**24** in rendered HUD mode). All pass: **622 functional assertions plus two rendering checks**, exit 0. Captured both real IN SMOKE / SMOKED OFF layouts and inspected them. Smoke regressions use real shared ground deployment/activation/expiry, including listener inside, target inside and both outside; they verify no new smoke-period sightings/refresh, legitimate pre-smoke delayed delivery, recovery, hidden-smoke wall masking and opponent-independent own smoke flags. Known bake performance warning remains. No human playtest, voice/model or export result is inferred. Same branch/draft PR #4; unchanged remaining cross-lane and ordered physical/scenario dependencies.

## Information session continuation - 2026-11-15

User split perception/delivery/HUD ownership from a concurrent action agent. Preserved its three commits (`3c6085d`, `47fa755`, `8c33f58`) and left its action/motion files untouched. Agreed through the user to the exact live **seen-only** player-entry payload and narrow runner mode/file/scene additions; its runner commit includes the already-approved local shared-wave overlay block. Current source/results/coordination: [docs/PERSON2_HANDOFF.md](../docs/PERSON2_HANDOFF.md).

Fixed dropped sight evidence in map gaps/overlaps via delayed `{type: "enemy_seen_unknown_region", enemy_id}`; the private sentinel never leaves the adapter, named sightings stay unchanged and the region belief handler is not fed unsupported location content. HUD shows unknown region and makes ended-round/inactive sensing explicit. User expressly selected "Blind as it passes actors": small shared wave/player changes apply the same passing primitive to teammate and player once per source, retaining range/facing/walls/duration and excluding viewers behind launch plane. FPS prints/copies those two local scripts for actual testing; Person 1 review/adoption remains necessary. Mixed flash/wave typed registry lookup errors were corrected.

Added live delayed `{type: "player_entry", actor_id: "player", entry_id: "entry"}` through existing inbox/promotion with actual velocity/progress, authored region/direction, FOV/LOS/smoke/blind/exposure and independent seed. No anonymous heard identity, teleport cue, new bot logic or hidden target data. Actual quiet entry releases the staged follow-player command only after delivery and cites the evidence; obscured/out-of-view movement does not. Consumer examples and limits are in [perception/README.md](../perception/README.md#information-recovery-and-action-consumer-additions).

Actual official Godot 4.4.1, Person 1 `487ad73` / Person 3 `57f809d` plus explicit local wave/player overrides: **506** owned/cross-lane + **106** live perception + **40** FPS + **33** functional HUD checks = **685 functional assertions pass**, plus two actual-renderer PNG saves (**35** rendered HUD checks), exit 0. Original synthetic demo passes; HUD capture inspected. Known bake performance warning remains. First optional cross-session action-harness run reached 32 assertions with only viewport-containment failure, relayed to the action owner; not marked passing. No new human gameplay/voice/model/export pass. Existing draft PR #4 only; no main merge or changes to Person 3 schemas/beliefs. Remaining delayed combat-aim, voice/model/full-acceptance, shared bootstrap/nav and verified scenario dependencies remain.

Final checkpoint adds the agreed delayed torso-only `enemy_aim` / causal `enemy_lost` producer; regional enemy_seen stays unchanged. Action consumer freshness is capped at 30 ticks with own impairment guards and opt-in firing. Final direct official Godot checks on preserved action base `b06cd3d`: **125** information + **33** HUD assertions pass, exit 0, including partial-cover protection, copied points, loss ordering, smoke/blind reacquisition and actual entry release. Docs/whitespace pass. Earlier totals are historical for the pre-aim producer. One parallel expanded run hit the unchanged timeout; isolated final execution passed without filtering errors. Action owner's record separately reports 505 default / 41 FPS / 46 action checks passing and supersedes its earlier layout failure. This information commit excludes its action/motion/runtime/runner/peek edits, preserves all commits, and adds only the agreed entry-sensing scenario key. No new human playtest; same draft PR #4, no main merge.

## Information continuation - causal evidence and own death, 2026-11-15

Started clean at `b7edb7f`, verified fetched refs and PR #4. The user now **authorizes merging PR #4 to main after validation**, superseding historical no-merge directions. Keep the branch; this is integration of an unfinished lane, not completion.

Added three-seed inherited-scene tests for five rapid aim/loss/reacquisition cycles before earlier delays finish, checking complete causal delivery, unique IDs, availability and no repeated hidden-state evidence. Shared-health target death after recognition preserves pending pre-death aim and emits only delayed loss, without a kill/cause/location disclosure. Fixed the information HUD to show own teammate death as inactive rather than ready; actual death with surviving player and reset are exercised. Only panel/tests/guides/handoffs changed; no sensing producer, action/runtime/runner/scenario/shared mechanic or Person 3 source changed.

Fresh official Godot 4.4.1 direct results: **552** default/cross-lane (505 owned + 47 optional), **139** perception, **36** HUD, **41** normal FPS, **46** action; original demo, docs and whitespace pass. Each runner exits 0. Refs: Person 1 `487ad73`, Person 3 `57f809d`, both local shared wave/player overlays printed in FPS modes. Initial certificate-restricted import failed; approved execution passes with strict error checks/timeout unchanged. Known bake warning remains. No new human/voice/model/render capture/export test. Exact commands/details: [current lane handoff](../docs/PERSON2_HANDOFF.md#continuation-causal-delivery-regressions-and-own-death-hud).

Person 3 fetched `4ee6a69` now has interpreter/vocabulary/log code and first-pass annotations, inspected read-only. Source metadata/annotator/team review and map vocabulary still require alignment; no pro claim is independently verified here. Tested belief source is unchanged and full-acceptance remains Person 3's dependency. Next: live voice/goal/log consumer review and actual model audit, human sensing/action tests, Person 1 bootstrap/nav/shared-wave review, then coordinated objective/scenario work. No other lane's branch/checkouts were changed. Merge outcome follows actual GitHub checks and is not assumed by this record.
