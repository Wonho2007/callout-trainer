"""
tools/validate_scenario.py — scenario JSON validator (Person 3, Track A)
=========================================================================
Validates a scenario file against schemas/scenario.schema.json AND performs
semantic checks that the schema alone cannot express:

  1. JSON Schema (Draft 2020-12) structural validation
  2. Every start_region and timeline/branch region is a real region id in the map
  3. spike_site_region is a real region id (or "unknown")
  4. spike_planted is present (structural, enforced by schema)
  5. Every ability_id in actor utility exists in utility/abilities.json
  6. Branch weights sum to 1.0 (within a small tolerance)
  7. Timeline beats are time-ordered (non-decreasing ticks)
  8. Unknown/unknown-valued fields are flagged (not silently dropped)

Exit codes:
  0  — validation passed (possibly with warnings)
  1  — validation failed (errors reported to stderr)

Usage:
  python tools/validate_scenario.py examples/scenario_sample_synthetic.json
  python tools/validate_scenario.py path/to/scenario.json --map world/maps/custom.json
  python tools/validate_scenario.py path/to/scenario.json --abilities utility/abilities.json

Install dependency (already in .venv if you have been following the README):
  pip install jsonschema
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SCHEMA = REPO_ROOT / "schemas" / "scenario.schema.json"
DEFAULT_ABILITIES = REPO_ROOT / "utility" / "abilities.json"
BRANCH_WEIGHT_TOLERANCE = 1e-6


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Validate a callout-trainer scenario JSON file."
    )
    parser.add_argument("scenario", help="Path to the scenario JSON file to validate.")
    parser.add_argument(
        "--schema", default=str(DEFAULT_SCHEMA),
        help=f"Path to the JSON Schema file (default: {DEFAULT_SCHEMA})",
    )
    parser.add_argument(
        "--map", default=None,
        help="Path to the map JSON file. Overrides map_file field in the scenario.",
    )
    parser.add_argument(
        "--abilities", default=str(DEFAULT_ABILITIES),
        help=f"Path to utility/abilities.json (default: {DEFAULT_ABILITIES})",
    )
    parser.add_argument(
        "--strict-unknown", action="store_true",
        help="Treat unknown-valued fields as errors instead of warnings.",
    )
    args = parser.parse_args()

    errors: list[str] = []
    warnings: list[str] = []

    # ------------------------------------------------------------------
    # 1. Load files
    # ------------------------------------------------------------------
    scenario_path = Path(args.scenario)
    if not scenario_path.exists():
        _die(f"Scenario file not found: {scenario_path}")

    scenario = _load_json(scenario_path)
    schema = _load_json(Path(args.schema))
    abilities_data = _load_json(Path(args.abilities))
    known_ability_ids = {a["id"] for a in abilities_data.get("abilities", [])}

    # Determine map file
    map_path: Path | None = None
    if args.map:
        map_path = Path(args.map)
    elif "map_file" in scenario:
        map_path = REPO_ROOT / scenario["map_file"]

    map_regions: dict[str, dict] = {}
    if map_path:
        if not map_path.exists():
            errors.append(f"Map file not found: {map_path}")
        else:
            map_data = _load_json(map_path)
            for region in map_data.get("regions", []):
                rid = region.get("id")
                if rid:
                    map_regions[rid] = region
            if not map_regions:
                warnings.append(
                    f"Map file loaded but contains no regions: {map_path}"
                )
    else:
        warnings.append(
            "No map file provided (no --map flag and no map_file in scenario). "
            "Region ID checks will be skipped."
        )

    # ------------------------------------------------------------------
    # 2. JSON Schema validation
    # ------------------------------------------------------------------
    schema_errors = _jsonschema_validate(scenario, schema)
    errors.extend(schema_errors)

    # If the schema check hard-failed, still try semantic checks but note it
    if schema_errors:
        warnings.append(
            "JSON Schema validation failed; semantic checks may report cascading errors."
        )

    # ------------------------------------------------------------------
    # 3. Semantic checks (run regardless so all errors surface at once)
    # ------------------------------------------------------------------

    # 3a. Region ID validity
    if map_regions:
        # spike_site_region
        rsc = scenario.get("round_context", {}).get("spike_site_region")
        if rsc and rsc != "unknown" and rsc not in map_regions:
            errors.append(
                f"round_context.spike_site_region {rsc!r} is not a known region id. "
                f"Known ids: {sorted(map_regions)}"
            )

        # actor start_regions
        for actor in scenario.get("actors", []):
            sr = actor.get("start_region")
            if sr and sr != "unknown" and sr not in map_regions:
                errors.append(
                    f"Actor {actor.get('id')!r}: start_region {sr!r} is not a known region id."
                )

        # timeline beats
        for i, beat in enumerate(scenario.get("timeline", [])):
            reg = beat.get("region")
            if reg and reg != "unknown" and reg not in map_regions:
                errors.append(
                    f"Timeline beat [{i}] actor={beat.get('actor_id')!r} tick={beat.get('tick')}: "
                    f"region {reg!r} is not a known region id."
                )

        # branch beats
        for branch in scenario.get("branches", []):
            for i, beat in enumerate(branch.get("beats", [])):
                reg = beat.get("region")
                if reg and reg != "unknown" and reg not in map_regions:
                    errors.append(
                        f"Branch {branch.get('id')!r} beat [{i}] actor={beat.get('actor_id')!r}: "
                        f"region {reg!r} is not a known region id."
                    )

    # 3b. Ability ID validity
    for actor in scenario.get("actors", []):
        for slot in actor.get("utility", []):
            aid = slot.get("ability_id")
            if aid and aid not in known_ability_ids:
                errors.append(
                    f"Actor {actor.get('id')!r}: ability_id {aid!r} not found in "
                    f"utility/abilities.json. Known ids: {sorted(known_ability_ids)}"
                )

    # 3c. Branch weights sum to 1.0
    branches = scenario.get("branches", [])
    if branches:
        total_weight = sum(b.get("weight", 0.0) for b in branches)
        if abs(total_weight - 1.0) > BRANCH_WEIGHT_TOLERANCE:
            errors.append(
                f"Branch weights sum to {total_weight:.6f}, expected 1.0 "
                f"(tolerance {BRANCH_WEIGHT_TOLERANCE}). "
                f"Branch ids: {[b.get('id') for b in branches]}"
            )

    # 3d. Timeline is time-ordered (non-decreasing ticks)
    timeline = scenario.get("timeline", [])
    prev_tick = -1
    for i, beat in enumerate(timeline):
        tick = beat.get("tick")
        if tick is None:
            continue  # schema will have caught this
        if tick < prev_tick:
            errors.append(
                f"Timeline is not time-ordered: beat [{i}] tick={tick} < "
                f"beat [{i-1}] tick={prev_tick}. Timeline must be non-decreasing."
            )
        prev_tick = tick

    # 3e. Flag unknown-valued fields (warn or error)
    unknown_paths = _find_unknown_values(scenario)
    if unknown_paths:
        msg = (
            f"Fields with value 'unknown' (acceptable, but flag for annotation follow-up): "
            f"{unknown_paths}"
        )
        if args.strict_unknown:
            errors.append(msg)
        else:
            warnings.append(msg)

    # 3f. spike_planted must be present (belt-and-suspenders; schema requires it)
    if "round_context" in scenario and "spike_planted" not in scenario["round_context"]:
        errors.append("round_context.spike_planted is required but missing.")

    # ------------------------------------------------------------------
    # 4. Report
    # ------------------------------------------------------------------
    for w in warnings:
        print(f"WARNING: {w}", file=sys.stderr)

    if errors:
        print(f"\nVALIDATION FAILED — {len(errors)} error(s):", file=sys.stderr)
        for e in errors:
            print(f"  ERROR: {e}", file=sys.stderr)
        sys.exit(1)
    else:
        print(
            f"OK: {scenario_path.name} passed all checks "
            f"({len(warnings)} warning(s), 0 errors)."
        )


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _load_json(path: Path) -> dict:
    try:
        with path.open(encoding="utf-8") as f:
            return json.load(f)
    except json.JSONDecodeError as exc:
        _die(f"JSON parse error in {path}: {exc}")
    except OSError as exc:
        _die(f"Could not read {path}: {exc}")


def _jsonschema_validate(instance: dict, schema: dict) -> list[str]:
    """Run jsonschema Draft 2020-12 validation. Returns list of error strings."""
    try:
        import jsonschema  # type: ignore
        from jsonschema import Draft202012Validator  # type: ignore
    except ImportError:
        return [
            "jsonschema is not installed. Run: pip install jsonschema\n"
            "Schema structural validation was skipped."
        ]

    validator = Draft202012Validator(schema)
    errs = sorted(validator.iter_errors(instance), key=lambda e: list(e.path))
    return [
        f"Schema error at {_path_str(e.path)}: {e.message}" for e in errs
    ]


def _path_str(path) -> str:
    parts = list(path)
    if not parts:
        return "(root)"
    return ".".join(str(p) for p in parts)


def _find_unknown_values(obj, _path: str = "") -> list[str]:
    """Recursively find all paths where the value is the string 'unknown'."""
    found: list[str] = []
    if isinstance(obj, dict):
        for k, v in obj.items():
            child_path = f"{_path}.{k}" if _path else k
            found.extend(_find_unknown_values(v, child_path))
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            found.extend(_find_unknown_values(v, f"{_path}[{i}]"))
    elif obj == "unknown":
        found.append(_path)
    return found


def _die(msg: str) -> None:
    print(f"FATAL: {msg}", file=sys.stderr)
    sys.exit(1)


if __name__ == "__main__":
    main()
