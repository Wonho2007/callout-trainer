# Annotation: FNC vs PRX — Lotus B, final round (from the plant)

**Owner: Person 3.** Hand-annotated from a public VOD per `docs/VIDEO_ANNOTATION.md`.
**Status: SKELETON — awaiting observed facts from the VOD. Nothing below the region list is confirmed.**

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
| Round | Final round of the map |
| Segment | From the bomb plant to round end (B site) |
| VOD URL | https://www.youtube.com/watch?v=Al4HobbrHWM |
| Plant timestamp (t=0) | `01:01:25` (`t=3685s`) |
| VOD title / channel | `unverified` — scraper returned no metadata; confirm from the page |
| Annotated by | <your name> |
| Review status | draft / not reviewed |
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
| Player takeover role (which real player the user controls) | `unknown` — choose after reviewing |
| Side (atk / def) | `unknown` |
| Compact Lotus B area the sandbox needs | the 7 regions above (refine after review) |
| Reduced-player simplifications (if any) | `unknown` |

---

## 4. Starting state at the plant (t=0)

Fill one row **per player alive at the plant instant**. Everything is `unknown` until read
off the VOD. Weapon/util/HP that cannot be seen stay `unknown` — do not guess.

| Actor (name) | Agent | Side (atk/def) | Region (one id above) | Weapon | Remaining utility | Visible HP | Evidence source (POV/minimap/HUD) | Certainty (observed/inferred/unknown) |
|---|---|---|---|---|---|---|---|---|
| | | | | | | | | |
| | | | | | | | | |
| | | | | | | | | |
| | | | | | | | | |
| | | | | | | | | |
| | | | | | | | | |
| | | | | | | | | |
| | | | | | | | | |
| | | | | | | | | |
| | | | | | | | | |

**Spike / round state at t=0**

| Field | Value |
|---|---|
| Spike planted | yes (segment starts from plant) |
| Spike site | B |
| Spike region | `b_pit` (confirm — the plant spot) |
| Time left on round / spike timer at plant | `unknown` |
| Attacker / defender count alive at plant | `unknown` |

---

## 5. Timeline (plant → round end)

Coarse key beats only — not every frame. One row per beat. Keep observation (what's on
screen) separate from inference (what you reason happened off-screen).

| t (rel. sec from plant) | Abs. VOD timestamp | Actor | Observed region / action | Utility (what / where / when) | Evidence source (POV/minimap/HUD) | Certainty (observed/inferred/unknown) | Notes |
|---|---|---|---|---|---|---|---|
| 0 | 01:01:25 | | | | | | plant instant |
| | | | | | | | |
| | | | | | | | |
| | | | | | | | |
| | | | | | | | |
| | | | | | | | |
| | | | | | | | |
| | | | | | | | |
| | | | | | | | |
| | | | | | | | |
| | | | | | | | |

**Round end**

| Field | Value |
|---|---|
| Outcome (defuse / detonation / elimination) | `unknown` |
| Who won the round | `unknown` |
| Recorded outcome (one line, from VOD) | `unknown` |

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

- VOD title and channel not verified (scraper returned nothing). Confirm from the page.
- Player takeover role not yet chosen.
- Round/spike timer at plant not yet read.
- [add any fact you could not observe here, rather than guessing it above]

---

## 8. Handoff note (fill when starting state + rough timeline are done)

Deliver sections 4 and 5 (starting state + a rough timeline) to **Person 2** early so they can
begin the executable `scenarios/fnc_prx_lotus_toronto2024_gf.json`. Region ids in section 2
must be frozen with **Person 1** before the scenario is authored. Refine the timeline and
comms opportunities afterwards.
