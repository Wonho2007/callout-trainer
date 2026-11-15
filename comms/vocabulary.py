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
  2. FROZEN sandbox region IDs (Person 1, seam #1 in the handoffs). These are what a
     comms.v1 report's region_id MUST be. They are NOT frozen yet, so REGION_IDS below
     is a clearly-labeled PLACEHOLDER. When Person 1 freezes the Lotus B region list,
     replace REGION_IDS and ALIASES with the real ids and re-run the tests.

The ability->primitive mapping is our design decision (brief 6.3 / utility/abilities.json),
not API data: smoke=los_blocker, flash/blind_wave=blind, molly=area_damage, scan=recon.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Optional

_CACHE_PATH = Path(__file__).resolve().parent / "vocabulary_cache.json"

# ---------------------------------------------------------------------------
# PLACEHOLDER sandbox region ids. NOT FROZEN. Replace with Person 1's frozen
# Lotus B region list (seam #1) when available. These names are deliberately
# generic Lotus B-area callouts so no pro position is invented; they are the
# vocabulary the executor would accept, not claims about the real round.
# ---------------------------------------------------------------------------
REGION_IDS: list[str] = [
    "b_main",
    "b_site",
    "b_pit",
    "b_link",
    "b_tree",
    "b_hut",
    "b_drop",
    "b_ct",
    "mid",
    "heaven",
]
REGIONS_FROZEN: bool = False  # flip to True only after Person 1 freezes the list

# Natural-language callout -> frozen region id. Many spoken forms, one id.
# Keep lowercase keys; the interpreter lowercases spoken text before lookup.
# These are aliases for the PLACEHOLDER ids above; revisit when ids are frozen.
REGION_ALIASES: dict[str, str] = {
    "b main": "b_main", "bee main": "b_main", "b-main": "b_main",
    "b site": "b_site", "site": "b_site", "b": "b_site",
    "pit": "b_pit", "b pit": "b_pit",
    "link": "b_link", "b link": "b_link",
    "tree": "b_tree", "trees": "b_tree",
    "hut": "b_hut",
    "drop": "b_drop",
    "ct": "b_ct", "ct spawn": "b_ct", "back site": "b_ct",
    "mid": "mid", "middle": "mid",
    "heaven": "heaven",
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
