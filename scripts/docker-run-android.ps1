# Chạy bonus Docker Android từ Windows qua WSL2.
# Yêu cầu: WSL2 Ubuntu, Docker Desktop (WSL integration), Flutter trong WSL.

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$WslPath = wsl wslpath -a $ProjectRoot

Write-Host "==> Running docker-run-android.sh in WSL: $WslPath" -ForegroundColor Cyan
wsl bash -lc "cd '$WslPath' && chmod +x scripts/docker-run-android.sh && ./scripts/docker-run-android.sh"
