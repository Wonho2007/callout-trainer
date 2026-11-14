"""Run isolated Godot tests without editing Person 1's project settings.

Usage: python validation/run_person2_tests.py --godot /path/to/godot [--demo]
"""
import argparse
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import traceback

ROOT = Path(__file__).resolve().parents[1]
FILES = [
    "perception/plain_data.gd", "perception/observation_inbox.gd",
    "validation/comms_validator.gd", "bots/command_executor.gd",
    "schemas/comms_v1.schema.json", "examples/comms_v1.json",
    "tests/person2/fake_actor.gd", "tests/person2/run_tests.gd",
    "bots/knowledge_planner.gd", "tests/person2/planner_tests.gd",
    "scenarios/synthetic_coverage.json",
]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True, help="Godot 4.4.1 executable")
    parser.add_argument("--demo", action="store_true", help="Print the synthetic command trace")
    parser.add_argument("--person3-root", type=Path, help="Optional Person 3 checkout; copy belief files read-only to the temporary project")
    args = parser.parse_args()
    godot = shutil.which(args.godot) or str(Path(args.godot).resolve())
    try:
        version = subprocess.run([godot, "--version"], capture_output=True, text=True, timeout=15, check=True)
        if not version.stdout.strip().startswith("4.4.1.stable"):
            raise RuntimeError("Expected Person 1's Godot 4.4.1 stable; got " + version.stdout.strip())
        with tempfile.TemporaryDirectory(prefix="callout-person2-") as temporary:
            project = Path(temporary)
            files = FILES + (["tests/person2/demo.gd"] if args.demo else [])
            for relative in files:
                target = project / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(ROOT / relative, target)
            if args.person3_root:
                for relative in ["belief/plain_values.gd", "belief/region_belief.gd", "comms/report_adapter.gd"]:
                    target = project / relative
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(args.person3_root / relative, target)
                shutil.copy2(ROOT / "tests/person2/planner_belief_integration.gd", project / "tests/person2/planner_belief_integration.gd")
            (project / "project.godot").write_text(
                'config_version=5\n[application]\nconfig/name="Person 2 isolated tests"\n'
                '[rendering]\nrenderer/rendering_method="gl_compatibility"\n',
                encoding="utf-8",
            )
            scripts = [("demo.gd", "PERSON2_DEMO_PASS")] if args.demo else [
                ("run_tests.gd", "PERSON2_TESTS_PASS"),
                ("planner_tests.gd", "PERSON2_PLANNER_PASS"),
            ]
            if args.person3_root:
                scripts.append(("planner_belief_integration.gd", "PERSON2_BELIEF_INTEGRATION_PASS"))
            for script, marker in scripts:
                result = subprocess.run(
                    [godot, "--headless", "--path", str(project), "--script", "res://tests/person2/" + script],
                    capture_output=True, text=True, timeout=45,
                )
                output = result.stdout + result.stderr
                print(output, end="")
                if result.returncode or marker not in output or "SCRIPT ERROR" in output or "ERROR:" in output:
                    return 1
    except (OSError, RuntimeError, subprocess.SubprocessError) as exc:
        print("Person 2 checks failed: " + str(exc), file=sys.stderr)
        traceback.print_exc()
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
