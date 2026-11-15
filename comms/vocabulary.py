"""
comms/vocabulary.py — grounding vocabulary for the LLM interpreter (Person 3, Step 5.1)
========================================================================================
Produces the compact vocabulary object the interpreter hands the model as context:
the region IDs the model is ALLOWED to emit, the agents/abilities in a scenario, the
ability->sandbox-primitive mapping, and weapon names. The model may use ONLY these
tokens; anything else is a hallucination the output validator rejects.

Two separate name spaces — keep them straight:
  1. REAL community callouts from valorant-api.com (comms/vocabulary_cache.json).
     These ground natural language ("they're on heaven", "B main") but are NOT the
     IDs the executor understands.
  2. FROZEN sandbox region IDs (annotation §2, frozen with the team). These are what a
     comms.v1 report's region_id MUST be: the 7 Lotus B-scenario ids in REGION_IDS below.
     Person 1 still owes the world-space Area3D bounds for each; the ids themselves are
     frozen as the belief-space/vocabulary contract.

The ability->primitive mapping is our design decision (brief 6.3 / utility/abilities.json),
not API data: smoke=los_blocker, flash/blind_wave=blind, molly=area_damage, scan=recon.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Optional

_CACHE_PATH = Path(__file__).resolve().parent / "vocabulary_cache.json"

# ---------------------------------------------------------------------------
# FROZEN sandbox region ids for the FNC vs PRX Lotus B scenario
# (annotations/fnc_prx_lotus_toronto2024_gf.md §2). These are the informal
# community Lotus B callouts the scenario uses, frozen with the team as the
# belief-space vocabulary. Person 1 later gives each a world-space Area3D bound;
# the coordinate->region helper bridges them. No pro position is invented here.
# ---------------------------------------------------------------------------
REGION_IDS: list[str] = [
    "b_main",
    "b_cubby",
    "b_heaven",
    "b_upper",
    "b_pit",
    "c_link",
    "a_link",
]
REGIONS_FROZEN: bool = True  # frozen for this scenario (annotation §2)

# Natural-language callout -> frozen region id. Many spoken forms, one id.
# Keep lowercase keys; the interpreter lowercases spoken text before lookup.
REGION_ALIASES: dict[str, str] = {
    "b main": "b_main", "bee main": "b_main", "b-main": "b_main", "main": "b_main",
    "cubby": "b_cubby", "b cubby": "b_cubby",
    "heaven": "b_heaven", "b heaven": "b_heaven",
    "upper": "b_upper", "b upper": "b_upper",
    "pit": "b_pit", "b pit": "b_pit",
    "c link": "c_link", "c-link": "c_link", "see link": "c_link",
    "a link": "a_link", "a-link": "a_link", "ay link": "a_link",
}

# Ability-id (utility/abilities.json) -> sandbox primitive. Our mapping, not API data.
ABILITY_PRIMITIVE: dict[str, str] = {
    "smoke": "los_blocker",
    "flash": "blind",
    "blind_wave": "blind",
    "molly": "area_damage",
    "scan_orb": "recon",
}

# Spoken utility word -> sandbox ability id. The interpreter maps "flash"->throw_flash
# command; "smoke"/"molly" are reports/context (no command action exists for them yet).
UTILITY_ALIASES: dict[str, str] = {
    "flash": "flash", "flashbang": "flash", "pop flash": "flash",
    "smoke": "smoke", "smokes": "smoke",
    "molly": "molly", "molotov": "molly", "incendiary": "molly", "fire": "molly",
    "scan": "scan_orb", "recon": "scan_orb",
}


def load_cache(path: Optional[Path] = None) -> dict:
    """Load the committed valorant-api.com cache. Offline; raises if missing."""
    p = path or _CACHE_PATH
    if not p.exists():
        raise FileNotFoundError(
            f"vocabulary cache not found at {p}. Run: python comms/fetch_vocabulary.py"
        )
    return json.loads(p.read_text(encoding="utf-8"))


def build_vocabulary(
    scenario_agents: Optional[list[str]] = None,
    region_ids: Optional[list[str]] = None,
    cache: Optional[dict] = None,
) -> dict:
    """
    Build the compact vocabulary object passed to the model as grounding context.

    Parameters
    ----------
    scenario_agents : list[str] or None
        Agent display names present in THIS scenario (filters the agent/ability lists).
        None -> include no agent abilities (keeps the prompt small); pass the scenario's
        actors to enable agent/ability grounding.
    region_ids : list[str] or None
        Override the frozen region id list. Defaults to REGION_IDS (placeholder).
    cache : dict or None
        Pre-loaded cache; defaults to load_cache().

    Returns
    -------
    dict with keys: map, region_ids, regions_frozen, callouts, agents, abilities,
    weapons, primitives. All copied values; no live objects.
    """
    cache = cache or load_cache()
    regions = list(region_ids) if region_ids is not None else list(REGION_IDS)

    agent_abilities: dict[str, list[str]] = {}
    if scenario_agents:
        for name in scenario_agents:
            if name in cache.get("agents", {}):
                agent_abilities[name] = list(cache["agents"][name])

    return {
        "map": cache.get("map"),
        "region_ids": regions,
        "regions_frozen": REGIONS_FROZEN if region_ids is None else True,
        "callouts": list(cache.get("callouts", [])),
        "agents": agent_abilities,
        "weapons": list(cache.get("weapons", [])),
        "primitives": dict(ABILITY_PRIMITIVE),
    }


def resolve_region(spoken: str, region_ids: Optional[list[str]] = None) -> Optional[str]:
    """
    Map a spoken callout phrase to a frozen region id, or None if unresolved.
    Exact id match wins first, then the alias table. Case-insensitive.
    Returns None on ambiguity-by-absence so the caller asks instead of guessing.
    """
    regions = region_ids if region_ids is not None else REGION_IDS
    s = spoken.strip().lower()
    if s in regions:
        return s
    if s in REGION_ALIASES and REGION_ALIASES[s] in regions:
        return REGION_ALIASES[s]
    return None


def resolve_utility(spoken: str) -> Optional[str]:
    """Map a spoken utility word to a sandbox ability id, or None."""
    return UTILITY_ALIASES.get(spoken.strip().lower())
