# Person 2 perception sensor

The [sensor](perception_sensor.gd) is the privileged boundary between live physics/navigation and copied bot-local observations. It is implemented and tested in isolated Godot 4.4.1 scenes. It is not yet attached to the shared game's actor registry or utility/audio systems.

## What it does

- Checks a three-dimensional view cone and range against up to three registered enemy sample points.
- Raycasts through the actual physics world; a ray must hit that enemy's registered collider. Solid geometry and smoke areas block it.
- Requires continuous exposure before recognizing a target, with separate near/far durations. Occlusion, blindness, omitted targets and skipped sensor ticks reset recognition.
- Emits on initial recognition, a visible region change, or a refresh interval; it does not spam every frame.
- Suppresses new visual observations while the observer's own blind status is active. Hearing remains available.
- Attenuates sounds by the actual navigation path length, with action-specific radii. Quiet walking/crouching have zero radius in this model.
- Emits coarse near/far sound observations without the source position, source actor identity or exact region.
- Adds seeded positive reaction delays and stable IDs to ordinary inbox-compatible observations.

This is a sensor kernel, not a utility implementation. Person 1's shared flash mechanics determine blind duration; the sensor honors blind_until_tick. A smoke must have an active blocker collider/Area3D, not only a visual material.

## Configuration

Supply all fields explicitly. Example production-starting placeholders (not measured game values):

~~~json
{
  "region_ids": ["entrance", "logs", "site"],
  "vision_mask": 23,
  "vision_range": 30.0,
  "fov_degrees": 100.0,
  "near_range": 8.0,
  "near_exposure_ticks": 2,
  "far_exposure_ticks": 5,
  "refresh_ticks": 30,
  "delay_min_ticks": 12,
  "delay_max_ticks": 18,
  "sound_radii": {
    "footstep_run": 11.0,
    "footstep_walk": 0.0,
    "footstep_crouch": 0.0,
    "gunshot": 40.0,
    "utility": 15.0,
    "defuse": 12.0
  },
  "hearing_near_distance": 3.0,
  "navigation_layers": 1,
  "navigation_snap_distance": 0.25
}
~~~

Tune against the configured physics rate: 12-18 ticks is 0.2-0.3 seconds only at 60 Hz. Tests deliberately use shorter delays/exposure values and synthetic distances. No claim of exact Valorant tuning is made.

Person 1's existing physics layers are world=1, player=2, bots=4, regions=8. The test mask 23 includes world/player/bots and a PROPOSED smoke bit 16; it excludes region triggers. Coordinate that additional smoke layer with Person 1 before wiring it into the game. No root project settings were changed.

The view is a 3D cone, not separate horizontal/vertical camera FOVs. This first hearing model is a walkable-path approximation, not a full acoustic simulation through materials/doors.

## Privileged input and lifecycle

~~~gdscript
const Sensor = preload("res://perception/perception_sensor.gd")
var sensor = Sensor.new(bot_id, configuration, per_bot_seed)
# In the trusted actor/perception adapter's _physics_process:
var output = sensor.sample(tick, observer, eligible_enemy_descriptors,
    current_sound_events, world.direct_space_state, world.navigation_map)
# On success, enqueue output.observations into this bot's existing inbox/executor.
# Only delivered observations go to belief/policy. Do not pass sensor/output early.
~~~

Create a fresh sensor per bot per round to reset timing, recognition, event-ID caches and RNG. Call once per simulation physics tick. The API rejects rewound/repeated ticks; gaps reset continuous recognition. Invalid batches fail before advancing the clock, recognition state or random sequence.

observer has exactly:
- eye: finite Vector3;
- position: finite Vector3 walkable hearing anchor;
- forward: finite nonzero Vector3, normalized internally;
- exclude_rids: distinct valid RIDs for this observer's own colliders only;
- blind_until_tick: nonnegative integer; vision is blocked while tick is less;
- alive: bool; a dead observer emits no new visual/hearing observations.

