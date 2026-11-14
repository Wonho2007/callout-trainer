# Integration handoffs

Initial state: planning documents and synthetic examples only. No Godot project, tests, bot scenes, gameplay logs or evaluation results exist.

| Lane | Current state | Next deliverable | Blocker / dependency |
|---|---|---|---|
| Person 1 | Not started | Pin Godot version; JSON-driven synthetic room/builder, actor stubs and blank desktop export | Confirm target hardware and shared contracts |
| Person 2 | Not started | Delayed observation interface and leak-test fixture with Person 3 | Shared contracts; use fake world adapter |
| Person 3 | Not started | Freeze schemas; fake run and evidence/time checks | Shared contracts; use synthetic fixture |

Update only the facts for your lane. Append a short handoff using:

- Branch/PR and owning lane:
- Changed files:
- Interface/schema changes and consumers:
- Actual checks run and results:
- Remaining work/dependency:
- Next integration step:

Do not record a check as passed when it was unavailable. The repository documentation check is not the leak test. Keep participant data, raw recordings and secrets out of handoff notes.

## Planning update: agent-led development

The brief and docs/AGENT_WORKFLOW.md now specify code-generated map geometry and short agent tasks for a beginner team. Person 1 starts with the synthetic room; Persons 2/3 integrate the communication fixture before site detail. Separate automated checks from human playtest evidence. No Godot implementation or manual playtest is claimed by this documentation update.

## Product clarification: clear communication across skills

The user selected clear communication as the overall objective, with readiness, enemy reports, utility coordination before entry and useful death reports as examples. Added docs/COMMUNICATION_COACHING.md and aligned the README/brief/decision record. Person 2 supplies delivered-observation/result evidence; Person 3 grades opportunities/omissions and distinguishes parser failures; Person 1 supplies permitted player/death events and post-death input. No runtime/schema fields changed, no cross-lane code edited, and the broader grader is not claimed implemented. Next integration work must preserve player-knowledge limits and accept natural paraphrases.

## Handoff notes

### 2026-11-14 — Person 1: Godot editor version pinned

- Branch/PR and owning lane: `person-1/world-scaffold`; Person 1 (world/player/delivery).
- Changed files: `docs/DECISIONS.md`, `docs/HANDOFFS.md`.
- Interface/schema changes and consumers: none yet. Version pin affects future `project.godot`, export presets and any version-specific API use; relevant to all lanes once the project exists.
- Actual checks run and results: `python tools/check_repo.py` not run locally (Python 3 unavailable on this machine); change is documentation-only with no new markdown links or fixture edits. CI docs workflow will run the check on push.
- Remaining work/dependency: Wonho2007 and sn-kurup must install the same Godot 4.4.1 stable build and confirm; install matching 4.4.1-stable export templates; confirm launch on target hardware. Pin remains a Person 1 proposal until the team confirms.
- Next integration step: create `project.godot`, the JSON-driven synthetic test room (`world/maps/test_room.json` + `world/sandbox_builder.gd`), actor stubs and a blank desktop export.

### 2026-11-14 — Person 1: synthetic test room + first-person player (stage 1)

- Branch/PR and owning lane: `person-1/world-scaffold`; Person 1 (world/player/delivery).
- Changed files: `project.godot`, `icon.svg`, `world/maps/test_room.json`, `world/sandbox_builder.gd`, `scenes/main.tscn`, `scenes/main.gd`, `scenes/player/player.tscn`, `scenes/player/player.gd`.
- Interface/schema changes and consumers: introduces the synthetic map data shape (meters, Y up, `[x,y,z]`, box center + full-extent size) and placeholder region IDs (`region_a`/`region_b`/`region_mid`) and spawn roles. Region IDs/graph and coordinate convention are NOT frozen — to be aligned with Persons 2/3 before freeze (see docs/CONTRACTS.md). `sandbox_builder.gd` exposes `get_spawn(role)` and `map_data`.
- Automated checks run and results: project opens in Godot 4.4.1 stable (Compatibility renderer); builder reports 8 geometry nodes, 3 regions, 3 spawns built from `test_room.json`; `python tools/check_repo.py` not run locally (Python 3 unavailable on this machine) — change is mostly code, docs edits add no new links.
- Manual playtest and results: tester confirmed in-editor playtest — room renders (floor, 4 walls, 3 cover crates), first-person movement (WASD + mouse look), wall/cover collision, walk/crouch/jump, Esc mouse capture toggle, and R restart all work. Not yet tested as an exported build.
- Remaining work/dependency: navigation bake (NavMesh) not yet implemented — separate next Person 1 step; no actors beyond the player; no weapons/damage/smoke/flash/defuse; no desktop export yet. Region IDs pending team freeze.
- Next integration step: bake navigation on the generated geometry (NavigationRegion3D + NavigationMesh), then add actor stubs and a blank desktop export.

