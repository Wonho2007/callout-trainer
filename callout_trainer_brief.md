# Callout Trainer: Project Brief

A hand-off document for the three-person team and AI collaborators. Updated for the user-confirmed **Godot** path after reading all seven pages of advice.pdf and the single page of prompt.pdf in Downloads.

**Confirmed:** Godot; three developers; a playable first-person scenario with interactive bots. **Planning defaults:** one greyboxed site and its approaches, a 30-45 second post-plant segment, player plus two teammate bots versus two enemies, one rifle, smoke and flash, quick-call input, offline desktop build. The 24-hour budget comes from the earlier brief; confirm the actual deadline. Map, clip, team names, and judging hardware remain open.

**Product:** a callout practice teammate. Reconstruct a pro round's starting situation and baseline plan; let the player take over one role; show how communication changes teammate beliefs and decisions. After player intervention, the continuation is an approximate tactical simulation, not a prediction of what the actual professionals would do. Read the whole document before writing code.

> **Authoritative direction update, confirmed by the user in this session (November 14, 2026):** adopt the newer Person 2/3 handoffs from Person 3's `b078210`. These decisions supersede conflicting older requirements throughout this brief:
> - Player communication is **voice only**. Quick-call code remains a deterministic test/fallback helper, not the player UI.
> - A free, local, pretrained LLM interprets speech and chooses teammate goals using only copied, available bot-local information. Ground it in the agreed vocabulary; do not train a model. Person 3 owns this core. Person 2 validates/physically executes goals, with the existing deterministic planner as the required circuit breaker.
> - **No speaker trust model:** use hedge-only testimony strength. Preserve the existing empty `trust: {}` snapshot key until a coordinated contract change.
> - Grading/debrief and belief-only counterfactual are **deferred**, not cut, until voice-to-reaction works. Do not prioritize their older milestone order over the playable comms loop.
> - Person 3 supplies verified VOD notes; Person 2 converts them to executable scenarios. The proposed FNC/PRX Lotus source label in the new handoffs still needs an exact verified VOD/year/round/timestamp before any pro reconstruction. Continue synthetic integration meanwhile.
> - The model machine is a capable PC with a discrete GPU, specific machine **TBD**. Record actual latency and model configuration; do not assume hardware from an older handoff.
> - Audit nondeterministic LLM decisions using the actual recorded context/prompt/output. Keep deterministic dependency, availability and hidden-state perturbation tests as additional checks.

---

## 0. How to use this document

- Treat sections 4 (constraints), 6 (components), and 7 (evaluation) as requirements. Treat section 9 (build plan) as the recommended order.
- Anything marked **ASSUMPTION** or **PLACEHOLDER** is a guess that the team has not confirmed. Do not present it as fact. Flag it and ask, or pick a sensible default and say so.
- Section 12 lists decisions that are still open. Ask about those before building the parts they affect.
- Do not invent data, citations, or Valorant facts. If you need a fact about the game, use the data sources in section 4 or ask the team.
- Bot logic, belief math, and the comms layer should be deterministic given a random seed and the logged inputs. The 3D physics and the human player's inputs will not reproduce bit for bit across runs, so the counterfactual replay is designed around recorded inputs and snapshots (see 6.11).
- Write the leak test (section 6.12) before the bots. It is the project's integrity check.

---

## 1. Context

### 1.1 The event

The team is entering **DevHacks 2026**, Riot track 1, prompt "Gameplay bots: agents that play and adapt". The time frame is 24 hours. The team has **3 developers**, confirmed by the user; this is separate from the number of bot teammates. The game is a **3D first-person recreation** where the player directly controls the character (see 6.3). The user has confirmed Godot 4 and a three-person development team; section 9 assigns the work.

### 1.2 The prompt (paraphrased; checked against prompt.pdf, page 1)

Explore a new role for AI gameplay bots in Riot's games. Choose a player or development need and define an experience around it. Decide what the bot should contribute, how it should adapt, and why someone would use it. The prompt's table asks for:

- **Who it helps:** players practicing together, and designers exploring bot behavior.
- **Build:** the bot, plus a small environment where its decisions can be observed.
- **Show:** the bot handling a new situation, and how that helps its user.
- **Demo:** bot, then scenario, then behavior trace.
- Reminder in the prompt: a bot's value depends on its role, not just its win rate.

### 1.3 The mentor's judging rubric and advice (paraphrased; checked against advice.pdf, pages 1-7)

The mentor's deck is explicitly a draft and invites pushback. Key points:

- **Limited value:** a bot that moves or wins with no player need behind it, or generated code or a chain of agents with no clear development problem.
- **High value:** a real unmet need and an original role or workflow that changes how people practice, play together, design, or build.
- **Credible evidence:** a comparison against a simpler bot or the current workflow, a verified change, and what it saves.
- **The 2026 bar:** hooking an agent up to an engine, or making an NPC chat, is only the starting line. The mentor wants to see what you do after that.
- **Learned bots break in new ways.** Suggested safeguards: out-of-distribution detection, action entropy as a health signal, and circuit breakers that hand control to a simpler system.
- **Game scripts talk to humans.** Data-driven definitions, and anything generated, should pass a simulation before anyone trusts it.
- **Where the LLM goes.** Use it to talk, remember, and explain. Keep fast decisions in a behavior tree or small policy. Hierarchical control (slow planner sets goals, fast controller acts) is recommended.
- **Fairness.** Limit what the bot knows and how fast it reacts. Fog of War already works out what each player can see, so a bot can play by the same rules. Potentially visible sets make visibility checks cheap.
- **Measure transfer, not win rate.** The mentor's recurring stat: Riot found that co-op against AI did not improve new players' PvP win chances regardless of how many games they played. Suggested methods: behavior cloning from human play, and A/B tests with a holdout group so transfer can be measured.
- Self-play agents are known to coordinate badly with humans (Overcooked research).

Some factual claims in the mentor deck (engine versions, a specific on-device model size, specific patch notes) have **not** been independently verified. Do not repeat them in the pitch unless the team verifies them.

---

## 2. The pitch

> **A practice teammate for callouts.** It only knows what it saw, heard, or was told. You speak to it, and its decisions show what your comms changed about the team's picture of the round.

### 2.1 One-paragraph description

Players pick a pro-style scenario (first target: a post-plant retake). The scenario is rebuilt as a small first-person 3D recreation and populated with bots. The player controls the character directly, aims, shoots, uses utility, and plays the round out as if it were a real round, and must communicate. Teammate bots are **information-limited**: each keeps its own belief about where enemies are, built only from what it saw, heard, or was told, tagged with where each fact came from. The system grades the player's callouts against simulation ground truth (precision, recall, latency, and how much each callout reduced the team's uncertainty). After each run, a debrief replays ground truth next to what each bot believed, and reprocesses recorded observations with a useful omitted callout to show the difference in beliefs. Recomputing combat outcomes is an approximate stretch feature, not a core promise.

The bots are not the product. The measurable improvement in the player's communication is.

### 2.2 Why this fits the rubric

- **Unmet need and workflow change:** practicing comms today means scrims or watching VODs. Neither gives instant, graded feedback on callout quality.
- **Beyond NPC chat:** the novelty is grading, trust modeling, a communication budget, and counterfactual replay, not talking.
- **Credible evidence:** a VOD-only arm (the current workflow, which doubles as a holdout), silent bots, chatty bots, and the full system, plus a transfer test with a human teammate.

