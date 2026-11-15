"""
tools/coords_to_region.py — coordinate→region helper (Person 3, Track A)
==========================================================================
Pure function: given a map's `regions` list (center + size AABB boxes) and
an [x, y, z] point, return which region_id contains the point, or None.

Conventions match world/maps/test_room.json and docs/CONTRACTS.md:
  - Units: meters
  - Y up
  - Vector3 as [x, y, z]
  - Each region has: id, center [x,y,z], size [sx,sy,sz]
  - AABB: the box spans [center - size/2, center + size/2] on each axis.
  - If a point falls on the boundary of two regions, the first region in
    the list that contains it wins (list ordering is Person 1's concern).
  - Returns None if the point is outside all regions.

This module has zero runtime dependencies beyond the Python standard library.
"""

from __future__ import annotations

from typing import Optional


def point_to_region(
    regions: list[dict],
    point: list[float] | tuple[float, float, float],
) -> Optional[str]:
    """
    Return the region_id of the first region whose AABB contains `point`,
    or None if the point is outside all regions.

    Parameters
    ----------
    regions : list of region dicts
        Each dict must have:
          "id"     : str           — unique region identifier
          "center" : [x, y, z]    — center of the AABB in meters
          "size"   : [sx, sy, sz] — full extents of the AABB in meters

    point : [x, y, z]
        The position to test, in the same coordinate space as the regions.

    Returns
    -------
    str or None
        The id of the first containing region, or None.

    Raises
    ------
    ValueError
        If any required field is missing or malformed.
    """
    px, py, pz = _as_xyz(point, "point")

    for region in regions:
        region_id = _require_str(region, "id")
        cx, cy, cz = _as_xyz(region.get("center"), f"region '{region_id}' center")
        sx, sy, sz = _as_xyz(region.get("size"),   f"region '{region_id}' size")

        half_x, half_y, half_z = sx / 2.0, sy / 2.0, sz / 2.0

        if (
            cx - half_x <= px <= cx + half_x
            and cy - half_y <= py <= cy + half_y
            and cz - half_z <= pz <= cz + half_z
        ):
            return region_id

    return None


def build_region_index(regions: list[dict]) -> dict[str, dict]:
    """
    Build a dict keyed by region_id for O(1) region lookup by ID.
    Useful when the validator or interpreter needs repeated per-region access.
    """
    index: dict[str, dict] = {}
    for region in regions:
        region_id = _require_str(region, "id")
        if region_id in index:
            raise ValueError(f"Duplicate region id: {region_id!r}")
        index[region_id] = region
    return index


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _as_xyz(value, label: str) -> tuple[float, float, float]:
    if value is None:
        raise ValueError(f"Missing required field: {label}")
    try:
        x, y, z = value
        return float(x), float(y), float(z)
    except (TypeError, ValueError) as exc:
        raise ValueError(
            f"Expected [x, y, z] for {label}, got {value!r}"
        ) from exc


def _require_str(d: dict, key: str) -> str:
    val = d.get(key)
    if not isinstance(val, str) or not val:
        raise ValueError(f"Region entry missing or empty string field {key!r}: {d!r}")
    return val
