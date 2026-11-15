"""
comms/fetch_vocabulary.py — build the grounding-vocabulary cache (Person 3, Step 5.1)
=====================================================================================
Pulls the free community catalog from valorant-api.com ONCE and writes a compact,
committed cache at comms/vocabulary_cache.json. Run this when online; after that the
interpreter is fully offline (it reads the cache, never the network).

What it caches (and nothing more — keep the file small):
  - Lotus callout regions: {api_id, region_name, super_region_name} straight from the API.
    These are the REAL community callouts, not invented by us. The frozen sandbox region
    IDs (Person 1, seam #1) are a SEPARATE list; see comms/vocabulary.py REGION_IDS.
  - Agent names + their ability names, for the agents named in a scenario.
  - Weapon names.
  - The ability -> sandbox-primitive mapping (smoke=los_blocker, flash=blind,
    molly=area_damage) is NOT from the API; it is our design decision and lives in
    comms/vocabulary.py, cross-checked against utility/abilities.json at runtime.

Usage:
  python comms/fetch_vocabulary.py                 # refresh the cache (needs network)
  python comms/fetch_vocabulary.py --map Lotus     # pick a different map's callouts

License: valorant-api.com is a free community API; data is Riot-owned game data exposed
for community tools. No key, no payment. We cache names/ids only.
"""

from __future__ import annotations

import argparse
import json
import sys
import urllib.request
from pathlib import Path

API = "https://valorant-api.com/v1"
CACHE_PATH = Path(__file__).resolve().parent / "vocabulary_cache.json"
DEFAULT_MAP = "Lotus"


def _get(url: str) -> dict:
    req = urllib.request.Request(url, headers={"User-Agent": "callout-trainer/vocab-cache"})
    with urllib.request.urlopen(req, timeout=30) as resp:  # noqa: S310 (fixed https host)
        return json.loads(resp.read().decode("utf-8"))


def fetch(map_name: str) -> dict:
    maps = _get(f"{API}/maps")["data"]
    the_map = next((m for m in maps if m.get("displayName") == map_name), None)
    if the_map is None:
        raise SystemExit(f"Map {map_name!r} not found in valorant-api.com /maps.")

    callouts = []
    for c in the_map.get("callouts") or []:
        callouts.append({
            "region_name": c.get("regionName"),
            "super_region_name": c.get("superRegionName"),
        })

    agents = _get(f"{API}/agents?isPlayableCharacter=true")["data"]
    agent_vocab = {}
    for a in agents:
        name = a.get("displayName")
        if not name:
            continue
        agent_vocab[name] = [
            ab.get("displayName")
            for ab in (a.get("abilities") or [])
            if ab.get("displayName")
        ]

    weapons = _get(f"{API}/weapons")["data"]
    weapon_names = sorted({w.get("displayName") for w in weapons if w.get("displayName")})

    return {
        "source": "valorant-api.com (free community catalog)",
        "map": map_name,
        "map_uuid": the_map.get("uuid"),
        "callouts": callouts,
        "agents": agent_vocab,
        "weapons": weapon_names,
    }


def main() -> None:
    p = argparse.ArgumentParser(description="Refresh the grounding-vocabulary cache.")
    p.add_argument("--map", default=DEFAULT_MAP, help=f"Map name (default: {DEFAULT_MAP})")
    p.add_argument("--out", default=str(CACHE_PATH), help="Output cache path.")
    args = p.parse_args()

    print(f"[fetch_vocabulary] pulling {args.map} vocab from {API} …", file=sys.stderr)
    data = fetch(args.map)
    Path(args.out).write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    print(
        f"[fetch_vocabulary] wrote {args.out}: "
        f"{len(data['callouts'])} callouts, {len(data['agents'])} agents, "
        f"{len(data['weapons'])} weapons.",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
