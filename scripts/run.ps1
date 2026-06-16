# Chạy app với OpenAlex API key từ dart_defines.local.json (nếu có)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

$DefinesFile = Join-Path $Root "dart_defines.local.json"

if (Test-Path $DefinesFile) {
  Write-Host "Using API key from dart_defines.local.json" -ForegroundColor Cyan
  flutter run --dart-define-from-file=dart_defines.local.json @args
} else {
  Write-Host "No dart_defines.local.json — copy from dart_defines.example.json" -ForegroundColor Yellow
  flutter run @args
}
