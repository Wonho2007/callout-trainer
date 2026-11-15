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
    "bots/intent_gate.gd", "tests/person2/intent_gate_tests.gd",
]


def git_read(arguments, *, text=False):
    # This launcher intentionally reads THIS checkout's committed files. The
    # shared Windows workspace may be owned by the sandbox account instead of
    # the person launching it. Trust only this resolved root for this command;
    # never persist global config or trust an arbitrary parent/directory list.
    result = subprocess.run(
        ["git", "-c", "safe.directory=" + ROOT.resolve().as_posix(), *arguments],
        cwd=ROOT, capture_output=True, text=text, timeout=15,
    )
    if result.returncode:
        detail = result.stderr if text else result.stderr.decode("utf-8", errors="replace")
        raise RuntimeError(
            "Git read failed: git " + " ".join(arguments) + "\n" + detail.strip()
            + "\nIf the named revision is unavailable, fetch the teammate branches with git fetch origin."
        )
    return result.stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True, help="Godot 4.4.1 executable")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--demo", action="store_true", help="Print the synthetic command trace")
    mode.add_argument("--visual-demo", action="store_true", help="Open the standalone interactive movement demo (close window to exit)")
    mode.add_argument("--visual-smoke", action="store_true", help="Headless automated check of the visual demo's action callbacks")
    mode.add_argument("--first-person", action="store_true", help="Open the shared first-person sandbox with a teammate (voice/model host seam, no menu)")
    mode.add_argument("--first-person-smoke", action="store_true", help="Headless first-person scene/comm/intent integration assertions")
    person3 = parser.add_mutually_exclusive_group()
    person3.add_argument("--person3-root", type=Path, help="Optional Person 3 checkout; copy belief files read-only to the temporary project")
    person3.add_argument("--person3-ref", help="Optional fetched git ref; read Person 3 belief files without changing a checkout")
    parser.add_argument("--person1-ref", help="Optional fetched git ref; test actual shared actor and baked room (requires Person 3 input)")
    args = parser.parse_args()
    first_person = args.first_person or args.first_person_smoke
    visual = args.visual_demo or args.visual_smoke
    if visual or first_person:
        args.person1_ref = args.person1_ref or ("origin/main" if first_person else "0fd1285")
        if not (args.person3_root or args.person3_ref):
            args.person3_ref = "57f809d" if first_person else "ff2a6d7"
    if args.person1_ref and not (args.person3_root or args.person3_ref):
        parser.error("--person1-ref requires --person3-root or --person3-ref")
    godot = shutil.which(args.godot) or str(Path(args.godot).resolve())
    try:
        version = subprocess.run([godot, "--version"], capture_output=True, text=True, timeout=15, check=True)
        if not version.stdout.strip().startswith("4.4.1.stable"):
            raise RuntimeError("Expected Person 1's Godot 4.4.1 stable; got " + version.stdout.strip())
        # Freeze each selected ref once per run so a simultaneous fetch cannot
        # mix source versions. FPS defaults follow the latest locally fetched
        # main rather than remaining pinned to an old Person 1 map revision.
        for field in ["person1_ref", "person3_ref"]:
            selected = getattr(args, field)
            if selected:
                revision = git_read(["rev-parse", "--verify", selected + "^{commit}"], text=True).strip()
                setattr(args, field, revision)
                print("PERSON2_DEPENDENCY " + field + "=" + revision)
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
                target.write_bytes(git_read(["show", ref + ":" + relative]))

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
            if first_person:
                # Reuse the actual shared FPS scene/settings/assets, read-only.
                listing = git_read(
                    ["ls-tree", "-r", "--name-only", args.person1_ref, "--",
                     "actors", "weapons", "utility", "world", "scenes/player",
                     "scenes/main.gd", "scenes/main.gd.uid", "scenes/main.tscn",
                     "recording/game_events.gd", "recording/game_events.gd.uid",
                     "ui/minimap.gd", "ui/minimap.gd.uid", "project.godot", "icon.svg"], text=True,
                )
                for relative in listing.splitlines():
                    copy_ref(args.person1_ref, relative)
                for relative in ["bots/teammate_runtime.gd", "scenes/bots/bot.tscn",
                                 "scenes/bots/first_person.gd", "scenes/bots/first_person.tscn",
                                 "scenarios/b_site_coverage.json",
                                 "tests/person2/first_person_smoke.gd"]:
                    target = project / relative
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(ROOT / relative, target)
            if visual:
                for relative in ["scenes/bots/motion_visual_demo.gd", "scenes/bots/motion_visual_demo.tscn"]:
                    target = project / relative
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(ROOT / relative, target)
            if first_person:
                settings = (project / "project.godot").read_text(encoding="utf-8")
                settings = settings.replace('run/main_scene="res://scenes/main.tscn"',
                                            'run/main_scene="res://scenes/bots/first_person.tscn"')
                (project / "project.godot").write_text(settings, encoding="utf-8")
            else:
                (project / "project.godot").write_text(
                    'config_version=5\n[application]\nconfig/name="Person 2 isolated tests"\n'
                    + ('run/main_scene="res://scenes/bots/motion_visual_demo.tscn"\n'
                       '[display]\nwindow/size/viewport_width=1440\nwindow/size/viewport_height=900\n'
                       'window/size/window_width_override=1280\nwindow/size/window_height_override=800\n'
                       'window/stretch/mode="canvas_items"\n' if visual else '')
                    + '[rendering]\nrenderer/rendering_method="gl_compatibility"\n',
                    encoding="utf-8",
                )
            scripts = [("demo.gd", "PERSON2_DEMO_PASS")] if args.demo else [
                ("run_tests.gd", "PERSON2_TESTS_PASS"),
                ("planner_tests.gd", "PERSON2_PLANNER_PASS"),
                ("perception_tests.gd", "PERSON2_PERCEPTION_PASS"),
                ("motion_tests.gd", "PERSON2_MOTION_PASS"),
                ("intent_gate_tests.gd", "PERSON2_INTENT_GATE_PASS"),
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
            if args.visual_demo or args.first_person:
                print("Opening first-person scene (voice backend not connected). Close the window to return."
                      if args.first_person else "Opening overhead motion test. Close window or press Esc to return.", flush=True)
                # Human-controlled run: keep the temporary project alive until
                # the window closes; no short test timeout or headless flag.
                return subprocess.run([godot, "--path", str(project)], check=False).returncode
            if args.first_person_smoke:
                result = subprocess.run(
                    [godot, "--headless", "--path", str(project), "--", "--first-person-smoke"],
                    capture_output=True, text=True, timeout=45,
                )
                output = result.stdout + result.stderr
                print(output, end="")
                return int(bool(result.returncode or "PERSON2_FIRST_PERSON_PASS" not in output
                                or "SCRIPT ERROR" in output or "ERROR:" in output))
            if args.visual_smoke:
                result = subprocess.run(
                    [godot, "--headless", "--path", str(project), "--", "--smoke"],
                    capture_output=True, text=True, timeout=45,
                )
                output = result.stdout + result.stderr
                print(output, end="")
                return int(bool(result.returncode or "PERSON2_VISUAL_SMOKE_PASS" not in output
                                or "SCRIPT ERROR" in output or "ERROR:" in output))
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
