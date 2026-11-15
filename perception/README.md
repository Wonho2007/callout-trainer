# Perception and delayed observations

[perception_sensor.gd](perception_sensor.gd) is the sensing kernel;
[scene_sensor.gd](scene_sensor.gd) attaches it to actual world physics and actors.
These are privileged adapters. Their output is copied bot-local evidence delivered
through [observation_inbox.gd](observation_inbox.gd), not direct world access for
policies. See [architecture](../docs/ARCHITECTURE.md) and
[contracts](../docs/CONTRACTS.md).

Vision checks range, a three-dimensional view cone, real collider LOS and continuous
exposure. Recognition resets after occlusion, blindness or missing samples. Active
smoke supplies segment occlusion rather than treating an undeployed smoke collider
as visible cover. Observations emit on recognition/region changes and refresh
intervals rather than every frame. Blindness suppresses vision while hearing remains.

Hearing uses navigation path distance and action-specific radii. Quiet walking and
crouching have zero hearing radius in this model. Heard events are coarse near/far
observations without an exact source location or hidden actor identity. Physical
teammate-entry evidence may release follow-player actions only after ordinary
delivery and readiness checks.

Enemy aim evidence contains only a copied torso point that passed the view/LOS/
exposure checks. Head/foot-only regional sightings cannot grant a torso behind cover.
Loss events invalidate sight without disclosing a hidden cause or new location.
Per-enemy aim/loss delivery is causally ordered; old aim cannot renew sight after
a newer loss. Combat checks evidence ownership, event age, actual delivery and
copied own blindness/smoke status. Shared physical hits are not policy testimony.

Sensor configuration supplies region IDs, masks, distances, exposure, refresh,
hearing and reaction delays. Current ordinary delay tuning is 12–18 ticks; the
communication fixture uses a fixed 18-tick delivery. These are simulator settings,
not measured VALORANT parameters. Enemy arrival/registration alone is never a
sighting. Preserve legitimate pending evidence during late registration.

Kernel, integration and live-scene regression commands are in
[testing](../docs/TESTING.md). Automated evidence checks are scoped validation,
not a complete fairness proof or human perception acceptance.
