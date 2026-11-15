param([switch]$ModelGoals)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$pythonExe = Join-Path $env:USERPROFILE '.cache\callout-voice-venv\Scripts\python.exe'
$godotExe = Join-Path $env:USERPROFILE '.cache\callout-godot-4.4.1\Godot_v4.4.1-stable_win64_console.exe'
$sourceRoot = Join-Path $env:TEMP 'callout-voice-integration-b84cc93\source'
if (-not (Test-Path -LiteralPath $godotExe)) { throw 'Install pinned Godot 4.4.1; see bots/VOICE_GAME.md.' }
if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot 'comms\interpreter.py'))) {
    & (Join-Path $PSScriptRoot 'run_live_voice.ps1') -Preflight
    if ($LASTEXITCODE -ne 0) { throw 'Voice preflight failed' }
}
$modelPath = & $pythonExe -c "from huggingface_hub import snapshot_download; print(snapshot_download('Systran/faster-whisper-small.en', local_files_only=True, allow_patterns=['config.json','model.bin','tokenizer.json','vocabulary.*']))"
if ($LASTEXITCODE -ne 0) { throw 'Whisper model is not cached' }
Push-Location $repoRoot
try {
    Write-Host 'Warming local models before starting the round...'
    & $pythonExe -c "import sys; sys.path.insert(0,'bots'); from voice_host import warm_model; warm_model('http://127.0.0.1:11434','llama3.1:8b')"
    if ($LASTEXITCODE -ne 0) { throw 'Interpreter model unavailable' }
    if ($ModelGoals) {
        & $pythonExe -c "import sys; sys.path.insert(0,'bots'); from voice_host import warm_model; warm_model('http://127.0.0.1:11434','qwen2.5:3b')"
        if ($LASTEXITCODE -ne 0) { throw 'Experimental goal model unavailable; omit -ModelGoals for the scripted planner' }
    }
    $portProbe = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
    $portProbe.Start()
    $voicePort = $portProbe.LocalEndpoint.Port
    $portProbe.Stop()
    $runRoot = Join-Path $repoRoot ('runs\voice-game-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    New-Item -ItemType Directory -Force -Path $runRoot | Out-Null
    $gameLog = Join-Path $runRoot 'game.log'
    $gameErrors = Join-Path $runRoot 'game-errors.log'
    $gameArgs = @('-u', "`"$(Join-Path $PSScriptRoot 'run_person2_tests.py')`"", '--godot', "`"$godotExe`"",
        '--voice-playtest', '--voice-port', $voicePort, '--person1-ref', '8712f7d', '--person3-ref', '57f809d')
    $gameProcess = Start-Process -FilePath $pythonExe -ArgumentList $gameArgs -WorkingDirectory $repoRoot -WindowStyle Hidden -RedirectStandardOutput $gameLog -RedirectStandardError $gameErrors -PassThru
    $ready = $false
    $readyDeadline = (Get-Date).AddSeconds(30)
    while ((Get-Date) -lt $readyDeadline -and -not $gameProcess.HasExited) {
        if ((Test-Path -LiteralPath $gameLog) -and (Select-String -LiteralPath $gameLog -Pattern 'PERSON2_VOICE_READY' -Quiet)) { $ready = $true; break }
        Start-Sleep -Milliseconds 100
    }
    if (-not $ready) { throw "Game not ready; inspect $runRoot" }
    $hostArgs = @('-u', (Join-Path $repoRoot 'bots\voice_host.py'), '--source-root', $sourceRoot,
        '--model-path', $modelPath.Trim(), '--port', $voicePort, '--output', $runRoot)
    if ($ModelGoals) { $hostArgs += '--model-goals' }
    Write-Host 'Voice game ready. F restarts the round. Hold Right Ctrl to speak.'
    & $pythonExe @hostArgs
} finally {
    Pop-Location
}
