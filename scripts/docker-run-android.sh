#!/usr/bin/env bash
# Chạy app Lab2 trên Android emulator trong Docker (WSL2 / Linux).
# Yêu cầu: Docker, Flutter SDK, ADB trong cùng môi trường WSL/Linux.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ADB_HOST="${ADB_HOST:-localhost}"
ADB_PORT="${ADB_PORT:-5555}"
PACKAGE="com.example.lab2"
APK="$ROOT/build/app/outputs/flutter-apk/app-debug.apk"

echo "==> Starting Android emulator (docker compose)..."
docker compose up -d

echo "==> Waiting for emulator boot (up to 120s)..."
for i in $(seq 1 24); do
  if adb connect "${ADB_HOST}:${ADB_PORT}" 2>/dev/null | grep -q connected; then
    if adb -s "${ADB_HOST}:${ADB_PORT}" shell getprop sys.boot_completed 2>/dev/null | grep -q 1; then
      echo "    Emulator ready."
      break
    fi
  fi
  sleep 5
  if [ "$i" -eq 24 ]; then
    echo "ERROR: Emulator did not boot in time. Check: docker compose logs"
    exit 1
  fi
done

echo "==> flutter pub get"
flutter pub get

echo "==> flutter build apk --debug"
if [ -f "$ROOT/dart_defines.local.json" ]; then
  flutter build apk --debug --dart-define-from-file=dart_defines.local.json
else
  flutter build apk --debug
fi

echo "==> adb install"
adb -s "${ADB_HOST}:${ADB_PORT}" install -r "$APK"

echo "==> Launch app"
adb -s "${ADB_HOST}:${ADB_PORT}" shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1

echo ""
echo "Done."
echo "  noVNC:  http://localhost:6080"
echo "  ADB:    ${ADB_HOST}:${ADB_PORT}"
echo "  Package: $PACKAGE"
