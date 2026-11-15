# Build, run and export (Person 1)

Reproducible commands for the Godot project. Editor pinned to **Godot 4.4.1
stable, Windows 64-bit standard (GDScript) build** (see docs/DECISIONS.md). All
developers must use this exact editor and matching export templates.

Replace `GODOT` below with the path to your extracted editor executable, e.g.
`C:\Godot\Godot_v4.4.1-stable_win64.exe`. On Windows PowerShell, use the
`_console` variant if you want to see stdout, or prefix with `&`.

## Run in the editor

Open `project.godot` in Godot and press F5, or from the command line:

```powershell
& "GODOT" --path . 
```

Main scene is `scenes/main.tscn`. Controls: WASD move, mouse look, Shift walk,
Ctrl crouch, Space jump, R restart, Esc free/recapture mouse.

## One-time: install export templates

The exported build needs the export templates that match the editor version.
In the editor: **Editor -> Manage Export Templates -> Download and Install**.
This downloads the 4.4.1-stable templates. Do this once per machine.

## Export a Windows desktop build

The preset `export_presets.cfg` ("Windows Desktop", x86_64) writes to
`build/windows/callout-trainer.exe`. `build/` is gitignored, so the binary is
not committed.

GUI: **Project -> Export -> Windows Desktop -> Export Project**, save as
`build/windows/callout-trainer.exe`.

Headless / command line (release build):

```powershell
New-Item -ItemType Directory -Force -Path build\windows | Out-Null
& "GODOT" --headless --path . --export-release "Windows Desktop" "build/windows/callout-trainer.exe"
```

For a debug build (shows the console window), use `--export-debug` instead of
`--export-release`.

## Run the exported build

```powershell
& "build\windows\callout-trainer.exe"
```

The build is offline-capable: no network, no paid services. A headless export
succeeding does NOT prove the build renders or plays — launch the `.exe` and
confirm the room renders, movement/collision work and the HUD/disclaimer show.

## Notes

- The export is a standalone `.exe` plus a `.pck` data file in the same folder
  (the preset does not embed the pck). Ship both together, or set
  `binary_format/embed_pck=true` for a single file.
- Re-baking navigation happens automatically at runtime when the room builds;
  no editor nav-bake step is needed before export.
- Record automated export results separately from manual playtest of the
  exported build (see docs/AGENT_WORKFLOW.md).
