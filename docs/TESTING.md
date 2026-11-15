# Testing and diagnostics

Run commands from the repository in PowerShell after [setup](SETUP.md). Use Godot
**4.4.1 stable**. The runner creates isolated temporary projects and preserves
strict engine-error checks and 45-second per-run timeouts.

```powershell
$pythonExe = "$env:USERPROFILE\.cache\callout-voice-venv\Scripts\python.exe"
$godotExe = "$env:USERPROFILE\.cache\callout-godot-4.4.1\Godot_v4.4.1-stable_win64_console.exe"
& $pythonExe tools/check_repo.py
git diff --check
```

## Required bot and current-site checks

Run each command separately:

```powershell
& $pythonExe validation/run_person2_tests.py --godot $godotExe --person1-ref 0260f28 --person3-ref 57f809d
& $pythonExe validation/run_person2_tests.py --godot $godotExe --site-smoke --person3-ref 57f809d
& $pythonExe validation/run_person2_tests.py --godot $godotExe --site-smoke --position-orders-only --person3-ref 57f809d
& $pythonExe validation/run_person2_tests.py --godot $godotExe --site-smoke --completed-movement-only --person3-ref 57f809d
```

The gameplay checkpoint `73cb362`, merged into main at `6175400`, passed:

| Suite | Checks | Scope |
|---|---:|---|
| Required bot/cross-component suites | 575 | Commands, planner, perception, motion, intent gate, flash, combat, annotation and integrations |
| Current site | 47 | Geometry/arrivals, utility, blind firing gate, death/reset, actual box ascent/descent and holding the commanded elevation |
| Explicit positioning | 24 | Radio delay, real travel/holding in Heaven, reports, replacement, cancellation, ordering and stale session protection |
| Completed movement | 10 | Logged push proposal, actual A Link swing, holding after expiry and duplicate completion protection |

These 656 automated checks concern the stated gameplay revision. Documentation
cleanup only requires the documentation and whitespace checks above; historical
totals are not claims of fresh runtime tests for a docs-only change.

The long positioning holds run separately so the combined scene fixture does not
exceed its existing timeout. Do not increase expiry/timeouts or suppress errors
to manufacture a passing result. Known runtime navigation-bake and ObjectDB-at-exit
warnings remain distinct from script/engine errors.

## Other development checks

```powershell
# The TCP room fixture needs its original matching map, not the new site snapshot.
& $pythonExe validation/run_person2_tests.py --godot $godotExe --voice-smoke --person1-ref 8712f7d --person3-ref 57f809d
& $pythonExe validation/run_person2_tests.py --godot $godotExe --perception-smoke --person1-ref 8712f7d --person3-ref 57f809d
& $pythonExe validation/check_lotus.py
```

Python authoring/voice tests additionally use pytest, installed separately in the
development environment:

```powershell
& $pythonExe -m pip install pytest
& $pythonExe -m pytest tests/person2/test_lotus_authoring.py tests/person2/test_voice_host.py -q
```

The earlier TCP voice fixture passed 35 checks; that result predates the final
completed-movement change. The earlier live-perception fixture passed 139 checks.
Use their matching sources and report actual new results when rerunning.

For a rendered site capture, add `--site-capture "$env:TEMP\callout-site.png"`
to `--site-smoke`. It opens a rendering window and adds capture verification;
headless runs cannot establish layout or player feel.

## Voice and model diagnostics

`validation/run_live_voice.ps1 -Preflight` checks CUDA/STT loading without gameplay.
`-Loops 5` captures standalone human calls. The real-model engine bridge fixture is:

```powershell
$sourceRoot = "$env:TEMP\callout-voice-integration-b84cc93\source"
& $pythonExe validation/run_voice_model_smoke.py --godot $godotExe --source-root $sourceRoot --interpret-only
```

Prepare the Python source cache using the normal launcher/preflight first. Omitting
`--interpret-only` selects the separate unaccepted full-model-goal experiment;
its failures are not ordinary demo regressions.

Do not run competing microphone hosts during a human demo. Test new spoken behavior
through the actual transcript, submitted order, delivery and physical result in
ignored run logs. The model proposal can differ from engine normalization. A recent
example was "Let's push A Link together": the first positioning patch missed the
swing-completion path, so the follow-up tests now verify that it stays at A Link.

Human playtests, rendered captures, typed/synthetic fixtures, exported builds and
offline deployment are different evidence. The demo does not claim measured
training benefit, professional fidelity or a completed full-game fairness audit.
