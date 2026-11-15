# Person 2 perception sensor

The [sensor](perception_sensor.gd) is the privileged boundary between live physics/navigation and copied bot-local observations. The [scene adapter](scene_sensor.gd) now attaches it to Person 2's inherited first-person scene using Person 1's current map, real actors, utility and narrow weapon/audio callbacks. Automated kernel and inherited-scene checks use Godot 4.4.1; human perception playtests remain pending.

## What it does

- Checks a three-dimensional view cone and range against up to three registered enemy sample points.
- Raycasts through the actual physics world; a ray must hit that enemy's registered collider. Solid geometry and smoke areas block it.
- Requires continuous exposure before recognizing a target, with separate near/far durations. Occlusion, blindness, omitted targets and skipped sensor ticks reset recognition.
- Emits on initial recognition, a visible region change, or a refresh interval; it does not spam every frame.
- Suppresses new visual observations while the observer's own blind status is active. Hearing remains available.
- Attenuates sounds by the actual navigation path length, with action-specific radii. Quiet walking/crouching have zero radius in this model.
- Emits coarse near/far sound observations without the source position, source actor identity or exact region.
- Adds seeded positive reaction delays and stable IDs to ordinary inbox-compatible observations.

Person 1's shared flash mechanics determine blind duration; the kernel honors blind_until_tick. In the live adapter, smoke bit 16 is excluded from raw rays because the shared collider exists before activation. Shared active-smoke segment geometry supplies occlusion instead. Blind waves are identified through the explicit shared registry, including its extra blackout second; ordinary flashes require LOS.

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

Person 1's current physics layers are world=1, player=2, bots=4, regions=8, smoke=16. The kernel fixture uses mask 23; the live adapter removes bit 16 and separately queries active-smoke geometry. No root project settings were changed.

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

## Live scene boundary and automated acceptance

`scene_sensor.gd` privately holds the registered opponent, own actor, map/utility and physics handles. Three real target samples map to unambiguous room/entry/corridor bounds. Neither live aim points nor a full-region-clear claim leave it. Only copied delayed envelopes reach the runtime inbox. Due sightings update the imported Person 3 belief module; heard sounds are delivered/logged without invented belief likelihoods. IDs include the round; reset disposes subscriptions and creates a fresh adapter/inbox.

The adapter subscribes only to registered actors' Weapon.fired and shared UtilitySystem.deployed. It ignores hit data and utility's hard-coded thrower identity, and never reads the archive, scan marks or minimap. Sound event time is the next sensing tick with that tick's listener pose. Run steps require displacement, grounded RUN mode and horizontal velocity above walk speed; walk/crouch and zero-velocity teleports remain quiet. Eighteen-tick cadence is a sampling approximation. Defuse audio is not connected.

Own smoke awareness is cached as plain `inside_smoke`, `view_smoked_off`, `smoke_view_known` alongside `blind_until_tick` in `own_status()`. Inside means active smoke contains its own eye. Smoked-off means active smoke crosses its forward sight ray before the first world wall and within vision range. The ray never uses opponent positions/colliders; a hidden opponent move cannot change these flags. Forward assessment is unavailable while blind/down, while own smoke occupancy remains an own-state effect. These fields drive the HUD's separate IN SMOKE / SMOKED OFF labels; they are not new model inputs or whole-FOV/whole-region clearance evidence. Smoke behind solid cover and inactive/falling smoke cannot create a smoked-off claim.

Sound sources may map to a local floor anchor only within 0.75 horizontal / 3 vertical meters. A listener farther than configured navigation_snap_distance from the navigation surface receives no hearing; its exact suppression diagnostic remains in decision telemetry. No distant listener snap or straight-line hearing fallback is used. All sensor errors, including rejected samples, survive the decision record's new `errors` array.

~~~sh
python validation/run_person2_tests.py --godot "/path/to/godot" --perception-smoke
~~~

This mode loads the actual inherited FPS scene/current map and tests delayed recognition/delivery, actual wall collision, active versus falling smoke, flash LOS/blind recovery, explicit through-wall waves, real weapon/utility sounds, shared actor run/walk/crouch, path-distance hearing, off-nav suppression, exact error telemetry, copied contexts, belief/evidence availability, model evidence rejection, newly generated inputs/decisions under unseen-opponent perturbation, callback disposal and pending-evidence reset. It manually clocks the real runtime to control cutoffs; it is not a human input/rendering test. Pending pre-occlusion observations may arrive; assertions use their event_tick.

Expanded natural-smoke regressions use the actual shared deploy/activation/expiry path (only disposable test duration is shortened), with smoke between both outside actors, around the listener and around the enemy. Each case first proves real visibility, verifies all three sight samples are blocked, forbids new smoke-period sightings/memory refresh, allows genuinely pre-smoke delayed evidence, and checks recovery after real expiry plus normal exposure/reaction. HUD smoke flags and independence from unseen target positions are also checked. The unattended FPS HUD fixture exercises both actual smoke labels and can render PNG previews.

