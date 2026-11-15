# Annotation: FNC vs PRX — Lotus B, final round (from the plant)

**Owner: Person 3.** Hand-annotated from a public VOD per `docs/VIDEO_ANNOTATION.md`.
**Status: COMPLETE (first pass) — full round annotated from the plant to round end.**
Starting state (§4) and timeline (§5) are observed from the VOD and ready for Person 2.
Region ids (§2) still need the team freeze with Person 1. Comms opportunities (§6) are
deferred (not needed yet). Weapons were not read (`unknown`); utility cooldowns past a death
are voided.

> **Hard rule in force:** do not invent any pro fact. Every observed value comes from the
> VOD. Anything not visible on screen stays `unknown`. Observation and inference are kept in
> separate columns. Reference the video by URL/timestamp only; do not download or commit
> footage. Authored "what-if" branches are labelled as adaptations, not observed pro play.

---

## 1. Source

| Field | Value |
|---|---|
| scenario_id | `fnc_prx_lotus_toronto2024_gf` |
| Match | FNC vs PRX, Masters Toronto 2024, Grand Final |
| Map | Lotus |
| Round | Final round of the map (score 13–12 PRX pre-round; PRX win ends it 14–12) |
| Segment | From the bomb plant to round end (B site) |
| VOD URL | https://www.youtube.com/watch?v=Al4HobbrHWM |
| Plant timestamp (t=0) | `01:01:25` (`t=3685s`) |
| VOD title / channel | `unverified` — scraper returned no metadata; confirm from the page |
| Annotated by | <your name> |
| Review status | first pass complete; pending team review (region freeze with Person 1) |
| Reference overlay image | hand-drawn B-site region overlay (annotator's own); path only, NOT committed |

**t=0 convention:** t=0 is the plant instant. Timeline beats are **relative seconds from the
plant** (negative only if a pre-plant fact is needed). The absolute VOD timestamp is noted
alongside each beat.

---

## 2. Region vocabulary (frozen for this scenario — pending team freeze with Person 1)

Informal/community Lotus B callouts, **not raw valorant-api.com names** (only `Upper` matches
the API). These are the belief-space vocabulary: every observed position and every callout
uses one of these ids. Person 1 later gives each a world-space `Area3D` bound; the
coordinate→region helper bridges them. No coordinates are invented here.

| region_id | Callout name | Overlay colour | Rough location (annotator's overlay) |
|---|---|---|---|
| `b_main` | B Main | white | bottom-center, long horizontal entry space |
| `b_cubby` | B Cubby | pink | left-center, narrow vertical pocket |
| `b_heaven` | B Heaven | green | top-right, elevated |
| `b_upper` | B Upper | yellow | center, between Heaven and Pit |
| `b_pit` | B Pit | red | center, round plant/defuse space |
| `c_link` | C Link | purple | top-left, connector toward C side |
| `a_link` | A Link | blue | right, connector toward A side |

`unknown` is a valid region value when a player's location cannot be seen.

---

## 3. Takeover role and sandbox area

| Field | Value |
|---|---|
| Player takeover role (which real player the user controls) | **Something (Yoru, PRX)** — the post-plant holder in `b_pit`/`b_heaven` |
| Side (atk / def) | **attack (PRX)** — defending the plant against the FNC retake |
| Compact Lotus B area the sandbox needs | the 7 regions above (refine after review) |
| Reduced-player simplifications (if any) | scenario starts 2v4 (PRX 2 alive vs FNC 4 alive); 3 PRX + 1 FNC already dead at plant — model only the 6 alive actors |

---

## 4. Starting state at the plant (t=0)

Fill one row **per player alive at the plant instant**. Everything is `unknown` until read
off the VOD. Weapon/util/HP that cannot be seen stay `unknown` — do not guess.

| Actor (name) | Agent | Side (atk/def) | Region (one id above) | Weapon | Remaining utility | Visible HP | Evidence source (POV/minimap/HUD) | Certainty (observed/inferred/unknown) |
|---|---|---|---|---|---|---|---|---|
| Something | Yoru | atk (PRX) | `b_heaven` | `unknown` | none | 100 + 50 shield | POV/minimap (lower-left corner of B Heaven) | observed |
| f0rsakeN | Omen | atk (PRX) | `b_pit` | `unknown` | 1 smoke (2nd smoke on 18s cooldown) | 70 + 0 shield | POV/minimap | observed |
| Chronicle | Viper | def (FNC) | `unknown` at t=0 (first seen `b_heaven` at +23s) | `unknown` | none | 100 + 50 shield | HUD/scoreboard; position from +23s | observed (HP/util); t=0 position unknown |
| kaajak | Raze | def (FNC) | `unknown` at t=0 (first seen `c_link` at +23s) | `unknown` | 1 grenade | 100 + 50 shield | HUD/scoreboard; position from +23s | observed (HP/util); t=0 position unknown |
| Boaster | Omen | def (FNC) | `unknown` | `unknown` | 1 blind (Paranoia), 2 smokes | 100 + 50 shield | HUD/scoreboard (off-screen at plant) | observed (HP/util); position unknown — DIED +23s in b_main |
| crashies | Fade | def (FNC) | `unknown` at t=0 (first seen `b_heaven` at +23s) | `unknown` | none at t=0 (Fade **Eye** on 12s CD; available by +16s) | 100 + 50 shield | HUD/scoreboard; position from +23s | observed (HP/util); t=0 position unknown |

_Dead at plant (5v5, so 4 players down): 3× PRX, 1× FNC — names/agents not yet recorded; add if the VOD shows them._

**Spike / round state at t=0**

| Field | Value |
|---|---|
| Spike planted | yes (segment starts from plant) |
| Spike site | B |
| Spike region | `b_pit` (observed — planted in Pit) |
| Time left on round / spike timer at plant | just planted; timer not yet shown / `unknown` |
| Attacker / defender count alive at plant | PRX (atk) 2 alive; FNC (def) 4 alive |
| Match context | Score 13–12 PRX before this round; a PRX win ends the map 14–12 (PRX match point) |

---

## 5. Timeline (plant → round end)

Coarse key beats only — not every frame. One row per beat. Keep observation (what's on
screen) separate from inference (what you reason happened off-screen).

| t (rel. sec from plant) | Abs. VOD timestamp | Actor | Observed region / action | Utility (what / where / when) | Evidence source (POV/minimap/HUD) | Certainty (observed/inferred/unknown) | Notes |
|---|---|---|---|---|---|---|---|
| 0 | 01:01:25 | — | spike planted on B | — | POV | observed | plant instant = t=0 |
| 0 | 01:01:25 | f0rsakeN (Omen) | in `b_pit` | 1 smoke held; 2nd smoke recharging (HUD 18s → ready +18s / 01:01:43) | POV/HUD | observed | PRX post-plant holder on site |
| 0 | 01:01:25 | Something (Yoru) | in `b_heaven` (lower-left corner) | none | minimap | observed | PRX off-angle hold |
| +2 | 01:01:27 | f0rsakeN (Omen) | moved `b_pit` → `b_cubby` | — | POV/minimap | observed | repositions off site before smoking |
| +2 | 01:01:27 | f0rsakeN (Omen) | — | **Omen smoke** thrown on LEFT side of `c_link` (see overlay img 000410) | POV (smoke visible top-left of B marker) | observed | blocks C-side retake approach; now 0 smokes |
| +2 | 01:01:27 | Something (Yoru) | moved `b_heaven` → `a_link` | — | minimap | observed | rotates to hold A-side approach |
| +12 | 01:01:37 | crashies (Fade) | — | Fade **Eye** comes off cooldown (projected +12s; confirmed available at +16s) | HUD | observed (ready-state), computed (exact tick) | matches the 12s HUD read at t=0 |
| +16 | 01:01:41 | crashies (Fade) | `unknown` (out of camera bounds) | has 1 Eye available | HUD/scoreboard | observed (util); position unknown | alive with Eye up; location not visible |
| +16 | 01:01:41 | Boaster (Omen) | `unknown` (out of camera bounds) | **Omen smoke** on RIGHT side of `b_main` (see overlay img 235530); 2 → 1 smoke; blind still held | POV (smoke visible below B marker) | observed (util/placement); position unknown | FNC smokes off a Main hold angle to retake |
| +18 | 01:01:43 | f0rsakeN (Omen) | `b_cubby` | smoke charge A recharges (projected +18s; confirmed — he throws it next beat) | HUD | observed (ready-state), computed (tick) | matches the 18s HUD read at t=0 |
| +19 | 01:01:44 | f0rsakeN (Omen) | `b_cubby` | **Omen smoke** on `b_main` (slightly left of center; see overlay img 003059); 1 → 0 smokes; now NO util | POV (smoke visible below/left of B marker) | observed | PRX also smokes Main; f0rsakeN now dry on util |
| +23 | 01:01:48 | f0rsakeN (Omen) | moved `b_cubby` → `b_main` | — | POV/minimap | observed | pushes aggressively into Main |
| +23 | 01:01:48 | f0rsakeN (Omen) | kills **Boaster (Omen, FNC)** in `b_main` | — | killfeed/POV | observed | FIRST KILL; PRX picks the FNC Omen (loses FNC blind + 1 smoke) |
| +23 | 01:01:48 | Boaster (Omen) | **dies** in `b_main` | held 1 blind + 1 smoke (lost on death); pending smoke recharge voided | killfeed | observed | FNC down to 3 (Chronicle, kaajak, crashies) |
| +23 | 01:01:48 | crashies (Fade) | `b_heaven` (first seen) | **Fade Eye** thrown into `b_heaven` (see overlay img 004028); 1 → 0 Eye | POV (eye icon + recon arc visible) | observed | recon sweep over Heaven; Eye now on cooldown |
| +23 | 01:01:48 | Chronicle (Viper) | `b_heaven` (first seen) | none | minimap/POV | observed | in Heaven at +23s; later moves to `b_upper` (dies there +30s) |
| +23 | 01:01:48 | kaajak (Raze) | `c_link` (first seen) | 1 grenade held | minimap/POV | observed | swings retake via C side |
| +26 | 01:01:51 | Something (Yoru) | moved `a_link` → boundary between `b_site` and `a_link`, holding angle onto `b_heaven` | none | POV/minimap | observed (position is a region boundary — see note) | off-angle hold onto Heaven |
| +26 | 01:01:51 | Something (Yoru) | kills **crashies (Fade, FNC)** in `b_heaven` | — | killfeed/POV | observed | SECOND PICK for PRX; FNC down to 2 (Chronicle, kaajak) |
| +26 | 01:01:51 | crashies (Fade) | **dies** in `b_heaven` | Eye already thrown (+23s); no util lost | killfeed | observed | retake now 2v2 |
| +26 | 01:01:51 | f0rsakeN (Omen) | moved `b_main` → `b_cubby` | none | POV/minimap | observed | repositions back into Cubby after the Main trade |
| +28 | 01:01:53 | Something (Yoru) | moved `b_site`/`a_link` boundary → `b_pit` (onto the spike) | none | POV/minimap | observed | PRX holds the plant spot |
| +28 | 01:01:53 | kaajak (Raze) | `c_link` | **Raze grenade** thrown into `b_pit`; 1 → 0 (one-use, no recharge); FNC now 0 util total | POV/minimap | observed | contests Pit/spike; Something in Pit reported 100/50 (not hit per readout) |
| +30 | 01:01:55 | Something (Yoru) | `b_pit` → now 97/44 (took minor damage, likely Raze nade chip) | none | HUD | observed | survives the Pit nade with light damage |
| +30 | 01:01:55 | f0rsakeN (Omen) | kills **Chronicle (Viper, FNC)** in `b_upper` | — | killfeed/POV | observed | round-ending pick 1 (Chronicle was in `b_upper`, distinct from the Heaven holds) |
| +30 | 01:01:55 | Something (Yoru) | kills **kaajak (Raze, FNC)** in `c_link` | — | killfeed/POV | observed | round-ending pick 2 — FNC eliminated |
| +30 | 01:01:55 | — | **ROUND END — PRX win by elimination** | — | killfeed | observed | PRX wins map 14–12 (Grand Final) |

**Round end**

| Field | Value |
|---|---|
| Outcome (defuse / detonation / elimination) | **elimination** — PRX kill both remaining FNC at +30s; spike never defused |
| Who won the round | **PRX** (attackers) |
| Recorded outcome (one line, from VOD) | PRX hold the B plant 2v4→2v0: f0rsakeN trades Boaster (Main, +23s), Something picks crashies (Heaven, +26s), then a +30s double (f0rsakeN→Chronicle, Something→kaajak) ends it. PRX win the map 14–12 (Grand Final). |

### 5a. Utility cooldown tracker (annotator's running math)

Recharge/cooldown numbers: **HUD readings are observed**; durations below are **team-provided
rules** used to project future readiness. Applied rules:
- **Omen smoke** recharge = **30s per charge** (from the moment a charge is thrown). Omen has 2 charges.
- **Fade Eye (Haunt)** cooldown = **45s** (from use).
- A direct HUD reading always overrides a computed value (e.g. the 2nd smoke was read at 18s
  remaining at t=0, so it is kept as +18s, not recomputed to a fresh 30s).

| Player | Ability | Basis | Started/triggered | Ready at (rel) | Ready at (abs) | Status |
|---|---|---|---|---|---|---|
| f0rsakeN (Omen) | smoke charge A (recharging at plant) | HUD read: 18s @ t=0 | pre-plant | +18s | 01:01:43 | **thrown at +19s** (ready then, used immediately) |
| f0rsakeN (Omen) | smoke charge B (thrown at +2s) | rule: 30s recharge | +2s (01:01:27) | +32s | 01:01:59 | pending |
| f0rsakeN (Omen) | smoke charge (thrown at +19s) | rule: 30s recharge | +19s (01:01:44) | +49s | 01:02:14 | pending |
| crashies (Fade) | **Eye** (Haunt — recon reveal) | HUD read: 12s @ t=0 | pre-plant | +12s | 01:01:37 | **used at +23s** (thrown into b_heaven) |
| crashies (Fade) | **Eye** (thrown at +23s) | rule: 45s cooldown | +23s (01:01:48) | +68s | 01:02:33 | **VOID — crashies died +26s** |
| Boaster (Omen) | smoke charge (thrown at +16s) | rule: 30s recharge | +16s (01:01:41) | +46s | 01:02:11 | **VOID — Boaster died +23s** |
| Boaster (Omen) | blind + held smoke | — | held | — | — | **VOID — lost on death +23s** |
| kaajak (Raze) | grenade (one-use) | held at plant | thrown +28s (01:01:53) into b_pit | — (no recharge) | — | **expended** |

> Readout note: you are stripping on-cooldown util from the per-beat HP/util readout so the
> annotator computes it here. To project a new cooldown, read the HUD number once at use.

---

## 6. Communication opportunities (what the coach grades later)

Points where a real callout, util plan, readiness call, correction, or death report would
matter. Mark whether the info was **knowable by the player** (POV/HUD) vs spectator/minimap
only — a participant does not automatically know spectator info.

| t (rel. sec) | Opportunity type (report / util plan / readiness / correction / death report) | What the player could call | Knowable by the player? (POV/HUD vs spectator-only) | Certainty |
|---|---|---|---|---|
| | | | | |
| | | | | |
| | | | | |
| | | | | |

---

## 7. Open questions / unknowns to resolve

- VOD title and channel not verified (scraper returned nothing). Confirm from the page if cited.
- Weapons for every actor are `unknown` (not read off the VOD this pass). Add if needed by Person 2.
- Spike/round timer value at the plant was not read (just-planted; `unknown`). The 45s post-plant
  window is implied by the +0→+30s action but the exact clock was not recorded.
- Something's +26s position ("between B site and A Link") is a region boundary, not a clean
  single id — flag for the Person 1 region freeze (may widen `a_link`/`b_site` or accept it).
- The 4 players already dead at the plant (3 PRX, 1 FNC) are not identified; not needed for the
  6-actor scenario.

---

## 8. Handoff note to Person 2

**Ready to convert.** §4 (starting state) and §5 (timeline) are observed and complete for a
first pass. Build the executable `scenarios/fnc_prx_lotus_toronto2024_gf.json` from this.

Key facts for the scenario:
- **6 live actors** (2 PRX attackers hold the plant, 4 FNC defenders retake). 3 PRX + 1 FNC
  already dead at the plant — do not model them.
- **Player takes over Something (Yoru, PRX)**; the AI teammate the player comms with is
  **f0rsakeN (Omen, PRX)**. The 4 FNC are the enemy retake line (script + branches).
- **Spike in `b_pit`**, planted at t=0. PRX win by **elimination** at +30s; spike never defused.
- The real round resolves fast (~30s). The **PRX "pro line"** = hold Pit/Heaven, smoke C Link
  + B Main, trade aggressively. The **FNC retake line** = stack Heaven, Raze nade Pit, push —
  and got traded out. Person 2 authors FNC branches (reactive retakes) as *adaptations*, not
  observed pro play (none beyond this one line is in the VOD).

Dependencies / open items:
- **Region ids (§2) need the team freeze with Person 1** before authoring. 7 ids:
  `b_main`, `b_cubby`, `b_heaven`, `b_upper`, `b_pit`, `c_link`, `a_link`.
- Something's +26s boundary position (`b_site`/`a_link`) needs a region decision (see §7).
- Weapons are `unknown`; utility cooldown rules (Omen smoke 30s, Fade Eye 45s) are
  **team-provided modeling values**, not VOD-observed — see §5a.
- Comms opportunities (§6) are intentionally left blank for now.
