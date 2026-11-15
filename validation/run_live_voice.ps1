param([switch]$Preflight, [int]$Loops = 5)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$pythonExe = Join-Path $env:USERPROFILE '.cache\callout-voice-venv\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $pythonExe)) {
    throw 'Create the voice environment and install validation/voice_runtime_requirements.txt; see bots/LIVE_VOICE.md.'
}
$sourceRoot = Join-Path $env:TEMP 'callout-voice-integration-b84cc93\source'
if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot 'comms\pipeline.py'))) {
    $snapshotRoot = Split-Path $sourceRoot -Parent
    New-Item -ItemType Directory -Force -Path $snapshotRoot | Out-Null
    $archivePath = Join-Path $snapshotRoot 'source.zip'
    & git -C $repoRoot archive --format=zip --output $archivePath b84cc93
    if ($LASTEXITCODE -ne 0) { throw 'Person 3 source b84cc93 unavailable; fetch origin first.' }
    Expand-Archive -LiteralPath $archivePath -DestinationPath $sourceRoot -Force
}
$modelPath = & $pythonExe -c "from huggingface_hub import snapshot_download; print(snapshot_download('Systran/faster-whisper-small.en', local_files_only=True, allow_patterns=['config.json','model.bin','tokenizer.json','vocabulary.*']))"
if ($LASTEXITCODE -ne 0) { throw 'Whisper small.en is not cached. Follow bots/LIVE_VOICE.md to download it.' }
$voiceArgs = @('-u', (Join-Path $repoRoot 'bots\live_voice.py'), '--source-root', $sourceRoot,
    '--model-path', $modelPath.Trim(), '--loops', $Loops, '--output', (Join-Path $repoRoot 'runs\live-voice.jsonl'))
if ($Preflight) { $voiceArgs += '--preflight' }
& $pythonExe @voiceArgs
exit $LASTEXITCODE
