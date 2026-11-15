# Current run and delivery status

Use **Godot 4.4.1 stable**, standard GDScript/Compatibility build. Current executable
paths, dependencies and acceptance results are in [the handoff](PERSON2_HANDOFF.md).

## Run the voice-enabled scenario on the configured PC

Close older voice-host consoles, then use PowerShell:

```powershell
cd "C:\Users\Isoto\Documents\GitHub\callout-trainer"
.\validation\run_voice_game.ps1 -Lotus
```

Right Ctrl talks, F restarts at plant, Esc releases the mouse. Omit `-Lotus` for the
older three-region integration profile. [Scenario guide](../bots/LOTUS_SCENARIO.md),
[voice setup](../bots/LIVE_VOICE.md) and [bridge guide](../bots/VOICE_GAME.md) explain
the installed environment and measured limits.

The root `project.godot` still selects the original scaffold. The current launcher
prepares a disposable integrated project, including pinned Person 3 dependencies,
and keeps it alive while the game runs. Do not assume root export commands package
the new scenario, Python host, model runtime or weights correctly.

## Export is remaining work

No successful integrated voice-to-scenario desktop export or human exported-build
acceptance is recorded. Before claiming one:

1. Prepare a durable integrated project with the intended main scene and actual pinned
   dependencies, preserving the original map/profile.
2. Install matching **4.4.1-stable export templates** and verify the actual export preset.
3. Package/launch the local Python voice host and Ollama dependencies with clear setup.
   Keep model licensing/redistribution explicit; cached weights on this PC do not prove
   a new machine can run the product offline.
4. Export and test the exact target build. If the preset uses a separate `.pck`, ship it
   with the executable. Keep generated artifacts out of Git.
5. Test rendering, movement/collision, voice-to-reaction, death/reset, utility, fallback
   and first-known enemy spawning on that build. Record actual results separately from
   headless checks. Verify offline behavior without assuming localhost means no setup.
6. Record a backup video and rehearse bot -> scenario -> trace. Never claim measured
   benefit or pro fidelity from a successful export.

The old scaffold-only export guide is preserved at
[608cae7](https://github.com/Wonho2007/callout-trainer/blob/608cae7/docs/BUILD.md).
Its existence is not an exported-build acceptance result.
