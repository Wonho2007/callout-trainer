"""
tests/test_coords_to_region.py — unit tests for tools/coords_to_region.py
===========================================================================
Uses only the Python standard library (unittest). No Godot, no network.

Regions are from world/maps/test_room.json (synthetic test room):
  region_a   center=[-6, 1, -6]  size=[6, 4, 6]  → x ∈ [-9,-3], y ∈ [-1,3], z ∈ [-9,-3]
  region_b   center=[ 6, 1,  6]  size=[6, 4, 6]  → x ∈ [ 3, 9], y ∈ [-1,3], z ∈ [ 3, 9]
  region_mid center=[ 0, 1,  0]  size=[6, 4, 6]  → x ∈ [-3, 3], y ∈ [-1,3], z ∈ [-3, 3]

Run with: python -m pytest tests/test_coords_to_region.py -v
       or: python tests/test_coords_to_region.py
"""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

# Allow running from repo root without installing as a package
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools.coords_to_region import point_to_region, build_region_index  # noqa: E402

# ---------------------------------------------------------------------------
# Test fixtures — matches world/maps/test_room.json exactly
# ---------------------------------------------------------------------------
TEST_ROOM_REGIONS = [
    {"id": "region_a",   "name": "A",   "center": [-6, 1, -6], "size": [6, 4, 6]},
    {"id": "region_b",   "name": "B",   "center": [ 6, 1,  6], "size": [6, 4, 6]},
    {"id": "region_mid", "name": "Mid", "center": [ 0, 1,  0], "size": [6, 4, 6]},
]


