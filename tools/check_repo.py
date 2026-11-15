"""Documentation and synthetic-fixture checks, not gameplay/fairness validation."""
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]


def check():
    required = [
        "README.md", "AGENTS.md", "CONTRIBUTING.md", "callout_trainer_brief.md",
        "docs/TEAM.md", "docs/CONTRACTS.md", "docs/DECISIONS.md", "docs/HANDOFFS.md",
        "examples/interface_fixture.json",
    ]
    for name in required:
        assert (ROOT / name).is_file(), f"Missing {name}"
    for path in ROOT.rglob("*.md"):
        parts = path.relative_to(ROOT).parts
        if ".git" in parts or ".venv" in parts:
            continue
        content = path.read_text(encoding="utf-8")
        for target in re.findall(r"\]\(([^)]+)\)", content):
            if "://" in target or target.startswith(("#", "mailto:")):
                continue
            target = target.split("#", 1)[0]
            if target:
                assert (path.parent / target).exists(), f"{path}: broken link {target}"
    fixture = json.loads((ROOT / "examples/interface_fixture.json").read_text())
    assert fixture["synthetic"] is True
    regions = {r["id"] for r in fixture["regions"]}
    observations = {o["id"]: o for o in fixture["observations"]}
    assert len(observations) == len(fixture["observations"])
    for obs in observations.values():
        assert obs["available_tick"] >= obs["event_tick"]
        assert obs["content"]["region_id"] in regions
    for decision in fixture["decisions"]:
        assert decision["goal_region_id"] in regions
        assert decision["aim_region_id"] in regions
        for evidence_id in decision["evidence_ids"]:
            obs = observations[evidence_id]
            assert obs["bot_id"] == decision["bot_id"]
            assert obs["available_tick"] <= decision["tick"]
    print("PASS: documentation links and synthetic fixture consistency.")
    print("No gameplay, Godot, leak-test or evaluation results are asserted.")


if __name__ == "__main__":
    check()
