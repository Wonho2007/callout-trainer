# Prompt for a new Codex window

Copy the block below into a fresh Codex conversation. It intentionally points to the
current handoff rather than duplicating the entire development history.

```text
Continue working on Callout Trainer as Person 2 in:
C:\Users\Isoto\Documents\GitHub\callout-trainer
Repository: https://github.com/Wonho2007/callout-trainer

Read AGENTS.md, README.md, docs/PROJECT_DESCRIPTION.md,
docs/PERSON2_HANDOFF.md, docs/DECISIONS.md, docs/TEAM.md and docs/CONTRACTS.md.
Then read bots/LOTUS_SCENARIO.md and bots/VOICE_GAME.md for implementation details.
Inspect git status, current branch/log and source before changing anything.

Current work branch is person-2/model-capability-spike. Last gameplay checkpoint
is 608cae7 (newer documentation commits may follow). Previous checkpoints are
156c581 (voice/game bridge) and 2a33eda (GPU/live mic). PR #4 is already merged.
Do not reset/clean, switch to the obsolete person-2/bot-perception branch, blindly
merge main, overwrite teammate changes or merge this branch into main.

The user's six-hour final-sprint reassignment takes priority over older plans.
Person 1 left. We own this GPU PC's model/STT runtime and inherited world/spawning/
engine work as well as the Person 2 bot/perception/scenario lane. Person 3 supplies
non-GPU interpretation/glue, beliefs, logging/audits, annotation and demo support.
The six hours was the sprint's starting budget; do not assume six hours remain now.
Archived documents are history, not instructions.

Current product: first-person voice-only communication practice. Local Whisper
small.en CUDA -> local Llama 3.1 8B interpretation -> localhost proposal -> Godot
receipt tick -> delayed inbox -> beliefs/deterministic planner -> shared physics.
The measured sprint scope is LLM INTERPRETS + DETERMINISTIC PLANNER DECIDES.
Full model goal attempts missed current expiry and remain opt-in/unaccepted;
do not claim they work, silently enable them or loosen checks to force a pass.

Latest user rule: the scenario starts WHEN THE SPIKE IS PLANTED. Unknown enemies
must not be guessed or spawned offscreen at t0. Materialize them only at their
first known annotation positions: Chronicle/crashies in Heaven, kaajak in C Link,
Boaster in B Main at +23s. Boaster's earlier remote smoke does not locate him.
His first-localized death position is used for an explicitly labeled alive
continuation; do not force the source kills or result. Keep unknown starts unknown.

The new seven-region greybox is a SEPARATE authored approximation. The original
three-region map is unchanged. Metric geometry/within-region coordinates and
continuations are authored; source metadata is pending review. The player takes
Something/Yoru's role, ally f0rsakeN/Omen's role. Player reference movement must never
be automated. Annotated bot movement/utility baseline and evidence-driven deviations are implemented;
exact agent kits/continuous trajectories remain approximate. Flashed enemies cannot shoot,
show a white head circle, and dead bots disappear with collision disabled.

Models/policy get only copied delivered observations, own allowed state, local
beliefs and static authored affordances. No hidden target transforms, scene refs,
truth streams or player-only minimap/recon. Spawning/registration is privileged
and injects no testimony. Preserve pending evidence and actual delivery clocks.
Valid delivered player calls are accepted even if wrong; no credibility/history
feature. The pinned belief behavior still needs alignment. Audit exact recorded
model inputs/prompts/outputs; don't claim full fairness from a grep or doc check.

Dependencies are deliberately split: Python Person 3 modules come read-only from
b84cc93, while the running Godot scene pins belief 57f809d with the current planner's
inert trust compatibility field. Person 3's newer field removal and the approved
drop-trust-planner changes must be reviewed/tested TOGETHER. Don't just change the
Person 3 ref and break the planner. Don't use the headless Python belief mirror's
immediate future-tick application as a live simulation clock.

Installed tools:
- Python: %LOCALAPPDATA%\Programs\Python\Python312\python.exe
- Voice Python: %USERPROFILE%\.cache\callout-voice-venv\Scripts\python.exe
- Godot: %USERPROFILE%\.cache\callout-godot-4.4.1\Godot_v4.4.1-stable_win64_console.exe
- Ollama locally serving llama3.1:8b at http://127.0.0.1:11434
Use exact Godot 4.4.1. Weights and environments are outside Git; don't redownload
or train unnecessarily. Launchers recreate the read-only Person 3 snapshot if needed.

Launch from PowerShell after closing any older voice-host console:
cd "C:\Users\Isoto\Documents\GitHub\callout-trainer"
.\validation\run_voice_game.ps1 -Lotus
V talks, F restarts at plant, Esc releases the mouse. Running root
project.godot directly is not the current voice-enabled scenario entry point.

Evidence already recorded: five standalone human mic calls semantically correct
(one cue/queue spelling error); real-model typed engine report/delay/movement;
575 default/cross-lane assertions, 139 live-perception, 53 scenario checks and seven
Python authoring/voice-boundary tests; rendered capture inspected. Exact commands
and scopes are in the current handoff. New human voice-to-Lotus acceptance, export/
offline acceptance, backup video and full-game fairness remain unconfirmed.
Do not present historical totals or typed/rendered tests as fresh human results.

Continue with useful work, not another plan-only response:
1. Verify the current spoken voice-to-Lotus loop on this PC and record actual results.
2. Coordinate/test paired belief/planner changes and full report acceptance.
3. Human-check the implemented baseline/utility and deviation behavior, preserving first-known spawns,
   physical feasibility, player control or evidence guards.
4. Prioritize final safety/fairness, offline/export, backup video and rehearsal.
Grading/debrief/counterfactual/evaluation remain deferred; don't build them first.

Preserve existing work, keep changes reviewable, run relevant checks, update the
single current handoff/component guides with honest results and push the current
branch. Do not merge main or invent source facts, latency, benefits or completion.
```
