# Journal Trend Analyzer — PRM393 Lab 2

App Flutter tra cứu xu hướng nghiên cứu khoa học qua [OpenAlex API](https://developers.openalex.org/).

**MSSV / repo mẫu:** [hdant2/PRM393_Lab2_SE182125](https://github.com/hdant2/PRM393_Lab2_SE182125)

## Tính năng

- Tìm kiếm bài báo theo chủ đề (topic)
- Dashboard thống kê (papers, citation, trend, top author/journal/paper)
- Biểu đồ xu hướng theo năm (`fl_chart`)
- Top Papers / Journals / Authors + màn chi tiết

## Kiến trúc

```
lib/
  model/       Publication, Author, Journal
  services/    OpenAlexService
  providers/   PublicationProvider (Provider)
  screens/     UI
  widgets/     PublicationCard, DashboardCard, TrendChart
```

## Yêu cầu

- Flutter SDK 3.x
- Dart ^3.11

## Chạy app

```powershell
cd PRM393_Lab2_SE182125
flutter pub get
flutter run
```

Chọn thiết bị: Windows / Chrome / Android emulator / điện thoại thật.

### OpenAlex API key (tùy chọn)

Lấy key miễn phí tại [openalex.org/settings/api](https://openalex.org/settings/api).

**Cách 1 — file local (khuyến nghị):**

```powershell
copy dart_defines.example.json dart_defines.local.json
# Sửa OPENALEX_API_KEY trong dart_defines.local.json
.\scripts\run.ps1
```

File `dart_defines.local.json` đã được `.gitignore` — **không push lên GitHub**.

**Cách 2 — dart-define trực tiếp:**

```powershell
flutter run --dart-define=OPENALEX_API_KEY=your_key_here
```

## Kiểm tra chất lượng

```powershell
.\scripts\verify.ps1
```

Chạy lần lượt: `flutter pub get` → `flutter analyze` → `flutter test`.

## Bonus: Android trên Docker

Cần **WSL2 Ubuntu** + Docker Desktop (WSL integration).

```powershell
.\scripts\docker-run-android.ps1
```

Hoặc trong WSL:

```bash
./scripts/docker-run-android.sh
```

- Emulator UI: http://localhost:6080
- ADB: `localhost:5555`
- Chi tiết: [docker/README.md](docker/README.md)

## Cấu trúc màn hình

```
Search → Dashboard → Trend / Top Papers / Top Journals / Top Authors
                  → Detail (publication / author / journal)
```

## Dependencies

| Package | Mục đích |
|---------|----------|
| `provider` | State management |
| `http` | Gọi OpenAlex |
| `fl_chart` | Biểu đồ trend |

## Harness / AI agent

Workspace gốc `PRM/` có `AGENTS.md` và `docs/` hướng dẫn phát triển với Cursor agent.