---

## 3. Research motivation (use as motivation, not proof)

All of these are preprints or reports from other domains. Frame them as inspiration and say so. Verify details before citing in a pitch.

- **Dialogue is not free.** A May 2026 preprint (arXiv 2605.12920) added a dialogue channel for partially observing embodied agents. Dialogue reduced action conflicts but lowered task success compared with silent coordination. Domain: household robotics. This motivates the comm budget and the silent-bot arm.
- **Agents trust badly.** Epistemic Context Learning (arXiv 2601.21742) reports that multi-agent LLM systems tend to blindly conform to misleading peers, and that history-aware trust helps. A study on trust under pressure (SSRN abstract 6759863, May 2026) reports "trust scarring": agents keep verifying or excluding a partner long after the partner becomes reliable. This motivates the asymmetric trust model, which is a **hypothesis** for human learners, not a proven benefit.
- **Auditable beliefs.** A paper on auditable belief updates (arXiv 2610.38869) frames belief as evidence-based commitments guiding action and argues for auditing how they update. This motivates provenance-tagged beliefs and the leak test.
- **Discretized pro-data simulators work.** DECOY (arXiv 2509.06355) simulates CS:GO using only movement decisions as tactical positioning, without modeling aiming or shooting, and reports replays that closely match real games. This motivated an earlier 2D design. The team has since chosen full 3D, so DECOY now informs only the callout-region belief graph, not the game itself.
- **Imitation of pro movement.** "Learning to Move Like Professional Counter-Strike Players" (arXiv 2408.13934) and "Human-like Bots for Tactical Shooters Using Compute-Efficient Sensors" (arXiv 2501.00078, a VALORANT-like 2v2 game) show imitation-based human-like bots and evaluation recipes (human evaluation, Jensen-Shannon divergence between bot and human behavior distributions).
- **Counterfactual feedback exists in coaching.** A 2026 preprint (arXiv 2607.00190) and commercial tools offer what-if analysis on recorded matches. The team found no tool that grades callout quality, but cannot prove none exists. Do not claim "first".

---

## 4. Hard constraints

### 4.1 Platform and legal

- **Do not read or touch the Valorant game client or its memory.** Everything runs in this standalone simulator. advice.pdf p2 reports blocked memory access, but dates and approval deadlines in earlier drafts are unverified; do not repeat them as established facts.
- **Do not scrape or parse game replay files.** Manually annotate public video as reference. This project constraint does not require making claims about current replay policy.
- **Not affiliated with Riot.** Include a disclaimer in the app. Use the community minimap and VOD footage only as authoring reference for the blockout. Do not commit or ship them (**ASSUMPTION: safer, confirm with the event rules**). **Do not extract or rip assets from the game client or its files**; the legal status is unclear. Ask the organizers whether any official assets are available for the event.

### 4.2 Free to build

Everything must be buildable and demoable for free. No paid APIs are required. Optional components (LLM parsing) must have a free or local option and a deterministic fallback.

### 4.3 Data sources

- **Map, agent, and ability data:** valorant-api.com, a community-run content catalog (not an official Riot API). It exposes maps with coordinates, callouts, and minimap images, plus agents, abilities, and weapons.
- **Scenario lines:** hand-annotated from public VCT VODs on YouTube. The official Valorant Data Portal (Riot and GRID) provides map-coordinate round data, but it was built for pro teams first. Do not assume access.
- **Optional priors:** public aggregate stats (map pick rates, round outcomes, economy habits). Community scrapers of vlr.gg exist, are unofficial, and must be rate-limited. Use sparingly.

---

## 5. System overview

```
 Scenario JSON  ->  Validator (sim feasibility)  ->  Scenario loader
                                                         |
 3D map: greybox + callout regions + belief graph ------+
                                                         v
        +--------------- 3D game core (fixed timestep, seeded bot RNG) ----------------+
        |  true world state: positions, hp, utility, spike, time                       |
        |                                                                              |
        |  Perception (raycast LOS, smoke/flash, sound, reaction delay)                |
        |        |                                                                     |
        |        v                                                                     |
        |  Per-bot observation log  [saw | heard | told], timestamped, provenance      |
        |        |                                                                     |
        |        v                                                                     |
        |  Per-bot belief over enemy positions  <---- Trust model (tau per speaker)    |
        |        |                                       ^                             |
        |        v                                       |                             |
        |  Planner (slow, event-driven) -> Controller (fast)       Callout parser <-- speech/text
        |        |                                                  (say again? if unsure)
        |        v                                                                     |
        |  Comm budget -> bot callouts (only from own observation log)                 |
        +-------------------------------------------------------------------------------+
                 |                                   |                         |
                 v                                   v                         v
         Safety valves                      Callout grader            Behavior trace + leak test
   (OOD, entropy, circuit breaker)    (precision, recall, latency,        (JSON log)
                                       information gain)                         |
                                                 \                               |
                                                  v                              v
                                        Debrief UI: truth vs belief timeline + counterfactual re-run
```

---

## 6. Components

### 6.0 Godot implementation and playable-round model

Use one shared **Godot 4 desktop project**. Pin the same stable editor version and matching export templates at kickoff. Typed GDScript and the Compatibility renderer are planning defaults to reduce tooling and demo-machine friction; test the actual build on the target machine. No multiplayer backend, paid plugin, or runtime API connection is required.

| Need | Godot implementation | Owner |
|---|---|---|
| Site and approaches | Primitive/CSG greybox, static collision, cover and elevation | Person 1 |
| Actors | CharacterBody3D, player Camera3D, shared movement/weapon/damage rules | Person 1 |
| Navigation | NavigationRegion3D and baked NavigationMesh; NavigationAgent3D supplies paths and actor controller moves the body | Person 1 bakes; Person 2 consumes |
| Callout regions | Named Area3D volumes, shared registry, travel-time graph and unknown fallback | Person 1 |
| Perception | Physics ray queries, FOV, smoke intersections, flash status, sound events and reaction delay | Person 2 |
| Bot behavior | Event-driven state machine or small behavior tree; slow planner and fast controller | Person 2 |
| Communication/debrief | Control UI, structured callouts, beliefs/trust, grader, timeline/heatmaps and trace | Person 3 |
| Logs | Tick-indexed JSONL events and snapshots in user://runs/; private truth separate from bot observations | Person 3 defines; all emit |

**Reconstruction workflow:**

1. Choose a public pro-round clip with action concentrated around one site. Person 1 recreates the relevant layout and sightlines; Person 3 watches and annotates the starting situation, observed actions, uncertainty and communication opportunities; Person 2 converts those notes into executable baseline actions and reactive branches.
2. Start inside the round at a decision point, with the spike already planted. The player replaces one participant. Label reduced player counts and missing positions as simplifications.
3. Baseline steps have goals, earliest times, deadlines, observation-based guards, and fallbacks. Example: hold angle -> receive delayed entry sound -> reposition -> see opponent -> engage. Do not force actions at VOD timestamps after a bot dies or loses vision.
4. When observations no longer fit the baseline, select an authored reactive branch: cover a changed entry, hold behind smoke, or defend the spike. Guards use available observations, beliefs, own state and explicitly public round signals, never hidden enemy coordinates.
5. Default first slice: 30-45 seconds, one site, two allies and two enemies, one rifle, smoke, flash and defuse. Additional weapons, full agent kits and full-map play are outside the first milestone.