### 2026-11-14 — Person 1: navigation bake on generated geometry

- Branch/PR and owning lane: `person-1/world-scaffold`; Person 1 (world/player/delivery).
- Changed files: `world/sandbox_builder.gd`, `scenes/main.gd`.
- Interface/schema changes and consumers: geometry is now generated under a `NavigationRegion3D` and the navmesh bakes from the same meshes. New builder API for Person 2: `navigation_ready` signal + `navigation_is_ready` flag (await before path queries), `query_path(from, to)` (snaps endpoints to the navmesh and returns a `PackedVector3Array`), and `get_region_center(region_id)`. Navigation only supplies paths; actor controllers (Person 2) move bodies — the builder moves nothing. Navmesh agent params (radius 0.4, height 1.8, max_climb 0.4, cell 0.2/0.1) are placeholders to tune in playtest.
- Automated checks run and results: navmesh bakes to 44 vertices / 42 polygons; a path query region_a -> region_b returns 14 points (routes around central cover). Bake is async; readiness is announced via `navigation_ready` after `bake_finished` and physics-frame sync, guarding against querying too early. `python tools/check_repo.py` still not run locally (no Python 3).
- Manual playtest and results: tester confirmed the project runs clean in Godot 4.4.1 (no errors/warnings in Output) with the room rendering as before. Navmesh overlay (Debug > Visible Navigation) not separately confirmed this pass.
- Remaining work/dependency: no actors beyond the player; no weapons/damage/smoke/flash/defuse; no desktop export yet. Region IDs and coordinate convention still pending team freeze with Persons 2/3. Navmesh must be re-baked after any map edit (the builder does this automatically on build/rebuild).
- Next integration step: add actor stubs (shared actor base for Person 2's bots) and a blank offline desktop export to prove the build pipeline early.

### 2026-11-14 — Person 1: shared actor base and health component

- Branch/PR and owning lane: `person-1/world-scaffold`; Person 1 (actors/ shared mechanics).
- Changed files: `actors/actor_base.gd`, `actors/actor_base.tscn`, `actors/health.gd`, `scenes/player/player.gd`.
- Interface/schema changes and consumers: new shared components for Person 2's bots. `ActorBase` (CharacterBody3D) holds the movement the player and bots share and exposes an intent API: `set_move_dir(Vector3)`, `request_jump()`, `move_toward_point(point) -> distance`, `teleport_to(marker)`, plus `move_mode` (RUN/WALK/CROUCH). `Health` component: `apply_damage(amount)`, `reset()`, signals `damaged`/`died`. `actors/actor_base.tscn` is a reusable actor (CharacterBody3D + capsule collision + visible capsule mesh + Health) for Person 2 to instance and attach behavior to. Fairness boundary preserved: the base holds and exposes NO references to other actors; bots drive it from their own observations/beliefs. `player.gd` now `extends ActorBase`, so player and bots use one movement implementation.
- Automated checks run and results: project loads with no errors/warnings in Godot 4.4.1; class_name resolution for `ActorBase`/`Health` is clean. `actors/actor_base.tscn` is not yet instanced anywhere (Person 2 owns bot scenes). `python tools/check_repo.py` still not run locally (no Python 3).
- Manual playtest and results: tester confirmed player movement, collision, walk/crouch/jump, mouse toggle and restart still work unchanged after refactoring the player onto the shared base.
- Remaining work/dependency: no weapons/damage sources yet (Health has no driver); no smoke/flash/spike/defuse; no desktop export yet. Region IDs/coordinate convention pending team freeze. Agent/collision-layer and capsule sizing are placeholders to confirm with Person 2.
- Next integration step: blank offline desktop export to prove the build pipeline on target hardware (brief §9.1).

### 2026-11-14 — Person 1: Windows desktop export verified

- Branch/PR and owning lane: `person-1/world-scaffold`; Person 1 (delivery/export).
- Changed files: `export_presets.cfg`, `docs/BUILD.md` (committed earlier); `export_presets.cfg` updated to disable resource modification.
- Interface/schema changes and consumers: none (build tooling only). Export preset "Windows Desktop" (x86_64 release) writes to `build/windows/` which is gitignored; exported binaries are not committed. `docs/BUILD.md` documents run/template-install/GUI+headless export commands.
- Automated checks run and results: `python tools/check_repo.py` PASSES locally (Python 3.12.10 now installed). Export completed with only a harmless rcedit warning (icon/metadata embedding); disabled `application/modify_resources` so future exports are clean.
- Manual playtest and results: tester launched the standalone `build/windows/callout-trainer.exe` on the target machine (Windows, RTX 4070 laptop) — the room renders and movement/collision/crouch/jump/HUD/disclaimer all work offline, matching the editor. Export templates 4.4.1.stable confirmed installed.
- Remaining work/dependency: export save dialog defaulted to project root the first time; binaries were moved to `build/windows/`. Team members export to `build/windows/` per docs/BUILD.md. No gameplay beyond movement yet (no weapons/damage/smoke/flash/spike/defuse). Region IDs/coordinate convention still pending team freeze.
- Next integration step: first gameplay increment — damage/death wired to the Health component, keeping the player able to communicate after death per docs/COMMUNICATION_COACHING.md, and emitting player-permitted perception/death/entry/utility events for Person 3's grader.

### 2026-11-14 — Person 1: damage/death handling (comms-after-death preserved)

- Branch/PR and owning lane: `person-1/world-scaffold`; Person 1 (actors/ shared mechanics + player).
- Changed files: `actors/actor_base.gd`, `scenes/player/player.gd`, `scenes/player/player.tscn`, `scenes/main.gd`, `scenes/main.tscn`, `project.godot`.
- Interface/schema changes and consumers: `ActorBase` gains `is_alive`, a `died` signal (carries no killer/hidden truth), `apply_damage(amount)` passthrough, and connects the Health `died` signal; `teleport_to` now revives (is_alive=true + health reset) on restart. Player scene gains a `Health` child. Player death stops movement but keeps mouse-look and the input/comms channel alive, per COMMUNICATION_COACHING "retain speech/menu input after player death". `died` is the permitted death event Person 3's grader can forward.
- Automated checks run and results: `python tools/check_repo.py` PASSES locally. Project loads clean in Godot 4.4.1. No weapons yet — a temporary debug key (K) applies 35 damage to the player to test death; to be replaced by weapons.
- Manual playtest and results: tester confirmed HP drops 100->65->30->0 on K, status flips to DEAD, movement stops while mouse-look still works (can observe/report after death), and R restarts and revives to full HP. Also fixed swapped crouch/walk bindings (crouch now Ctrl, walk now Shift, matching the HUD).
- Remaining work/dependency: no weapons/damage source yet (K is a stand-in); no smoke/flash/spike/defuse; death does not yet emit a structured permitted event payload for Person 3 (only the `died` signal). Region IDs/coordinate convention still pending team freeze. Export save path defaults to project root — export to build/windows/ per docs/BUILD.md.
- Next integration step: a basic hitscan rifle (shared weapon model) that drives Health via apply_damage, keeping bots and player on the same rules.
