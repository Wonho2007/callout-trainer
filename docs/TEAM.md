# Team ownership

Team GitHub handles: Wonho2007, sn-kurup and liedwin49. Person-to-lane assignments are unassigned; choose by claiming the matching GitHub issue. These labels refer to developers, not characters in the simulation. The complete task split and timed acceptance gates are in project brief section 9.

| Lane | Owns | Must provide | Depends on |
|---|---|---|---|
| Person 1: world/player/delivery | world/, actors/, weapons/, utility/, scenes/maps/, scenes/player/, project.godot, main scene, export settings | Test room; named regions/spawns; shared mechanics; navigation bake; utility tests; map overlay geometry; offline build/video | Schemas from Person 3; bot integration from Person 2 |
| Person 2: perception/bots/scenario | perception/, bots/, scenarios/, validation/, scenes/bots/; policy/perception tests | Delayed perception; baseline and reactive branches; fair controller; evidence trace; validator; fallback diagnostics | World/action interfaces from Person 1; belief contract from Person 3 |
| Person 3: comms/evaluation/debrief | comms/, belief/, grading/, recording/, ui/debrief/, evaluation/; shared schemas | Quick-call; beliefs/trust; grading/logging; modes; debrief; belief counterfactual; headless pilot | Regions/events from Person 1; observations/decisions from Person 2 |

Directories above are reserved ownership boundaries; they are not claims that these modules already exist.

## Work together first

Freeze region IDs, coordinates, collision masks, physics tick rate/order, availability timing, seeds, public information allowlist and schema version before parallel implementation. Use fake adapters and examples until dependencies land.

Person 1 coordinates engine version, root project configuration and the main scene. Person 3 coordinates schema definitions. Person 2 and Person 3 jointly implement the leak fixture before intelligence.

## Integration gates

- Hour 2: contracts, stubs and a failing forbidden-information fixture.
- Hour 6: navigable room; perception; beliefs/grading on shared fixtures.
- Hour 8: player callout changes teammate goal in-engine.
- Hour 12: end-to-end retake, fair bots, recording and score screen.
- Hour 16: trace/debrief and belief-only counterfactual.
- Hour 20: actual pilot results and offline export.
- Final two hours: freeze, rehearse and package.

These times follow the brief's unconfirmed 24-hour planning budget.

Person 3 has the heaviest UI/analysis workload. Person 1 supplies map drawing data and handles export/video; Person 2 owns validators/safety telemetry. Both help collect evaluation runs. Do not add optional speech/LLM work while the debrief remains incomplete.