Each eligible enemy descriptor has exactly {enemy_id, region_id, sample_points, collision_rids}. sample_points is an Array of one to three finite Vector3 values, typically head/torso/feet. collision_rids is a nonempty Array of that actor's valid collider RIDs. An enemy cannot also be in the self-exclusion list, and collider/actor identities cannot be duplicated across descriptors.

These descriptors are supplied by a TRUSTED entity registry that maps actual live opponents to their colliders/regions. Do not let language-model output, player requests or policy register arbitrary enemy/collider identities. Policy must never receive these raw descriptors, RIDs, positions, or the sensor object itself. Passing all opponents to this privileged service does not grant policy their coordinates.

Sample/target limits prevent arbitrarily large per-call batches. No potentially-visible-set filter is implemented yet. A future PVS can conservatively reduce candidates but must never treat a candidate as an actual sighting or a whole region as clear.

## Sound and navigation contract

Each sound event has exactly {id, event_tick, kind, position}. kind is one of the configured sound_radii keys. IDs are unique per round; reused IDs and duplicate events within a batch are rejected. Supply only current-tick events and the listener pose from that tick. Historical sounds must not be reevaluated against a listener's new pose.

position is a privileged walkable sound anchor, not a muzzle/head position. Observer and sound anchors must lie within navigation_snap_distance of the navigation surface. Airborne/off-mesh actions require the trusted adapter to provide an appropriate acoustic/navigation anchor; this kernel does not infer one. Off-mesh or disconnected paths are conservatively unheard, never silently replaced by straight-line range.

Wait for Person 1's navigation_ready/map synchronization before enabling nonquiet hearing. Missing, unknown or unsynchronized navigation maps return navigation_not_ready and leave the entire sample uncommitted. The game adapter must log the error and retry with valid current-frame inputs rather than use a Euclidean fallback.

The sound observation intentionally does not distinguish ally/enemy identity. Filter noninformative own-action events upstream if desired; do not infer an enemy identity/location from raw event metadata in policy.

## Output and Person 3 compatibility

sample returns {ok, errors, observations}; no debug target list or live object is returned. Every observation has the existing id, bot_id, event_tick, available_tick, source, speaker_id, content envelope. speaker_id is "sensor".

Visual content: {type: "enemy_seen", enemy_id, region_id}. This matches Person 3's current region_belief.gd sighting handler. event_tick is the recognition/update tick, not the first exposure frame. available_tick adds the seeded reaction delay. The inbox still enforces actual delivery-time provenance.

Hearing content: {type: "sound_heard", sound_kind, distance_class: "near" | "far"}. This is a proposed sensory content shape, not a comms.v1 change. Person 3's current belief implementation explicitly does not yet process hearing. Retain these observations for logging/future sound likelihoods; do not pretend they already update enemy beliefs.

No region_clear negative evidence is emitted. Seeing a few target samples does not prove full current coverage of an entire region. The privileged grader may retain independent player sighting intervals, but this sensor does not implement that coaching metric.

## Automated checks and manual playtests

~~~sh
python validation/run_person2_tests.py --godot "/path/to/godot"
python validation/run_person2_tests.py --godot "/path/to/godot" --person3-root "../callout-trainer-person3"
~~~

Default includes actual headless PhysicsServer3D raycasts/Area3D blockers and a NavigationServer3D L-shaped path fixture. Checks cover walls, partial cover, range/FOV, observer-inside-smoke, flash/reacquisition, self-exclusion, region-trigger masking, exposure/refresh, seeded replay, path distance, disconnected endpoints, quiet movement, malformed inputs, reaction delay and hidden-target invariance.

Optional Person 3 integration also runs actual raycast -> private delayed inbox -> real region belief -> knowledge planner. Person 3 files are copied read-only into the disposable project; no teammate files are edited or merged.

**Manual playtests: none.** Headless physics tests verify specific mechanics, not visual quality, game feel, actual shared-scene wiring, full-game fairness or training effectiveness.

Next: build the Person 2 scene adapter for the actual enemy registry, own-state/utility effects and sound event bus; connect autonomous goals to Person 1's actor/navigation mechanics. Verify those in the shared synthetic room and run a human playtest. Pro annotations remain Person 3's responsibility.
