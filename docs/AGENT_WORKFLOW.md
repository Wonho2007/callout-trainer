# Agent-led Godot sandbox workflow

This is the development plan for a team with no game-engine experience. It does not mean the sandbox or any of the scripts below already exists.

## Working model

Use Godot as the runtime, with agents building scenes and configuration through code. Prefer a small JSON-defined greybox assembled by a GDScript builder over manually placing every object in the editor. Keep the builder readable and avoid unnecessary abstractions.

Humans mainly open/run the project, inspect errors, playtest, and give specific feedback. Learn the scene tree, Inspector, run/stop, error panel and collision/navigation debug views. Advanced modeling, animation and shader workflows are not needed for this prototype.

Agent autonomy depends on access: an agent with repository editing and a Godot executable can generate files, launch checks and inspect logs. Without executable/GUI access, report that limitation and give the teammate exact commands and manual checks. A successful headless run does not verify rendering, input, movement feel or tactical behavior.

## Proposed files and ownership

These are proposed implementation paths, not files supplied by this documentation update.

| Path | Responsibility | Owner |
|---|---|---|
| project.godot; scenes/main.tscn | Project settings and small bootstrap scene | Person 1 |
| world/sandbox_builder.gd | Read map data and create visible geometry, matching collision, regions and spawns | Person 1 |
| world/maps/test_room.json | Clearly synthetic map dimensions and named regions/spawns | Person 1 |
| scenes/player/player.tscn | Camera and CharacterBody3D movement; shared mechanics | Person 1 |
| scenes/bots/bot.tscn | Reusable bot actor assembled against shared actor components | Person 2; Person 1 owns shared mechanics |
| ui/debug/ | Bot goal, region, sightline and observation diagnostics | Person 3; Persons 1/2 provide data |
| validation/ | Map/scenario checks and perception validation | Person 2; Person 1 supplies map adapter |

Static geometry data is distinct from scenario data. Person 1 owns wall dimensions/collision/spawns; Person 3 owns verified video notes in annotations/; Person 2 converts those notes into round actors, baseline actions and branches in scenarios/. Agree region IDs together. Privileged debug information must not enter policy.

Example geometry record, for discussion only:

~~~json
{
  "id": "central_cover",
  "position": [0, 1, -5],
  "size": [3, 2, 1]
}
~~~

Confirm units and axis conventions with docs/CONTRACTS.md. One record should generate both mesh and matching collision. Validate sizes, unique IDs, map bounds and spawn clearance. Generate the navigation bake from the same geometry; pathfinding does not automatically understand collision. Bake after geometry creation, wait for navigation synchronization before querying, and document regeneration after map edits. Rebuild/reset cleanly without duplicating nodes.

Code-generated geometry can later be inspected or saved as scenes if useful. Prefer ordinary reusable scenes for actors and a small bootstrap; do not write the entire game as one generator.

## Build order and acceptance gates

1. **Empty synthetic room.** Floor, walls, lights, player controller, mouse capture/release, restart, matching collision. Human confirms movement and visibility.
2. **One interaction.** Cover, one teammate, one enemy, three named regions and a navigable route. Verify the teammate cannot see the enemy.
3. **Communication loop.** Quick-call -> delayed observation -> belief update -> teammate watches a relevant angle -> trace cites evidence. Include leak fixture and unseen-state perturbation check before claiming fairness.
4. **Mechanics.** Shared rifle/damage, smoke, flash, spike and defuse; test visibility and collision.
5. **Source-derived site.** Replace synthetic map data with a manually annotated pro-clip blockout, preserving sightlines and noting uncertain scale/positions and reduced player count.

This order stages implementation; it does not remove the brief's final acceptance requirements. Do not wait for a polished or recognizable site before testing the communication loop.

## Short agent tasks

Assign one playable increment at a time. Each task states owned paths, interfaces, acceptance criteria, actual checks and a short manual playtest. For example, Person 1 can start with:

> Read AGENTS.md and the project brief, then docs/AGENT_WORKFLOW.md and shared contracts. Implement only a synthetic JSON-generated test room with a first-person CharacterBody3D player, matching wall collision, named regions/spawns, mouse capture/release and restart. Pin the editor version with the team first. Run available startup checks, document the exact launch command and provide manual checks. Coordinate actor interfaces with Persons 2/3; do not implement bot intelligence. Update docs/HANDOFFS.md with actual results and remaining work.

After a human verifies it, request the next increment. Useful feedback is concrete: doorway too narrow; cover does not block sight; bot gets stuck at a particular corner; mouse stays captured after pause. Do not ask an agent to build the whole simulator in one pass.

## Human interaction with the engine

| Activity | Agent responsibility | Human responsibility |
|---|---|---|
| Setup | Prepare files/settings; document pinned editor/export setup | One teammate installs/opens Godot, confirms target machine |
| Geometry | Generate map, collision, regions and navigation from data | Walk the room; judge cover, scale and sightlines |
| Code/debugging | Edit files, inspect logs, run available checks | Report reproducible behavior and inspect visual errors |
| Gameplay | Implement shared rules and bot behavior | Test aiming/movement and believable responses |
| Integration/export | Automate repeatable launch/check/export commands | Play exported build and rehearse demo |

One teammate, usually Person 1, can operate Godot while Persons 2/3 work against fixtures. Each lane still needs feedback from the integrated game. Expect frequent short playtests rather than lots of manual scene authoring; do not promise a percentage of automation or zero editor work.

## Validation loop

Agent changes one feature -> available automated checks -> human playtest -> specific feedback -> next small change.

Keep two separate records:

- **Automated:** exact command, editor version, result, and what was checked. Headless startup, scene loading and policy tests each cover different things.
- **Manual:** tester, scene/build, steps, observed result and unresolved issues. Do not mark a visual/manual check passed from logs alone.

Person 1 documents the real launch/reset/export commands after the project exists. A timed startup smoke check is not a complete test suite; custom headless runners need explicit assertions and nonzero exit on failure. The current python tools/check_repo.py only checks documentation and the synthetic interface fixture.

Official references: [nodes and scenes](https://docs.godotengine.org/en/stable/getting_started/step_by_step/nodes_and_scenes.html), [command-line operation](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html), [navigation meshes](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationmeshes.html).
