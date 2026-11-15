# Hackathon scenario

The playable demo is a plant-hold adaptation on the seven-zone B-site greybox,
using shared source `0260f28`. Zones are `b_main`, `b_cubby`, `b_heaven`, `b_upper`,
`b_pit`, `c_link`, and `a_link`. Main, Cubby, Heaven, Upper and Pit are their spoken
B-site aliases. Pit is circular; Upper takes precedence where their volumes overlap.

## Round behavior

The player takes the Something/Yoru role; the teammate takes f0rsakeN/Omen. The
friendly team holds an already-planted spike. The player starts in Heaven, while
the ally and spike start in Pit. Actor names/roles come from the source annotation;
kit behavior and geometry are simulator approximations.

Unknown enemy starts remain unknown: no enemy actors/colliders exist at plant.
At +23 seconds (scenario tick 1380 at 60Hz), the first-known positions materialize:

| Enemy | Arrival zone |
|---|---|
| Chronicle | Heaven |
| crashies | Heaven |
| kaajak | C Link |
| Boaster | Main |

Boaster's earlier remote smoke does not locate or spawn him. His first localized
annotation is a recorded death; spawning him alive there is an authored adaptation.
The player must earn kills through gameplay; recorded deaths and outcomes are not
forced. Source metadata and metric map fidelity are not independently verified.

Friendly victory occurs on spike detonation or elimination of all four enemies.
Spike defuse or losing both friendly actors is defeat. Player death alone leaves
the round and voice active while the teammate survives. F clears the round, utility,
runtime state and transport session and starts again at plant.

## Bot movement and combat

Annotation supplies baseline movement/utility beats until delivered player calls,
accepted commands, own damage or off-baseline sightings cause a deviation. The
teammate then follows explicit player positions or belief-based coverage. Enemy
policies react to their own delayed evidence. No policy reads hidden transforms.

Positioning and pushes persist at the requested authored zone. Completed swings
retain their endpoint. New positioning/cancel supersedes that goal; death/reset
clears it. Holding a zone does not continuously track the player's location.

The map's source geometry remains intact. Scenario anchors adapt Pit's deep floor
and raised areas. Two bidirectional navigation links use existing box_3 to reach
Upper: ground to the 1m box top, then the 2m platform. The bot requests ordinary
shared jumps, verifies landings, and can descend; there is no added ramp,
teleportation, increased jump strength, or general learned parkour.

Rifle damage is **160 head / 40 body / 34 legs**. HP is a simplified shared pool;
the scenario supplies actor health values. Blinded enemies cannot fire. Blind
effects have a visible head indicator, and dead bots hide with collisions disabled.

## Utility

"Flash C Link" first turns toward the zone and checks authored aim points against
world/smoke LOS and the 20m bot throw range. If possible, it throws from its current
spot. Otherwise it walks toward a reachable view and throws as soon as a valid point
opens. It fails honestly if no reachable view exists. "On my cue" prepares and waits;
cancel before release retains the charge. The teammate has one extra commanded
flash per round as an extension to the annotated kit. No teammate molly voice
command exists; scripted grenade/molly effects are separate.

Shared player flash physics uses the active 0.75s fuse for ballistic throws and
approximately 3–5 seconds of blindness depending on distance/facing/LOS. Native
indicators display the effect. Active smoke blocks the simulator's vision,
utility LOS and weapon segments; standing in smoke applies a player fog overlay.
These are shared simulator rules, not a claim of exact VALORANT mechanics.

## Presentation and optional profiles

The current main build has minimap, HP/ammo status text, teammate information,
crosshair and impairment overlays. F1/F2 hide the respective HUD groups while
flash/blind/smoke feedback stays visible. A victory overlay exists for elimination;
the round label also reports the other outcomes. The separate combat UI branch's
kill effect/count, health bar and unified defeat/result overlay are not part of
the current main build documented here.

The default launcher selects this site. `-Lotus` is a compatibility alias for it;
`-LegacyRoom` and `-LegacyLotus` explicitly select older developer profiles.
Those profiles and their tests use different pinned map revisions; see
[testing](TESTING.md). Grading, debrief and counterfactual evaluation are outside
the hackathon demo.
