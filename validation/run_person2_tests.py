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
    "perception/perception_sensor.gd", "tests/person2/perception_tests.gd",
    "tests/person2/physics_probe.gd",
    "bots/motion_controller.gd", "tests/person2/motion_tests.gd",
    "tests/person2/motion_actor.gd", "tests/person2/motion_navigation.gd",
]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True, help="Godot 4.4.1 executable")
    parser.add_argument("--demo", action="store_true", help="Print the synthetic command trace")
    person3 = parser.add_mutually_exclusive_group()
    person3.add_argument("--person3-root", type=Path, help="Optional Person 3 checkout; copy belief files read-only to the temporary project")
    person3.add_argument("--person3-ref", help="Optional fetched git ref; read Person 3 belief files without changing a checkout")
    parser.add_argument("--person1-ref", help="Optional fetched git ref; test actual shared actor and baked room (requires Person 3 input)")
    args = parser.parse_args()
    if args.person1_ref and not (args.person3_root or args.person3_ref):
        parser.error("--person1-ref requires --person3-root or --person3-ref")
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
            def copy_ref(ref, relative):
                target = project / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                content = subprocess.run(
                    ["git", "show", ref + ":" + relative], cwd=ROOT,
                    capture_output=True, timeout=15, check=True,
                )
                target.write_bytes(content.stdout)

            if args.person3_root or args.person3_ref:
                for relative in ["belief/plain_values.gd", "belief/region_belief.gd", "comms/report_adapter.gd"]:
                    target = project / relative
                    target.parent.mkdir(parents=True, exist_ok=True)
                    if args.person3_ref:
                        copy_ref(args.person3_ref, relative)
                    else:
                        shutil.copy2(args.person3_root / relative, target)
                shutil.copy2(ROOT / "tests/person2/planner_belief_integration.gd", project / "tests/person2/planner_belief_integration.gd")
                shutil.copy2(ROOT / "tests/person2/perception_belief_integration.gd", project / "tests/person2/perception_belief_integration.gd")
            if args.person1_ref:
                for relative in ["actors/actor_base.gd", "actors/health.gd", "world/sandbox_builder.gd", "world/maps/test_room.json"]:
                    copy_ref(args.person1_ref, relative)
                shutil.copy2(ROOT / "tests/person2/motion_integration.gd", project / "tests/person2/motion_integration.gd")
            (project / "project.godot").write_text(
                'config_version=5\n[application]\nconfig/name="Person 2 isolated tests"\n'
                '[rendering]\nrenderer/rendering_method="gl_compatibility"\n',
                encoding="utf-8",
            )
            scripts = [("demo.gd", "PERSON2_DEMO_PASS")] if args.demo else [
                ("run_tests.gd", "PERSON2_TESTS_PASS"),
                ("planner_tests.gd", "PERSON2_PLANNER_PASS"),
                ("perception_tests.gd", "PERSON2_PERCEPTION_PASS"),
                ("motion_tests.gd", "PERSON2_MOTION_PASS"),
            ]
            if args.person3_root or args.person3_ref:
                scripts.append(("planner_belief_integration.gd", "PERSON2_BELIEF_INTEGRATION_PASS"))
                scripts.append(("perception_belief_integration.gd", "PERSON2_SENSOR_INTEGRATION_PASS"))
            if args.person1_ref:
                # Register Person 1's existing class_name Health/ActorBase without
                # touching root settings or modifying their copied source.
                imported = subprocess.run(
                    [godot, "--headless", "--path", str(project), "--editor", "--import"],
                    capture_output=True, text=True, timeout=45,
                )
                output = imported.stdout + imported.stderr
                if imported.returncode or "SCRIPT ERROR" in output or "ERROR:" in output:
                    print(output, end="")
                    return 1
                print("PERSON2_SHARED_IMPORT_PASS (temporary project only)")
                scripts.append(("motion_integration.gd", "PERSON2_MOTION_INTEGRATION_PASS"))
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