Fixed physics ticks, independently seeded bot RNG, and a consistent observation/belief/planning/action/logging order support repeatable policy tests. Log settings, seeds and tick numbers. Do not promise bit-exact physics or automatic reconstruction from video.

#### Agent-led sandbox construction and minimal editor work

The team has no game-engine experience and intends to develop mainly through coding agents. Use Godot as the runtime and build the initial greybox from code and map data. Humans focus on running, inspecting and playtesting rather than manually placing each wall.

**Person 1's approach:** a small bootstrap scene loads world/sandbox_builder.gd and world/maps/test_room.json. Map records define wall/cover dimensions, positions, named regions and spawn markers. The builder generates visible geometry and matching collision, then prepares navigation from the same geometry. Keep static map data separate from Person 2's round/scenario JSON. Rebuild/reset without duplicating generated objects. Validate IDs, dimensions, clear spawn positions and navigable routes; collision and navigation are separate systems.

Use reusable player and bot scenes rather than one giant procedural script. Proposed paths: scenes/main.tscn and scenes/player/player.tscn (Person 1), scenes/bots/bot.tscn (Person 2 using Person 1's actor components), and ui/debug/ (Person 3 with data from the other lanes). Show regions, navigation, bot goals and available observations in debug views, without leaking privileged debug data into policy.

**Implementation order:** empty synthetic room with movement/collision/reset -> one teammate and one enemy separated by cover -> quick-call changes delayed observation, belief and watched angle, with an evidence trace -> shared combat/smoke/flash/defuse -> source-derived site blockout. Keep the first communication moment small: three regions and one enemy visible to the player but hidden from the teammate. These are development stages, not cuts to the final requirements.

**Who interacts with Godot:** agents create scenes/scripts/data/settings and run available checks; one teammate initially installs/opens the pinned editor and confirms launch on the target machine. Humans learn opening/importing the project, run/stop, scene tree/Inspector, error panel and collision/navigation debug views. Advanced modeling, animation and shaders are unnecessary for this prototype. Map changes can be requests such as moving cover or widening a doorway, implemented as data edits.

**Playtest loop:** agent changes one feature -> automated checks -> human playtest -> concrete feedback. Humans must judge mouse/movement feel, cover/sightlines, stuck bots, sensible callout responses and the exported build. Headless startup does not establish rendering, input or playability. Record automated commands/results separately from manual checks and never mark an unperformed playtest as passed.

Agent autonomy depends on access to files and the Godot executable; GUI inspection also depends on available tools. If an agent cannot launch or inspect the game, it documents exact commands and manual steps for a teammate. No promise of zero editor interaction or a fixed automation percentage. Assign short tasks with explicit acceptance criteria, not a single request to build the whole simulator.

The repository's docs/AGENT_WORKFLOW.md gives the detailed sequence, ownership, beginner workflow and first-task prompt. This section is self-contained for readers of the standalone brief.

### 6.1 Scenario database and validator

Scenarios are JSON files in the repo. A real database adds nothing at this scale.

```json
{
  "id": "retake_01",
  "map": "<map name from valorant-api.com>",
  "situation": "post_plant_retake",
  "source": { "vod_url": "<url>", "timestamp": "<mm:ss>", "annotated_by": "<name>" },
  "round_state": { "time_left_s": 40, "spike_site": "<callout>", "spike_planted": true },
  "player": { "team": "defenders", "agent": "<agent>", "start": "<callout>", "hp": 100, "utility": ["<ability>"] },
  "teammates": [ { "id": "t1", "agent": "<agent>", "role": "<role>", "start": "<callout>", "hp": 100 } ],
  "enemies": [
    {
      "id": "e1", "agent": "<agent>", "start": "<callout>", "hp": 100,
      "scripted_line": [ { "t": 0, "at": "<callout>", "action": "hold" } ],
      "branches": [ { "id": "b1", "weight": 0.6, "line": [ ] } ]
    }
  ],
  "branch_weights_source": "annotation | public_stats",
  "recorded_outcome": "<what happened in the VOD>"
}
```

Extend the example JSON with schema version, seed, coordinate convention, clip start/end timestamps, annotation uncertainty, simplified player slots, and baseline steps containing goal region, action, time window, observation guard and fallback. At least one authored branch must handle a changed entry or smoke. Hidden source positions remain private loader/evaluator data, not policy inputs.

**Annotation ownership:** Person 3 owns source-video notes in annotations/. Person 2 owns conversion to executable scenarios/ and validation. Person 1 owns map geometry and markers. The repository's docs/VIDEO_ANNOTATION.md defines the annotation template and handoff; source observations, inferred facts and authored alternatives must remain distinguishable.

The **validator** is a script that must pass before a scenario is accepted:

- Every `at` and `start` value is a real callout region on the 3D map.
- Every move in every line is reachable in the available time (NavMesh path length divided by movement speed).
- Claimed lines of sight are consistent with raycasts between the relevant region sample points (run in the editor).
- Branch weights sum to 1.
- Every ability referenced exists in the ability definitions file and passes its own scripted-scene tests (6.3).
- Run an authored stand-in for the player in the baseline dry run and validate movement, timing and tactical sequence. Record whether the source outcome occurs. Simplified combat need not reproduce a pro result; flag discrepancies and label the scenario as an adaptation rather than claiming an exact replay.

### 6.2 The 3D map, callout regions, and the belief graph

- **Geometry:** a **greybox blockout** (simple boxes and ramps, no art) of one site plus its approaches, built by hand using the community minimap and VOD footage as reference. Match layout, sight lines, and rough scale, not looks. Budget real time for this (section 9) and keep the area small. Do not extract game assets.
- **Callout regions:** each map callout from valorant-api.com becomes a named trigger volume placed on the blockout. Any world position maps to at most one region (or none). The player's vocabulary, the bots' vocabulary, and the belief space are this same set.
- **Belief graph:** regions are the nodes of the belief space `X` (6.5). Edge travel times come from NavMesh path lengths between region centers divided by movement speed.
- **Navigation:** a NavMesh baked on the blockout for all bot movement.
- **Visibility:** actual sight checks use raycasts against the 3D geometry (6.4). In addition, an editor script bakes a coarse region-to-region visibility table `V[x][y]` by raycasting between sample points in each region. At runtime the table lets a bot cheaply work out which regions it can currently watch (needed for negative evidence in 6.5) without raycasting every region every tick. This table is only a candidate filter: negative evidence needs current visible-coverage checks, including partial cover and dynamic smoke; seeing part of a region does not clear all of it. This is the potentially-visible-set idea from the mentor's advice.
- **Sound:** a radius per action type (running footsteps, gunshots, ability use, spike defuse), attenuated by NavMesh path distance rather than straight-line distance. Walking slowly and crouching are quiet. **ASSUMPTION:** values are tuned by feel in playtest.

### 6.3 3D game core

**Team decision: a 3D first-person recreation. The player directly controls the character and plays the round as if it were a real round: moves, aims, shoots, uses utility, and defuses.**

- **Engine:** Godot 4, confirmed. Single-player desktop, no networking. Pin a stable editor/export version and measure performance on the actual demo machine.
- **Player controller:** first-person mouse look, walk (quiet), run, crouch, jump, weapon switch. Use CharacterBody3D with move_and_slide() for the player and all bots, which keeps movement predictable and loggable. Use a minimal controller in the project or a verified permissively licensed Godot starter.
- **Weapons:** hitscan with a spread model (spread grows while moving and firing; recoil kept very simple). Start with one rifle; a pistol and weapon switching are optional extensions. Take damage per body part, fire rate, and magazine size from valorant-api.com weapon data where available, otherwise use documented placeholders. Armor and health are simple counters. Reload and swap times are placeholders.
- **Utility, data driven:** abilities are defined in a JSON definitions file built from three primitives, not hand-coded per agent:
  1. `los_blocker`: a volume that blocks vision raycasts for a duration (smoke-like).
  2. `blind`: a short effect that blinds any agent (player or bot) with the source in view, with duration scaled by how directly they look at it (flash-like).
  3. `area_damage`: a zone that damages agents inside it over time and can deny the spike area (molly-like). **Stretch.**

  Do not try to replicate agent kits exactly. Map the scenario's abilities onto these primitives and say so in the app. Each definition has tests that run in a scripted scene (the "pass a simulation first" rule from the mentor's advice). Bots use the same definitions and rules as the player, and abilities occlude and blind bots through the perception system (6.4), not through special cases.
