# Verification script — chạy trước khi coi task hoàn thành
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

Write-Host "==> flutter pub get" -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "==> flutter analyze" -ForegroundColor Cyan
flutter analyze
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "==> flutter test" -ForegroundColor Cyan
$DefinesFile = Join-Path $Root "dart_defines.local.json"
if (Test-Path $DefinesFile) {
  flutter test --dart-define-from-file=dart_defines.local.json
} else {
  flutter test
}
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "==> All checks passed" -ForegroundColor Green
