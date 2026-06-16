# Docker — Bonus Android

Chạy Flutter app trên **Android emulator trong Docker** (Lab2 bonus).

## Yêu cầu

- **WSL2 Ubuntu** (Windows) hoặc native Linux
- Docker + Docker Compose
- Flutter SDK và ADB **trong WSL/Linux** (không dùng Flutter Windows cho bước ADB)
- RAM khuyến nghị ≥ 8 GB

## Nhanh

### WSL / Linux

```bash
cd PRM393_Lab2_SE182125
chmod +x scripts/docker-run-android.sh
./scripts/docker-run-android.sh
```

### Windows (PowerShell → WSL)

```powershell
cd PRM393_Lab2_SE182125
.\scripts\docker-run-android.ps1
```

Script sẽ:

1. `docker compose up -d` — emulator `budtmo/docker-android`
2. Đợi boot + `adb connect localhost:5555`
3. `flutter build apk --debug`
4. `adb install` + mở app `com.example.lab2`

## Xem emulator

- noVNC: http://localhost:6080
- ADB: `adb connect localhost:5555`

## Lệnh thủ công

```bash
docker compose up -d
docker compose down
adb devices
```

## Ghi chú

- Image cần `/dev/kvm` trên Linux — WSL2 có thể cần bật nested virtualization trong BIOS.
- Nếu KVM không có, thử bỏ block `devices:` trong `docker-compose.yml` (emulator chậm hơn).
- Chi tiết troubleshooting: [docs/runbooks/docker-android-bonus.md](../../docs/runbooks/docker-android-bonus.md)