class TestPointToRegion(unittest.TestCase):

    # ------------------------------------------------------------------
    # Points clearly inside a region
    # ------------------------------------------------------------------
    def test_center_of_region_a(self):
        """Center of region_a → region_a."""
        self.assertEqual(point_to_region(TEST_ROOM_REGIONS, [-6, 1, -6]), "region_a")

    def test_center_of_region_b(self):
        """Center of region_b → region_b."""
        self.assertEqual(point_to_region(TEST_ROOM_REGIONS, [6, 1, 6]), "region_b")

    def test_center_of_region_mid(self):
        """Center of region_mid → region_mid."""
        self.assertEqual(point_to_region(TEST_ROOM_REGIONS, [0, 1, 0]), "region_mid")

    def test_inside_region_a_non_center(self):
        """Off-center point inside region_a bounds."""
        # region_a x ∈ [-9,-3], y ∈ [-1,3], z ∈ [-9,-3]
        self.assertEqual(point_to_region(TEST_ROOM_REGIONS, [-7, 2, -5]), "region_a")

    def test_inside_region_b_non_center(self):
        """Off-center point inside region_b bounds."""
        # region_b x ∈ [3,9], y ∈ [-1,3], z ∈ [3,9]
        self.assertEqual(point_to_region(TEST_ROOM_REGIONS, [4, 0, 7]), "region_b")

    def test_inside_region_mid_non_center(self):
        """Off-center point inside region_mid bounds."""
        # region_mid x ∈ [-3,3], y ∈ [-1,3], z ∈ [-3,3]
        self.assertEqual(point_to_region(TEST_ROOM_REGIONS, [1, 0.5, -2]), "region_mid")

    # ------------------------------------------------------------------
    # Points clearly outside all regions
    # ------------------------------------------------------------------
    def test_outside_all_regions_corner(self):
        """Corner of map outside all regions → None."""
        self.assertIsNone(point_to_region(TEST_ROOM_REGIONS, [9, 1, -9]))

    def test_outside_above_ceiling(self):
        """Above the ceiling (y > 3) → None."""
        self.assertIsNone(point_to_region(TEST_ROOM_REGIONS, [0, 5, 0]))

    def test_outside_below_floor(self):
        """Below region floor (y < -1) → None."""
        self.assertIsNone(point_to_region(TEST_ROOM_REGIONS, [0, -2, 0]))

    def test_outside_between_regions(self):
        """Gap between region_a and region_mid → None."""
        # region_a ends at x=-3; region_mid starts at x=-3; so this tests the exact gap
        # Slightly outside both: x=-9.1 is outside region_a (which ends at -9)
        self.assertIsNone(point_to_region(TEST_ROOM_REGIONS, [-9.1, 1, -6]))

    def test_empty_region_list(self):
        """No regions → always None."""
        self.assertIsNone(point_to_region([], [0, 0, 0]))

    # ------------------------------------------------------------------
    # Boundary / edge cases (inclusive boundary: <= and >=)
    # ------------------------------------------------------------------
    def test_on_min_boundary_region_a(self):
        """Point exactly on the minimum corner of region_a → region_a."""
        # min corner: [-9, -1, -9]
        self.assertEqual(point_to_region(TEST_ROOM_REGIONS, [-9, -1, -9]), "region_a")

    def test_on_max_boundary_region_a(self):
        """Point exactly on the maximum corner of region_a → region_a."""
        # max corner: [-3, 3, -3]
        self.assertEqual(point_to_region(TEST_ROOM_REGIONS, [-3, 3, -3]), "region_a")

    def test_on_min_boundary_region_b(self):
        """Point exactly on the minimum corner of region_b → region_b."""
        # min corner: [3, -1, 3]
        self.assertEqual(point_to_region(TEST_ROOM_REGIONS, [3, -1, 3]), "region_b")

    def test_on_max_boundary_region_b(self):
        """Point exactly on the maximum corner of region_b → region_b."""
        # max corner: [9, 3, 9]
        self.assertEqual(point_to_region(TEST_ROOM_REGIONS, [9, 3, 9]), "region_b")

    def test_just_outside_min_boundary_region_a(self):
        """Point just past the min-x boundary of region_a → None."""
        self.assertIsNone(point_to_region(TEST_ROOM_REGIONS, [-9.001, 1, -6]))

    def test_just_outside_max_boundary_region_b(self):
        """Point just past the max-z boundary of region_b → None."""
        self.assertIsNone(point_to_region(TEST_ROOM_REGIONS, [6, 1, 9.001]))

    # ------------------------------------------------------------------
    # First-match ordering
    # ------------------------------------------------------------------
    def test_first_match_wins(self):
        """When regions overlap, the first region in the list wins."""
        # Create two overlapping regions; point is in both
        overlapping = [
            {"id": "first",  "center": [0, 0, 0], "size": [4, 4, 4]},
            {"id": "second", "center": [0, 0, 0], "size": [4, 4, 4]},
        ]
        self.assertEqual(point_to_region(overlapping, [0, 0, 0]), "first")

    # ------------------------------------------------------------------
    # Tuple input (not just list)
    # ------------------------------------------------------------------
    def test_tuple_point_input(self):
        """point can be a tuple as well as a list."""
        self.assertEqual(point_to_region(TEST_ROOM_REGIONS, (-6, 1, -6)), "region_a")

    # ------------------------------------------------------------------
    # Error handling
    # ------------------------------------------------------------------
    def test_missing_center_raises(self):
        """Region with no 'center' field raises ValueError."""
        bad_regions = [{"id": "bad", "size": [2, 2, 2]}]
        with self.assertRaises(ValueError):
            point_to_region(bad_regions, [0, 0, 0])

    def test_missing_size_raises(self):
        """Region with no 'size' field raises ValueError."""
        bad_regions = [{"id": "bad", "center": [0, 0, 0]}]
        with self.assertRaises(ValueError):
            point_to_region(bad_regions, [0, 0, 0])

    def test_missing_id_raises(self):
        """Region with no 'id' field raises ValueError."""
        bad_regions = [{"center": [0, 0, 0], "size": [2, 2, 2]}]
        with self.assertRaises(ValueError):
            point_to_region(bad_regions, [0, 0, 0])


class TestBuildRegionIndex(unittest.TestCase):

    def test_index_has_all_ids(self):
        index = build_region_index(TEST_ROOM_REGIONS)
        self.assertIn("region_a", index)
        self.assertIn("region_b", index)
        self.assertIn("region_mid", index)
        self.assertEqual(len(index), 3)

    def test_index_values_are_original_dicts(self):
        index = build_region_index(TEST_ROOM_REGIONS)
        self.assertEqual(index["region_a"]["center"], [-6, 1, -6])

    def test_duplicate_id_raises(self):
        dup = [
            {"id": "dup", "center": [0, 0, 0], "size": [1, 1, 1]},
            {"id": "dup", "center": [5, 0, 5], "size": [1, 1, 1]},
        ]
        with self.assertRaises(ValueError):
            build_region_index(dup)


if __name__ == "__main__":
    unittest.main()
