# Person 2 handoff — perception, bot behavior, scenario runtime

**Audience: assume zero prior knowledge.** Read this top to bottom before touching code.
You are **Person 2 (Wonho2007)**. This document tells you what the project now is, what
your lane owns, what already exists, and every file you need to create or change. It does
not change any code itself — it is instructions.

## 1. What the project is now (read this, it changed)

The product is a **VALORANT comms coach**. The player controls one character in first
person inside a VALORANT-like sandbox (Person 1 is building it). Bots play every other
teammate and every enemy. The player talks **out loud**; their **voice comms** are the
only input (no menu). AI teammates **hear, interpret, and react** to those comms. Enemies
move like the pros did in a real reference round and adapt when the world diverges.

Key product decisions (see `docs/DECISIONS.md`) that affect you:

- **Voice is the only player input.** There is no quick-call menu anymore.
- **Teammate decisions are made by a local LLM and are non-deterministic.** The LLM uses
  only information the bot is allowed to have (delayed observations, its own state, local
  beliefs, public round signals). It must never read hidden truth.
- **No trust model.** A callout is believed and acted on by its hedge strength alone; a
  wrong call gets the bot caught out. The consequence is a bad in-round outcome, which
  **plays out in your lane** (the bot commits and can die).
- **No paid APIs. Everything local/free.** The LLM and speech run on the **Dell G16 7630**
  (the only machine with a discrete GPU). Model files copy to the other laptops.
- **Grading/debrief is deferred.** Do not build it yet.
- **Reference round:** FNC vs PRX, Masters Toronto 2024 Grand Final, Lotus, the final
  round, starting from the bomb plant. Person 3 annotates it from the VOD.

## 2. Your lane (ownership)

You own: `perception/`, `bots/`, `scenarios/`, `validation/`, `scenes/bots/`, and
bot/perception tests. In one line: **everything the AIs physically do, and the runtime that
runs a scenario.** You do **not** own voice, LLM interpretation, belief, or the annotation
notes — those are Person 3.

The clean split with Person 3:

- **Person 3** turns the player's voice into a structured comm and into a bot's belief/goal,
  and runs the LLM that decides the teammate's intent. Person 3 also writes the annotation
  notes (`annotations/`).
