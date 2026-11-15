@echo off
cd /d "%~dp0"
if exist "C:\Users\Siddh\tools\godot\Godot_v4.4.1-stable_win64.exe" (
    start "" "C:\Users\Siddh\tools\godot\Godot_v4.4.1-stable_win64.exe" --path .
) else (
    start "" godot --path .
)
