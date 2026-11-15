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
    "scenarios/b_site_coverage.json",
    "perception/perception_sensor.gd", "tests/person2/perception_tests.gd",
    "tests/person2/physics_probe.gd",
    "bots/motion_controller.gd", "tests/person2/motion_tests.gd",
    "tests/person2/motion_actor.gd", "tests/person2/motion_navigation.gd",
    "bots/intent_gate.gd", "tests/person2/intent_gate_tests.gd",
    "bots/flash_controller.gd",
    "bots/visible_flash_controller.gd",
    "tests/person2/flash_tests.gd",
    "bots/combat_policy.gd", "bots/combat_controller.gd",
    "tests/person2/combat_tests.gd",
    "bots/annotation_policy.gd", "bots/retake_policy.gd",
    "scenarios/fnc_prx_lotus_toronto2024_gf.json", "tests/person2/annotation_tests.gd",
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
    mode.add_argument("--action-playtest", action="store_true", help="Open inherited first-person developer action controls (synthetic comms/goals)")
    mode.add_argument("--action-smoke", action="store_true", help="Headless inherited first-person action-control and physical execution assertions")
    mode.add_argument("--voice-playtest", action="store_true", help="Open synthetic FPS with localhost voice/model bridge")
    mode.add_argument("--voice-smoke", action="store_true", help="Real TCP voice delivery/goal/reset regression")
    mode.add_argument("--lotus-playtest", action="store_true", help="Seven-region plant-start adaptation; enemies arrive at first known positions")
    mode.add_argument("--lotus-smoke", action="store_true", help="Seven-region geometry/nav and late enemy spawning regression")
    mode.add_argument("--site-playtest", action="store_true", help="Plant-hold voice game on Person 3 seven-zone B site map")
    mode.add_argument("--site-smoke", action="store_true", help="Seven-zone B site scenario and source-map integration checks")
    mode.add_argument("--combat-ui-smoke", action="store_true", help="Combat UI regression in the real site scene")
    parser.add_argument("--combat-ui-capture", type=Path, help="Rendered combat UI capture prefix")
    parser.add_argument("--site-capture", type=Path, help="Optional rendered B site capture from --site-smoke")
    parser.add_argument("--voice-port", type=int, default=8765)
    parser.add_argument("--combat-damage-debug", action="store_true", help="Log privileged physical shot collisions and HP changes; never sent to policy")
    parser.add_argument("--voice-headless", action="store_true", help="Developer external-host fixture, no window")
    parser.add_argument("--voice-interpret-only", action="store_true", help="External fixture requires LLM interpretation with scripted goals")
    mode.add_argument("--first-person-smoke", action="store_true", help="Headless first-person scene/comm/intent integration assertions")
    mode.add_argument("--perception-smoke", action="store_true", help="Inherited FPS live perception and fairness assertions")
    mode.add_argument("--hud-smoke", action="store_true", help="Teammate information HUD and real enemy test-control assertions")
    parser.add_argument("--hud-capture", type=Path, help="Optional rendered HUD PNG from --hud-smoke (opens a temporary game window)")
    parser.add_argument("--lotus-capture", type=Path, help="Optional rendered late-arrival frame from --lotus-smoke")
    person3 = parser.add_mutually_exclusive_group()
    person3.add_argument("--person3-root", type=Path, help="Optional Person 3 checkout; copy belief files read-only to the temporary project")
    person3.add_argument("--person3-ref", help="Optional fetched git ref; read Person 3 belief files without changing a checkout")
    parser.add_argument("--person1-ref", help="Optional fetched git ref; test actual shared actor and baked room (requires Person 3 input)")
    args = parser.parse_args()
    if args.hud_capture and not args.hud_smoke:
        parser.error("--hud-capture requires --hud-smoke")
    if args.lotus_capture and not args.lotus_smoke:
        parser.error("--lotus-capture requires --lotus-smoke")
    if args.site_capture and not args.site_smoke:
        parser.error("--site-capture requires --site-smoke")
    if args.combat_ui_capture and not args.combat_ui_smoke:
        parser.error("--combat-ui-capture requires --combat-ui-smoke")
    action_mode = args.action_playtest or args.action_smoke
    combat_ui = args.combat_ui_smoke
    site_mode = args.site_playtest or args.site_smoke or combat_ui
    lotus_mode = args.lotus_playtest or args.lotus_smoke or site_mode
    if lotus_mode:
        from check_lotus import validate_files
        authoring_errors = validate_files()
        if authoring_errors:
            print("Invalid Lotus adaptation: " + "; ".join(authoring_errors), file=sys.stderr)
            return 1
    voice_mode = args.voice_playtest or args.voice_smoke or lotus_mode
    first_person = args.first_person or args.first_person_smoke or args.perception_smoke or args.hud_smoke or action_mode or voice_mode
    visual = args.visual_demo or args.visual_smoke
    if visual or first_person:
        args.person1_ref = args.person1_ref or ("0260f28" if site_mode else "origin/main" if first_person else "0fd1285")
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
                # User-requested shared mechanics: use the current wave/player,
                # rifle damage, utility attribution and round cleanup scripts.
                for relative in ["utility/blind_wave.gd", "utility/utility_system.gd", "utility/molly.gd", "scenes/player/player.gd", "weapons/weapon.gd"]:
                    shutil.copy2(ROOT / relative, project / relative)
                print("PERSON2_SHARED_OVERLAY utility/blind_wave.gd utility/utility_system.gd utility/molly.gd scenes/player/player.gd weapons/weapon.gd (user-requested mechanics)")
                for relative in ["bots/teammate_runtime.gd", "scenes/bots/bot.tscn",
                                 "perception/scene_sensor.gd",
                                 "scenes/bots/teammate_info_panel.gd",
                                 "scenes/bots/first_person.gd", "scenes/bots/first_person.tscn",
                                 "scenarios/b_site_coverage.json",
                                 "tests/person2/first_person_smoke.gd"]:
                    target = project / relative
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(ROOT / relative, target)
                shutil.copy2(ROOT / "tests/person2/scene_perception_smoke.gd", project / "tests/person2/scene_perception_smoke.gd")
                shutil.copy2(ROOT / "tests/person2/teammate_hud_smoke.gd", project / "tests/person2/teammate_hud_smoke.gd")
                if action_mode:
                    for relative in ["scenes/bots/action_playtest.tscn", "scenes/bots/action_playtest.gd",
                                     "scenes/bots/action_test_panel.gd", "tests/person2/action_playtest_smoke.gd"]:
                        target = project / relative
                        target.parent.mkdir(parents=True, exist_ok=True)
                        shutil.copy2(ROOT / relative, target)
                if voice_mode:
                    for relative in ["scenes/bots/voice_bridge.gd", "scenes/bots/voice_playtest.gd",
                                     "scenes/bots/voice_playtest.tscn", "tests/person2/voice_bridge_smoke.gd"]:
                        target = project / relative
                        target.parent.mkdir(parents=True, exist_ok=True)
                        shutil.copy2(ROOT / relative, target)
                if lotus_mode:
                    for relative in ["ui/combat_feedback.gd", "tests/person2/combat_ui_smoke.gd",
                                     "world/lotus_builder.gd", "world/maps/lotus_b_adaptation.json",
                                     "scenarios/lotus_b_coverage.json", "scenarios/first_known_spawns.gd",
                                     "scenarios/fnc_prx_lotus_toronto2024_gf.json",
                                     "bots/annotation_policy.gd", "bots/annotation_executor.gd",
                                     "bots/retake_policy.gd", "scenes/bots/lotus_playtest.gd",
                                     "scenes/bots/lotus_playtest.tscn", "tests/person2/lotus_smoke.gd"]:
                        target = project / relative
                        target.parent.mkdir(parents=True, exist_ok=True)
                        shutil.copy2(ROOT / relative, target)
            if site_mode:
                for relative in ["world/site_builder.gd", "scenarios/site_coverage.json",
                                 "scenes/bots/site_playtest.gd", "scenes/bots/site_playtest.tscn",
                                 "tests/person2/site_smoke.gd"]:
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
                                            'run/main_scene="res://scenes/bots/site_playtest.tscn"' if site_mode else 'run/main_scene="res://scenes/bots/lotus_playtest.tscn"' if lotus_mode else 'run/main_scene="res://scenes/bots/voice_playtest.tscn"' if voice_mode else 'run/main_scene="res://scenes/bots/action_playtest.tscn"' if action_mode
                                            else 'run/main_scene="res://scenes/bots/first_person.tscn"')
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
                ("flash_tests.gd", "PERSON2_FLASH_PASS"),
                ("combat_tests.gd", "PERSON2_COMBAT_PASS"),
                ("annotation_tests.gd", "PERSON2_ANNOTATION_PASS"),
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
            if args.visual_demo or args.first_person or args.action_playtest or args.voice_playtest or args.lotus_playtest or args.site_playtest:
                print("Opening synthetic first-person voice bridge. Close the window to return." if args.voice_playtest else "Opening first-person scene (voice backend not connected). Close the window to return."
                      if args.first_person or args.action_playtest else "Opening overhead motion test. Close window or press Esc to return.", flush=True)
                # Human-controlled run: keep the temporary project alive until
                # the window closes; no short test timeout or headless flag.
                return subprocess.run([godot, *(["--headless"] if args.voice_headless else []), "--path", str(project), *(["--", "--voice-port=" + str(args.voice_port), *(["--combat-damage-debug"] if args.combat_damage_debug else []), *(["--voice-interpret-fixture" if args.voice_interpret_only else "--voice-model-fixture"] if args.voice_headless else [])] if args.voice_playtest or args.lotus_playtest or args.site_playtest else [])], check=False).returncode
            if args.first_person_smoke or args.perception_smoke or args.hud_smoke or args.action_smoke or args.voice_smoke or args.lotus_smoke or args.site_smoke or combat_ui:
                smoke_mode = "--site-smoke" if args.site_smoke else "--lotus-smoke" if args.lotus_smoke else "--voice-smoke" if args.voice_smoke else "--action-smoke" if args.action_smoke else ("--hud-smoke" if args.hud_smoke else ("--perception-smoke" if args.perception_smoke else "--first-person-smoke"))
                if combat_ui:
                    smoke_mode = "--combat-ui-smoke"
                marker = "PERSON2_SITE_PASS" if args.site_smoke else "PERSON2_LOTUS_PASS" if args.lotus_smoke else "PERSON2_VOICE_SMOKE_PASS" if args.voice_smoke else "PERSON2_ACTION_PASS" if args.action_smoke else ("PERSON2_HUD_PASS" if args.hud_smoke else ("PERSON2_SCENE_PERCEPTION_PASS" if args.perception_smoke else "PERSON2_FIRST_PERSON_PASS"))
                if combat_ui:
                    marker = "PERSON2_COMBAT_UI_PASS"
                command = [godot, *([] if args.combat_ui_capture or args.hud_capture or args.lotus_capture or args.site_capture else ["--headless"]), "--path", str(project), "--", smoke_mode]
                if combat_ui:
                    command.append("--voice-port=0")
                if args.combat_damage_debug:
                    command.append("--combat-damage-debug")
                if args.combat_ui_capture:
                    command.append("--combat-ui-capture=" + str(args.combat_ui_capture.resolve()))
                if args.hud_capture:
                    command.append("--hud-capture=" + str(args.hud_capture.resolve()))
                if args.voice_smoke or args.lotus_smoke or args.site_smoke:
                    command.append("--voice-port=0")
                if args.lotus_capture:
                    command.append("--lotus-capture=" + str(args.lotus_capture.resolve()))
                if args.site_capture:
                    command.append("--site-capture=" + str(args.site_capture.resolve()))
                result = subprocess.run(
                    command,
                    capture_output=True, text=True, timeout=45,
                )
                output = result.stdout + result.stderr
                print(output, end="")
                return int(bool(result.returncode or marker not in output
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
        if isinstance(exc, subprocess.TimeoutExpired):
            for captured in (exc.stdout, exc.stderr):
                if captured:
                    print(captured.decode("utf-8", errors="replace") if isinstance(captured, bytes) else captured, end="")
        print("Person 2 checks failed: " + str(exc), file=sys.stderr)
        traceback.print_exc()
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
