# Callout Trainer

A Godot first-person practice scenario where the player communicates with information-limited bot teammates, then reviews what those callouts changed.

**Current direction: first-person voice comms coach with local LLM teammates.** Person 1's synthetic first-person sandbox/mechanics and Person 2's isolated bot modules exist. Person 2 now provides a separate first-person teammate integration scene; the live Person 3 voice/LLM service is still a dependency. No end-to-end voice, pro reconstruction or training benefit is claimed. Use Godot 4.4.1 stable.

The user confirmed [the newer Person 2 handoff](docs/PERSON2_HANDOFF.md) and [Person 3 core handoff](docs/PERSON3_KIRO_HANDOFF.md) as authoritative: voice-only player comms, local grounded LLM decisions, no trust model, deterministic safe fallback, and grading/debrief deferred. See the precedence note at the top of the [brief](callout_trainer_brief.md). Older planning text below is historical where it conflicts.

## Start here

1. Read [AGENTS.md](AGENTS.md) for AI collaboration rules.
2. Read the complete [project brief](callout_trainer_brief.md), especially sections 4, 6, 7 and 9.
3. Read [team ownership](docs/TEAM.md), [shared contracts](docs/CONTRACTS.md), and [decisions](docs/DECISIONS.md).
4. Claim one of the three work lanes in GitHub Issues. Check [handoffs](docs/HANDOFFS.md) and coordinate interface changes before implementation.

The brief is the product requirements source. Supporting documents organize that work; they do not silently replace its requirements. Advice and prompt PDF summaries are mapped to acceptance criteria in brief section 8. Those PDFs and reference footage are not bundled, and no local Downloads path is needed to work from this repository.

## Clone and contribute

Public repository: anyone can clone. Collaborators must accept their GitHub invitation to push branches.

Team: Wonho2007, sn-kurup and liedwin49. Lane assignments are still open; claim an issue together.

~~~sh
git clone https://github.com/Wonho2007/callout-trainer.git
cd callout-trainer
git switch -c person-1/world-scaffold
~~~

Use person-2/bot-perception or person-3/comms-belief for the other lanes. Make small pull requests into main. Follow [CONTRIBUTING.md](CONTRIBUTING.md); do not commit directly over another lane's work.

Paste this into your AI assistant after cloning:

> Read AGENTS.md and callout_trainer_brief.md completely, then docs/TEAM.md, docs/CONTRACTS.md, docs/DECISIONS.md and docs/HANDOFFS.md. I am Person [1/2/3], working on issue #[number]. Inspect the current repository and branch before editing. Work within this lane, preserve the fair-perception boundary, and implement the next handoff against shared fixtures. Record real checks and unresolved dependencies; do not invent completion or change another lane's interfaces silently.

## Building with agents and minimal editor work

Read [the agent-led sandbox workflow](docs/AGENT_WORKFLOW.md). Person 1 builds a JSON-defined synthetic room with a GDScript builder, matching geometry/collision, named regions/spawns and navigation. Get one teammate responding to a callout before recreating a pro site.

Agents write files and run available checks; humans mainly launch, inspect and playtest. One teammate can initially operate Godot. Learn run/stop, scene tree/Inspector, errors and debug views; advanced editor authoring is unnecessary for the first prototype. Headless success does not prove movement, visuals or bot responses are correct.

Use short tasks: agent changes one feature -> checks -> human playtest -> specific feedback. The workflow document includes a first-task prompt, proposed paths and acceptance gates. Map and scene construction remain planned; the Person 2 command runtime below is now implemented.

## Three lanes

| Lane | Responsibility | First handoff |
|---|---|---|
| Person 1 | World, player, shared mechanics, navigation bake, export | Test room, actor adapters, named regions |
| Person 2 | Perception, scripts, reactive bots, validators, safety | Delayed observation interface and leak fixture |
| Person 3 | Callouts, beliefs/trust, grading, logs, debrief, evaluation | Shared schemas, synthetic log, audit fixture |

Full assignments and hour-by-hour gates are in brief section 9. The 24-hour schedule is a planning assumption, not a verified event deadline.

## Natural-language commands

The selected [communication contract](docs/COMMANDS.md) separates flexible speech from bot actions. Start with enemy reports, flashes and coordinated swings; paraphrases share intents, while countdown timing remains explicit. See the [schema](schemas/comms_v1.schema.json) and [synthetic examples](examples/comms_v1.json). The bot-side inbox/executor is implemented against this boundary; speech interpretation and 3D mechanics remain pending.

## Communication training objective

**Clear communication throughout the round is the main skill.** Readiness is one example alongside timely enemy reports, utility planning before entry, useful death reports and appropriate uncertainty. The debrief should identify information the player could reasonably have shared but the teammate did not receive. See [communication coaching](docs/COMMUNICATION_COACHING.md) for eligibility rules, examples and ownership. Unknown facts and parser/delivery failures must not be scored as player omissions. This broader grader is specified, not yet implemented.

## First integrated milestone

One player, one teammate and one enemy in a synthetic test room. The player sees an enemy that the teammate cannot see. A quick-call message updates the teammate's belief and watched angle. The trace links the delayed message to the decision, and the hidden-state perturbation check passes.

Then extend to the planned compact retake: one site, player plus two allies versus two enemies, one rifle, smoke, flash, defuse and a reactive branch. See the brief's never-cut list before reducing scope.

## Person 2 runtime

See [executor setup and integration](docs/PERSON2_EXECUTOR.md) for the delayed inbox, swing/flash execution, reports, actor adapter API, tests and synthetic trace demo. Use Godot 4.4.1 stable, matching Person 1's proposed version; no root project is required for these isolated checks.

~~~sh
python validation/run_person2_tests.py --godot "/path/to/godot"
python validation/run_person2_tests.py --godot "/path/to/godot" --demo
~~~

These checks exercise policy with fake actor feedback. Real navigation, utility effects, language interpretation and full-game integration remain separate work.

## Checks and running

Documentation/fixture validation only, using Python 3.10+ (standard library):

~~~sh
python tools/check_repo.py
~~~

The GitHub Actions workflow runs this check. It is **not** a gameplay, leak-test or engine validation report.

Person 1's main sandbox runs from `project.godot`; use [the build guide](docs/BUILD.md). For Person 2's first-person teammate scene and the current voice-service dependency, use [the first-person integration guide](bots/FIRST_PERSON.md). The overhead `--visual-demo` is a development fixture and is not the player experience.

## Project contents

- callout_trainer_brief.md ? canonical full requirements and three-person plan.
- AGENTS.md ? instructions for coding assistants.
- docs/ ? ownership, proposed interfaces, open decisions and handoffs.
- examples/ ? explicitly synthetic interface examples, not pro data.
- .github/ ? issue/PR templates and documentation validation.
- tools/check_repo.py ? local documentation/fixture sanity check.

No Riot client integration, extracted assets or replay-file scraping. This is an independent simulator, not affiliated with Riot Games. Reference studies, statistics and policy claims in the brief remain unverified motivation unless a source is independently checked.