Remaining: human sight/hearing/utility playtest, PVS/complete-region coverage if required, agreed delayed combat aim payload, defuse audio, and Person 3 hearing beliefs/actual model prompt audit. Person 3 still owns aligning its imported hedge-weighted belief implementation with full player-comm acceptance. Pro annotations remain Person 3's responsibility.

## Information recovery and action consumer additions

Named-region sight content is unchanged. A visible registered enemy in a map gap/ambiguous overlap now delivers `{type: "enemy_seen_unknown_region", enemy_id: "enemy"}` after normal exposure/reaction delay. A private kernel sentinel is stripped before output; no invented region or aim coordinate leaves the adapter. The existing runtime promotes this evidence into copied contexts/HUD but does not send it to Person 3's region-only belief handler. Both consumers must handle location unknown explicitly rather than treating this as a located enemy or a combat aim payload. Shared schemas and named `enemy_seen` payloads are unchanged; this new internal content type requires consumer review.

The agreed live follow-player producer emits only `seen` envelopes:

~~~json
{
  "id": "ally:round:1:entry:ally:sense:1",
  "bot_id": "ally",
  "event_tick": 100,
  "available_tick": 114,
  "source": "seen",
  "speaker_id": "sensor",
  "content": {"type": "player_entry", "actor_id": "player", "entry_id": "entry"}
}
~~~

`SceneSensor.new` accepts optional final `entry_regions`, copied from own scenario `player_entry_sensing`, currently `{entry: {region_id: "entry", direction: [0,0,-1]}}`. It validates known unique regions and finite nonzero horizontal directions. Actual forward displacement plus velocity in the authored region must remain visible through the same FOV/physics/smoke/blind/exposure kernel, using independently seeded recognition so opponent changes do not affect its delay RNG. Quiet walking/crouching can be seen. A stationary player, teleport or anonymous heard sound cannot create the cue. The existing delayed inbox/executor validates whether movement occurred at/after readiness and releases only on actual delivery. The producer does not change command logic or consult the active command. Live fixture tests clear/smoked/blinded/out-of-view movement and actual evidenced release. Entry IDs/region/direction come from authored data, never model coordinates. The action session owns staging and facing behavior.

User-confirmed wave semantics now blind actors during travel. Shared `BlindWave.passing_blind_duration_for` retains radius/facing/through-wall/duration rules and excludes viewers behind the launch plane; teammate and shared player receivers apply each source only once. Ordinary flashes remain detonation/LOS-based. The adapter identifies waves by instance-ID membership in the explicit registry, avoiding invalid cross-type TypedArray searches when flashes and waves coexist. The runner explicitly overlays the two approved local shared scripts for FPS tests/launch; Person 1 should review/adopt that behavior. No wave truth or target handle enters policy.

## Agreed delayed combat evidence

The action session requested and this session accepted two new internal **seen** contents, separate from unchanged regional enemy_seen:

~~~json
{"type":"enemy_aim","enemy_id":"enemy","aim_position":[2.0,0.9,11.5]}
{"type":"enemy_lost","enemy_id":"enemy"}
~~~

`enemy_aim` copies only a torso point that itself passed collider LOS, FOV/range, smoke, blindness and recognition. Head-only/foot-only regional sightings cannot grant a torso coordinate behind cover. It refreshes at six ticks while visible, with independently seeded ordinary 12–18-tick delay in the current scenario. Unknown-region visibility may supply a legitimately visible torso point without guessing its callout. Arrays are copied, never live target references or future transforms.

`enemy_lost` invalidates usable torso sight after those checks break. It is emitted once per previously recognized lock, with no hidden cause or new location. Per-enemy availability is causally ordered so old aim cannot arrive after its invalidating loss, nor an older loss after subsequent reacquisition. The existing inbox still enforces actual availability. `sampled_visible_ids()` is a privileged kernel diagnostic for generating delayed loss only; its immediate output must never reach policy/model.

The consumer agreement is a maximum aim age of **30 ticks**, selecting evidence by event time and actual delivery, rejecting newer delivered losses, and immediately guarding fire with copied own blindness/smoke status. This is synthetic tuning, not measured game behavior. Firing is opt-in during integration so ordinary information fixtures remain independent. No hidden target state may be consulted for aim, fire eligibility or pursuit. Shared weapon physics may resolve a shot without returning hidden hit/collider truth to policy. The action session owns combat execution/telemetry and lateral peek routes; existing spawn/home/cover/flash/entry-sensing fields are preserved. These are proposed internal consumer seams, not silent changes to shared schemas or Person 3 beliefs.