- **You** provide perception (what a bot can see/**hear** + reaction delay), execute the
  intent the LLM/planner produces (move, hold, peek, trade, throw, defuse), drive the enemy
  bots along the annotated pro line with adaptation, and convert Person 3's verified notes
  into executable `scenarios/` JSON.

## 3. What already exists (Person 1, `main` branch)

Person 1 pushed a working sandbox to `main`. It has:

- A code-generated room from `world/maps/test_room.json` via `world/sandbox_builder.gd`.
  **It is a synthetic test room, NOT Lotus B yet.** Region IDs are placeholders
  (`region_a`, `region_b`, `region_mid`).
- A first-person player controller: `scenes/player/player.gd`, `scenes/player/player.tscn`.
- Actor base + health: `actors/actor_base.gd`, `actors/health.gd`.
- Weapons: `weapons/weapon.gd`, tracers.
- A full utility system: `utility/utility_system.gd` plus `smoke.gd`, `flash.gd`,
  `molly.gd`, `blind_wave.gd`, `scan_orb.gd`, `recon_outline.gd`, and `utility/abilities.json`.
- A spike: `world/spike.gd`. Minimap: `ui/minimap.gd`. Event log: `recording/game_events.gd`.
- `docs/VIDEO_ANNOTATION.md` — the agreed annotation ownership (Person 3 annotates,
  **you** convert notes to scenario JSON, Person 1 maps regions/markers).

**Two things you depend on do not exist yet:**

1. **No bot spawning of any kind.** There are `spawn_enemy_1` / `spawn_teammate_1` markers
   in the map JSON, but nothing spawns or controls a bot.
2. **No Lotus B region names.** The sandbox is still the generic test room.

Both are blockers for full in-engine integration. Coordinate with Person 1 on who adds bot
spawning and the Lotus B geometry/regions; until then, build against fixtures (section 6).

## 4. The communication path you plug into (already designed)

A player comm becomes a **delayed "told" observation** delivered to one bot's inbox. Person
3's existing code already models this world-independently and has passed on Godot 4.4.1:

- `comms/report_adapter.gd`, `comms/quick_call.gd` — build/validate `comms.v1` messages.
  (The quick-call file stays as a deterministic fallback/test helper even though the player
  uses voice; do not delete it.)
- `belief/region_belief.gd` — per-bot enemy-position beliefs; a comm updates belief by its
  hedge (sure/think/unsure → 0.9/0.7/0.4). No trust.
- `perception/observation_inbox.gd` (yours, already written) — holds observations and
  releases them at their available tick (the reaction delay). The LLM/policy reads only
  released observations.

The shared message contract is `docs/COMMANDS.md` + `schemas/comms_v1.schema.json`
(report / command / cue / cancel). Do not silently change these; coordinate in a PR.

## 5. Files you need to create or change

Nothing here is written for you yet — this is the work list. Create under your owned dirs.

### 5.1 Bot spawning and the teammate/enemy actor (`scenes/bots/`, `bots/`)

- `scenes/bots/bot.tscn` + script: a bot built from Person 1's actor components
  (`actors/actor_base.gd`), spawned at a map `spawn` marker. One scene reused for
  teammates and enemies; role is a parameter.
- A spawner that reads the scenario's actor list and instances bots at the right markers.
  Coordinate with Person 1 on whether the spawner lives in the main scene (his) or a bot
  manager (yours) — do not edit his main scene without asking.

### 5.2 Perception, including hearing (`perception/`)

- Sight: physics ray queries from the bot's eye, FOV, smoke occlusion, flash blindness.
- **Hearing:** this is the half of "the teammate hears comms" that is yours. Decide whether
  a bot is in range to receive a comm / sound event, apply the **reaction delay**, and emit
  a delayed observation into `observation_inbox.gd`. Person 3 does the interpretation; you
  do the "could this bot hear it, and when does it arrive" gate.
- Negative evidence / region coverage for the belief model's `region_clear`.
- Keep `plain_data.gd` (yours) as the copied-value boundary; never hand policy a live node.

### 5.3 The intent executor (`bots/`)

- You already have `bots/command_executor.gd` and `bots/knowledge_planner.gd`. Under the new
  direction, the **LLM (Person 3) produces the teammate's goal/intent** non-deterministically.
  Your planner/executor's job shifts to **executing** that intent fairly and physically:
  move along nav to the goal region, hold/peek/trade, throw the called utility, defuse.
- **Important contract change to coordinate with Person 3:** the belief snapshot no longer
  contains a meaningful `trust` value. Person 3 kept a `trust: {}` empty dict so your
  `knowledge_planner._valid_belief` `keys_exact` check still passes. You may drop `trust`
  from that validation in a coordinated change. Do not assume trust exists.
- The fallback deterministic planner stays as the circuit-breaker path (brief §6.10): if the
  LLM is unavailable, errors, or produces an invalid/illegal intent, fall back to a simple
  scripted policy inside the same information boundary. This is required, not optional.

### 5.4 Enemy pro-line behavior (`bots/`, `scenarios/`)

- Enemies follow the annotated pro line from the scenario until the observed world diverges
  (player does something different, util blocks them). Then pick an authored reactive branch,
  else a simple heuristic. This is the only "prediction" in the system and it is a prior, not
  a claim about what the real pros would do. Label adaptations "pro-inspired adaptation."

### 5.5 Scenario runtime and data (`scenarios/`, `validation/`)

- `scenarios/<scenario_id>.json`: the executable scenario. **You** author this from Person
  3's verified `annotations/<scenario_id>.md` notes (per `VIDEO_ANNOTATION.md`). Extend the
  shape Person 1 used in `world/maps/test_room.json` (regions, spawns, spike) with: schema
  version, map, side, round context (time left, spike state, economy, per-actor weapon/util),
  per-actor start region, and a baseline action timeline + at least one reactive branch.
- `validation/`: a scenario validator (reachability, region IDs real, util references exist,
  branch weights sum to 1, baseline dry run). Keep `validation/comms_validator.gd`.
- The fairness/leak checks remain yours to own with Person 3 (brief §6.12): evidence the bot
  used must be a subset of what it could have observed by that tick; moving an unseen enemy
  with all allowed inputs fixed must not change the decision. **With a non-deterministic LLM,
  you prove this against the recorded prompt/decision log Person 3 produces, not by
  re-running** (you cannot replay a non-deterministic model to the same output).

## 6. Build against fixtures first (because bots/regions do not exist yet)

Do not wait for Lotus B. The brief and your existing tests already use synthetic fixtures.
Build perception, executor and enemy behavior against the synthetic coverage fixture you
already have (`scenarios/synthetic_coverage.json` on your branch) and Person 3's
`examples/person3_fake_run.json`. Integrate with the real sandbox when Person 1's Lotus B
regions and the bot spawner land.

## 7. What to do first (ordered)

1. Read `callout_trainer_brief.md`, `AGENTS.md`, `docs/TEAM.md`, `docs/DECISIONS.md`,
   `docs/COMMANDS.md`, `docs/VIDEO_ANNOTATION.md`, and this file.
2. Agree with Person 1: who adds **bot spawning** and the **Lotus B regions/markers**, and
   the exact region IDs. Freeze those IDs with Person 3 too (the LLM needs the same names).
3. Confirm with Person 3 the **intent contract**: what the LLM emits as a teammate goal, and
   the **decision-log format** (you need it for the fairness proof).
4. Build the bot scene + spawner and the intent executor against fixtures.
5. Add perception + hearing + reaction delay feeding `observation_inbox.gd`.
6. Add the enemy pro-line + one reactive branch once Person 3 delivers the annotated notes.
7. Keep the deterministic fallback planner as the circuit breaker.

## 8. Hard rules (do not break)

- Fairness boundary: policy/LLM sees only copied delayed observations, own state, local
  beliefs, allowed public signals. No live nodes, no hidden transforms, no truth singleton.
- No client access, no ripped assets, no replay-file scraping, no paid API, offline-capable.
- Do not invent pro behavior, positions or facts. Reference the VOD by URL/timestamp.
- Do not edit Person 1's main scene or Person 3's files without coordinating in a PR.

## 9. Validation and handoff

- Run `python tools/check_repo.py` for doc/fixture changes.
- Run your Godot tests with the pinned editor (Godot 4.4.1 stable) and report real results;
  mark unavailable checks honestly. Keep automated results separate from manual playtests.
- Update your row in `docs/HANDOFFS.md` with changed paths, interface effects, real
  commands/results, remaining dependency and next integration step.
