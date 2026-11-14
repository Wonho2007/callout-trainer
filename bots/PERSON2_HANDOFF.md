# Person 2: resume in a new Codex window

Handoff prepared November 14, 2026. Implementation baseline: `04291d8` (physics-backed sight and navigation-distance hearing). This document is a continuation guide, not a claim that the game is complete. Recheck repository state before acting; newer teammate work may change the integration facts below.

## Start here

Paste this into a new Codex window:

> Continue as Person 2 on Callout Trainer. Read AGENTS.md, the complete callout_trainer_brief.md, required team/contracts/decision/workflow documents, docs/HANDOFFS.md, and bots/PERSON2_HANDOFF.md. Inspect git status, branch, remotes and current teammate interfaces before editing. Stay in Person 2's ownership, preserve existing work, and do not merge or overwrite teammate branches. Implement the next small bot integration increment described in the handoff using the current interfaces. Run meaningful automated checks, distinguish them from manual playtests, update Person 2's handoff with actual results and dependencies, and push the existing Person 2 branch. Do not merge to main.

Repository: https://github.com/Wonho2007/callout-trainer

- Local checkout: `C:\Users\Isoto\Documents\GitHub\callout-trainer`.
- Branch/upstream: `person-2/bot-perception` / `origin/person-2/bot-perception`.
- Existing draft PR: [#4](https://github.com/Wonho2007/callout-trainer/pull/4), “Add bot perception, knowledge planning, and validated command execution”. Continue this PR rather than creating a duplicate.
- Last implementation commit: `04291d8`. The working tree was clean when this documentation task began.
- Person 3's separate checkout: `C:\Users\Isoto\Documents\GitHub\callout-trainer-person3`, branch `person-3/comms-belief`. Last compatibility test used clean commit `7a5375c`; inspect before reusing it. Never edit it from the Person 2 task.
- Person 1's remote branch: `origin/person-1/world-scaffold`; last inspected commit `34ce8a9`. Inspect current source read-only rather than assuming these APIs are final.

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
| Synthetic data | `scenarios/synthetic_coverage.json`: authored coverage markers and test tuning, explicitly not a pro reconstruction |
| Automated runners | `validation/run_person2_tests.py`, `tests/person2/`: disposable Godot projects, fake actor demo, real physics/nav fixtures, optional read-only integration with Person 3 |

Detailed APIs: [executor guide](../docs/PERSON2_EXECUTOR.md), [planner guide](README.md), [sensor guide](../perception/README.md), [command contract](../docs/COMMANDS.md), and [communication coaching](../docs/COMMUNICATION_COACHING.md).

These components are **not yet wired into a playable shared bot scene**. Autonomous goals do not yet produce actual movement through a production controller. No complete aiming/combat implementation, pro baseline/branches, live speech integration, scenario safety suite or human playtest is claimed by Person 2.

## Integration rules that must survive

1. Sample the sensor once per physics tick using a trusted opponent registry and current poses/sounds. Create a fresh sensor per bot per round. Raw target descriptors and physics handles never leave the privileged boundary.
2. Enqueue successful sensor observations and normalized communication into the bot's existing inbox/executor. Do not expose observations before `available_tick` or backdate their actual delivery.
3. Step the executor once for the tick with its own physical state and actor feedback. Forward only accepted report IDs from its `reports` output to Person 3; rejected raw testimony must not update beliefs.
4. Apply due valid visual observations to the real belief module, preserving IDs. Query the belief snapshot, then call the planner with the same bot's inbox and executor `active_command_snapshot()`.
5. Dispatch executor intents exactly once. A planner `command` goal yields control; it must not re-dispatch the command. Other goals require a separate autonomous actor controller. Keep movement ownership unambiguous and report actual physical completion/failure.

Person 3's tested snapshot is `{bot_id, tick, enemies: {enemy_id: {region_id: probability}}, trust, evidence_ids}`. Planner evidence must actually have been delivered by the snapshot tick. Freshness uses the original event time; prediction or unrelated reports must not refresh stale enemy knowledge. Planner scores average enemy-slot regional mass, not the probability of any enemy being present.

Sensor visual content `{type: "enemy_seen", enemy_id, region_id}` is compatible with Person 3's tested belief handler. Proposed hearing content `{type: "sound_heard", sound_kind, distance_class}` carries no actor identity, coordinates or exact region. **Person 3 does not yet consume hearing**; keep it for logging/future likelihoods rather than inventing belief updates.

Inspected Person 1 physics layer bits: world=1, player=2, bots=4, regions=8. Smoke bit 16 and vision mask 23 are test/proposed settings; coordinate before production use. Flash mechanics must supply `blind_until_tick`. Nonquiet hearing requires synchronized navigation plus walkable sound/listener anchors. No straight-line fallback, PVS filter or full-region-clear evidence exists. Example timing values are placeholders, not measured Valorant behavior.

## Next concrete increment

Inspect current Person 1 actor/navigation interfaces and Person 3 live-message/belief entry points. Last inspection found `ActorBase.set_move_dir`, `move_toward_point(point)` and a sandbox builder with `navigation_ready`, `navigation_is_ready` and `query_path`. Confirm signatures and return values in current source. Do not copy or replace shared mechanics.

Build the smallest Person 2-owned adapter/controller that can turn a planner's authored coverage marker into movement through the shared actor API, yield to accepted command intents, and stop safely on death, invalid goals or physical failure. Use an isolated test scene/fixture under Person 2 ownership if shared bootstrap/registry hooks are unavailable. Request exact missing interfaces in the handoff rather than editing another lane's files. Do not add a production controller around guessed APIs.

Acceptance for the next integrated slice: a delivered enemy report changes coverage goal and real movement/watched angle; a player command overrides routine autonomy; its physical action is not dispatched twice; cancellation/expiry/death/error stop or recover appropriately; decision traces cite only available evidence. Test unavailable/stale observations and hidden-enemy perturbation. Then have a human verify the shared synthetic room visually. Headless assertions alone do not satisfy that manual gate.

Subsequent work: connect the trusted scene registry/flash/smoke/audio adapters, implement remaining physical behavior and stuck/fallback checks, convert Person 3's verified annotations into baseline/reactive scenarios, validate feasibility, and rehearse the bot -> scenario -> evidence-trace demo. Do not wait for annotation work to implement independent controller tests.

## Reproduce automated checks

Run from the Person 2 checkout in PowerShell. Local tools already installed:

```powershell
$pythonExe = 'C:\Users\Isoto\AppData\Local\Python\pythoncore-3.14-64\python.exe'
$godotExe = 'C:\Users\Isoto\Downloads\callout-godot-4.4.1\Godot_v4.4.1-stable_win64_console.exe'
& $pythonExe tools/check_repo.py
& $pythonExe validation/run_person2_tests.py --godot $godotExe
& $pythonExe validation/run_person2_tests.py --godot $godotExe --person3-root '..\callout-trainer-person3'
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
