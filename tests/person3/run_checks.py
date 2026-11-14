"""Run Person 3's pure GDScript checks in a temporary project (no main-scene edits)."""
import argparse
from pathlib import Path
import shutil
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True, help="Path to a Godot 4 stable executable")
    parser.add_argument("--person2-root", type=Path, help="Optional Person 2 checkout for read-only executor integration checks")
    args = parser.parse_args()
    godot = shutil.which(args.godot) or str(Path(args.godot).resolve())
    version = subprocess.run([godot, "--version"], capture_output=True, text=True, check=True, timeout=15)
    print("Editor:", version.stdout.strip())
    if not version.stdout.startswith("4.") or ".stable" not in version.stdout:
        raise RuntimeError("Expected Godot 4 stable; team-wide version pin remains Person 1's responsibility")
    with tempfile.TemporaryDirectory(prefix="callout-person3-") as temporary:
        project = Path(temporary)
        for directory in ("belief", "comms", "grading", "recording", "tests/person3"):
            for source in (ROOT / directory).glob("*.gd"):
                target = project / source.relative_to(ROOT)
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, target)
        (project / "examples").mkdir()
        shutil.copy2(ROOT / "examples/person3_fake_run.json", project / "examples/person3_fake_run.json")
        if args.person2_root:
            for relative in ("perception/plain_data.gd", "perception/observation_inbox.gd",
                             "validation/comms_validator.gd", "bots/command_executor.gd",
                             "schemas/comms_v1.schema.json"):
                target = project / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(args.person2_root / relative, target)
        (project / "project.godot").write_text(
            'config_version=5\n[application]\nconfig/name="Person 3 isolated checks"\n'
            '[rendering]\nrenderer/rendering_method="gl_compatibility"\n', encoding="utf-8")
        scripts = [("run_tests.gd", "PERSON3_TESTS_PASS")]
        if args.person2_root:
            scripts.append(("executor_integration.gd", "PERSON3_INTEGRATION_PASS"))
        for script, marker in scripts:
            result = subprocess.run(
                [godot, "--headless", "--path", str(project), "--script", "res://tests/person3/" + script],
                capture_output=True, text=True, timeout=45)
            output = result.stdout + result.stderr
            print(output, end="")
            # This offline suite does not use TLS. Tolerate only this exact
            # sandbox diagnostic; preserve it in output and reject all others.
            checked_output = re.sub(
                r"ERROR: Failed to read the root certificate store\.\r?\n"
                r"\s+at: get_system_ca_certificates \(platform/windows/os_windows\.cpp:\d+\)\r?\n?",
                "", output)
            if checked_output != output:
                print("Environment note: Windows certificate-store access unavailable; offline assertions completed.")
            if result.returncode or marker not in output or "SCRIPT ERROR" in checked_output or "ERROR:" in checked_output:
                return 1
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