- **Spike and defuse:** the spike is already planted at scenario start. Defusing is a hold-to-defuse interaction with a placeholder duration. The round ends on defuse, spike detonation (timer), or the defending team being eliminated.
- **Scenario size (planning default):** the player plus 2 bot teammates against 2 bot enemies, not a full 5v5. This is a deliberate cut for the 24-hour limit. Bot counts are scenario parameters, so scaling up later needs no code changes. Confirm in section 12.
- **Determinism, honestly stated:** the world uses a fixed timestep, bot logic uses a seeded random number generator, and bots move with kinematic controllers, so bot behavior is repeatable given the same inputs. The human's inputs and engine physics will not reproduce bit for bit. All human inputs, bot states, and events are logged every tick, and that log is what the debrief and counterfactuals (6.11) use.
- **Out of scope:** exact Valorant movement and recoil feel, exact agent kits, art quality, netcode, anti-cheat, other maps, ranked-style economy.

### 6.4 Perception, reaction delay, and provenance

Each bot has an **observation log**. Every entry has: `{id, t_event, t_available, source: seen|heard|told, speaker, content, confidence}`.

- **Seen:** raycasts from the bot's eye to several sample points on a target (head, torso, feet) within the bot's field of view (**PLACEHOLDER** angle) and range. Smoke volumes and geometry block rays, and a flashed bot sees nothing. A target must stay visible for a minimum exposure time, shorter at close range, before the sighting is logged (a cheap model of recognition time).
- **Heard:** within the sound radius of an action (6.2).
- **Told:** a parsed or menu-selected callout from the player or a teammate bot.
- **Reaction delay (fairness):** an event becomes available to the bot's planner and aim controller only at `t_available = t_event + d`, where `d ~ D` is sampled per bot per event. `D` is a documented PLACEHOLDER chosen conservatively (a few hundred milliseconds) and tuned in playtest. State the numbers openly.
- **Aim model:** a bot's shots use the same weapon model as the player's, with an aim error that starts large when a target appears and shrinks over time on target, plus tracking error when the target strafes. These knobs decide whether fights feel fair. PLACEHOLDER values, tuned by playtest.

Bot policy reads only delayed observations, beliefs, own actor state and an explicit public-round-signal allowlist. It cannot read other actors' live transforms. Perception may query the world; the physical executor resolves collision and shot hits without leaking targets back into policy. Graders and debriefs read truth outside the policy input path.

### 6.5 Belief model

Let `X` be the set of callout regions. Each bot keeps, per enemy slot, a belief `b_t(x)` over where that enemy is. Prediction uses a movement model `T(x | x')`; the first version can be a simple stay-or-move-to-neighbor model weighted toward the scenario prior.

$$b_{t+1}(x) \;\propto\; \Big(\sum_{x'} T(x \mid x')\, b_t(x')\Big)\, P(o_t \mid x)$$

Observation likelihoods:

- **Seen** enemy at `x`: near-deterministic (a small noise term).
- **Heard** at distance class `d`: a likelihood concentrated around regions consistent with that sound.
- **Told** a report `r` from a speaker with trust `tau`:

$$P(r \mid x) \;=\; \tau\,\mathbb{1}[r = x] + (1-\tau)\,\frac{1}{|X|}$$

**Negative evidence.** For every region a bot is currently watching (inside its view cone, with a clear line per the baked visibility table, and not smoked), if it sees no enemy there, belief in that region is multiplied by a factor below 1 (the chance it would have spotted an enemy there, a PLACEHOLDER) and then renormalized. Absence of a sighting is evidence.

A callout is **testimony, not ground truth**. It moves belief in proportion to trust and never sets it directly.

### 6.6 Comms in: natural language, commands and clarification

**Updated user direction:** accept flexible tactical language repeatedly throughout play, including enemy reports, utility requests and coordinated swings. "Swing with me" and "let's peek together" normalize to the same action. "Three, two, one, swing" shares that action but has cue-based timing, not identical execution timing.

1. **Input:** desired push-to-talk speech plus mandatory quick-call fallback. Build against typed transcripts first. Person 3 implements transcription/interpretation and context; provider/model remains open, with no mandatory paid API. A keyword-only vocabulary is insufficient for the desired natural-language behavior, but deterministic aliases/menu remain fallbacks.
2. **Selected interface:** comms.v1 messages have message_id, speaker_id, recipient_id, issued_tick, expires_tick, kind and payload. Full rules are in docs/COMMANDS.md with schemas/comms_v1.schema.json and examples/comms_v1.json. Model output cannot assign trusted timestamps, invent coordinates or directly operate actors.
3. **Initial intents:** report_enemy (region/count/hedge), throw_flash (authored flash target), swing_together (authored entry). Reports update beliefs without interrupting actions. Commands are validated/executed by Person 2 using Person 1's shared mechanics; cue/cancel messages manage coordination.
4. **Timing:** follow_player uses permitted nearby movement observations; now still respects reaction delay; on_cue stages and waits for a ready acknowledgment and explicit go cue. Do not wait for an LLM on the final countdown release path or claim retrospective synchronization from a completed transcript.
5. **Clarification:** ambiguous "that smoke" or entry references require a question, never guessed coordinates. Interpretation receives conversation/static vocabulary and permitted observations, never hidden ground truth.
6. **Lifecycle:** validate recipient, IDs, expiry, reachability, actor state and utility. Emit accepted/ready/executing/completed or a specific rejection/failure. New feasible commands can supersede interruptible ones; committed throws cannot be undone; repeated IDs cannot repeat actions. Continue consuming reports during actions.
7. **Fairness and measurement:** messages become delayed told observations, and decisions cite available evidence. Language understanding is separate from trust in reports. Keep transcripts, normalized messages, status/results and timing for evaluation without feeding private logs into policy.

### 6.7 Trust model

Each bot keeps `tau` for the player (and optionally for teammate bots). After each callout is confirmed or refuted by that bot's later available observations within an explicit expiry window (otherwise leave it unresolved; an enemy moving away does not prove a call false):

$$\tau_{t+1} = \tau_t + \eta\,(a_t - \tau_t), \qquad \eta = \begin{cases} \eta_+ & a_t = 1 \\ \eta_- & a_t = 0 \end{cases}, \qquad \eta_- > \eta_+$$

where `a_t = 1` means the callout was confirmed correct. Wrong calls cost trust quickly and trust returns slowly ("scarring").

- PLACEHOLDERS: `tau_0 = 0.7`, `eta_+ = 0.1`, `eta_- = 0.4`. Tune in the scripted-player pilot (section 7.3).
- **Control condition:** symmetric trust (`eta_+ = eta_-`). The asymmetric version is a hypothesis and must be tested against it.

### 6.8 Bot decisions (hierarchical)

- **Slow planner**, event-driven plus a slow heartbeat (every 1 to 2 seconds, **PLACEHOLDER**): reads the bot's belief and role and picks a goal region and stance (hold an angle, rotate to a region, trade a teammate, peek, cover the defuse, throw utility at a region at a given time). Rule-based or behavior-tree first. An LLM is optional and only for phrasing or explanation, never for fast decisions.
- **Fast controller:** moves along the NavMesh toward the goal, handles peeking and cover, aims and shoots with the aim model (6.4), reloads, and executes planned utility throws, all subject to reaction delays. This is the riskiest module in a 24-hour build because fights must feel plausible. Keep behaviors few and tuned: hold angle, wide peek, jiggle peek, fall back, cover the defuse.
- **Enemy bots, "predicting what players would do":** follow the scenario's scripted line (the prior) until observed events diverge from it. After divergence, they choose among the scenario's annotated branches, weighted by annotation or public stats, and fall back to a simple heuristic policy when no branch fits. This is the only "prediction" in the system, and it is honest about being a prior.

### 6.9 Comms out and the comm budget

- Bots speak **only from their own observation log**, never from the world state. Relays are marked as relays ("you said B main").
- A bot speaks only if the expected information gain of the message exceeds the cost of occupying the channel:

$$\text{speak} \iff \mathbb{E}[G_m] \;>\; \lambda\, c_m$$

where `c_m` grows with message length and `lambda` is a tunable weight. Add a hard rate limit and a cooldown, and never talk over the player (the channel is busy while the player is speaking).

- The wording is template-based. Hedged language reflects belief strength ("one B main, I think").

### 6.10 Safety valves

These are required, and they appear in the demo trace.

1. **Out-of-distribution (OOD):** if a bot's available observations and beliefs match no authored branch for a documented window, it drops the script and uses the simple heuristic policy. Privileged positional divergence can be logged by the evaluator, but cannot trigger hidden-information-aware policy. Log the event.
2. **Action entropy:** over a sliding window of enemy action choices, compute

$$H = -\sum_a p(a)\log p(a)$$

Treat entropy as a diagnostic alongside progress and stuck duration: a legitimate hold has low entropy. Do not trigger fallback from entropy alone. Repeated ineffective actions or invalid transitions trigger a conservative fallback with a logged reason.

3. **Circuit breaker:** any invariant violation (leak test failure, NaN belief, parser error rate above threshold, frame or tick budget overrun, a bot stuck or off the NavMesh) freezes the learned or LLM parts and hands control to a plain scripted bot, with a visible banner.
4. **Parser uncertainty:** "say again" instead of guessing (6.6).

### 6.11 Scoring, debrief, counterfactuals

**Callout grading against simulation ground truth.** A callout `c = (type, place, count, t)` is:

- **Correct** if at time `t` an enemy of that kind is truly within `k` graph edges of `place` (default `k = 1`, **PLACEHOLDER**).
- **Wrong** otherwise.
- A **sighting** is a period where the player had line of sight to an enemy. It is **missed** if no matching callout follows within a latency window.

Report:

- **Precision** = correct callouts / all callouts.
- **Recall** = sightings called / sightings.
- **Latency** = median time from sighting to callout.
- **Information gain per callout**, using team-average belief entropy:

$$H_{\text{team}}(t) = \frac{1}{N}\sum_{i=1}^{N} H\big(b^{(i)}_t\big), \qquad G_c = H_{\text{team}}(t^-) - H_{\text{team}}(t^+)$$

where `t^-` is just before the callout and `t^+` is after the bots have processed it (after reaction delay). A wrong callout can still reduce entropy by making bots confidently wrong. Entropy reduction measures uncertainty, not accuracy. Report callout correctness separately and add ground-truth probability or Brier score before/after the callout; do not reward confident errors solely for reducing entropy.

**Debrief UI:**

- A scrubbable timeline with a top-down map overlay drawn from the logged positions: ground truth on one side, each bot's belief heatmap over the callout regions on the other. The game is 3D, but this overlay is only a rendering of the logs, not a second simulation.
- Callouts marked on the timeline with their `G_c` and correctness.
- **Counterfactual, tier 1 (core, cheap, exact):** replay the logged observation streams through the belief model with the callout the player should have made injected at the right time (the one that would have maximized gain, or the one the pro made). Show how team belief entropy and each bot's belief would have differed. This is pure math on logs.
- **Counterfactual, tier 2 (stretch, approximate):** restore the world snapshot at the decision point, replay the player as a ghost from the recorded inputs, inject the callout, and re-run the bots several times with different seeds. Report the share of reruns where the outcome changed (for example "defused in 7 of 10 reruns") instead of a single result. The ghost's aim cannot react to the changed situation and engine physics is not exactly repeatable, so label this an approximate what-if.

#### Clear communication and relevant omissions

**Latest user clarification:** clear team communication is the overall training objective. Readiness/cue coordination is one skill, not the main or only skill. Also coach timely enemy reports, requesting/coordinating appropriate utility before entry, and useful death reports naming the opponent if known and the last-known threat location.

Detect missing information by comparing what the player could reasonably know with what relevant teammates actually received. Score an omission only when the information was available to the player, useful within the scenario's time window, absent from the recipient's usable knowledge, and not already communicated in equivalent natural language. Distinguish player death position from killer location; never demand a hidden shooter identity or exact unseen location. Accept uncertainty and last-seen reports.

Utility requests are situational: require them only in a documented coordination opportunity with feasible utility and no existing adequate plan, not before every entry. Keep the player input channel usable after death so surviving bots can receive reports. Separate absent speech from recognition, interpretation, delivery and execution failures; do not penalize the player when the system dropped a valid report.

The debrief states the missing content, the recipient's information gap, the observed effect if supported, and one actionable retry suggestion. Track eligible-opportunity coverage and information completeness across skills, with readiness as one category. Full rules, ownership and acceptance examples are in docs/COMMUNICATION_COACHING.md; this is a specification, not a completed grader.

The current comms.v1 report supports enemy location/count/hedge but has no explicit identity or death/last-seen fields. Coordinate a versioned extension before adding those to live policy; offline grading annotations can retain them separately.

### 6.12 Logging, behavior trace, and the leak test

Every decision a bot makes is logged with: tick, bot id, planner goal, controller action, and the **ids of the observation-log entries it used**.

**Leak test (write first):** an automated assertion that for every logged decision, the set of evidence ids is a subset of that bot's observation log at that tick, and that hidden world state never reaches policy outside the perception boundary. Privileged world, physics executor, grader and replay modules may use truth without exposing it to policy. Run it in CI and on every demo run. The target is 100% pass. In code, give bots access to the world only through one perception interface, and fail the build if bot code references world-state objects directly (a dependency/lint check). In Godot, policy must not use scene-tree lookups, truth singletons or live target Node references; pass copied observation values and target IDs. Add a hidden-state perturbation test: identical allowed inputs produce identical decisions even when unseen enemies move. Evidence membership or text search alone is not a complete proof. This is the fairness proof for judges.

The behavior trace shown in the demo is this log, rendered: what each bot saw, was told, believed, and did.

---

## 7. Evaluation plan

Be honest about scale: with a handful of friends this is a **pilot**. Do not claim win-rate improvements or statistical significance. Report direction and effect sizes.

### 7.1 Arms (all must exist)

| Arm | Description | Role |
|---|---|---|
| A. VOD-only | Participant watches the pro VOD and an annotated explanation | Current workflow, and the holdout |
| B. Silent bots | Bots use player comms but never speak | Tests whether bot talk helps at all |
| C. Chatty bots | Bots report everything they see, no budget | Tests the comm budget |
| D. Full system | Comm budget, asymmetric trust, debrief with counterfactuals | The product |

### 7.2 Protocol (per participant)

1. **Pre-test** on an unseen scenario `S_pre` against baseline scripted bots.
2. **Practice** on the practice scenario for a fixed time under their assigned arm, counterbalanced across participants.
3. **Post-test** on an unseen scenario `S_post`.
4. **Human-receiver test (transfer to humans):** on an unseen scenario, a human teammate who cannot see the game receives only the participant's callouts (live voice or the callout log) and, at fixed checkpoints, marks where they think each enemy is on a top-down map. Their marks are scored against ground truth. This tests transfer to humans, the failure mode the mentor flagged for bots trained against bots, and gives a belief measure that does not come from the bots' own model. **ASSUMPTION:** a second person is available. If not, cut it.

### 7.3 Cheap pilot first: headless comms simulation

Running the full 3D game thousands of times is not realistic. Instead, record the ground-truth traces and observation logs from a few full runs (the team can play them), then run the **comms and belief layer headless** on those logs. A script generates synthetic callouts from the true positions with a controllable error rate, miss rate, and delay (a scripted noisy player), feeds them through the structured-callout path, and recomputes beliefs, trust, information gain, and comm budget decisions. Use it to:

- Compare silent vs. chatty vs. budgeted bots by belief entropy and message counts.
- Compare symmetric vs. asymmetric trust.
- Tune `lambda`, `eta_+`, `eta_-`, `tau_0`.

This tests the comms and belief layer, not combat or movement, and it evaluates bot speech by information gain and message rate, not by round outcomes. It produces results even if recruiting humans fails.

### 7.4 Metrics

- Callout precision, recall, and median latency.
- Total team information gain per run.
- Retake success rate.
- **Savings:** attempts and minutes to reach a callout-quality criterion (for example a callout F1 threshold, **pre-registered after the scripted pilot, before human sessions**).
- Leak test pass rate (must be 100%).
- Safety valve activation counts.
- **Stretch:** Jensen-Shannon divergence between enemy bot behavior distributions and annotated pro lines when multiple annotated clips exist.

### 7.5 Known weaknesses and how to address them

- **Circular metric.** Information gain is computed with the team's own belief model, so a judge can say players are graded against the bots. Check it: report the correlation between per-run gain and actual retake success, and compare with the human-receiver marks (7.2) and a human teammate's ratings of callout usefulness.
- **Trust asymmetry is untested for humans.** Present it as a tested hypothesis with a symmetric control, not as a finding.
- **Comm budget motivation is one robotics preprint.** Present as a tested design choice.
- **Ground truth is simulation truth, not pro truth.** Callouts are graded against the simulator, and enemy bots deviate from the annotated line.
- **Small sample.** See the pilot framing above.

---

## 8. Traceability: source PDFs to acceptance criteria

Both source PDFs were read directly. Page numbers are PDF pages. Mentor recommendations become explicit design choices here; they do not require RL training or an LLM. Slide statistics remain unverified outside the deck.

| Source | Acceptance evidence | Owner |
|---|---|---|
| prompt.pdf p1: player need and bot role | Practice callouts; teammate changes its plan using information it could receive | Persons 2/3 |
| prompt.pdf p1: small observable environment | Playable first-person site and visible bot decisions | Persons 1/2 |
| prompt.pdf p1: handle a new situation and help the user | Changed entry or smoke causes an observation-driven branch; useful callout changes coverage | Persons 2/3 |
| prompt.pdf p1: bot -> scenario -> behavior trace | Rehearsed demo in that order, linking observations to actions | All |
| advice.pdf p3: original workflow, credible comparison, verified change and savings | Silent/chatty/full modes and VOD-only workflow; actual callout metrics and measured time/attempts where available | Person 3; all collect runs |
| advice.pdf p4: OOD, entropy and circuit breaker | Branch-miss diagnostic, contextual entropy monitor, stuck/invalid-state fallback with visible reason | Person 2 |
| advice.pdf p5: data definitions pass a simulation | Invalid scenario rejected; smoke/flash tests; baseline dry run | Persons 1/2 |
| advice.pdf p6: slow planner, fast controller, fair knowledge/reaction | Policy boundary, raycast visibility, smoke/flash, reaction delay and leak checks | Person 2; Person 3 audits |
| advice.pdf p7: transfer and holdouts, not win rate alone | Unseen pre/post situations, VOD-only comparison and human-receiver test if feasible; honest pilot framing | Person 3 |

---

## 9. Three-person build plan (24-hour planning budget)

One shared Godot project, three owners, shared schemas. Replace Person 1/2/3 with names at kickoff. Confirm the actual event deadline. This is an ambitious schedule; extra art, speech, LLM integration and outcome counterfactuals are outside the critical path.

### 9.1 Person 1: world, player, and delivery

**Owns:** world/, actors/, weapons/, utility/, scenes/maps/, scenes/player/, main scene, project.godot and export presets. Others request shared settings changes through this owner.

1. Set up the project, input actions, collision layers, main scene, HUD and offline desktop export. Prove a blank export works on target hardware early.
2. Build the JSON-driven sandbox builder and a synthetic test room first; generate matching meshes/collision, named spawns and callout regions. After the communication loop works, replace the room data with one site's relevant cover, elevation, routes and spike position.
3. Build CharacterBody3D movement/mouse look, one rifle, reload, damage, defuse/detonation and round restart. Bots and player share weapon, damage and utility rules.
4. Bake navigation, maintain region registry/graph with the others, and expose movement/action execution adapters without live target access for policy.
5. Implement smoke and flash from shared definitions. Emit footsteps, shots, damage, utility and round events. Test both player and bot effects in scripted scenes.
6. Supply logged-map outlines/region polygons for the debrief. Document reproducible launch/reset/check/export commands, coordinate short human playtests, integrate/export the build, help collect gameplay runs and record the backup video.

**Done when:** the player can finish and restart a retake; navigation/collision match the blockout; smoke blocks sight and flash suppresses vision; the frozen build runs offline.

**Handoffs:** hour 2 test room and actor stubs; hour 6 navigable map/regions; hour 8 combat and utility events; hour 12 complete round.

### 9.2 Person 2: perception, scenarios, and reactive bots

**Owns:** perception/, bots/, scenarios/, validation/, scenes/bots/ and bot/perception tests.

1. With Person 3, define the perception/policy boundary and build the first leak-test fixture before bot intelligence. Develop policy against fake observations.
2. Consume Person 3's verified video annotations and convert the initial state/timeline into scenario JSON, baseline goals/timings, authored reactive guards and fallback. Preserve source timestamps, uncertainties and simplifications; validate feasibility rather than reassigning video annotation to Person 2.
3. Build sight/hearing, smoke/flash effects, seeded reaction delay, observation logs and the coarse region visibility filter.
4. Implement slow planner and fast controller: hold, move/peek, engage, retreat and cover defuse. Track last observed positions instead of hidden live targets.
5. Add baseline script and observation-driven reactive branches. Consume Person 3's belief interface via a stub until ready. Emit decision/evidence records.
6. Build scenario schema/reachability/branch checks, baseline dry run, branch-miss fallback, contextual entropy health signal, stuck/off-nav checks and circuit breaker. Fallback obeys the same information limits.
7. Verify the novel-situation demo, create an invalid scenario for the validator demonstration, and help collect comparison runs.

**Done when:** bots navigate and fight fairly; new available evidence changes their plan; every decision has traceable inputs; hidden-state perturbation leaves policy decisions unchanged; invalid scenarios fail validation.

**Handoffs:** hour 2 perception/action interfaces and leak fixture; hour 6 delayed sight/hearing and hold/shoot; hour 8 baseline plus one reactive branch; hour 12 playable fair bots.

### 9.3 Person 3: communication, evaluation, and explanation

**Owns:** annotations/ (video notes), comms/, belief/, grading/, recording/, ui/debrief/, evaluation/, shared schema definitions and belief/logging tests.

1. Own video annotation: watch the selected public retake segment and record source timestamps, initial actor regions/state, visible actions/utility, uncertainty and communication opportunities in annotations/<scenario_id>.md. Provide early notes to Person 1 for the blockout and Person 2 for scenario scripting. Verify agent-assisted notes manually; never invent off-screen facts or unavailable team comms. Follow docs/VIDEO_ANNOTATION.md in the repository.
2. Define copied-value observation, callout, decision, run and snapshot schemas. Create a fake run and evidence-ID/time checks with Person 2 before bots.
3. Implement per-enemy region beliefs, movement prediction, observation updates, trust/expiry and quick-call UI. Keyword parsing follows only if the core works; speech is stretch.
4. Add silent/chatty/budgeted message modes and symmetric/asymmetric trust settings; keep perception/combat identical across modes. Bot templates speak only from observations.
5. Implement precision, recall, latency, entropy change and belief accuracy against truth. Track message counts, fallback events and time/attempts to criterion. Undefined metrics are unavailable, not zero.
6. Record truth separately from observations; build a scrubbable top-down truth-versus-belief timeline, callout markers and evidence-to-action inspector.
7. Add core belief-only counterfactual replay from fixed observation logs; label it explicitly as not recomputing combat outcomes.
8. Build the headless noisy-callout pilot and VOD-only instruction sheet; reserve unseen pre/post variants, document settings and limitations, coordinate a human-receiver test if feasible.
9. Prepare real comparison results and the bot -> scenario -> trace demo narrative. Ask both teammates to collect runs and help test.

**Done when:** structured callouts change beliefs and behavior; the debrief explains why; all four comparison arms exist; repeatable pilot results are saved; no transfer claim exceeds the evidence.

**Handoffs:** early verified clip notes/starting state for Persons 1/2 alongside hour 2 schemas/fixtures; hour 6 belief/trust/grading on fake logs; hour 8 quick-call and live belief adapter; hour 12 real run recording and basic score end screen. Debrief and counterfactual follow integration.

### 9.4 Shared contracts and integration gates

**Hours 0-2: everyone together.** Select the compact tactical segment and communication opportunity; pin editor/export versions; assign names; agree region IDs, coordinates/scale, tick order, seeds, input actions, collision layers and schemas. Unresolved clip selection must not block a clearly synthetic test room; never pitch that fixture as a pro reconstruction.

| Contract | Producer -> consumer | Minimum content / boundary |
|---|---|---|
| Regions/graph | Person 1 -> Persons 2/3 | Stable ID, name, bounds, center, neighbors, travel time, unknown fallback, version |
| Gameplay event | Person 1 -> perception/private recorder | ID, tick/time, type, actor, position, payload; privileged stream not exposed to policy |
| Observation | Person 2 -> belief/policy | ID, bot ID, event/availability ticks, seen/heard/told, copied content, confidence, speaker/provenance |
| Callout | Person 3 -> delayed comms delivery | ID, speaker, type, region, count, hedge, time; menu/parser/fixture share schema |
| Belief query | Person 3 -> Person 2 | Bot-local enemy-region probabilities, trust and available evidence IDs; no world nodes |
| Actor command | Person 2 -> Person 1 | Bot ID, movement/aim and fire/reload/utility/defuse intent; executor resolves physics |
| Decision trace | Person 2 -> Person 3 | Tick, bot ID, goal/action, evidence IDs, reason, branch/fallback status |
| Run archive | All -> Person 3 | Schema/build/scenario versions, config/seed, inputs/events, snapshots, private truth and per-bot observations |

Use signals and narrow adapters, with restricted bot subscriptions. A global event bus is not permission to read every event.

| Hours | Person 1 | Person 2 | Person 3 | Acceptance gate |
|---|---|---|---|---|
| 0-2 | Project/export/test room; actor stub | Policy boundary/leak fixture | Schemas/fake log/audit fixture | Contracts frozen; forbidden data path fails a test |
| 2-6 | Blockout/collision/regions/navigation | Perception/delay/hold-shoot | Beliefs/trust/grader/recorder | Modules use the same fixtures |
| 6-8 | Rifle/smoke/flash/spike | Baseline and reactive branch | Quick-call/live belief adapter/modes | Callout changes a bot goal in-engine |
| 8-12 | Round/restart and event integration | Integrate combat/navigation; leak checks | Capture real run; score end screen | Full retake playable; leak checks pass |
| 12-16 | Utility tests; map overlay data | Validator/visibility bake/fallbacks | Debrief/trace/belief counterfactual | Bot -> scenario -> trace demo works |
| 16-20 | Export regression; collect gameplay | New-situation tests; help evaluation | Headless pilot and comparison evidence | Actual results saved; modes present |
| 20-22 | Target build; backup video | Final fairness/validator checks | Metrics/limitations/demo rehearsal | Rehearsed offline demo and video |
| 22-24 | Freeze/export/package | Verify frozen build | Submission/evidence bundle | No feature additions |

**Balance:** Person 3 has the heaviest UI/analysis lane and now owns video annotation. Timebox one short clip and deliver early verified notes before polishing UI; Person 1 handles map drawing data, export and demo video; Person 2 owns executable scenario conversion, validation and safety telemetry; both help collect evaluation runs. No optional speech/LLM work while debrief is incomplete.

Merge small changes at hours 2, 6, 8, 12 and 16. Separate scene ownership avoids main-scene conflicts. Shared schema changes require updating fixtures and both consumers.

**Beginner/agent workflow:** Person 1 operates the editor initially; all three supply specific playtest feedback. Assign short, independently checkable increments, keep fake adapters available, and record automated versus manual evidence separately. Follow section 6.0 and docs/AGENT_WORKFLOW.md; do not postpone the communication loop for map polish.

**Hour 8 tripwire:** if a structured callout cannot change a bot goal, pause extra mechanics and integrate the information path. **Hour 12 tripwire:** if the retake is unplayable, shorten routes, reduce enemies to one, simplify aim and keep one reactive branch.

**Cut order:** extra scenarios; combat-outcome counterfactual; speech; LLM parsing; second weapon/weapon switching; area damage; autonomous utility timing (retain scripted smoke/flash); UI polish; human-receiver sessions if recruitment fails; stretch movement metrics. Without unseen human test content and participants, report a synthetic-log pilot only and do not claim transfer.

**Never cut:** player-controlled shooting, smoke/flash, fair perception/delay, leak checks, callout grading, debrief/core belief counterfactual, one new-situation branch, VOD-only workflow comparison, silent/chatty/full modes, scenario validation, visible fallback reasons and backup video.

### 9.5 Demo and evidence package

1. **Bot:** explain the practice need and the teammate's limited knowledge.
2. **Scenario:** identify the source clip and simplified starting situation. Player calls an enemy hidden from a teammate; teammate changes belief and covers the route. A changed entry or smoke demonstrates adaptation.
3. **Behavior trace:** inspect the sighting/callout, availability delay, trust, belief update, chosen action and evidence IDs. Show truth separately and the belief-only counterfactual.
4. Show invalid-scenario rejection or forced stuck fallback and a passing leak report.
5. Show actual pilot metrics and comparison settings. VOD-only human comparisons require participants: if unrun, label them unrun. Report time/attempt savings only if measured.

Package an offline desktop build, controls README, scenario/annotation notes, model/settings card, validator/leak reports, run logs, pilot results, limitations and backup video. Do not bundle reference footage or extracted game assets.

---

## 10. Free stack

- **Engine:** Godot 4, pinned stable editor and matching free export templates. Typed GDScript planning default; no mandatory external packages.
- **World:** primitive/CSG blockout, CharacterBody3D, physics ray queries, Area3D regions, NavigationRegion3D/NavigationMesh and NavigationAgent3D.
- **UI/logging:** Godot Control and 2D drawing; JSON scenarios, JSONL logs. No database.
- **Testing/pilot:** minimal Godot headless runner for pure belief/comms fixtures and replay; scene-based geometry/perception/utility validation. Failed checks exit nonzero; use the same editor locally and in CI.
- **Data:** manual public VOD annotation and documented community catalog data; cache permissible metadata for offline use. Reference footage/images remain authoring aids.
- **Input:** required quick-call menu; optional local speech or model parser after core gates pass, with deterministic fallback.
- **Delivery/assets:** zipped desktop build and backup video; self-made geometry or free assets with verified redistribution terms, credits and non-affiliation notice.

Official Godot implementation references (pin version-specific pages when selecting the editor):

- [CSG level prototyping](https://docs.godotengine.org/en/stable/tutorials/3d/csg_tools.html).
- [NavigationAgent3D](https://docs.godotengine.org/en/stable/classes/class_navigationagent3d.html): supplies paths; actor code performs movement.
- [Navigation meshes](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationmeshes.html).
- [Command-line/headless operation](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html).

## 11. Risks and honesty rules

- Do not claim the system improves win rate, or that results are statistically significant, from a small pilot.
- The 3D first-person scope is the main schedule risk. Say openly that the map is a greybox recreation of layout and sight lines, and that bots, weapons, and abilities are approximations.
- Do not claim to be first, or that no similar tool exists. Say what was and was not found.
- Do not cite the research in section 3 as proof for Valorant. It is motivation from other domains.
- State the reaction-delay distribution, trust parameters, and sound radii as the placeholders they are.
- Do not present the simulator's ground truth as pro ground truth.
- If a component misbehaves, show the circuit breaker in the demo instead of hiding it. That is a feature the mentor asked for.

---

## 12. Confirmed choices and remaining decisions

**Confirmed:** Godot; three developers. Do not reopen engine choice or confuse team size with bot count.

**Scaffolding defaults:** typed GDScript, Compatibility renderer, desktop single-player, one site, 30-45 second segment, two allies/two enemies, one rifle, smoke/flash and quick-call menu. These are scope defaults, not verified Valorant mechanics.

Settle these before building affected content:

1. Names for Persons 1/2/3, operating systems and exact stable Godot version.
2. Map/site, public pro clip, takeover moment/player role, annotation uncertainty, simplified player slots and communication opportunity.
3. Actual event deadline, demo format, target OS/hardware and export requirements.
4. Local callout vocabulary, reference scale, rifle parameters and placeholder utility/defuse timings.
5. Availability of human-receiver/VOD-only participants and unseen pre/post variants.
6. Organizer-provided assets and event redistribution requirements.

Use clearly synthetic fixtures for unresolved content and continue independent scaffolding.

## 13. References

- arXiv 2605.12920, Embodied Multi-Agent Coordination by Aligning World Models Through Dialogue (May 2026).
- arXiv 2601.21742, Epistemic Context Learning: Building Trust the Right Way in LLM-Based Multi-Agent Systems.
- SSRN abstract 6759863, Trust under Fire: How LLM Agents Build, Lose, and Recover Trust in High-Stakes Multi-Agent Coordination (May 2026).
- arXiv 2610.38869, Auditable Belief Updates as a Missing Safety Layer for LLM-Powered Multi-Agent Systems.
- arXiv 2509.06355, A Data-Driven Discretized CS:GO Simulation Environment to Facilitate Strategic Multi-Agent Planning Research (DECOY).
- arXiv 2408.13934, Learning to Move Like Professional Counter-Strike Players.
- arXiv 2501.00078, Human-like Bots for Tactical Shooters Using Compute-Efficient Sensors.
- arXiv 2607.00190, Play Like Champions: Counterfactual Feedback Generation in Latent Space.
- Riot support article, "Game Memory Access Removed for Third Party Apps" (effective 6 October 2026).
- valorant-api.com, community VALORANT content API (not an official Riot API).

Verify any of these before quoting them in a submission.

## 14. Local sources reviewed

- C:/Users/Isoto/Downloads/prompt.pdf, page 1: Riot track 1, Gameplay bots / Agents that play and adapt; user need, observable environment, new situation, bot -> scenario -> behavior trace.
- C:/Users/Isoto/Downloads/advice.pdf, pages 1-7: mentor draft; rubric p3, robustness p4, simulated validation p5, hierarchical control/fairness p6, transfer/holdouts p7.
- These sources ground the design advice. They do not independently verify the research citations, policy dates or product statistics retained as unverified motivation elsewhere in this brief.
